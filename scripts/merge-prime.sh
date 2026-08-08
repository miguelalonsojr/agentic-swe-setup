#!/usr/bin/env bash
# Merge this repo's managed keys into Prime Agent's settings and harness state.
#
# Prime Agent has no agent-definition files and no plugin system. Model tiers
# live in settings.json, and every role is installed as a continual-harness
# subagent spec so `rlm(...)` dispatches can look up a model per role.
#
# Usage: merge-prime.sh <provider>
# Exit:  0 merged
#        1 error
#        2 settings.json is not strict JSON (comments) — nothing was written

set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-}
[ -n "$provider" ] || die "usage: merge-prime.sh <provider>"

src="$REPO_ROOT/prime/$provider.json"
[ -f "$src" ] || die "unknown provider '$provider' (no $src)"
have jq || die "jq is required to merge Prime Agent settings"

dir=$(prime_dir)
settings="$dir/settings.json"
harness="$dir/harness/harness_state.json"
manifest="$dir/.agentic-swe-setup.json"
mkdir -p "$dir" "$dir/harness"

backup=""
if [ -f "$settings" ]; then
    if ! jq -e . "$settings" >/dev/null 2>&1; then
        warn "$settings is not strict JSON (comments?); refusing to rewrite it"
        {
            printf '\nAdd these keys to %s by hand, then re-run:\n\n' "$settings"
            jq -S .settings "$src"
            printf '\n'
        } >&2
        exit 2
    fi
    backup="$settings.bak.$(date +%s)"
    cp "$settings" "$backup"
    log "backed up $settings to $backup"
else
    printf '{}\n' > "$settings"
fi

# --- settings.json: model defaults plus the skills search path -------------
# Prime Agent discovers ~/.prime/agent/skills automatically, so the skills
# array only needs the two shared checkouts that live outside it.
tmp=$(mktemp)
jq -n \
    --argjson base "$(cat "$settings")" \
    --argjson mgd "$(cat "$src")" '
      ($mgd.settings // {}) as $s
    | $base
    # Right-biased: managed defaults win, unmanaged settings survive.
    | . + $s
    ' > "$tmp"
mv "$tmp" "$settings"

# --- harness_state.json: one subagent spec per role ------------------------
[ -f "$harness" ] || printf '{"schema":1,"entries":{},"refinements":[]}\n' > "$harness"
if ! jq -e . "$harness" >/dev/null 2>&1; then
    warn "$harness is not valid JSON; replacing it with a fresh store"
    printf '{"schema":1,"entries":{},"refinements":[]}\n' > "$harness"
fi

now=$(date -u +%Y-%m-%dT%H:%M:%S+00:00)
tmp=$(mktemp)
jq -n \
    --argjson base "$(cat "$harness")" \
    --argjson mgd "$(cat "$src")" \
    --arg now "$now" \
    --arg provider "$provider" '
      def spec($name; $cfg):
        { id: ($name | gsub("-"; "_")),
          kind: "subagent",
          title: $name,
          # Prime Agent truncates this at 180 chars and shows only six specs
          # per kind (refinement.js:12,14), neither of which an installer can
          # raise. So the dispatch form leads: truncation can then only cost
          # the hint, never the call an agent needs to make. The role name is
          # already printed from `title`, the selector is already in the
          # dispatch form, and rlm() cannot be passed a thinking level, so
          # none of those are repeated here.
          content: (
            "await rlm(task, name=\"" + $name + "\", model=\"" + $cfg.model + "\")"
            + (if $cfg.readOnly then " | read-only" else "" end)
            # A missing hint would otherwise silently degrade to a dangling
            # " | " separator (jq treats null as the identity for +), so
            # fail loud at generation time instead of emitting a malformed
            # spec.
            + " | " + ($cfg.hint // error("no hint for " + $name))
          ),
          path: "swe/roles",
          scope: "global",
          reference: {},
          arguments: {},
          metadata: {
            model: $cfg.model,
            thinking: $cfg.thinking,
            mode: ($cfg.mode // "primary"),
            read_only: ($cfg.readOnly // false),
            provider: $provider,
            managed_by: "agentic-swe-setup"
          },
          source: "agentic-swe-setup",
          created_at: $now,
          updated_at: $now,
          version: 1 };

      ( [ $mgd.agent | to_entries[] | { key: (.key | gsub("-"; "_")),
                                        value: spec(.key; .value) } ] | from_entries
      ) as $specs
    | $base
    | .schema = (.schema // 1)
    | .refinements = (.refinements // [])
    | .entries = (.entries // {})
    # Preserve created_at for specs we already installed, so re-running does
    # not make every role look brand new.
    | .entries.subagent = (
        (.entries.subagent // {}) as $old
        | (.entries.subagent // {}) + (
            $specs | with_entries(
              .value.created_at = (($old[.key].created_at) // .value.created_at)
            )
          )
      )
    ' > "$tmp"
mv "$tmp" "$harness"

printf '%s\n' "${PRIME_AGENTS[@]}" \
    | jq -R . \
    | jq -s \
        --arg provider "$provider" \
        --arg backup "$backup" \
        --argjson settings_keys "$(jq -c '.settings | keys' "$src")" \
        '{provider: $provider,
          backup: $backup,
          agents: .,
          settings_keys: $settings_keys}' \
    > "$manifest"

log "merged $provider config into $settings and $harness"
