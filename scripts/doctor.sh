#!/usr/bin/env bash
# Report what is and is not installed. Read-only; always exits 0.
#
# Note: no `set -e`. Every check must run even when an earlier one fails.
set -uo pipefail
# shellcheck source=/dev/null
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ok()   { printf '[ok]   %s\n' "$*"; }
bad()  { printf '[warn] %s\n' "$*"; }
skip() { printf '[skip] %s\n' "$*"; }

# check_instructions PATH LABEL — the installed instructions are a symlink to
# a rendered file under build/, so a link into this repo is not enough: the
# render itself can be missing after a clean, and the harness then reads
# nothing at all.
check_instructions() {
    local p=$1 label=$2
    if ! links_into_repo "$p"; then
        bad "$label not linked from this repo"
    elif [ ! -f "$p" ]; then
        bad "$label links to a missing render; run just update"
    else
        ok "$label linked"
    fi
}

printf 'tooling\n'
for c in claude opencode prime-agent git jq; do
    if have "$c"; then ok "$c on PATH"; else bad "$c not on PATH"; fi
done

printf '\nshared\n'
if [ -d "$(swe_skills_dir)/.git" ]; then
    ok "swe-skills checkout at $(swe_skills_dir)"
else
    bad "no swe-skills checkout at $(swe_skills_dir)"
fi
# Only Prime Agent needs the Superpowers checkout; the others use the plugin.
if have prime-agent; then
    if [ -d "$(superpowers_dir)/.git" ]; then
        ok "superpowers checkout at $(superpowers_dir)"
    else
        bad "no superpowers checkout at $(superpowers_dir)"
    fi
fi

printf '\nclaude code\n'
if have claude; then
    if claude plugin list 2>/dev/null | grep -q superpowers; then
        ok "superpowers plugin installed"
    else
        bad "superpowers plugin not installed"
    fi
    for s in "${SKILL_NAMES[@]}"; do
        if [ -e "$(claude_dir)/skills/$s" ]; then ok "skill $s"
        else bad "skill $s missing"; fi
    done
    for s in "${LOCAL_SKILLS[@]}"; do
        if links_into_repo "$(claude_dir)/skills/$s"; then ok "local skill $s"
        else bad "local skill $s not linked from this repo"; fi
    done
    for a in "${CLAUDE_AGENTS[@]}"; do
        if links_into_repo "$(claude_dir)/agents/$a.md"; then ok "agent $a"
        else bad "agent $a not linked from this repo"; fi
    done
    check_instructions "$(claude_dir)/CLAUDE.md" "global CLAUDE.md"
else
    skip "claude not installed"
fi

printf '\nopencode\n'
if have opencode; then
    cfg="$(opencode_dir)/opencode.jsonc"
    man="$(opencode_dir)/.agentic-swe-setup.json"
    if have jq && [ -f "$man" ]; then
        ok "provider: $(jq -r .provider "$man")"
    else
        bad "no install manifest at $man"
    fi
    if have jq && [ -f "$cfg" ] \
        && jq -e --arg p "$SUPERPOWERS_PLUGIN" \
            '(.plugin // []) | index($p)' "$cfg" >/dev/null 2>&1; then
        ok "superpowers plugin configured"
    else
        bad "superpowers plugin not in $cfg"
    fi
    for a in "${MANAGED_AGENTS[@]}"; do
        if have jq && [ -f "$cfg" ] \
            && jq -e --arg a "$a" '.agent[$a]' "$cfg" >/dev/null 2>&1; then
            ok "agent $a"
        else
            bad "agent $a missing from $cfg"
        fi
    done
    for s in "${SKILL_NAMES[@]}"; do
        if [ -e "$(opencode_dir)/skills/$s" ]; then ok "skill $s"
        else bad "skill $s missing"; fi
    done
    for s in "${LOCAL_SKILLS[@]}"; do
        if links_into_repo "$(opencode_dir)/skills/$s"; then ok "local skill $s"
        else bad "local skill $s not linked from this repo"; fi
    done
    check_instructions "$(opencode_dir)/AGENTS.md" "global AGENTS.md"
else
    skip "opencode not installed"
fi

printf '\nprime agent\n'
if have prime-agent; then
    pdir=$(prime_dir)
    pcfg="$pdir/settings.json"
    pharness="$pdir/harness/harness_state.json"
    pman="$pdir/.agentic-swe-setup.json"
    if have jq && [ -f "$pman" ]; then
        ok "provider: $(jq -r .provider "$pman")"
    else
        bad "no install manifest at $pman"
    fi
    if have jq && [ -f "$pcfg" ] \
        && jq -e '.defaultModel' "$pcfg" >/dev/null 2>&1; then
        ok "default model: $(jq -r .defaultModel "$pcfg")"
    else
        bad "no defaultModel in $pcfg"
    fi
    specs_found=0
    for a in "${PRIME_AGENTS[@]}"; do
        key=${a//-/_}
        if have jq && [ -f "$pharness" ] \
            && jq -e --arg k "$key" '.entries.subagent[$k]' "$pharness" \
                >/dev/null 2>&1; then
            ok "subagent spec $a"
            specs_found=$((specs_found + 1))
        else
            bad "subagent spec $a missing from $pharness"
        fi
    done
    # Prime Agent renders at most six subagent specs per kind into the system
    # prompt (refinement.js DEFAULT_OVERVIEW_ENTRY_LIMIT), so a ladder larger
    # than six is partly invisible there. Report that shortfall against what
    # the loop above actually found, not against the size of the array: a
    # count nothing counted is the kind of claim this repo keeps getting wrong.
    if [ "$specs_found" -eq "${#PRIME_AGENTS[@]}" ]; then
        ok "$specs_found managed subagent specs (Prime Agent renders 6; AGENTS.md table is authoritative)"
    else
        bad "$specs_found of ${#PRIME_AGENTS[@]} managed subagent specs installed"
    fi
    # Superpowers reaches Prime Agent as skills, so check a representative one.
    for s in brainstorming writing-plans subagent-driven-development; do
        if [ -e "$pdir/skills/$s" ]; then ok "superpowers skill $s"
        else bad "superpowers skill $s missing"; fi
    done
    for s in "${SKILL_NAMES[@]}"; do
        if [ -e "$pdir/skills/$s" ]; then ok "skill $s"
        else bad "skill $s missing"; fi
    done
    for s in "${LOCAL_SKILLS[@]}"; do
        if links_into_repo "$pdir/skills/$s"; then ok "local skill $s"
        else bad "local skill $s not linked from this repo"; fi
    done
    check_instructions "$pdir/AGENTS.md" "global AGENTS.md"
else
    skip "prime-agent not installed"
fi

exit 0
