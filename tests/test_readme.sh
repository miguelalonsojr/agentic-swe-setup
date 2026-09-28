#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

R="$REPO_ROOT/README.md"
assert_file "$R" "README exists"
body=$(cat "$R")

# Every recipe in the justfile must be documented.
for r in install install-prime install-skills doctor update uninstall test; do
    assert_contains "$body" "just $r" "README documents 'just $r'"
done

# The provider knob and its default must be stated.
assert_contains "$body" "just --set provider openai install" "README shows the provider override"
assert_contains "$body" "anthropic" "README names the default provider"

assert_contains "$body" "Prime Agent" "README names Prime Agent"
assert_not_contains "$body" 'just install-claude' 'README omits retired recipe'
assert_not_contains "$body" 'just install-opencode' 'README omits retired recipe'

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

assert_contains "$body" "${#PRIME_AGENTS[@]} roles are installed"     "README states the Prime role count"
assert_contains "$body" 'bash scripts/retire-legacy.sh'     "README names the separate retirement command"
assert_contains "$body" 'Normal install, update, doctor, and uninstall do not touch Claude Code or'     "README separates legacy retirement from routine commands"
exit "$ASSERT_FAILURES"
