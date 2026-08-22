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
assert_contains "$body" "Workers must not dispatch nested agents." \
    "worktree skill prevents nested worker dispatch"
assert_contains "$body" 'set -euo pipefail' \
    "worktree cleanup fails closed"
assert_contains "$body" 'It does not accept `ledger_state` as input.' \
    "worktree cleanup does not trust external ledger state"
assert_contains "$body" 'grep -F -x "Task $task_id | state=integrated | worktree=$path | branch=$branch" "$ledger"' \
    "worktree cleanup matches the integrated task record"
assert_contains "$body" 'grep -F -x "Task $task_id | state=abandoned | worktree=$path | branch=$branch" "$ledger"' \
    "worktree cleanup matches the abandoned task record"
assert_contains "$body" 'ledger_state=integrated' \
    "worktree cleanup sets integration only after a matching record"
assert_contains "$body" 'ledger_state=abandoned' \
    "worktree cleanup sets abandonment only after a matching record"
assert_contains "$body" 'case "$ledger_state" in' \
    "worktree cleanup gates on ledger state"
assert_contains "$body" 'integrated|abandoned)' \
    "worktree cleanup accepts only terminal ledger states"
assert_contains "$body" '*) exit 1 ;;' \
    "worktree cleanup rejects other ledger states"
assert_contains "$body" 'The `ledger_state` variable is the task state read from the plan ledger.' \
    "worktree skill defines the ledger state"
assert_contains "$body" 'git -C "$path" status --porcelain' \
    "worktree skill checks dirty state before cleanup"
assert_contains "$body" "explicitly abandoned" \
    "worktree skill guards destructive cleanup"

exit "$ASSERT_FAILURES"
