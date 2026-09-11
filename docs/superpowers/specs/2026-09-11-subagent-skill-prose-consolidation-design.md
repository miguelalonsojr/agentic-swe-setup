# Subagent skill prose consolidation

## Scope

This change tightens the instructions for the repository-owned subagent workflow without changing its behavior. It covers:

- `skills/routing-model-tiers/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/task-reviewer-prompt.md`
- `skills/subagent-driven-development/re-review-prompt.md`
- `skills/cross-checking-claims/SKILL.md`
- Existing shell tests that assert wording instead of a required structural contract

No new workflow behavior or pressure-test framework is in scope.

## Objective

Reduce the context cost and reading time of the selected skills. Preserve every operational rule, role boundary, threshold, state transition, and report contract. Replace generated-sounding prose with direct technical instructions.

The change does not claim improved agent compliance. Behavioral pressure tests are excluded by decision.

## Preserved contracts

### Routing

- Select access mode and isolation before selecting a model.
- Use the light tier for one pass over a known target.
- Use the default tier for synthesis and judgment.
- Use the strong tier for load-bearing judgment and escalation.
- Separate enumeration from judgment when a task contains both.
- Use harness-native model discovery and dispatch rules.
- Follow the role and escalation decisions owned by `subagent-driven-development`.

### Parallel dispatch

- Inventory dependencies, access mode, files, interfaces, generated artifacts, lockfiles, migrations, configuration, and external resources.
- Add collision edges for shared producers and consumers.
- Remove an external-resource collision only through an explicit, unique, testable namespace assigned by the controller.
- Give every concurrent writer a separate controller-created worktree.
- Use stable inputs for read-only work.
- Dispatch the largest safe wave.
- Stop affected integrations and update the graph when unexpected overlap appears.

### Task execution

- Keep progress in the plan-specific SDD ledger.
- Preserve the `planned`, `dispatched`, `committed`, `reviewed`, `integrating`, `integrated`, `abandoned`, and `cleaned` states.
- Reconcile the ledger and Git before redispatch after a restart.
- Keep implementation out of the controller context.
- Give each writing task a separate worktree and a complete task brief.
- Require TDD, applicable manual testing, a commit, self-review, and a detailed report.
- Accept `DONE`, `DONE_WITH_CONCERNS`, `BLOCKED`, and `NEEDS_CONTEXT` as implementer statuses.
- Prevent implementers and reviewers from dispatching nested subagents.

### Review and integration

- Review the complete worker commit range before integration.
- Require separate specification-compliance and task-quality verdicts.
- Enter the fix loop for specification failures and Critical or Important findings.
- Keep Minor findings for final review instead of entering the fix loop.
- Use the original implementer for rounds 1 through 3 when possible.
- Use a fresh, stronger implementer for rounds 4 and 5.
- Run one scoped re-review after each fix round.
- Adjudicate unresolved findings only after round 5 and record the ruling.
- Cherry-pick approved commits in dependency order.
- Run focused tests after each integrated commit and the full suite after each wave.
- Run one final whole-branch review, at most one final fix dispatch, and one scoped re-review.

### Claim verification

- Cross-check only claims whose answer changes what gets built, bought, or skipped.
- Give the cross-checker the question without the first agent's answer.
- Use a different model line when available.
- Verify the claim against a primary source.
- Record unresolved claims as unconfirmed.

## Rewrite method

Each rule will have one authoritative location within the context where it is used. Explanations that do not change an action will be removed. Tables will replace repeated prose when they improve lookup. Headings will name their subject. Sentences will use direct verbs and consistent terms.

The controller skill and child prompts are separate execution contexts. Instructions required by a child will remain in its prompt even when the controller skill contains a related rule. This duplication is required for correct dispatch behavior.

The rewrite will remove:

- Historical anecdotes that do not affect a decision
- Repeated rationale after a direct rule
- Duplicate warnings and rationalization tables
- Multiple examples of the same failure
- Excessive bold text and em dashes
- Vague management verbs and staged rhetorical language
- Headings that only announce the next section

The rewrite will not remove a threshold, command contract, dispatch input, report field, state transition, stop condition, or recovery action to meet a word-count target.

## Tests

The existing shell suite remains the automated verification mechanism. Tests may change when they assert an exact sentence rather than the underlying contract. Updated tests will continue to check:

- Required skill and prompt files
- Role and model definitions
- Required sub-skill boundaries
- Worktree isolation
- Ledger states and restart recovery
- Complete commit-range review
- Review and integration gates
- Escalation thresholds
- Final review behavior
- Required prompt inputs and report fields

No behavioral pressure scenarios will be added.

## Acceptance criteria

- Every preserved contract maps to text in the revised skills or prompts.
- Skill descriptions contain trigger conditions rather than workflow summaries.
- All relative links and referenced scripts resolve.
- The selected files contain fewer words and lines than their baseline totals of 10,559 words and 1,236 lines.
- Reduction does not override contract preservation.
- `just test` passes.
- The final diff contains no unintended workflow change.
- Completion claims are limited to structural preservation, clearer prose, and lower context cost.
