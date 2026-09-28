#!/usr/bin/env bash
# Explicit one-time cleanup of legacy harness items owned by this repository.
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

have jq || die 'jq is required for legacy retirement'
managed="$REPO_ROOT/scripts/retire-legacy-managed.json"
dir=$(opencode_dir)
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
    if ! printf '%s\n' "$plugin_list" | jq -e . >/dev/null 2>&1; then
        die 'cannot inspect Claude plugins: invalid JSON list'
    fi
    if printf '%s\n' "$plugin_list" | jq -e '
        [.. | objects | select(.name? == "superpowers" or .id? == "superpowers" or .id? == "superpowers@claude-plugins-official") ] | length > 0
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

# Ownership requires both a known destination and its matching source path.
unlink_known() {
    local dest=$1 expected=$2 target
    [ -L "$dest" ] || { [ ! -e "$dest" ] || warn "retaining non-link: $dest"; return 0; }
    target=$(readlink -f "$dest") || { warn "retaining unresolved link: $dest"; return 0; }
    case "$target" in
        "$expected"|"$expected"/*) rm -f "$dest"; log "removed owned link $dest" ;;
        *) warn "retaining unrelated link: $dest" ;;
    esac
}
for name in "${legacy_agents[@]}"; do
    unlink_known "$(claude_dir)/agents/$name.md" "$REPO_ROOT/agents/$name.md"
done
unlink_known "$(claude_dir)/CLAUDE.md" "$REPO_ROOT/CLAUDE.md"
# Older installations could point straight at the source file.
if [ -L "$dir/AGENTS.md" ] &&
   [[ $(readlink -f "$dir/AGENTS.md") == "$REPO_ROOT/build/opencode/"* ]]; then
    unlink_known "$dir/AGENTS.md" "$REPO_ROOT/build/opencode"
else
    unlink_known "$dir/AGENTS.md" "$REPO_ROOT/AGENTS.md"
fi
for skill in "${legacy_local_skills[@]}"; do
    for root in "$(claude_dir)/skills" "$dir/skills"; do
        unlink_known "$root/$skill" "$REPO_ROOT/skills/$skill"
    done
done
for skill in "${legacy_shared_skills[@]}"; do
    for root in "$(claude_dir)/skills" "$dir/skills"; do
        unlink_known "$root/$skill" "$(swe_skills_dir)/book-skills/$skill"
        unlink_known "$root/$skill" "$(swe_skills_dir)/skills/$skill"
    done
done
for root in "$(claude_dir)/skills" "$dir/skills"; do
    for source in "$(superpowers_dir)/skills"/*/; do
        [ -d "$source" ] || continue
        skill=$(basename "$source")
        unlink_known "$root/$skill" "${source%/}"
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
