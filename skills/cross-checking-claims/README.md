# cross-checking-claims

When to send a subagent's finding for an independent check, and how to ground it.
`SKILL.md` is the agent-facing guide; there is nothing to run by hand. It runs past the
500-word guidance in `writing-skills`, accepted because it has seven required sections
and loads on a narrow trigger rather than into every conversation.

## Where it came from

The session recorded in `subagents-2026-08-08.md`, at the root of this repo. Seven
research children ran over three batches, all on `anthropic/claude-opus-5`, and several
came back reporting that their priors about the field were stale. Seven agents agreeing
about a field they all learned from one corpus is one report, not seven.

Two errors surfaced. A child reported `NVlabs/GR00T-WholeBodyControl` as Apache-2.0 when
it is dual-licensed, and an ablation row cited from the PULSE paper was never confirmed
and is still flagged as unconfirmed in that project's notes. Both were caught by
re-fetching the arXiv API, the GitHub API and the raw licence files in the main thread.
Neither was caught by one child contradicting another.

That check ran because those claims felt load-bearing enough to prompt one, which is a
reflex rather than a process. The session's highest-stakes question, whether the
architecture had already been published, went to one agent on one model with no
cross-check. The answer was right, and was confirmed against the arXiv API afterwards:
verification after the fact rather than method.

## Why it is a skill and not a line in AGENTS.md

The decision is made mid-task, by whoever is holding a subagent's report and deciding
whether to write it down. A rule that far from the keyboard has to load at the moment of
the choice, which is what the skill description triggers on. `AGENTS.md` still owns the
role-to-model table, including the model the `cross-checker` runs on, and the skill
points at it rather than copying it.

## Related

- `routing-model-tiers`: the other half of that session's lesson, which model each
  dispatch gets in the first place.
- `verification-before-completion`, from Superpowers: your own work, not the world.
