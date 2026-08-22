#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/using-git-worktrees"
skill="$root/SKILL.md"
helper="$root/scripts/worker-worktree"
assert_file "$skill" "using-git-worktrees has a SKILL.md"
assert_file "$helper" "worker lifecycle helper is present"
[ ! -f "$helper" ] || [ -x "$helper" ] || fail "worker lifecycle helper is executable"
body=$(cat "$skill")
assert_contains "$body" "Feature/controller workspace mode"     "worktree skill names feature/controller setup mode"
assert_contains "$body" "SDD writer provisioning mode"     "worktree skill names writer provisioning mode"
assert_contains "$body" "may create child writer worktrees from a linked controller worktree"     "writer mode overrides top-level linked-worktree creation guard"
assert_contains "$body" "accepts the recorded base"     "native writer tool accepts the recorded base"
assert_contains "$body" "returns the path, branch, and base"     "native writer tool returns ledger fields"
assert_contains "$body" "Create writer worktrees sequentially before dispatching the wave"     "worktree skill avoids Git metadata lock races"
assert_contains "$body" 'worker-worktree create'     "worktree skill delegates writer creation to the helper"
assert_contains "$body" 'worker-worktree cleanup'     "worktree skill delegates destructive cleanup to the helper"
assert_contains "$body" "Workers must not create, remove, merge, rebase, or cherry-pick"     "worktree skill limits worker Git authority"
assert_contains "$body" "Workers must not dispatch nested agents."     "worktree skill prevents nested worker dispatch"
assert_contains "$body" "canonical primary-worktree"     "worktree skill defines the canonical writer root"
assert_contains "$body" "exact terminal ledger record"     "worktree cleanup requires exact ledger authorization"
assert_contains "$body" "Remove the worktree before deleting its branch"     "worktree cleanup preserves operation order"

if [ -f "$helper" ] && [ -x "$helper" ]; then
    repo="$SANDBOX/primary repo with spaces"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.name Test
    git -C "$repo" config user.email test@example.com
    printf '.worktrees/\n' > "$repo/.gitignore"
    printf 'one\n' > "$repo/tracked"
    git -C "$repo" add .gitignore tracked
    git -C "$repo" commit -qm base
    base=$(git -C "$repo" rev-parse HEAD)
    printf 'two\n' >> "$repo/tracked"
    git -C "$repo" commit -qam tip

    create_output=$(cd "$repo" && "$helper" create         --plan-slug example-plan --task-id 7 --task-slug focused-fix --base "$base" 2>&1)
    create_status=$?
    assert_eq "$create_status" 0 "writer creation succeeds from an explicit base"
    path=$(printf '%s\n' "$create_output" | sed -n 's/^path=//p')
    branch=$(printf '%s\n' "$create_output" | sed -n 's/^branch=//p')
    actual_base=$(printf '%s\n' "$create_output" | sed -n 's/^base=//p')
    assert_eq "$path" "$repo/.worktrees/example-plan/task-7-focused-fix"         "writer path uses the full primary path and canonical root"
    assert_eq "$branch" "sdd/example-plan/task-7-focused-fix"         "writer branch is deterministic"
    assert_eq "$actual_base" "$base" "writer helper reports the recorded base"
    assert_eq "$(git -C "$path" rev-parse HEAD 2>/dev/null)" "$base"         "writer starts at the explicit base rather than current HEAD"

    if (cd "$repo" && "$helper" create --plan-slug ../escape --task-id 8         --task-slug bad --base "$base" >/dev/null 2>&1); then
        fail "writer helper rejects path-escaping plan slugs"
    fi

    ledger="$SANDBOX/progress.md"
    printf 'dirty\n' >> "$path/tracked"
    printf 'Task 7 | state=integrated | worktree=%s | branch=%s\n' "$path" "$branch" > "$ledger"
    if (cd "$repo" && "$helper" cleanup --ledger "$ledger" --task-id 7         --path "$path" --branch "$branch" >/dev/null 2>&1); then
        fail "writer cleanup refuses a dirty worktree"
    fi
    git -C "$path" reset --hard -q

    printf 'Task 7 | state=integrated | worktree=%s | branch=%s-wrong\n' "$path" "$branch" > "$ledger"
    if (cd "$repo" && "$helper" cleanup --ledger "$ledger" --task-id 7         --path "$path" --branch "$branch" >/dev/null 2>&1); then
        fail "writer cleanup refuses a non-exact ledger record"
    fi

    printf 'Task 7 | state=integrated | worktree=%s | branch=%s\n' "$path" "$branch" > "$ledger"
    cleanup_output=$(cd "$repo" && "$helper" cleanup --ledger "$ledger" --task-id 7         --path "$path" --branch "$branch" 2>&1)
    cleanup_status=$?
    assert_eq "$cleanup_status" 0 "writer cleanup accepts the exact terminal record"
    [ ! -e "$path" ] || fail "writer cleanup removes the worktree"
    if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        fail "writer cleanup removes the worker branch"
    fi

    if (cd "$repo" && "$helper" create --plan-slug example-plan --task-id 8 \
        --task-slug bad-base --base not-a-commit >/dev/null 2>&1); then
        fail "writer creation rejects an invalid explicit base"
    fi
    [ ! -e "$repo/.worktrees/example-plan/task-8-bad-base" ] || \
        fail "invalid-base refusal creates no writer worktree"

    unignored="$SANDBOX/unignored repo"
    mkdir -p "$unignored"
    git -C "$unignored" init -q
    git -C "$unignored" config user.name Test
    git -C "$unignored" config user.email test@example.com
    printf 'x\n' > "$unignored/tracked"
    git -C "$unignored" add tracked
    git -C "$unignored" commit -qm base
    unignored_base=$(git -C "$unignored" rev-parse HEAD)
    if (cd "$unignored" && "$helper" create --plan-slug plan --task-id 1         --task-slug task --base "$unignored_base" >/dev/null 2>&1); then
        fail "writer creation refuses an unignored canonical root"
    fi
    [ ! -e "$unignored/.worktrees/plan/task-1-task" ] ||         fail "unignored-root refusal creates no writer worktree"
fi

exit "$ASSERT_FAILURES"
