---
name: dispatching-parallel-agents
description: Use when 2 or more subagent tasks may run concurrently and their dependencies, writes, or shared resources require a safe scheduling decision.
---

# Dispatching Parallel Agents

## Purpose

Map all dependencies and collision edges before parallel dispatch. A collision edge connects tasks that cannot run in one wave because one task changes state that another task reads or changes. A safe wave contains only tasks whose dependencies are satisfied and whose collision edges are resolved.

A different file does not prove independence. Tasks can collide through interfaces, generated state, repository-wide configuration, or external resources.

## Mandatory task inventory

Record one row for every task before selecting a wave. Each row retains:

- dependencies;
- access mode, classified as `read-only` or `write-capable`;
- expected files and interfaces read or changed;
- generated artifacts and lockfiles;
- migrations and configuration;
- external resources, including ports, databases, services, and test fixtures;
- controller-assigned namespaces;
- collision edges;
- rulings that add or remove edges.

Check every pair of tasks against the complete inventory. Check lockfiles, generated artifacts, migrations, and configuration. Record the producer and consumer for each edge. Do not define independence from disjoint test files.

## Namespace decisions

A namespace removes an external-resource collision edge only when the controller assigns it before dispatch, the namespace is unique among tasks in the wave, and the namespace is explicit and testable. Record the concrete namespace value and its verification command. A worker-selected, implicit, duplicated, or untestable namespace does not remove an edge.

Each namespace ruling adds or removes an identified collision edge. Keep the ruling in the inventory. Repository state such as files, interfaces, generated artifacts, lockfiles, migrations, and configuration does not become independent through an external-resource namespace.

## Safe-wave decision

Apply this order:

1. Map dependencies.
2. Classify every task as `read-only` or `write-capable`.
3. Complete the file, interface, generated-artifact, lockfile, migration, configuration, and external-resource inventory.
4. Add collision edges for each shared producer or consumer.
5. Apply only valid controller-assigned namespace rulings.
6. Dispatch the largest safe wave.

Read-only tasks use stable inputs. Every concurrent writer receives a separate controller-created worktree. Never dispatch concurrent write-capable agents into one worktree. If isolated worktrees are unavailable, keep writers sequential and continue to parallelize read-only tasks.

A task with uncertain write scope first receives a read-only exploration dispatch. Update the inventory and graph from its result before scheduling implementation.

## Dispatch output

Return the inventory, namespace rulings, collision graph, and largest safe wave to the orchestration skill. Prompts state the goal, acceptance criteria, scope, constraints, access mode, namespace values, relevant edges, and expected report.

## Integration feedback

Unexpected overlap stops integration of the affected tasks. Preserve their branches. Update the inventory and collision graph. Integrate the selected first task, then rerun or revise later work against the integrated state.

After integration, run each focused check and the wave suite. Worker reports and disjoint paths do not prove safe integration.
