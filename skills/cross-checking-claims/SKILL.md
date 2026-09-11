---
name: cross-checking-claims
description: Use when a subagent's finding is about to change a decision - prior art, licensing, feasibility, "this already exists" - before it is written into a design doc, plan, or decision log. Covers decorrelating agents and grounding claims in primary sources.
---

# Cross-Checking Claims

## Gate

Ask: would a different answer change what gets built, bought, or skipped?

If no, use the finding as reported. If yes, the claim is load-bearing and requires the checks below.

## Independent check

Dispatch the question to the `cross-checker` role on a different model line when available. Give it the question, not the first agent's answer. Do not anchor the check with a proposed conclusion.

If the first result came from the model configured for `cross-checker`, choose a different selector from the harness model list. If no second model is available, continue to the source check; do not treat the dispatch as independent.

`subagent-driven-development` `## Role routing and recovery` owns role selection. Follow it if its role rule conflicts with this skill.

## Source check

Verify the claim against the artifact itself. Accept primary sources such as the source repository, a raw `LICENSE` file, package metadata, a paper, or an official API response. Do not accept a blog post, a model's recollection, another agent's report, search snippets, or model agreement as evidence.

## Resolution

Settle disagreement at the source. Do not average the two answers, prefer confident wording, prefer a stronger model, or use a majority as a substitute for evidence.

If neither the independent check nor a primary source settles the claim, mark it as unconfirmed where it is used.

## Boundary with `verification-before-completion`

This skill covers external factual claims from subagents. `verification-before-completion` covers completion claims about your own work, using commands and their output as evidence. Handle a completion claim and an external factual claim in the same report separately.
