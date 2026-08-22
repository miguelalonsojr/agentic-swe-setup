# Controller-Managed Subagent Worktrees Design

## Goal

The workflow must use subagents for every bounded task that can run independently. Concurrent write-capable agents must not share a worktree. Task-level TDD, review, and integration checks remain mandatory.

## Scope

The repository will own these skills:

- `subagent-driven-development`
- `dispatching-parallel-agents`
- `routing-model-tiers`
- `using-git-worktrees`

The repository-owned copies override skills with the same names from Superpowers or `agentic-swe-skills`. Other installed skills remain unchanged.

The `subagent-driven-development` copy includes its prompt files and scripts. Each repository-owned skill includes a `README.md` for human readers.

## Dispatch model

The controller converts a plan into a dependency graph. Each task records:

- its dependencies;
- its expected files and interfaces;
- its generated files, lockfiles, migrations, and configuration;
- its external resources, including ports, databases, services, and test fixtures;
- its access mode: read-only or write-capable.

The controller also records collision edges. A collision edge exists when two tasks can change or consume the same file, interface, generated artifact, or external resource. An external resource with a controller-assigned namespace does not create a collision.

The controller dispatches all tasks in the largest safe wave. A safe wave contains tasks with satisfied dependencies and no unresolved collision edges.

Read-only tasks run concurrently in a stable worktree. Write-capable tasks run concurrently only in separate controller-created worktrees. A task with uncertain scope first receives a read-only exploration dispatch. The controller updates the dependency and collision graph from the exploration result before it dispatches a writer.

Small edits of the same shape remain one batched task when they need the same context and review surface. Dispatching many agents for trivial edits does not improve useful concurrency.

## Writer worktree lifecycle

The controller owns the lifecycle of every worker worktree.

For each write task in a wave, the controller:

1. Records the integration branch HEAD as the task base commit.
2. Creates a task branch and worktree from that commit.
3. Records the branch, path, base commit, worker identity, and task status in the plan ledger.
4. Gives the worker its worktree path, task brief, allowed scope, fixed interface decisions, required tests, and report path.
5. Prohibits the worker from merging, rebasing, cherry-picking, creating worktrees, removing worktrees, or dispatching nested agents.
6. Requires TDD, a self-review, a task commit, and a report that names the commit and actual files changed.

A worker does not edit the controller worktree. A worker does not modify another worker's branch or worktree.

The controller removes a worker worktree and branch only after successful integration or explicit abandonment. Cleanup verifies the expected path and branch and refuses to remove a dirty worktree unless the task is explicitly abandoned.

## Review and integration

Each worker commit receives a task-scoped review before integration. Reviewers are read-only and can run concurrently when their inputs are stable. A reviewer examines the task brief, base commit, worker commit, tests, and actual diff.

The controller compares the actual diff with the declared task scope. An out-of-scope edit blocks integration until it is explained, reverted, or added to the collision graph and reviewed.

Approved commits enter the integration branch one at a time in dependency order. The controller uses commit-based integration rather than copying files between worktrees. Focused tests run after each integrated commit. The full suite runs after each wave.

An unexpected overlap stops integration of the affected tasks. Completed work remains on its worker branch. The controller selects an integration order, updates the graph, and revises or reruns the later task against the integrated state. The controller does not resolve a semantic conflict by silently accepting both diffs.

After all waves, a final whole-branch reviewer examines the integrated result. The final review uses the strongest configured review tier. Final findings use the existing bounded fix and re-review loop.

## Skill responsibilities

### `dispatching-parallel-agents`

This skill defines the dependency and collision test, access modes, safe waves, external-resource namespacing, and the boundary between parallel and sequential work.

### `using-git-worktrees`

This skill defines controller and worker worktree creation, base-commit validation, naming, ownership, cleanup, and recovery. The controller creates worker worktrees. Workers only operate inside the path supplied by the controller.

### `subagent-driven-development`

This skill plans waves, delegates implementation, starts task reviews, maintains the ledger, integrates approved commits, and runs the final review. The controller coordinates work and does not take implementation tasks from an eligible subagent.

### `routing-model-tiers`

This skill selects a model for each dispatch from the task's output, complexity, risk, and role. Model choice does not change isolation requirements. Read-only enumeration uses the light tier. Implementation and review use the least costly tier that can complete the task reliably.

## Installation precedence

Claude Code and OpenCode continue to install `agentic-swe-skills` before linking repository-owned skills. Prime Agent continues to link Superpowers and `agentic-swe-skills` before linking repository-owned skills. The final local link replaces any target with the same skill name.

A non-overlapping skill from `agentic-swe-skills` remains linked by its existing installer. The local override step does not filter, copy, or replace unrelated entries.

`install-skills.sh` relinks the repository-owned skills without reinstalling shared checkouts. Repeated installation is idempotent and preserves local precedence.

## Recovery

The plan ledger is the recovery authority after context compaction. It records task states, dependency and collision decisions, worker worktrees, branches, base commits, worker commits, reviews, integration commits, and cleanup states.

A controller restart inspects the ledger and Git state before dispatching work. It does not redispatch a completed task whose commit and report still exist. A missing worktree does not erase a committed result. A dirty or ambiguous worktree requires inspection before cleanup or reassignment.

## Verification

Skill changes follow the `writing-skills` RED-GREEN-REFACTOR process. Read-only pressure-test agents evaluate the current skills before modification and fresh agents evaluate the updated skills afterward.

Pressure scenarios cover:

- independent read-only tasks that should run concurrently;
- independent writers that should receive separate worktrees in one wave;
- tasks with different files but a shared interface that must run sequentially;
- tasks that share a lockfile, generated artifact, migration, or unnamespaced external resource;
- a writer that changes an undeclared file;
- worker commits with an unexpected overlap;
- recovery from a ledger after controller context loss.

Shell tests verify:

- all four names appear in `LOCAL_SKILLS`;
- each skill includes `SKILL.md` and `README.md`;
- the `subagent-driven-development` prompts and scripts are present;
- required dispatch, isolation, review, integration, and recovery clauses remain present;
- a conflicting upstream skill resolves to the repository-owned directory;
- a non-conflicting upstream skill remains installed;
- repeated installation preserves precedence;
- doctor identifies each repository-owned link;
- uninstall removes repository-owned links;
- the complete existing test suite remains green.

## Non-goals

- Parallel writes in one worktree.
- Automatic merging by worker agents.
- Nested agent dispatch from workers.
- Parallel tasks with unresolved dependencies or shared state.
- Replacing non-overlapping Superpowers or `agentic-swe-skills` content.
- Removing task reviews, TDD, full-suite verification, or the final whole-branch review to increase dispatch volume.
