---
name: routing-model-tiers
description: Use when about to dispatch one or more subagents, especially a batch, before choosing which model each one runs on. Covers routing task types to model tiers, discovering the real model menu, and the per-harness dispatch mechanics.
---

# Routing Model Tiers

## Overview

The model is a per-task decision, not a session default. Choose it while you write
each task; a model chosen once for a whole batch is a default every later dispatch
inherits.

`dispatching-parallel-agents` decides whether to fan out into several agents; this
skill decides which model each of those agents gets. `subagent-driven-development`
`## Model Selection` is the overlapping authority: it ranks the roles of a plan by
tier and it is where the cost reasoning lives. Read it for role tiers, read this for
the per-dispatch decision, and follow it where the two ever disagree.

The failure this prevents, from the session recorded in `subagents-2026-08-08.md`:
seven children were dispatched, the model was read off one role spec and reused for
all seven, and frontier budget went on cataloguing licences and pulling version pins
while the light read-only role that exists for that work went unused.

## The Routing Test

## Access mode and isolation

Choose access mode and isolation before model tier. Use `dispatching-parallel-agents` to build the largest safe wave and `using-git-worktrees` to isolate write-capable workers.

Model choice does not change isolation requirements. A stronger model does not make shared writes safe, and a light model still needs a worker worktree when it can edit.

When write scope is uncertain, use a read-only exploration dispatch first. Update the dependency and collision map before routing the implementation task.

Ask one question before every dispatch: what does this task produce?

| The task produces | Tier |
|---|---|
| A list. Cataloguing licences, pulling version pins, listing a repository's contents, extracting an interface, reading files to answer a factual question. | Light |
| A verdict. Synthesis across sources, feasibility calls, trade-off judgements, design decisions, anything whose answer changes the plan. | Default, or strong when the verdict is load-bearing. See `cross-checking-claims` for what load-bearing means. |

A task that produces a list it then has to judge is two tasks. Dispatch the light
tier to enumerate, then hand the enumeration to the default or strong tier to rule
on. Fused into one dispatch, the judgement gains nothing and you pay frontier rates
for the lookup.

**The light tier has a floor: one pass.** Turn count beats token price. The cheapest
models routinely take two to three times the turns on multi-step work and cost more
in the end, so a task that loops (search, then read, then follow what it found)
takes mid-tier however list-shaped its output is. Light tier is for work that is one
pass over a known target.

## The Menu Is Bigger Than The Roster

The role roster is not the model menu. Ask the harness what it can address:

| Harness | Ask it |
|---|---|
| Prime Agent | `await rlm.find_models("", limit=20)`. `limit` is capped at 20 by the runtime; ask for more and the call raises. |
| Claude Code | `/model` in-session. `--model` and agent frontmatter take either an alias or a full name. |
| OpenCode | `opencode models`, or `opencode models <provider>` for one provider's list. |

In the Prime Agent environment this skill was written for, that call returned 13
selectors against the three the installed ladder names. What comes back depends on
which providers are authenticated, so make the call at the start of a batch instead
of working from the selectors you happen to remember.

## Dispatch Mechanics By Harness

### Prime Agent

```python
handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5")
```

`rlm()` accepts `name` and `model` and nothing else. Any other keyword raises
`Unsupported rlm.run kwargs`. The child's thinking level is inherited from the parent
session and clamped to the child model's capability, so it cannot be set per dispatch.

The role-to-model map is the table under `#### When running under Prime Agent` in
`AGENTS.md`. The harness roster shown in the system prompt is not that map, because
Prime Agent summarises each subagent spec to 180 characters and shows only six of
them, so some roles do not appear in it at all.

### Claude Code

Pass a model per dispatch, following `subagent-driven-development` `## Model
Selection`, which ranks the roles by tier. Models in agent frontmatter are fallbacks
for when you do not choose.

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
| "I know which models exist" | You know which ones the specs mention. Ask the harness for its list and count. |
| "All the children agreed, so the answer is solid" | Children on one model share one model's blind spots. Agreement between them is not corroboration. See `cross-checking-claims`. |
