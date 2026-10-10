---
name: clean-architecture
description: Use when reviewing a codebase's module boundaries, dependency direction, or whether core policy can be tested without infrastructure tools.
---

# Clean Architecture

## When to use

Use this guide when a review asks whether modules have clear responsibilities, whether imports point toward stable policy, or whether core behavior depends on a database, web framework, CLI, or external service. For local naming, function design, and ordinary code smells that do not cross module boundaries, use a code-level review instead.

## Procedure

1. Name the behavior under review and find its entry point, policy code, and tool-facing code. Read actual imports and calls before drawing a boundary. A directory name alone does not establish one.
2. List the rules that must stay true if the framework, storage engine, or delivery method changes. Identify the module that owns those rules. Treat I/O, serialization, and framework callbacks as details unless the behavior itself requires them.
3. Trace dependencies in both directions. Core policy may receive data or a small interface it needs; tool-facing code may call core policy. Flag a policy module that imports a concrete tool or requires tool startup to evaluate a rule. Quote the import or call path when reporting a finding.
4. Look for a test that exercises a representative rule without starting a server, connecting to storage, or patching an entire framework. If none exists, propose the smallest seam that allows such a test. For example, pass a clock value to a deadline rule instead of moving the rule into a new service package.
5. Recommend a boundary change only when it removes a demonstrated dependency or makes a necessary policy test possible. State the affected modules and the cost. Keep a direct call if an added adapter or layer would only rename it.

## Verification

Run the available focused tests and, when practical, add or identify a test that changes policy inputs and asserts policy output without infrastructure. Check imports after the change to confirm the tool-facing module depends on policy rather than the reverse. If execution is unavailable, label the recommendation as unverified and give the exact code path that supports it.

## Limits

Do not infer a dependency from a diagram or package name when code shows otherwise. Do not claim that every tool dependency is wrong: application entry points and adapters must use tools. Isolating policy tests does not replace tests for database queries, HTTP behavior, or integration wiring. Avoid adding ports, interfaces, or layers without a concrete rule or test that needs the boundary.

## References

- [What is design and architecture](references/chapter-01-what-is-design-and-architecture.md)
