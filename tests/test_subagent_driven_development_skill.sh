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
assert_contains "$body" "Consume its task inventory, collision edges, namespace decisions, and largest safe wave"     "SDD consumes parallel policy outputs"
assert_contains "$body" "Consume its verified writer path, branch, and base"     "SDD consumes worktree policy outputs"
assert_contains "$body" '`routing-model-tiers` selects the model'     "SDD delegates general tier choice"
assert_not_contains "$body" "## Model Selection"     "SDD does not duplicate general model-tier policy"
for item in "dependencies" "access mode" "expected files and interfaces" "generated artifacts"             "lockfiles" "migrations" "configuration" "external resources"             "controller-assigned namespaces" "collision edges" "rulings that add or remove edges"; do
    assert_contains "$body" "$item" "SDD ledger retains $item"
done
assert_contains "$body" "Never implement an eligible task in the controller"     "SDD controller delegates implementation"
assert_contains "$body" "Dispatch a fresh implementer subagent for each distinct task, except a same-shape batch" "SDD gives each distinct task a fresh implementer"
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
assert_contains "$body" "Reconcile the live child, worktree, and report"     "SDD reconciles dispatched tasks"
assert_contains "$body" "Verify the recorded commit range and report"     "SDD reconciles committed tasks"
assert_contains "$body" "Recreate access to the recorded branch or commit"     "SDD recovers committed tasks without a worktree"
assert_contains "$body" "Start task review rather than implementation"     "SDD does not redispatch committed implementation"
assert_contains "$body" "Verify approval and continue integration"     "SDD resumes reviewed tasks"
assert_contains "$body" "source-to-integration commit mappings"     "SDD records integration reconciliation data"
assert_contains "$body" "resume only the missing commits"     "SDD resumes multi-commit integration"
assert_contains "$body" "exact task, path, and branch terminal record"     "SDD uses terminal cleanup authority"
assert_contains "$body" "A missing worktree never erases a recorded commit"     "SDD preserves committed results"
assert_contains "$body" 'Write `Task N: complete` only after'     "SDD delays completion until terminal state"
assert_contains "$body" "scope check -> task review -> cherry-pick -> focused test -> wave suite -> terminal record -> completion -> cleanup" "SDD defines the required integration sequence"
assert_contains "$body" "Before task review, compare the actual files with the declared scope" "SDD checks scope before task review"
assert_contains "$body" "Integrate recorded commits one at a time, in dependency order" "SDD orders integration by dependency"
assert_contains "$body" "run focused tests after each integrated commit" "SDD verifies each integrated commit"
assert_contains "$body" "Run the full suite after each wave" "SDD verifies each wave"
assert_contains "$body" 'then write `Task N: complete`' "SDD writes completion after terminal state"
assert_contains "$body" "cleanup only after that exact task, path, and branch terminal record" "SDD cleans only after terminal record"
assert_contains "$body" "strongest final-review role available"     "SDD retains strongest final review"

assert_contains "$body" "scripts/test-summary" "SDD controller runs tests through test-summary"
assert_contains "$body" "observes the expected failure" "SDD requires RED evidence"
assert_contains "$body" "Implementers and reviewers do not dispatch nested subagents" "SDD prevents nested dispatch"
assert_contains "$body" "one fixer with the complete findings list" "SDD has one final fix dispatch"
assert_contains "$body" "Do not dispatch a second final fix wave" "SDD limits final fixes"
assert_contains "$body" "The task reviewer is read-only" "SDD makes task review read-only"
assert_contains "$body" 'Run `compound-step`' "SDD Finish runs the compound step"
assert_contains "$body" "before deleting the workspace" "compound step precedes workspace deletion"
assert_not_contains "$body" "superpowers:using-git-worktrees" "SDD names the forked worktree skill without the plugin prefix"
assert_not_contains "$body" "superpowers:finishing-a-development-branch" "SDD names the forked finishing skill without the plugin prefix"
assert_contains "$body" "superpowers:requesting-code-review" "SDD keeps the prefix for skills this repo does not fork"
assert_contains "$body" "## Role routing and ledger states" "SDD keeps the role-routing section"
for f in implementer-prompt task-reviewer-prompt re-review-prompt; do
    assert_not_contains "$(cat "$root/$f.md")" "Model Selection" "$f no longer points at the removed section"
    assert_contains "$(cat "$root/$f.md")" 'choose per `routing-model-tiers`' "$f points at routing-model-tiers"
