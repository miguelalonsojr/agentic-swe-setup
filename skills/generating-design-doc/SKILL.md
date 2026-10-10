---
name: generating-design-doc
description: Use when asked to create a structured architecture document for an existing codebase, grounded in source evidence and diagrams derived from code.
---

## When to use

Use this skill when the requested deliverable is a durable architecture or design document about software that already exists. The document should explain major responsibilities, boundaries, data and control flow, and important operational constraints. For a short guided tour of files or a reading-order explanation, use a codebase walkthrough instead. This skill does not design an unbuilt system.

## Procedure

1. Agree on the audience, scope, document location, and level of detail. Name the repository revision examined. If the request is broad, identify the key runtime paths and ask which ones matter most before claiming completeness.
2. Inventory entry points, packages, configuration, dependency declarations, tests, deployment files, and existing documentation. Read the actual code for each claim that shapes the architecture. Use search results to locate evidence, not as evidence by themselves.
3. Trace representative flows from input to outcome. Identify components by responsibility and observable dependencies, not just directory names. For each boundary, note what crosses it, who owns the contract, and whether behavior is synchronous, asynchronous, or unresolved by the inspected code.
4. Draft a document with a concise overview, context and scope, component map, key flows, persistence and external integrations where present, deployment/runtime assumptions, and known limitations. Omit sections that lack relevance; do not fill them with guesses. Cite repository-relative paths and symbols near the claims they support. Distinguish direct observations, reasonable inferences, and unknowns.
5. Draw diagrams only for relationships that the code supports. Label nodes with names readers can find in the repository. Show direction on dependencies or flows, and give each diagram a short explanation and evidence paths. Prefer a small number of readable diagrams to an exhaustive but speculative map.
6. Check the draft against the code and tests. Mark behavior not verified at runtime as unverified. Note outdated or conflicting existing documentation rather than silently adopting it.

## Verification

Confirm each central claim against a source location at the stated revision. Follow at least one complete representative flow; inspect both caller and callee where possible. Check that diagram edges have source evidence and that names match the code. If commands or tests were run, record their actual results; otherwise say that runtime behavior was not checked. List consequential unknowns and the precise evidence needed to resolve them.

## Limits

Do not infer production topology, scaling properties, guarantees, or security posture from naming alone. Avoid invented interfaces and claims that a diagram is complete. Keep the document descriptive: proposed changes and recommendations belong in a clearly separate section only when requested. Never expose secrets found in configuration or logs.
