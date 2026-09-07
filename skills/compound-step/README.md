# Compound Step

Origin: the guide's "AI should help us produce better code" chapter, section "Embrace the compound engineering loop" (`https://simonwillison.net/guides/agentic-engineering-patterns/better-code/`).

The pattern: a finished branch holds lessons that the code does not record. Rulings, repeated review findings, verification failures, and human corrections show where the instructions were wrong or missing. Writing them back into instructions, skills, or memory is what makes the next run cheaper.

Why a skill and not a line in `AGENTS.md`: the step runs at one moment, when a branch finishes, and it needs the harvest sources, the keep threshold, and the classify table in context at that moment. A one-line reminder produces a retrospective with no threshold and no destinations, which is a summary rather than a change.

Boundaries: `writing-skills` owns skill structure, so a proposed skill goes through it. `finishing-a-development-branch` owns branch integration and workspace deletion, and this step runs before the deletion. `subagent-driven-development` Finish produces the rulings list this step reads.
