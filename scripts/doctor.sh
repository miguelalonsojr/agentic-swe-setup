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

printf 'tooling\n'
for c in claude opencode git jq; do
    if have "$c"; then ok "$c on PATH"; else bad "$c not on PATH"; fi
done

printf '\nshared\n'
if [ -d "$(swe_skills_dir)/.git" ]; then
    ok "swe-skills checkout at $(swe_skills_dir)"
else
    bad "no swe-skills checkout at $(swe_skills_dir)"
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
    for a in "${CLAUDE_AGENTS[@]}"; do
        if links_into_repo "$(claude_dir)/agents/$a.md"; then ok "agent $a"
        else bad "agent $a not linked from this repo"; fi
    done
    if links_into_repo "$(claude_dir)/CLAUDE.md"; then
        ok "global CLAUDE.md linked"
    else
        bad "global CLAUDE.md not linked from this repo"
    fi
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
    if links_into_repo "$(opencode_dir)/AGENTS.md"; then
        ok "global AGENTS.md linked"
    else
        bad "global AGENTS.md not linked from this repo"
    fi
else
    skip "opencode not installed"
fi

exit 0