done

assert_contains "$body" "A ruling may not change text a Global Constraint pins as verbatim" "SDD rulings cannot alter verbatim-pinned text"
assert_contains "$body" "must be a whole sentence, unique in its target file, and on one unwrapped line" "SDD contradiction scan checks needles"
assert_contains "$body" "Paste the failing files and assertion lines into the dispatch; never paraphrase the count" "SDD dispatch states the baseline red state verbatim"
assert_contains "$body" "PLAN_FILE is the repo-relative plan path" "SDD names the review-package plan path rule"

implementer=$(cat "$root/implementer-prompt.md")
for clause in "[BRIEF_FILE]" "[CONTEXT]" "[WORKTREE_PATH]" "[REPORT_FILE]" \
    "Do not merge, rebase, cherry-pick, or create or remove worktrees" \
    "dispatch subagents. Commit only this task's changes" "Use TDD when the task requires it" \
    "run the focused test" "Run the full suite once before committing" \
    "or unclear condition arises while working, ask and pause" \
    "grows beyond the plan's intent, stop and report" \
    "DONE_WITH_CONCERNS. Do not split it without plan guidance" \
    'runnable CLI, HTTP API, web UI, startup path, or migration per' \
    "TDD evidence when required" "actual files changed" "self-review findings" \
    "Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT" \
    "Reply in under 15 lines"; do
    assert_contains "$implementer" "$clause" "implementer prompt preserves: $clause"
done

reviewer=$(cat "$root/task-reviewer-prompt.md")
for clause in "[BRIEF_FILE]" "[GLOBAL_CONSTRAINTS]" "[REPORT_FILE]" \
    "[BASE_SHA]" "[HEAD_SHA]" "[DIFF_FILE]" "Review the complete worker commit range" \
    "This checkout is read-only" "Do not dispatch subagents" "Read [DIFF_FILE] first" \
    "check per risk and name the risk and check" "Run only a focused test when a specific doubt remains" \
    "If commands cannot run, name the focused test that would resolve that doubt" \
    "check documentation when documented behavior changes" \
    "use a warning verdict" "file:line evidence" "### Spec Compliance" \
    "### Issues" "Task quality: Approved | Needs fixes"; do
    assert_contains "$reviewer" "$clause" "task reviewer prompt preserves: $clause"
done
assert_not_contains "$reviewer" "otherwise name the test that would be run" \
    "task reviewer names a hypothetical test only when commands cannot run"

rereviewer=$(cat "$root/re-review-prompt.md")
for clause in "[BRIEF_FILE]" "[FINDINGS]" "[REPORT_FILE]" "[FIX_BASE_SHA]" \
    "[HEAD_SHA]" "[DIFF_FILE]" "This checkout is read-only" \
    "Do not dispatch subagents" "Verdict each finding in order" \
    "specific defect no longer exists. Do not re-review" "non-blocking" \
    "covering tests and includes their output" "Run only a focused" \
    "test when a specific doubt remains" "### Finding Verdicts" \
    "ADDRESSED | NOT ADDRESSED" "### New Breakage in the Fix Diff" \
    "### Out-of-Scope Observations" "All findings addressed, no new Critical/Important breakage"; do
    assert_contains "$rereviewer" "$clause" "re-review prompt preserves: $clause"
done
assert_not_contains "$rereviewer" "otherwise name the test that would run" \
    "re-review does not require a hypothetical test"

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
