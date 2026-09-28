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

log "removing Prime Agent links"
for s in "${LOCAL_SKILLS[@]}"; do
    unlink_ours "$(prime_dir)/skills/$s"
done
unlink_ours "$(prime_dir)/AGENTS.md"
# Compare lexical targets so removed shared sources still count as ours.
unlink_shared_skill() {
    local p=$1 source=$2 target
    [ -L "$p" ] || return 0
    target=$(readlink "$p")
    case "$target" in
        /*) ;;
        *) target="$(dirname "$p")/$target" ;;
    esac
    if [ "$(realpath -ms -- "$target")" = "$(realpath -ms -- "$source")" ]; then
        rm -f "$p"
        log "removed $p"
    fi
}

for s in "${SKILL_NAMES[@]}"; do
    p="$(prime_dir)/skills/$s"
    unlink_shared_skill "$p" "$(swe_skills_dir)/skills/$s"
    unlink_shared_skill "$p" "$(swe_skills_dir)/book-skills/$s"
done
# Inspect installed links, not the checkout: a skill may have been removed upstream.
for p in "$(prime_dir)"/skills/*; do
    [ -L "$p" ] || continue
    unlink_shared_skill "$p" "$(superpowers_dir)/skills/$(basename "$p")"
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
printf '  swe-skills checkout : %s\n' "$(swe_skills_dir)"
printf '    remove with       : rm -rf %s\n' "$(swe_skills_dir)"
printf '  superpowers checkout: %s\n' "$(superpowers_dir)"
printf '    remove with       : rm -rf %s\n' "$(superpowers_dir)"
printf '  settings.json backups : %s/settings.json.bak.*\n' "$(prime_dir)"
