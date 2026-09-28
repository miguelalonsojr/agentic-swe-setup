#!/usr/bin/env bash
# Explicit one-time cleanup of legacy harness items owned by this repository.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

have jq || die 'jq is required for legacy retirement'
managed="$REPO_ROOT/scripts/retire-legacy-managed.json"
dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
claude_root="$HOME/.claude"
swe_root="${SWE_SKILLS_DIR:-$HOME/.swe-skills}"
superpowers_root="${SUPERPOWERS_DIR:-$HOME/.superpowers}"
manifest="$dir/.agentic-swe-setup.json"
config="$dir/opencode.jsonc"
plugin_id="superpowers@git+https://github.com/obra/superpowers.git"
legacy_agents=(implementer-light implementer implementer-strong reviewer reviewer-final
               reviewer-lite cross-checker reviewer-light)
legacy_local_skills=(jira-fu routing-model-tiers cross-checking-claims search-fu
    plain-technical-prose dispatching-parallel-agents subagent-driven-development
    using-git-worktrees agentic-manual-testing compound-step codebase-walkthrough
    finishing-a-development-branch systematic-debugging)
legacy_shared_skills=(clean-architecture clean-coding ddd-expert
    design-patterns-expert de-slop generating-design-doc pragmatic-engineer
    system-designing)
legacy_managed_agents=(general explore implementer-light implementer
    implementer-strong reviewer reviewer-final reviewer-lite cross-checker)

# Do not mutate any installation until the inputs needed for safe cleanup parse.
if [ -e "$manifest" ] || [ -L "$manifest" ]; then
    [ -f "$manifest" ] && [ ! -L "$manifest" ] || die "unsafe legacy manifest: $manifest"
    jq -e --arg plugin "$plugin_id" --argjson names "$(printf '%s\n' "${legacy_managed_agents[@]}" | jq -R . | jq -s .)" '
        type == "object" and (.provider == "anthropic" or .provider == "openai")
        and (.agents | type == "array" and all(.[]; type == "string" and IN($names[])))
        and .plugin == $plugin and .provider_key == "provider.openai"
    ' "$manifest" >/dev/null 2>&1 || die "invalid legacy manifest: $manifest"
    provider=$(jq -r '.provider' "$manifest")
    if [ -e "$config" ] || [ -L "$config" ]; then
        [ -f "$config" ] && [ ! -L "$config" ] && jq -e 'type == "object"' "$config" >/dev/null 2>&1 \
            || die "$config is not strict JSON or is not a regular file; remove managed keys by hand"
        jq -e '(.agent? == null or (.agent | type == "object")) and
               (.provider? == null or (.provider | type == "object")) and
               (.plugin? == null or (.plugin | type == "array"))' "$config" >/dev/null 2>&1 \
            || die "unexpected legacy config shape: $config"
    fi
else
    warn "no legacy OpenCode manifest; leaving OpenCode config alone"
fi

plugin_installed=false
if have claude; then
    if ! plugin_list=$(claude plugin list --json 2>&1); then
        die "cannot inspect Claude plugins: $plugin_list"
    fi
    if ! printf '%s\n' "$plugin_list" | jq -se 'length == 1 and (.[0] | type == "array"
        and all(.[]; type == "object" and (.id | type == "string" and length > 0))
        and ([.[].id] | length == (unique | length)))' >/dev/null 2>&1; then
        die 'cannot inspect Claude plugins: invalid JSON list'
    fi
    if printf '%s\n' "$plugin_list" | jq -se '
        any(.[0][]; .id == "superpowers@claude-plugins-official")
    ' >/dev/null; then
        plugin_installed=true
    fi
else
    warn 'claude unavailable; cannot confirm or uninstall Superpowers plugin'
    exit 1
fi

