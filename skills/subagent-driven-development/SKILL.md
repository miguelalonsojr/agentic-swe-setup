---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

## Preconditions and policy skills

Use this skill to execute an approved implementation plan in the current session. Do not use it for tightly coupled work, a plan that needs brainstorming, or work assigned to a separate execution session.

**REQUIRED SUB-SKILL:** Use `dispatching-parallel-agents` before wave selection. Consume its task inventory, collision edges, namespace decisions, and largest safe wave. Do not recreate its collision policy.

**REQUIRED SUB-SKILL:** Use `using-git-worktrees` for writer provisioning and cleanup. Consume its verified writer path, branch, and base. Do not copy its lifecycle commands.

**REQUIRED SUB-SKILL:** Use `routing-model-tiers` before every dispatch. This includes exploration, implementation, task review, fixes, re-reviews, final review, and the final fix pass. `routing-model-tiers` selects the model. SDD selects the role and owns escalation.

Keep implementation out of the controller. Never implement an eligible task in the controller. Dispatch a fresh implementer subagent for each distinct task, except a same-shape batch under Safe-wave execution. The controller owns planning, dispatch, review coordination, integration, verification, and recovery. Do not pause for progress approval between tasks. Narrate at most one short line between tool calls.

## Stop conditions and rulings

Continue through the approved plan unless an irreversible or destructive operation, a security-sensitive action, an external side effect that requires approval (a merge, push to a shared branch, or publish), or a plan with no non-guesswork path requires a stop. Ask the human only for these conditions.

Resolve other conflicts, ambiguities, plan defects, and cap decisions with a ledger ruling. The spec is binding authority. The plan argues from the spec. Record `Ruling: <what you decided> — <why> — <what it costs if wrong>`. A ruling may not change text a Global Constraint pins as verbatim. Change the plan or the needle instead.

## Workspace, ledger, plan, and contradiction scan

Use `using-git-worktrees` to create or verify an isolated workspace. Do not start implementation on `main` or `master` without explicit approval.

At skill start, run `scripts/sdd-workspace PLAN_FILE`. It prints `<repo-root>/.superpowers/sdd/<readable-basename>-<path-hash>/`. The canonical repository-relative plan path supplies the hash. The workspace holds the ledger, briefs, reports, and review packages. Do not read or write another plan's directory.

Use `<workspace>/progress.md` as the plan-specific ledger. Its first line is `# SDD ledger — plan: <plan file path>`. A ledger for a different plan, including `.superpowers/sdd/progress.md`, belongs to another plan. Leave it in place. A `Task <N>: complete` line proves a terminal state, but reconcile pending cleanup. Resume implementation at the first nonterminal task. Resume a task whose last line is a fix round at its next round. Trust the ledger and `git log` after compaction. `git clean -fdx` can destroy this git-ignored workspace; recover commits from `git log`.

For each task, retain dependencies; access mode; expected files and interfaces; generated artifacts; lockfiles; migrations; configuration; external resources; controller-assigned namespaces; collision edges; and rulings that add or remove edges. Also retain the worktree, branch, base, worker identity, report path, commit range, task-review status, source-to-integration commit mappings, cleanup state, and wave integration `HEAD`.

Read the plan, its context, and Global Constraints once. Create a todo per task. Read its reachable spec. Record that no spec is reachable when applicable; rulings without one are provisional. Before Task 1, give every task to `dispatching-parallel-agents` and retain its inventory, edge rulings, graph, and largest safe wave in the ledger.

Scan the plan for contradictions before dispatch. Record one ledger row per task comparing tests, implementation text, files, and Global Constraints. Check contradictions between tasks or Global Constraints and plan-mandated work that the review rubric treats as a defect. Each asserted test needle must be a whole sentence, unique in its target file, and on one unwrapped line in the plan insertion text. Fix the plan and rule on each contradiction before execution. Keep collision and namespace decisions in the separate parallel-policy inventory.

## Role routing and recovery

Route implementation and fix work to an implementer. Route task review and scoped re-review to read-only reviewers. Route final whole-branch review to the strongest final-review role available. A `BLOCKED` fix or fix round 4 or later uses the harness escalation role. Never retry an unchanged blocked dispatch. Implementers and reviewers do not dispatch nested subagents.

