#!/usr/bin/env bash
# Remove the symlinks and managed config keys this repo installed.
#
# Deliberately leaves the shared swe-skills and Superpowers checkouts in place.
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

# Compare exact lexical targets so missing intermediate sources count as ours.
unlink_skill() {
    local p=$1 source=$2
    if links_to "$p" "$source"; then
        rm -f "$p"
        log "removed $p"
    fi
}

log "removing Prime Agent links"
for s in "${LOCAL_SKILLS[@]}"; do
    unlink_skill "$(prime_dir)/skills/$s" "$REPO_ROOT/skills/$s"
done
unlink_ours "$(prime_dir)/AGENTS.md"
# Inspect installed links, not checkouts: older installs linked every skill name.
for p in "$(prime_dir)"/skills/*; do
    [ -L "$p" ] || continue
    s=$(basename "$p")
    unlink_skill "$p" "$(swe_skills_dir)/skills/$s"
    unlink_skill "$p" "$(swe_skills_dir)/book-skills/$s"
    unlink_skill "$p" "$(superpowers_dir)/skills/$s"
done

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
printf '  superpowers checkout: %s\n' "$(superpowers_dir)"
printf '    remove with       : rm -rf %s\n' "$(superpowers_dir)"
printf '  settings.json backups : %s/settings.json.bak.*\n' "$(prime_dir)"
