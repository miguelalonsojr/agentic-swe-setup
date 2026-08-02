#!/usr/bin/env bash
# Merge this repo's managed keys into the user's opencode.jsonc.
#
# Usage: merge-opencode.sh <provider>
# Exit:  0 merged
#        1 error
#        2 target is not strict JSON (JSONC comments) — nothing was written

set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

provider=${1:-}
[ -n "$provider" ] || die "usage: merge-opencode.sh <provider>"

src="$REPO_ROOT/opencode/$provider.json"
[ -f "$src" ] || die "unknown provider '$provider' (no $src)"
have jq || die "jq is required to merge opencode.jsonc"

dir=$(opencode_dir)
target="$dir/opencode.jsonc"
manifest="$dir/.agentic-swe-setup.json"
schema="https://opencode.ai/config.json"
mkdir -p "$dir"

backup=""
if [ -f "$target" ]; then
    if ! jq -e . "$target" >/dev/null 2>&1; then
        warn "$target is not strict JSON (JSONC comments?); refusing to rewrite it"
        {
            printf '\nAdd these keys to %s by hand, then re-run:\n\n' "$target"
            jq -S . "$src"
            printf '\n'
        } >&2
        exit 2
    fi
    backup="$target.bak.$(date +%s)"
    cp "$target" "$backup"
    log "backed up $target to $backup"
else
    printf '{"$schema":"%s"}\n' "$schema" > "$target"
fi

tmp=$(mktemp)
jq -n \
    --argjson base "$(cat "$target")" \
    --argjson mgd "$(cat "$src")" \
    --arg schema "$schema" '
      ($mgd.agent    // {}) as $agents
    | ($mgd.provider // {}) as $prov
    | ($mgd.plugin   // []) as $plugins
    | $base
    | .["$schema"] = (.["$schema"] // $schema)
    # Object + is right-biased, so each managed agent key is replaced
    # wholesale while unmanaged agents survive untouched.
    | .agent = ((.agent // {}) + $agents)
    # Append-and-dedupe, preserving any existing plugin order.
    | .plugin = ((.plugin // []) + ($plugins - (.plugin // [])))
    | if ($prov | length) > 0
      then .provider = ((.provider // {}) + $prov)
      else (if has("provider") then .provider |= del(.openai) else . end)
      end
    | if (.provider? == {}) then del(.provider) else . end
    ' > "$tmp"

mv "$tmp" "$target"

printf '%s\n' "${MANAGED_AGENTS[@]}" \
    | jq -R . \
    | jq -s \
        --arg provider "$provider" \
        --arg backup "$backup" \
        --arg plugin "$SUPERPOWERS_PLUGIN" \
        '{provider: $provider,
          backup: $backup,
          agents: .,
          plugin: $plugin,
          provider_key: "provider.openai"}' \
    > "$manifest"

log "merged $provider config into $target"
