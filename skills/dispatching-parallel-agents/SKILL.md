---
name: dispatching-parallel-agents
description: Use when 2 or more subagent tasks may run concurrently and their dependencies, writes, or shared resources require a safe scheduling decision.
---

# Dispatching Parallel Agents

## Purpose

Use parallel agents only after mapping dependencies and collision edges. A collision edge connects tasks that cannot run together because one task changes state that the other task reads or changes. A safe wave contains only tasks whose dependencies are satisfied and whose collision edges are resolved.

A different file does not prove independence. Two tasks collide when one changes an interface, generated artifact, migration, lockfile, configuration, or external resource that the other consumes.

## Decision order

1. Map dependencies.
2. Classify every task as `read-only` or `write-capable`.
3. Map file, interface, generated-artifact, and external-resource collisions.
4. Namespace external resources when the namespace is explicit and testable.
5. Dispatch the largest safe wave.
6. Run read-only tasks in a stable worktree.
7. Give every concurrent writer a controller-created worktree.
8. Review actual diffs and integrate approved commits sequentially.

## Access modes and collision edges

A `read-only` task does not modify repository state or shared external state. A `write-capable` task modifies either form of state.

Check each task pair for collision edges. Check files and interfaces. Check lockfiles, generated artifacts, migrations, and configuration. Check ports, databases, services, and test fixtures. A shared-state task runs sequentially unless an explicit, testable namespace removes the collision edge.

Never dispatch concurrent write-capable agents into one worktree. If isolated worktrees are unavailable, keep writers sequential and continue to parallelize read-only work.

## Dispatch prompts and output

Give each agent one focused, self-contained task. State the goal, relevant failures or acceptance criteria, permitted scope, constraints, access mode, and expected output. Ask for the changed files, commands run, test results, commit hash when applicable, and concerns.

Do not define independence from disjoint test files. Describe dependencies and collision edges in the prompt when they affect the task.

## Integration

The controller creates a worktree for every concurrent writer. The controller keeps read-only tasks in a stable worktree. After a safe wave completes, the controller reviews actual diffs, integrates approved commits sequentially, and runs the full suite.

Unexpected overlap stops integration of the affected tasks. Preserve both worker branches, update the collision map, and rerun or revise the later task against the integrated state.

## Verification

Before the next safe wave, verify each requested focused check and the full suite after integration. Do not treat worker reports or disjoint paths as proof that changes integrate safely.
