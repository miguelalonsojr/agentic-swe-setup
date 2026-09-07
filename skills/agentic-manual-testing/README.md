# Agentic Manual Testing

The skill covers the check that runs after the suite is green and before a change is called done: run the code through the interface a user reaches, and record the command and its real output. It gives a mechanism per surface (library, CLI, HTTP API, web UI, startup and migrations), the evidence rule, and the route back to red/green TDD when the check finds a bug.

The source is the "Agentic manual testing" chapter of Simon Willison's agentic engineering patterns guide (https://simonwillison.net/guides/agentic-engineering-patterns/agentic-manual-testing/).

It is a skill rather than a line in `AGENTS.md` because the mechanism table and the evidence rule are needed at one specific moment: the completion claim. A skill loads there, with the table and the rationalizations that argue against running the code. A standing instruction is read at the start of the session and is gone by the time it applies.
