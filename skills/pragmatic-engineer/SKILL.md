---
name: pragmatic-engineer
description: Use when choosing between practical implementation options whose cost, reversibility, duplicated knowledge, feedback speed, or security and testing exposure is uncertain.
---

# Pragmatic Engineer

## When to use

Use this guide when a team must choose a workable option under time or information constraints. Typical questions include whether to keep two similar implementations, build a narrow end-to-end slice first, defer a decision, or spend time on a security or test safeguard. Use it to compare options, not to replace an established project requirement or a specialist review.

## Procedure

1. State the decision and the observable outcome. Separate constraints that are known from assumptions that still need evidence. Name who will bear the cost if the choice is wrong.
2. Compare the smallest viable options. For each, note the cost to implement now, the cost to operate and change later, and how hard it is to reverse. Prefer a reversible choice when evidence is weak, but do not call a migration reversible without checking the data, consumers, and rollback path.
3. Look for duplicated knowledge. Two passages with the same words can serve different purposes; two different-looking pieces of code can encode the same rule. Identify the rule and its owner before proposing a shared abstraction. Consolidate only when maintaining the rule twice creates a real risk or recurring cost.
4. Find the shortest honest feedback loop. A tracer slice should cross the relevant path and expose the main uncertainty, even if it handles only one realistic case. State what the slice will prove and what remains untested; do not present a successful demo as proof of scale, reliability, or security.
5. Price safeguards against the failure they prevent. For security, identify the asset, trust boundary, plausible misuse, and impact before choosing a control. For testing, choose cases that would catch costly regressions and preserve required project checks. Savings from skipping a check must include the expected cost of a missed failure.
6. Record the choice, evidence, rejected alternative, and a signal that would trigger revision. Make the next check small enough to run soon.

## Verification

Confirm that the recommendation answers the stated decision, names a concrete cost or risk for each option, and distinguishes observed evidence from estimates. Check that rollback is feasible where claimed, the tracer actually reaches the uncertain boundary, and required security and test gates still run. If the missing facts could reverse the recommendation, ask for them or propose a limited experiment instead.

## Limits

This guide does not supply a threat model, a test strategy, or authority to waive controls. Do not infer repository behavior, external interfaces, test results, or exposure from a hypothetical example. Escalate a high-impact security, data-loss, or compliance choice to the responsible owner.

## References

- [Chapter 01: Pragmatic Philosophy](references/chapter-01-pragmatic-philosophy.md)
