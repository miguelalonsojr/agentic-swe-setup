# codebase-walkthrough

A reading order over code a human has not read, with the snippets pulled by command.
`SKILL.md` is the agent-facing guide; there is nothing to run by hand.

## Where it came from

Two chapters of Simon Willison's *Agentic Engineering Patterns*: "Linear walkthroughs"
(https://simonwillison.net/guides/agentic-engineering-patterns/linear-walkthroughs/) and
"Interactive explanations"
(https://simonwillison.net/guides/agentic-engineering-patterns/interactive-explanations/).

The audit that added this skill found the pattern missing from the repo. The installed
skills covered writing code, reviewing it by dispatch, and documenting an architecture.
None of them produced the artifact a human reads to understand a branch an agent built.
The anti-patterns chapter puts that reading on the human, so the skill exists to make it
cheap: a linear order, real code, and no paraphrase between the two.

The interactive explanation is the second chapter's pattern, kept opt-in. A single-file
HTML animation earns its cost for a mechanism that changes state over time, and not for
the rest of a walkthrough.

## How it differs from generating-design-doc

`generating-design-doc` produces a structured architecture document: components,
boundaries, diagrams, and the decisions behind them. It answers how the system is put
together.

A walkthrough answers what this code does, read in order, with the lines on the page. It
is linear rather than structured, it quotes rather than summarises, and it is scoped to
what one reader needs now, including a single branch.

## Related

- `requesting-code-review`: the dispatch that reviews the branch. The walkthrough helps
  the human do their own reading; it does not replace that dispatch.
- `routing-model-tiers`: the tier to send per-module reading to when the scope is large.