| State | Required ledger data | Restart action |
|---|---|---|
| `planned` | task inventory, rulings, brief, report path, wave, base | Verify these fields, provision access, and dispatch. |
| `dispatched` | planned data, worker identity, access mode, worktree, branch, dispatch handle | Reconcile the live child, worktree, and report. Resume or recover the dispatch. Do not duplicate it. |
| `committed` | report and complete ordered source commit range | Verify the recorded commit range and report. Recreate access to the recorded branch or commit if needed. Start task review rather than implementation. |
| `reviewed` | reviewed range, approval, parked rulings, focused evidence | Verify approval and continue integration. Do not repeat implementation or review. |
| `integrating` | ordered source range and source-to-integration commit mappings | Compare mappings with controller history and resume only the missing commits. |
| `integrated` | exact task, path, and branch terminal record, mappings, wave verification | Use the terminal record as cleanup authority and clean the writer. |
| `abandoned` | abandonment ruling and exact task, path, and branch terminal record | Use the terminal record as cleanup authority and clean the writer. |
| `cleaned` | cleanup command result and time | Do nothing. |

Transitions are `planned -> dispatched -> committed -> reviewed -> integrating -> integrated -> cleaned`. An abandonment ruling permits `abandoned -> cleaned`. Append each transition. Do not infer state from conversation memory. A missing worktree never erases a recorded commit. A dirty, missing, or ambiguous path changes reconciliation, not the recorded commit state.

On restart, inspect the ledger and Git before any redispatch. Reconcile every non-`cleaned` task from the table. Write `Task N: complete` only after `integrated` or `abandoned` is recorded. Cleanup can follow completion. Final review waits until every writer is `cleaned`.

## Safe-wave execution

Use the largest safe wave. For each wave:

1. Record `base=$(git rev-parse HEAD)` as the wave integration `HEAD`.
2. Create writer worktrees sequentially from that base with `using-git-worktrees` writer mode and `worker-worktree create`. Record the verified path, branch, base, task ownership, and access mode before dispatch. Read-only tasks use stable inputs. Do not create writer worktrees concurrently.
3. The task brief is the single source of task requirements. Give each writer a complete task brief. Include its worktree path, brief path, report path, relevant interfaces, Global Constraints, access mode, and ledger rulings. Run the suite at the wave base. Paste the failing files and assertion lines into the dispatch; never paraphrase the count. Record the worker identity from the dispatch result.
4. Require TDD, applicable manual testing, a self-review, a commit, and a detailed report. The worker adds or strengthens a focused test, runs it before implementation, and observes the expected RED failure. The worker then implements the minimum change, reruns the focused test, and observes GREEN. A task may produce multiple commits. Workers do not manipulate worktrees or branches beyond task commits.
5. Run the report, review, fix-loop, approval, and integration sequence below for each task. Freeze only affected integrations when unexpected overlap appears. Preserve worker branches, integrate the selected first task, revise or rerun the later task against the new integration `HEAD`, and update the graph and ledger.
6. Recompute the graph after the wave and dispatch the next safe wave.

Batch small, independent, same-shape edits in one brief and review their diff as one unit. Keep tasks that need distinct judgment, tests, or review surfaces separate. Pass artifacts as files rather than copying their contents into controller context. While children run, update the ledger and package work. When idle, wait in bounded five-to-ten-minute stretches where supported, then record one status line and reconcile live children.

## Implementer reports

Handle implementer status as follows:

- `DONE`: Verify the report and ordered commit range. Run `git diff --name-only "$base" "$commit"` and compare every actual file with the declared scope. If scope matches, record `committed`, create a range-based review package from recorded worker `BASE` through worker `HEAD`, and dispatch task review.
- `DONE_WITH_CONCERNS`: Read concerns. Resolve correctness or scope concerns before review. Record observations and continue to review.
- `NEEDS_CONTEXT`: Supply the missing context and re-dispatch.
- `BLOCKED`: For a context problem, supply missing context and re-dispatch with the same model. For a reasoning problem, use a more capable model. Split an oversized task, or rule on a plan correction and carry the ruling into a changed dispatch.

Answer implementer questions clearly and completely. Do not ignore escalation or retry the same model without a change.

## Task review

The required integration sequence is: scope check -> task review -> cherry-pick -> focused test -> wave suite -> terminal record -> completion -> cleanup. Before task review, compare the actual files with the declared scope by running `git diff --name-only "$base" "$commit"`. Review each worker commit before integration. Task review is a gate. It requires separate specification-compliance and task-quality verdicts. Implementer self-review does not replace task review. The task reviewer is read-only. Do not pre-judge findings, ask open-ended checks without a task-specific reason, or ask it to rerun tests already evidenced on the same code.

