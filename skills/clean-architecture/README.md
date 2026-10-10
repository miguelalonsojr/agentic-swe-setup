# Clean Architecture

Use this skill to review module boundaries and the direction of dependencies in an existing codebase. Start with a specific behavior and follow its real imports and calls. Identify which code owns the rule and which code handles storage, delivery, or framework integration. Recommend a change only when a concrete dependency makes the rule hard to test or ties it to a tool.

A useful review names the affected modules, cites the dependency path, and checks whether a focused test can exercise policy without starting infrastructure. It also keeps integration tests for the wiring. The guide does not require a fixed directory structure or extra layers for their own sake. It is not a substitute for a code-level review of naming or function design.
