---
name: design-patterns-expert
description: Use when deciding whether a named software design pattern fits a concrete change pressure, comparing it with simpler code, or reviewing an existing pattern's costs.
---

## When to use

Use this guide when a developer asks whether to introduce, keep, replace, or explain a software design pattern in a specific piece of code. Start from the change that is hard to make, not from a catalog of patterns. If the question has no code or constraints, ask for the responsibilities, likely changes, and current pain before recommending a structure. For a general naming, formatting, or function-size review, use clean-coding guidance instead.

## Procedure

1. State the current behavior, the requested change, and what must stay stable. Separate observed facts from assumptions. If code is available, inspect the call sites and tests that establish the current contract.
2. Name the simplest viable approach first, such as a direct function, a conditional, or one small object. Say what concrete future change would make that approach costly. Do not invent variants or extensibility needs.
3. If the pressure is real, identify one candidate pattern and the roles it needs. Show which existing responsibilities move and which do not. Prefer the smallest use of the pattern; a pattern name does not require a full class hierarchy.
4. Compare the candidate with the simple approach on the actual change: edited locations, coupling, state or lifecycle complexity, and ease of tracing behavior. Include the cost of extra indirection and any risk of making a common case harder to read. Reject the pattern if its benefit depends only on hypothetical work.
5. Give a narrow implementation sketch only when requested. Preserve the public contract unless the user explicitly asks to change it. Explain how to migrate one usage at a time if the change cannot be atomic.

## Verification

Give a check a developer can run or write. Cover the unchanged behavior and the change pressure that motivated the pattern. For example, a second output format should be selectable without editing the existing formatter when that isolation is the stated goal. Identify where the test observes behavior rather than asserting class names. If no executable context is supplied, describe a proposed check; do not report that it passed.

## Limits

A pattern is a choice under constraints, not a quality certificate. Do not claim measured performance, reduced defects, or easier maintenance without evidence. Do not guess framework or library interfaces. If thread safety, persistence, or external contracts matter, state what remains unknown and seek those constraints before giving code. Distinguish a pedagogical example from advice to refactor production code.

## References

- [Object-oriented foundations](references/chapter-01-oop-intro.md)
