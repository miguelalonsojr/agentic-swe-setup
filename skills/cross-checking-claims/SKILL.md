---
name: cross-checking-claims
description: Use when a subagent's finding is about to change a decision - prior art, licensing, feasibility, "this already exists" - before it is written into a design doc, plan, or decision log. Covers decorrelating agents and grounding claims in primary sources.
---

# Cross-Checking Claims

## Overview

Correlated agents agree, and agreement is not evidence. Children dispatched on one
model inherit that model's training cutoff, its priors and its gaps, so when they
concur you have one opinion returned several times.

The signature, from the session recorded in `subagents-2026-08-08.md`: seven research
children all ran on `anthropic/claude-opus-5`, and several independently reported that
their priors about the field were stale. Read as corroboration, that is seven checks
converging. It is one model's blind spot reported seven times.

## The Load-Bearing Test

Everything below costs a second dispatch and a round of fetching sources, so it must
not fire on every finding. One question decides:

**Would a different answer change what gets built, bought or skipped?**

If not, stop here and take the finding as reported. That question is the definition
of "load-bearing" that this repo's skills use.

| Claim | Load-bearing? |
|---|---|
| "This architecture has already been published" | Yes. A yes cancels the work, a no starts it. |
| "The repository is Apache-2.0" | Yes. Licence terms decide what you can ship on. |
| "This will not fit in 24 GB" | Yes. It picks the hardware and the training plan. |
| "This library already does it" | Yes. Build or adopt. |
| "The function takes a `dict` and returns a `Path`" | No. Open the file. |
| "The pinned version is 2.4.1" | No. Read the lockfile. |

The two halves differ in kind. The failing claims have one place to look and an answer
you get in seconds. The passing ones are judgements over evidence spread across
sources, where being wrong is expensive and does not announce itself.

## Step 1: Decorrelate

Re-dispatch the question on a different model family or version, to the `cross-checker`
role. The ladder puts that role on a different model from the default tier so that its
mistakes are less likely to be the first agent's mistakes.

A different vendor is the stronger decorrelation, a different model line the weaker one.
Both installed ladders give the weaker form: `claude-fable-5` against a default tier of
`claude-opus-5`, and `gpt-5.6-sol` against `gpt-5.6-terra`, which is two variants of one
version. Neither crosses vendors. Take the decorrelation the ladder gives, and do not
treat Step 2 as optional because Step 1 ran.

**Give it the question, not the answer.** An agent shown a claim tends to confirm it:
the claim becomes an anchor and the check turns into a search for supporting evidence.

| Do not send | Send |
|---|---|
| "`lit-rl-vla` says GR00T-WholeBodyControl is Apache-2.0. Confirm." | "What licence or licences does `NVlabs/GR00T-WholeBodyControl` ship under?" |

The residual case is a claim that came from the model the `cross-checker` spec already
names. That dispatch would not decorrelate anything, so pick a different selector from
the harness's own model list: `routing-model-tiers` `## The Menu Is Bigger Than The
Roster` has the call for each harness, and `## Dispatch Mechanics By Harness` has the
dispatch itself. Where no second model is reachable, Step 2 stands on its own.

`subagent-driven-development` `## Model Selection` is the overlapping authority on
model choice. Follow it where it and this section ever disagree.

## Step 2: Ground

A claim two models now share is still two models' recollection. Before it is written
down, check it against a primary source: the artefact the claim is about. The arXiv
API, the GitHub API, a raw `LICENSE` file, package metadata, the source itself.

Not a primary source: a blog post, a model's recollection, another agent's report, or
two models agreeing.

From the source session, a child reported `NVlabs/GR00T-WholeBodyControl` as
Apache-2.0. It is dual-licensed. Nothing in the report looked wrong; reading the
licence files in the repository is what caught it.

## Disagreement Is The Signal

Two verdicts that differ are the process working. That is the outcome you paid for.

Settle it at the sources. Do not average the two answers or take their overlap as a
safe subset. Do not prefer the more confident wording, or the stronger model, or a
majority from a third agent. Each of those closes the question without acquiring any
new evidence. The disagreement tells you which claim is worth the fetching.

## Unconfirmed Stays Unconfirmed

Some claims survive neither step. The cross-check cannot reach them and no primary
source settles them. Those go into the document flagged as unconfirmed, at the point
where they are used.

From the source session, `01-skill-embeddings.md` (in that project's research notes, not
in this repo) cites an ablation row in the PULSE
paper (R2/R5/R6) that was never confirmed against the paper. The citation is still
there and still carries its flag. Dropping it would have lost the lead. Rewriting it
as "PULSE reportedly ablates ..." would have kept the claim and hidden its status.

## Boundary With verification-before-completion

`verification-before-completion` governs your own claims about your own work, where the
evidence is a command you can run and read.

This skill governs a subagent's claims about the world, where no command settles it.
The evidence is a second model that did not inherit the first one's priors, plus a
source from outside the conversation.

A subagent that reports finishing its task and states a fact about the world in the
same message has made two claims. Handle them separately.
