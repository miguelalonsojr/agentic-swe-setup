---
name: routing-model-tiers
description: Use when about to dispatch one or more subagents, especially a batch, before choosing which model each one runs on. Covers routing task types to model tiers, discovering the real model menu, and the per-harness dispatch mechanics.
---

# Routing Model Tiers

## Policy ownership

`dispatching-parallel-agents` selects access mode, isolation, and the safe dispatch wave. `subagent-driven-development` `## Role routing and recovery` selects roles and owns escalation. This skill selects the model for each dispatch. Follow the SDD skill if its role or escalation rule conflicts with this skill.

## Access and isolation

Choose access mode and isolation before model tier. Use `dispatching-parallel-agents` to build the largest safe wave and `using-git-worktrees` to isolate write-capable workers.

Model choice does not change isolation requirements. A stronger model does not make shared writes safe, and a light model still needs a worker worktree when it can edit.

When write scope is uncertain, use a read-only exploration dispatch first. Update the dependency and collision map before routing the implementation task.

## Tier selection

Ask what the task produces.

| The task produces | Tier |
|---|---|
| A list: cataloguing licences, pulling version pins, listing repository contents, extracting an interface, or reading known files for a factual answer. | Light |
| A verdict: synthesis across sources, a feasibility call, a trade-off judgment, a design decision, or anything that changes the plan. | Default; use strong when the verdict is load-bearing. See `cross-checking-claims`. |

A task that lists and judges is two tasks. Dispatch the light tier to enumerate, then give that result to the default or strong tier for judgment.

The light tier has a one-pass floor. Use it only for one pass over a known target. Route multi-step or iterative work to the default tier even when its output is list-shaped.

## Model discovery

The role roster is not the model menu. Ask the harness what it can address before a batch.

| Harness | Command |
|---|---|
| Prime Agent | `await rlm.find_models("", limit=20)`. `limit` is capped at 20; a larger value raises. |
| Claude Code | `/model` in-session. `--model` and agent frontmatter accept an alias or full name. |
| OpenCode | `opencode models`, or `opencode models <provider>` for one provider. |

## Harness dispatch

### Prime Agent

```python
handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5", thinking="high")
```

`rlm()` accepts `name`, `model`, and optional `thinking`. For installed roles, pass the model and thinking level from the `AGENTS.md` table explicitly. The system-prompt harness roster is not the role-to-model map: it truncates specs to 180 characters and shows only six roles. An explicit model is preserved; unavailable models fail admission without fallback. Omitting `model` inherits the parent model.

An explicit `thinking` level must be supported by the selected model or admission fails. Omitting `thinking` inherits the parent's current effective level, clamped to the selected child's supported levels.

### Claude Code

Pass a model per dispatch. Agent-frontmatter models are fallbacks when no model is selected.

### OpenCode

The model is fixed by the agent definition in `opencode.json`. Do not pass a model; choose the agent whose tier fits the task.

## Failure prevention

Do not reuse the current model or one model for a whole batch without routing each task. Do not use the strong tier for enumeration. Do not treat agreement among same-model children as corroboration; use `cross-checking-claims` for a load-bearing factual claim.
