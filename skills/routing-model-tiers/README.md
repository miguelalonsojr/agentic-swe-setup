# routing-model-tiers

Which model each subagent dispatch gets. `SKILL.md` is the agent-facing guide.
There is nothing to run by hand: this skill is prose, with no script and no
credentials to set up.

## Where it came from

The session recorded in `subagents-2026-08-08.md`, at the root of this repo.
Seven research children were dispatched over three batches. All seven ran on
`anthropic/claude-opus-5`, because the model was copied from the `general` role
spec on the first dispatch and never re-decided. The `explore` role, which is
defined on the light tier for fast read-only lookup and would have covered
several of those tasks, was never used.

Some of that work was enumeration: cataloguing dataset licences, listing the
contents of a skills repository, pulling version pins out of package metadata.
A light-tier model does that. Frontier budget paid for it instead.

`rlm.find_models()` was never called during that session, on the assumption that
the selectors named in the role specs were the whole menu. They were not. Calling
it afterwards returned 13 selectors against the three the specs name.

## Why it is a skill and not a line in AGENTS.md

The routing decision is made at dispatch time, one task at a time, by whichever
agent is holding the plan. A rule that far from the keyboard needs to load at the
moment of the choice, which is what the skill description triggers on.

`AGENTS.md` still owns the role-to-model table, because that mapping is specific
to this repo's installed roles. The skill points at it rather than copying it.

## Related

- `cross-checking-claims` covers the other half of the same session's lesson:
  children on one model share one model's blind spots.
- Local `dispatching-parallel-agents` covers the largest safe wave.
- Local `using-git-worktrees` covers worker worktrees for write-capable workers.
- Local `subagent-driven-development` covers implementation routing.
