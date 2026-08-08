---
name: routing-model-tiers
description: Use when about to dispatch one or more subagents, especially a batch, before choosing which model each one runs on. Covers routing task types to model tiers, discovering the real model menu, and the per-harness dispatch mechanics.
---

# Routing Model Tiers

## Overview

The model is a per-task decision, not a session default. Choose it while you write
each task, not once for the batch and not once for the session.

`dispatching-parallel-agents` decides whether to fan out into several agents; this
skill decides which model each of those agents gets.

The failure this prevents, from the session recorded in `subagents-2026-08-08.md`:
seven children were dispatched, the model was read off one role spec and reused for
all seven, and frontier budget went on cataloguing licences and pulling version pins
while the light read-only role that exists for that work went unused.

## The Routing Test

Ask one question before every dispatch: what does this task produce?

| The task produces | Tier |
|---|---|
| A list. Cataloguing licences, pulling version pins, listing a repository's contents, extracting an interface, reading files to answer a factual question. | Light |
| A verdict. Synthesis across sources, feasibility calls, trade-off judgements, design decisions, anything whose answer changes the plan. | Default, or strong when the verdict is load-bearing |

A task that produces a list it then has to judge is two tasks. Dispatch the light
tier to enumerate, then hand the enumeration to the default or strong tier to rule
on. Fused into one dispatch, the judgement gains nothing and you pay frontier rates
for the lookup.

## The Menu Is Bigger Than The Roster

The role roster is not the model menu. Read the menu:

```python
models = await rlm.find_models("", limit=20)
```

In the environment this skill was written for that returned 13 selectors, against the
three the installed ladder names. Which 13 depends on the providers authenticated at
the time, so call it at the start of a batch rather than working from the selectors
you happen to remember. `limit` is capped at 20 by the runtime; ask for more and the
call raises.

## Dispatch Mechanics By Harness

### Prime Agent

```python
handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5")
```

`rlm()` accepts `name` and `model` and nothing else. Any other keyword raises
`Unsupported rlm.run kwargs`. The child's thinking level is inherited from the parent
session and clamped to the child model's capability, so it cannot be set per dispatch:
the model is the whole of the decision.

The role-to-model map is the table under `#### When running under Prime Agent` in
`AGENTS.md`. The harness roster shown in the system prompt is not that map, because
Prime Agent summarises each subagent spec to 180 characters and shows only six of
them. Roles are missing from it, and no entry it does show carries a complete dispatch.

### Claude Code

Pass a model per dispatch, following the dispatching skill's own model-selection
guidance. Models in agent frontmatter are fallbacks for when you do not choose.

### OpenCode

The model is fixed by the agent definition in `opencode.json`. Do not pass one. Route
by choosing the agent whose tier fits the task.

## Red Flags

| Rationalisation | Reality |
|---|---|
| "I'll use the model I'm already on" | That is a default, not a decision. |
| "It's all one research batch" | A batch is many tasks, and they are not the same shape. |
| "The strong model is the safe choice" | For enumeration it buys nothing, and it costs the budget you need for the judgement calls later. |
| "The spec names a model, so that's the model" | The spec names the tier's model for that role, not for the task you are dispatching now. |
| "I know which models exist" | You know which ones the specs mention. Call `rlm.find_models` and count. |
| "All the children agreed, so the answer is solid" | Children on one model share one model's blind spots. Agreement between them is not corroboration. See `cross-checking-claims`. |
