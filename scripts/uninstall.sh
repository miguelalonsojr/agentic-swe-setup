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

log "removing OpenCode links"
unlink_ours "$(opencode_dir)/AGENTS.md"

for s in "${SKILL_NAMES[@]}"; do
    for d in "$(claude_dir)/skills/$s" "$(opencode_dir)/skills/$s"; do
        if [ -L "$d" ]; then
            rm -f "$d"
            log "removed $d"
        fi
    done
done

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

printf '\n'
log "left in place on purpose (shared with other tooling):"
printf '  swe-skills checkout : %s\n' "$(swe_skills_dir)"
printf '    remove with       : rm -rf %s\n' "$(swe_skills_dir)"
printf '  superpowers plugin  : claude plugin uninstall superpowers\n'
printf '  opencode.jsonc backups: %s/opencode.jsonc.bak.*\n' "$(opencode_dir)"
