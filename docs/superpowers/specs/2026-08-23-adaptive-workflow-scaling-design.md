# Adaptive Workflow Scaling Design

## Goal

The installed agent instructions must reduce process for trivial low-risk changes. Bounded changes retain a short approval flow. Architectural and high-risk changes retain the full workflow.

The policy applies across Claude Code, OpenCode, and Prime Agent through the rendered global `AGENTS.md` files.

## Current problem

`AGENTS.md` tells agents to use judgment for trivial tasks, but its precedence section makes every Superpowers workflow mandatory. The installed `brainstorming` skill also requires an approval gate for every implementation change. These rules leave no effective fast path.

Simple documentation, configuration, and localized code changes can therefore trigger brainstorming, planning, worktree creation, subagent dispatch, formal review, and multiple skill loads. The extra process increases completion time without a matching reduction in risk for reversible changes.

## Workflow classes

The agent classifies implementation work before it selects workflow skills. The classification has three paths: fast, bounded, and full.

### Fast path

A task uses the fast path only when every condition holds:

- The change affects at most two files.
- The change is localized and easy to reverse.
- The expected result is clear.
- The change requires no cross-component coordination.
- One focused command can verify the result.
- The change does not affect a public API, schema, migration, dependency, security control, authentication flow, concurrent behavior, or destructive operation.

The fast path has these rules:

- Make the change directly.
- Keep the edit surgical.
- Do not invoke `brainstorming`, `writing-plans`, worktree management, subagents, or formal review.
- Do not require a new test for documentation, formatting, or mechanical configuration changes.
- Add or update a focused test for a behavior change when practical.
- Inspect the diff and run focused verification before reporting completion.
- Load a craft skill only when the task needs its specific guidance.

A failure without a known root cause does not qualify for the fast path. It uses the bounded path and `systematic-debugging` unless its risk or scope requires the full path.

### Bounded path

A task uses the bounded path when it changes an existing localized flow but fails one or more fast-path conditions and has no architectural or listed high-risk effect.

The bounded path has these rules:

- Use the short in-chat `brainstorming` flow and obtain approval before implementation.
- Do not write a design document or implementation-plan document.
- Work directly unless isolation or delegation has a concrete benefit.
- Use tests and review in proportion to the change risk.
- Apply the existing coding discipline and verification rules.

### Full path

A task uses the full path when it is architectural, unclear, cross-component, or high-risk. Public APIs, schemas, migrations, dependencies, security, authentication, concurrency, and destructive operations are high-risk for workflow selection even when their diffs are small.

The full path retains the existing Superpowers design, planning, TDD, worktree, delegation, review, and verification workflows.

## Classification changes

Classification can become heavier after work starts. It cannot become lighter during the same task.

If a fast-path task expands beyond two files or exposes new risk, the agent stops direct implementation. The agent explains the new classification and obtains the approval required by the bounded or full path. Existing edits remain in place but receive no extension until approval.

An explicit user request for more process selects the heavier requested path. An explicit request for less process can reduce optional ceremony but cannot remove a safety check required by a high-risk change.

## Instruction precedence

The `AGENTS.md` precedence section must make workflow classification effective. The revised order is:

1. Direct user instructions, subject to necessary safety checks.
2. Workflow classification and the rules for the selected path.
3. Applicable Superpowers workflow skills.
4. The phase mapping in `AGENTS.md`.
5. Advisory craft-skill guidance.

Superpowers workflows remain mandatory when the bounded or full path names them. They are not mandatory when the fast path explicitly excludes them. YAGNI continues to override optional abstractions and unrelated work.

## Repository changes

### `AGENTS.md`

Add a `Workflow Scaling` section before `Coding Discipline`. Define the three paths, the fast-path eligibility test, excluded risk categories, upgrade behavior, and user overrides. Revise the precedence section to use the selected path.

The existing phase mapping remains unchanged except where unconditional wording contradicts workflow classification. Fast-path work does not trigger the craft-skill review bundle because it does not use formal review.

### `tests/test_agents_md.sh`

Add assertions for:

- the fast, bounded, and full paths;
- the complete fast-path eligibility boundary;
- the excluded risk categories;
- the fast-path exclusions for brainstorming, plans, worktrees, subagents, and formal review;
- focused verification;
- one-way classification upgrades;
- the revised precedence order.

The assertions must test meaningful clauses rather than isolated words that unrelated text can satisfy.

### `tests/test_render_agents_md.sh`

Assert that every harness and provider rendering retains the workflow-scaling section and revised precedence. Existing harness-specific filtering must remain unchanged.

### `README.md`

Add a short `Adaptive workflow` section. Describe the three paths and name `AGENTS.md` as the detailed policy source. Do not duplicate the eligibility list.

## Expected behavior

The following examples define expected classification:

| Change | Path | Reason |
|---|---|---|
| Correct one README typo | Fast | The edit is clear, reversible, and locally verifiable. |
| Apply a mechanical rename across two files with an existing focused test | Fast | The scope and expected result are known. |
| Fix a known localized bug with a clear regression test | Fast | The behavior and verification are defined. |
| Diagnose a bug with an unknown cause | Bounded | Root-cause investigation is required. |
| Update a dependency | Full | Dependencies are an excluded risk category. |
| Change authentication behavior in one file | Full | Authentication is an excluded risk category. |
| Extend a two-file task into a third file | Upgrade | The task no longer meets the fast-path boundary. |
| Request a formal design for a small change | Requested heavier path | Direct user instructions select more process. |

## Verification

Implementation follows these checks:

1. Add failing assertions to `tests/test_agents_md.sh` and `tests/test_render_agents_md.sh` before changing the policy.
2. Update `AGENTS.md` and confirm the focused tests pass.
3. Update `README.md` without duplicating policy details.
4. Run `just test`.
5. Inspect the final diff for unconditional wording that makes all Superpowers workflows mandatory.
6. Confirm generated instructions for Claude Code, OpenCode, and Prime Agent contain the workflow-scaling policy.

The change has no runtime data migration. Installed behavior changes after `just install`, `just update`, or a harness-specific install recipe renders and links the updated instructions.

## Non-goals

- Forking or replacing upstream Superpowers skills.
- Adding a task-triage skill.
- Removing focused verification from the fast path.
- Letting a small diff bypass high-risk classification.
- Replacing the full workflow for architectural work.
- Changing model tiers, subagent definitions, or worktree mechanics.

## Rationale

The design limits process according to reversibility and risk. Reversible decisions should remain easy to change, as described in *The Pragmatic Programmer*, Chapter 2. The fast path also shortens the feedback loop for low-risk work, consistent with the agility guidance in Chapter 8. The bounded and full paths retain stronger controls where errors cost more to correct.
