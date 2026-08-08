#!/usr/bin/env bash
# Remove the symlinks and managed config keys this repo installed.
#
# Deliberately leaves the shared swe-skills checkout and the Superpowers
# plugin in place; other tooling may depend on both.
set -euo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# unlink_ours PATH — remove PATH only when it is a symlink into this repo.
unlink_ours() {
    local p=$1
    if links_into_repo "$p"; then
        rm -f "$p"
        log "removed $p"
    elif [ -e "$p" ] || [ -L "$p" ]; then
        warn "leaving $p alone; it is not a symlink into this repo"
    fi
}

log "removing Claude Code links"
for a in "${CLAUDE_AGENTS[@]}"; do
    unlink_ours "$(claude_dir)/agents/$a.md"
done
# Only removes them if they are symlinks into this repo; a real file the user
# owns is reported and left alone, same as any other path here.
for a in "${LEGACY_CLAUDE_AGENTS[@]}"; do
    unlink_ours "$(claude_dir)/agents/$a.md"
done
unlink_ours "$(claude_dir)/CLAUDE.md"

for s in "${LOCAL_SKILLS[@]}"; do
    unlink_ours "$(claude_dir)/skills/$s"
    unlink_ours "$(opencode_dir)/skills/$s"
    unlink_ours "$(prime_dir)/skills/$s"
done

log "removing OpenCode links"
unlink_ours "$(opencode_dir)/AGENTS.md"

log "removing Prime Agent links"
unlink_ours "$(prime_dir)/AGENTS.md"

for s in "${SKILL_NAMES[@]}"; do
    for d in "$(claude_dir)/skills/$s" "$(opencode_dir)/skills/$s" \
             "$(prime_dir)/skills/$s"; do
        if [ -L "$d" ]; then
            rm -f "$d"
            log "removed $d"
        fi
    done
done

# Superpowers reaches Prime Agent as symlinked skills rather than a plugin, so
# unlike the plugin it is this script's job to unlink them.
if [ -d "$(superpowers_dir)/skills" ]; then
    for d in "$(superpowers_dir)"/skills/*/; do
        [ -f "$d/SKILL.md" ] || continue
        p="$(prime_dir)/skills/$(basename "$d")"
        if [ -L "$p" ]; then
            rm -f "$p"
            log "removed $p"
        fi
    done
fi

manifest="$(opencode_dir)/.agentic-swe-setup.json"
cfg="$(opencode_dir)/opencode.jsonc"

if have jq && [ -f "$manifest" ] && [ -f "$cfg" ]; then
    if jq -e . "$cfg" >/dev/null 2>&1; then
        log "removing managed keys from $cfg"
        tmp=$(mktemp)
        jq \
            --argjson agents "$(jq -c '.agents' "$manifest")" \
            --arg plugin "$(jq -r '.plugin' "$manifest")" '
              reduce $agents[] as $a (
                  .;
                  if has("agent") then .agent |= del(.[$a]) else . end
              )
            | if has("provider") then .provider |= del(.openai) else . end
            | if (.provider? == {}) then del(.provider) else . end
            | if has("agent") and (.agent == {}) then del(.agent) else . end
            | if has("plugin")
              then .plugin = (.plugin - [$plugin])
              else . end
            | if (.plugin? == []) then del(.plugin) else . end
            ' "$cfg" > "$tmp"
        mv "$tmp" "$cfg"
    else
        warn "$cfg is not strict JSON; remove the managed keys by hand"
    fi
    rm -f "$manifest"
    log "removed $manifest"
fi

# --- Prime Agent: managed settings keys and harness subagent specs ---------
prime_manifest="$(prime_dir)/.agentic-swe-setup.json"
prime_settings="$(prime_dir)/settings.json"
prime_harness="$(prime_dir)/harness/harness_state.json"

if have jq && [ -f "$prime_manifest" ]; then
    if [ -f "$prime_settings" ] && jq -e . "$prime_settings" >/dev/null 2>&1; then
        log "removing managed keys from $prime_settings"
        tmp=$(mktemp)
        jq --argjson keys "$(jq -c '.settings_keys // []' "$prime_manifest")" '
              reduce $keys[] as $k (.; del(.[$k]))
            ' "$prime_settings" > "$tmp"
        mv "$tmp" "$prime_settings"
    elif [ -f "$prime_settings" ]; then
        warn "$prime_settings is not strict JSON; remove the managed keys by hand"
    fi

    # Only specs this project wrote come out; anything the agent refined in
    # itself stays, which is why each entry carries managed_by.
    if [ -f "$prime_harness" ] && jq -e . "$prime_harness" >/dev/null 2>&1; then
        log "removing managed subagent specs from $prime_harness"
        tmp=$(mktemp)
        jq '
              if (.entries.subagent? | type) == "object"
              then .entries.subagent |= with_entries(
                       select(.value.metadata.managed_by != "agentic-swe-setup"))
              else . end
            ' "$prime_harness" > "$tmp"
        mv "$tmp" "$prime_harness"
    fi

    rm -f "$prime_manifest"
    log "removed $prime_manifest"
fi

printf '\n'
log "left in place on purpose (shared with other tooling):"
printf '  swe-skills checkout : %s\n' "$(swe_skills_dir)"
printf '    remove with       : rm -rf %s\n' "$(swe_skills_dir)"
printf '  superpowers checkout: %s\n' "$(superpowers_dir)"
printf '    remove with       : rm -rf %s\n' "$(superpowers_dir)"
printf '  superpowers plugin  : claude plugin uninstall superpowers\n'
printf '  opencode.jsonc backups: %s/opencode.jsonc.bak.*\n' "$(opencode_dir)"
printf '  settings.json backups : %s/settings.json.bak.*\n' "$(prime_dir)"
