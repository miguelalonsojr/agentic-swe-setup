---
name: clean-coding
description: Use when reviewing or revising a local code change for clear names, focused functions, explicit error handling, useful comments, and behavior-focused tests.
---

# Clean Coding

## When to use

Use this guide when a code review or a small edit needs a judgment about readability and test intent. It applies to naming, function boundaries, error paths, comments, and tests that describe observable behavior. Identify the requested behavior and project conventions. Style differences alone are not defects.

## Procedure

1. Read the changed code with its callers and relevant tests. If the surrounding code is missing, ask for it rather than assuming how an interface works.
2. Check names against their roles. Prefer a name that distinguishes the value or action at the point of use. Propose a rename only if it removes a real ambiguity.
3. Trace each function from inputs to effects and outputs. Split a function when separate decisions are hard to follow or reuse, not because it exceeds a line limit. Keep related steps together when extraction would hide the flow.
4. Follow failure paths. Check whether errors preserve enough context for a caller to act, and whether cleanup still happens. Match the repository's error conventions. Do not add broad exception handling just to make a failure disappear.
5. Review comments against the code. Retain explanations of constraints or non-obvious choices; remove or correct comments that merely repeat statements or have become false. Do not erase a useful warning because it looks verbose.
6. Read tests as examples of the contract. Favor inputs, observable outcomes, and significant failure cases over assertions about private call order or incidental formatting. Keep tests deterministic and diagnostic.
7. Report each finding with its location, the concrete reading or behavior problem, and the smallest proportionate change. Separate verified defects from preferences. If no change is justified, say so.

## Verification

For a proposed edit, run the relevant tests through the project's normal command and inspect the diff. Exercise a runnable path when the change affects one. Confirm that the intended behavior stayed the same unless the task explicitly calls for a behavior change. A passing test cannot establish readability by itself; reread the affected call sites after the edit.

## Limits

This guide is not a mandate to refactor unrelated code, rename public interfaces, or impose universal formatting rules. Do not infer an API from a hypothetical example. Do not claim a test passes or an error is handled without inspecting evidence. Escalate changes to public contracts, security behavior, or concurrency through the project's normal review process.

## References

- [Clean Code, chapter 1](references/ch01_clean_code.md)
