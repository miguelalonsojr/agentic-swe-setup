#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

R="$REPO_ROOT/README.md"
assert_file "$R" "README exists"
body=$(cat "$R")

# Every recipe in the justfile must be documented.
for r in install install-claude install-opencode install-prime install-skills doctor update uninstall test; do
    assert_contains "$body" "just $r" "README documents 'just $r'"
done

# The provider knob and its default must be stated.
assert_contains "$body" "provider=openai" "README shows the provider override"
assert_contains "$body" "anthropic" "README names the default provider"

# The two prerequisites the repo does not install.
assert_contains "$body" "Claude Code" "README names Claude Code"
assert_contains "$body" "OpenCode" "README names OpenCode"
assert_contains "$body" "Prime Agent" "README names Prime Agent"

# Prime Agent's two structural differences must be stated, not glossed over.
assert_contains "$body" "harness_state.json" "README names the harness store"
# Not "~/.superpowers": the tilde is literal README text, and quoting it here
# trips shellcheck SC2088 for a path that is never expanded.
assert_contains "$body" "/.superpowers" "README names the superpowers checkout"

# What uninstall leaves behind, so nobody is surprised.
assert_contains "$body" "swe-skills" "README mentions the shared skills checkout"

# Skills this repo ships itself must be listed by name.
. "$REPO_ROOT/scripts/lib.sh"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_contains "$body" "$s" "README names the local skill $s"
done

# The Prime Agent render ceiling is the reason the AGENTS.md table exists.
# A reader who does not know about it will think the table is duplication.
assert_contains "$body" "180 characters and shows six per kind" \
    "README states the content render cap"
assert_contains "$body" "cross-checker" "README documents the cross-checker role"

# Role counts in prose drift silently: five of them were already wrong
# before cross-checker was added. Derive every count from the arrays that
# define it, so the next role added breaks a test instead of a sentence.
assert_contains "$body" "Claude Code gets ${#CLAUDE_AGENTS[@]} subagents" \
    "README states the Claude Code subagent count"
assert_contains "$body" "receive all ${#MANAGED_AGENTS[@]}" \
    "README states the OpenCode and Prime subagent count"
assert_contains "$body" "for the ${#MANAGED_AGENTS[@]} managed agent names" \
    "README states the managed agent count for the OpenCode merge"
assert_contains "$body" "for the ${#PRIME_AGENTS[@]} managed roles" \
    "README states the managed role count for the Prime merge"
assert_contains "$body" "removes the ${#CLAUDE_AGENTS[@]} agent symlinks" \
    "README states how many agent symlinks uninstall removes"
# Needles are left-anchored: a bare "8 book-grounded" is satisfied by
# "18 book-grounded", so array drift would be caught but a prose typo that
# prefixes a digit would not.
assert_contains "$body" "the ${#SKILL_NAMES[@]} book-grounded" \
    "README states the book-skill count"
assert_contains "$body" " ${#PRIME_AGENTS[@]} roles are installed" \
    "README states the installed role count"

exit "$ASSERT_FAILURES"
