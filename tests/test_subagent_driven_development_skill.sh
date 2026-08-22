#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/subagent-driven-development"
assert_file "$root/SKILL.md" "subagent-driven-development has a SKILL.md"
assert_file "$root/implementer-prompt.md" "implementer prompt is present"
assert_file "$root/task-reviewer-prompt.md" "task reviewer prompt is present"
assert_file "$root/re-review-prompt.md" "re-review prompt is present"
for script in review-package sdd-workspace task-brief; do
    assert_file "$root/scripts/$script" "SDD script $script is present"
    [ -x "$root/scripts/$script" ] || fail "SDD script $script is executable"
done
body=$(cat "$root/SKILL.md")
assert_contains "$body" "Build the dependency and collision graph" \
    "SDD skill plans safe waves"
assert_contains "$body" "Dispatch every task in the largest safe wave" \
    "SDD skill maximizes safe delegation"
assert_contains "$body" "Never implement an eligible task in the controller" \
    "SDD controller delegates implementation"
assert_contains "$body" "Review each worker commit before integration" \
    "SDD skill keeps the task review gate"
assert_contains "$body" 'git diff --name-only "$base" "$commit"' \
    "SDD skill validates actual scope"
assert_contains "$body" 'git cherry-pick "$commit"' \
    "SDD skill integrates commits rather than copying files"
assert_contains "$body" "focused tests after each integrated commit" \
    "SDD skill verifies incremental integration"
assert_contains "$body" "full suite after each wave" \
    "SDD skill verifies combined behavior"
assert_contains "$body" "worker worktree" \
    "SDD ledger records worker isolation"
implementer=$(cat "$root/implementer-prompt.md")
assert_contains "$implementer" "Do not merge, rebase, cherry-pick, or create or remove worktrees" \
    "implementer prompt limits Git authority"
assert_contains "$implementer" "actual files changed" \
    "implementer reports its real scope"

exit "$ASSERT_FAILURES"
