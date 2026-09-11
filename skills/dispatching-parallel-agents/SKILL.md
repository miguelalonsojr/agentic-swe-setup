---
name: dispatching-parallel-agents
description: Use when 2 or more subagent tasks may run concurrently and their dependencies, writes, or shared resources require a safe scheduling decision.
---

# Dispatching parallel agents

## Task inventory

Record one row for each task before selecting a wave.

| Field | Record |
| --- | --- |
| Dependencies and access mode | Prerequisites and `read-only` or `write-capable` |
| Repository scope | Files, interfaces, generated artifacts, lockfiles, migrations, and configuration read or changed |
| External scope | Resources such as ports, databases, services, and test fixtures; controller-assigned namespaces |
| Graph | Collision edges, their producers and consumers, and rulings that add or remove edges |

## Collision rules

Compare every task pair against the complete inventory. Add a collision edge only when one task produces or writes shared state and another task consumes, produces, or writes it. Treat interfaces, generated state, repository-wide configuration, and external resources as shared state. Do not treat different files or disjoint test files as proof of independence.

## Namespace rules

Remove an external-resource edge only when the controller assigns a namespace before dispatch and the namespace is unique in the wave, explicit, and testable. Record the namespace value and verification command with the ruling. Reject worker-selected, implicit, duplicated, or untestable namespaces. Retain repository-state edges for files, interfaces, generated artifacts, lockfiles, migrations, and configuration.

## Wave selection

Apply this order:

1. Map dependencies.
2. Classify every task as `read-only` or `write-capable`.
3. Complete the repository and external-scope inventory.
4. Add collision edges for shared producers and consumers.
5. Apply valid controller-assigned namespace rulings.
6. Dispatch the largest safe wave with satisfied dependencies and resolved collision edges.

Give read-only tasks stable inputs. Give each concurrent writer a separate controller-created worktree. Keep writers sequential when separate worktrees are unavailable. Parallelize read-only tasks when their edges permit it. Send a task with uncertain write scope to a read-only exploration dispatch. Update the inventory and graph from the result before scheduling implementation.

## Dispatch and integration

Return the task inventory, namespace rulings, collision graph, and largest safe wave to the orchestration skill. Include the goal, acceptance criteria, scope, constraints, access mode, namespace values, relevant edges, and expected report in each prompt.

Stop integration for affected tasks when unexpected overlap appears. Preserve their branches. Update the inventory and collision graph. Integrate the selected first task, then rerun or revise later work against the integrated state. Run each focused check and the wave suite after integration. Do not use worker reports or disjoint paths as proof of safe integration.