In the worker worktree, run `scripts/review-package PLAN_FILE BASE HEAD`. PLAN_FILE is the repo-relative plan path. An absolute path into another worktree fails with `plan is outside the repository`. Pass only the printed package path. It contains the commit list, stat summary, and full contextual diff. Use recorded worker `BASE` and `HEAD`. Never use `HEAD~1`; it truncates multi-commit tasks. Never dispatch a task reviewer without a diff file.

Give the reviewer the brief path, report path, review-package path, and Global Constraints. Copy binding values, formats, and component relationships verbatim from the plan or spec. Resolve each `⚠️ Cannot verify from diff` item before completion. A confirmed gap fails specification review and enters the fix loop.

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

## Five-round fix loop

Enter the loop for a failed specification verdict, a Critical or Important finding, or a confirmed `⚠️` gap. Record Minor findings as `Task <N>: minor (deferred): <one-liner>` and give them to final review. Minor findings never enter the loop. Rule on a plan-mandated finding against the spec before action. Do not dismiss it because the plan requires it or dispatch a contradictory fix without a ruling.

Each round contains one fix dispatch and one scoped re-review. Use the original implementer for rounds 1 through 3 when possible. If the harness cannot resume it, dispatch a fresh implementer with the brief path, report path, and findings. For rounds 4 and 5, dispatch a fresh, more capable implementer with those paths and open findings. State that a prior implementer attempted the task `<N>` times and that the report records prior work.

Each fixer reruns tests covering amended code, appends a fix report to the same report file, and returns the short contract. Confirm that the report names covering test files, command, and output before re-review. In the worker worktree, run `scripts/review-package PLAN_FILE FIX_BASE HEAD`, where FIX_BASE is the head seen by the prior review. Dispatch [re-review-prompt.md](re-review-prompt.md) with the findings, brief, report, and printed diff path. The re-reviewer marks each finding ADDRESSED or NOT ADDRESSED and reports new breakage in the fix diff only. New Critical or Important breakage joins the open list. Out-of-scope observations become deferred minors and do not extend the loop. Append `Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding one-liners>; commits <a7>..<b7>)` after each round. Never fix findings in the controller.

After round 5, stop dispatching. Adjudicate every open finding in the ledger. Park incorrect or contestable findings with a ruling. Park real findings with no downstream dependency with a ruling that says they are deferred. For a real load-bearing finding or plan defect, rule on the smallest unblocking change and carry it into the next task. Stop only when the defect leaves every path forward a guess. Do not adjudicate before the cap or silently discard a finding.

## Approval and integration

When review is clean, or all open findings are parked with cap rulings, record the approved worker commit range and task-review status. Change state to `reviewed`. Keep the worker branch until integration. Never move an unreviewed commit to the controller branch.

Integrate recorded commits one at a time, in dependency order, with `git cherry-pick "$commit"`. Change state to `integrating`, record each source-to-integration mapping, and run focused tests after each integrated commit through `scripts/test-summary -- <command>`. Read its summary and open its log only after a failure. Run the full suite after each wave through the same command. Do not start the next wave while a task has open Critical or Important issues without a cap ruling.

After integration and verification, write one terminal cleanup authorization record: `Task $task_id | state=integrated | worktree=$path | branch=$branch`. For abandonment, record the ruling and `Task $task_id | state=abandoned | worktree=$path | branch=$branch`. Change to `integrated` or `abandoned`, then write `Task N: complete`. Run `using-git-worktrees` cleanup only after that exact task, path, and branch terminal record. Change to `cleaned` only after cleanup succeeds.

## Final review and finish

After every writer is cleaned, create the whole-branch package with `scripts/review-package PLAN_FILE MERGE_BASE HEAD`, where MERGE_BASE is the branch start, such as `git merge-base main HEAD`. Dispatch the strongest final-review role after loading `routing-model-tiers`. Give it the printed package path and ledger deferred-minor and parked lines. Use `superpowers:requesting-code-review`.

If final review reports findings, dispatch one fixer with the complete findings list. Run exactly one scoped re-review of `scripts/review-package PLAN_FILE FIX_BASE HEAD` with [re-review-prompt.md](re-review-prompt.md). Adjudicate residual findings as at the task-loop cap. Park findings with rulings, or rule on load-bearing findings and record the decision. Do not dispatch a second final fix wave. Integrate and verify approved final fixes before finish. Surface residual load-bearing findings to the human through finishing-a-development-branch.

Before deleting the workspace, collect every `Ruling:` ledger line in order into the final message under `Rulings I made`, including what it costs if wrong. Run `compound-step` with `Ledger: <workspace>/progress.md` before deleting the workspace. Delete only this plan's workspace with `rm -rf <workspace>`. Leave sibling plan directories unchanged. Use finishing-a-development-branch.
