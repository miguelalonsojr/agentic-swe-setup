#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skill="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
assert_file "$skill" "using-git-worktrees has a SKILL.md"
body=$(cat "$skill")
assert_contains "$body" "The controller creates and removes worker worktrees" \
    "worktree skill assigns lifecycle ownership"
assert_contains "$body" "Create worker worktrees sequentially before dispatching the wave" \
    "worktree skill avoids Git metadata lock races"
assert_contains "$body" 'git worktree add "$path" -b "$branch" "$base"' \
    "worktree skill creates from the recorded base"
assert_contains "$body" 'git -C "$path" rev-parse HEAD' \
    "worktree skill verifies the worker base"
assert_contains "$body" "Workers must not create, remove, merge, rebase, or cherry-pick" \
    "worktree skill limits worker Git authority"
assert_contains "$body" 'git -C "$path" status --porcelain' \
    "worktree skill checks dirty state before cleanup"
assert_contains "$body" "explicitly abandoned" \
    "worktree skill guards destructive cleanup"

exit "$ASSERT_FAILURES"
