# Clean Coding

This skill guides focused reviews of names, functions, error paths, comments, and tests. It starts with the behavior the code must preserve and the conventions already used in the project. Its procedure asks reviewers to trace a specific reading or behavior problem before suggesting a small change.

The guide does not set a function-length limit or call for broad cleanup. It favors tests that check observable results, while allowing implementation-specific assertions when those details are part of the contract. For proposed edits, it asks for relevant test results, a diff check, and a runnable-path check when available. Missing context is a reason to ask for code, not to guess an interface or report a hypothetical defect as fact.
