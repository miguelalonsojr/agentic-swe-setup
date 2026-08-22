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
assert_contains "$body" '**REQUIRED SUB-SKILL:** Use `dispatching-parallel-agents`'     "SDD loads the collision and safe-wave policy"
assert_contains "$body" '**REQUIRED SUB-SKILL:** Use `using-git-worktrees`'     "SDD loads the writer lifecycle policy"
assert_contains "$body" '**REQUIRED SUB-SKILL:** Use `routing-model-tiers` before every dispatch'     "SDD loads routing policy per dispatch"
assert_contains "$body" "consume its task inventory, collision edges, namespace decisions, and largest safe wave"     "SDD consumes parallel policy outputs"
assert_contains "$body" "consume its verified writer path, branch, and base"     "SDD consumes worktree policy outputs"
assert_contains "$body" '`routing-model-tiers` selects the model'     "SDD delegates general tier choice"
assert_not_contains "$body" "## Model Selection"     "SDD does not duplicate general model-tier policy"
for item in "dependencies" "access mode" "expected files and interfaces" "generated artifacts"             "lockfiles" "migrations" "configuration" "external resources"             "controller-assigned namespaces" "collision edges" "rulings that add or remove edges"; do
    assert_contains "$body" "$item" "SDD ledger retains $item"
done
assert_contains "$body" "Never implement an eligible task in the controller"     "SDD controller delegates implementation"
assert_contains "$body" "Review each worker commit before integration"     "SDD skill keeps the task review gate"
assert_contains "$body" "TDD" "SDD retains task TDD"
assert_contains "$body" "A task may produce multiple commits"     "SDD retains multi-commit tasks"
assert_contains "$body" 'Never use `HEAD~1`'     "SDD reviews the full task range"
assert_contains "$body" 'git diff --name-only "$base" "$commit"'     "SDD skill validates actual scope"
assert_contains "$body" 'git cherry-pick "$commit"'     "SDD skill integrates commits rather than copying files"
assert_contains "$body" "focused tests after each integrated commit"     "SDD skill verifies incremental integration"
assert_contains "$body" "full suite after each wave"     "SDD skill verifies combined behavior"
for state in planned dispatched committed reviewed integrating integrated abandoned cleaned; do
    state_marker=$(printf '`%s`' "$state")
    assert_contains "$body" "$state_marker" "SDD defines recovery state $state"
done
assert_contains "$body" "inspect the ledger and Git before any redispatch"     "SDD reconciles persistent state before dispatch"
assert_contains "$body" "reconcile the live child, worktree, and report"     "SDD reconciles dispatched tasks"
assert_contains "$body" "verify the recorded commit range and report"     "SDD reconciles committed tasks"
assert_contains "$body" "recreate access to the recorded branch or commit"     "SDD recovers committed tasks without a worktree"
assert_contains "$body" "start task review rather than implementation"     "SDD does not redispatch committed implementation"
assert_contains "$body" "verify approval and continue integration"     "SDD resumes reviewed tasks"
assert_contains "$body" "source-to-integration commit mappings"     "SDD records integration reconciliation data"
assert_contains "$body" "resume only the missing commits"     "SDD resumes multi-commit integration"
assert_contains "$body" "exact task, path, and branch terminal record"     "SDD uses terminal cleanup authority"
assert_contains "$body" "A missing worktree never erases a recorded commit"     "SDD preserves committed results"
assert_contains "$body" 'Write `Task N: complete` only after'     "SDD delays completion until terminal state"
assert_contains "$body" "scope check -> task review -> cherry-pick -> focused test -> wave suite -> terminal record -> completion -> cleanup"     "SDD worked example demonstrates integration and cleanup order"
assert_contains "$body" "most capable available model"     "SDD retains strongest final review"

implementer=$(cat "$root/implementer-prompt.md")
assert_contains "$implementer" "Do not merge, rebase, cherry-pick, or create or remove worktrees"     "implementer prompt limits Git authority"
assert_contains "$implementer" "actual files changed"     "implementer reports its real scope"

workspace="$root/scripts/sdd-workspace"
if [ -x "$workspace" ]; then
    repo="$SANDBOX/workspace-repo"
    mkdir -p "$repo/plans/one" "$repo/plans/two"
    git -C "$repo" init -q
    printf '# one\n' > "$repo/plans/one/same.md"
    printf '# two\n' > "$repo/plans/two/same.md"
    first=$(cd "$repo" && "$workspace" plans/one/same.md)
    second=$(cd "$repo" && "$workspace" plans/two/same.md)
    [ "$first" != "$second" ] || fail "same-basename plans receive distinct SDD workspaces"
    case "$(basename "$first")" in same-*) ;; *) fail "workspace keeps a readable plan basename" ;; esac
    first_again=$(cd "$repo" && "$workspace" "$repo/plans/one/../one/same.md")
    assert_eq "$first_again" "$first" "workspace identity uses the canonical plan path"
fi

exit "$ASSERT_FAILURES"
