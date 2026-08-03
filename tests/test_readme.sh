#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

R="$REPO_ROOT/README.md"
assert_file "$R" "README exists"
body=$(cat "$R")

# Every recipe in the justfile must be documented.
for r in install install-claude install-opencode install-skills doctor update uninstall test; do
    assert_contains "$body" "just $r" "README documents 'just $r'"
done

# The provider knob and its default must be stated.
assert_contains "$body" "provider=openai" "README shows the provider override"
assert_contains "$body" "anthropic" "README names the default provider"

# The two prerequisites the repo does not install.
assert_contains "$body" "Claude Code" "README names Claude Code"
assert_contains "$body" "OpenCode" "README names OpenCode"

# What uninstall leaves behind, so nobody is surprised.
assert_contains "$body" "swe-skills" "README mentions the shared skills checkout"

# Skills this repo ships itself must be listed by name.
. "$REPO_ROOT/scripts/lib.sh"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_contains "$body" "$s" "README names the local skill $s"
done

exit "$ASSERT_FAILURES"