# Compare complete named entries, never only model fields.
if [ -f "$manifest" ] && [ -f "$config" ]; then
    tmp=$(mktemp "$dir/.opencode-retire.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    jq --slurpfile ownership "$managed" --slurpfile record "$manifest" '
        $record[0] as $m | $ownership[0][$m.provider] as $owned |
        reduce $m.agents[] as $name (.;
            if .agent?[$name] == $owned.agent[$name] and (.agent | has($name))
            then del(.agent[$name]) else . end)
        | if (.provider? | type) == "object" and (.provider | has("openai")) and .provider.openai == $owned.provider.openai
          then del(.provider.openai) else . end
        | if (.agent? == {}) then del(.agent) else . end
        | if (.provider? == {}) then del(.provider) else . end
        | if .plugin? then .plugin |= map(select(. != $m.plugin)) else . end
        | if (.plugin? == []) then del(.plugin) else . end
    ' "$config" > "$tmp" || die 'could not prepare OpenCode retirement'
    for name in $(jq -r '.agents[]' "$manifest"); do
        if jq -e --arg name "$name" '.agent? | has($name)' "$config" >/dev/null &&
           jq -e --arg name "$name" '.agent? | has($name)' "$tmp" >/dev/null; then
            warn "retaining changed OpenCode agent: $name"
        fi
    done
    if jq -e '.provider? | has("openai")' "$config" >/dev/null &&
       jq -e '.provider? | has("openai")' "$tmp" >/dev/null; then
        warn 'retaining changed OpenCode provider.openai'
    fi
    if ! cmp -s "$config" "$tmp"; then
        chmod --reference="$config" "$tmp"
        mv "$tmp" "$config"
        log "retired matching OpenCode entries from $config"
    fi
    rm -f "$tmp"
    trap - EXIT
elif [ -f "$manifest" ]; then
    warn "OpenCode config absent: $config"
fi

# Normalize the link text, not its target inode: owned sources can be deleted.
unlink_known() {
    local dest=$1 target expected link
    shift
    [ -L "$dest" ] || { [ ! -e "$dest" ] || warn "retaining non-link: $dest"; return 0; }
    link=$(readlink -- "$dest")
    if [[ $link = /* ]]; then
        target=$(readlink -m -- "$link")
    else
        target=$(readlink -m -- "$(dirname "$dest")/$link")
    fi
    for expected in "$@"; do
        if [ "$target" = "$expected" ]; then
            rm -f "$dest"
            log "removed owned link $dest"
            return 0
        fi
    done
    warn "retaining unrelated link: $dest"
}
for name in "${legacy_agents[@]}"; do
    unlink_known "$claude_root/agents/$name.md" "$REPO_ROOT/agents/$name.md"
done
unlink_known "$claude_root/CLAUDE.md" "$REPO_ROOT/CLAUDE.md"
unlink_known "$dir/AGENTS.md" "$REPO_ROOT/AGENTS.md" \
    "$REPO_ROOT/build/opencode/anthropic/AGENTS.md" \
    "$REPO_ROOT/build/opencode/openai/AGENTS.md"
for skill in "${legacy_local_skills[@]}"; do
    for root in "$claude_root/skills" "$dir/skills"; do
        unlink_known "$root/$skill" "$REPO_ROOT/skills/$skill"
    done
done
for skill in "${legacy_shared_skills[@]}"; do
    for root in "$claude_root/skills" "$dir/skills"; do
        unlink_known "$root/$skill" "$swe_root/book-skills/$skill" "$swe_root/skills/$skill"
    done
done
for root in "$claude_root/skills" "$dir/skills"; do
    [ -d "$root" ] || continue
    for dest in "$root"/*; do
        [ -L "$dest" ] || continue
        skill=$(basename "$dest")
        unlink_known "$dest" "$superpowers_root/skills/$skill"
    done
done

if [ "$plugin_installed" = true ]; then
    claude plugin uninstall superpowers || die 'failed to uninstall Claude Superpowers plugin'
    log 'uninstalled Claude Superpowers plugin'
else
    log 'Claude Superpowers plugin already absent'
fi
if [ -f "$manifest" ]; then
    rm -f "$manifest"
    log "removed legacy manifest $manifest"
fi
