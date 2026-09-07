---
name: agentic-manual-testing
description: Use after the tests pass and before claiming a change works, is fixed, or is done - run the code the way a user would and record what happened. Also use when a task brief names a manual check, or when a change touches a CLI, an HTTP API, a web UI, a startup path, or a migration.
---

# Agentic Manual Testing

Never assume generated code works until it has been executed. Passing tests are necessary, not sufficient. A test suite exercises the code the author expected to be exercised, through the interfaces the author chose. Manual testing runs the change through the interface a user reaches: the command line, the HTTP endpoint, the browser, the startup path.

Manual testing is not a substitute for tests. It runs after the suite is green, on the same change, and it answers a different question: does the assembled system behave as claimed. A bug found by manual testing is fixed with red/green TDD.

## Pick the mechanism by surface

| Surface | Mechanism |
|---|---|
| Library or function | `python -c` or the language equivalent, or a scratch file under `/tmp` (never inside the repo) |
| CLI | Run it with real arguments, including `--help` |
| HTTP API | Start the dev server, `curl` it, explore several endpoints and edge cases |
| Web UI | Playwright, `agent-browser`, or `uvx rodney --help`; take screenshots and read them |
| Startup and migrations | Boot the app; run the migration against a scratch database |

A screenshot that is captured and not read is not evidence. Open the image and describe what it shows.

## Evidence

Record the command and its real output. Output is pasted from the run, never typed. Paraphrase, prediction, and description of expected behaviour are not evidence.

Default format: fenced blocks in the task report under subagent-driven development, or in the final message and the pull request body outside it.

When the task asks for a demo document, run `uvx showboat --help` and use `note`, `exec`, and `image`.

If you cannot run the code in this environment, say so and name the exact command you would run. Silence is not evidence, and an untested claim marked as tested is a false report.

## Scope

A few happy-path cases and the edge cases the change touches, time-boxed. This is not a second test suite. Coverage belongs to the suite. Manual testing checks that the change is reachable and behaves as described through a real interface.

## When it finds a bug

1. Write the failing test that reproduces the bug.
2. Run it and confirm it fails for the stated reason.
3. Fix the code.
4. Run the test and the suite again.
5. Rerun the manual check that found the bug, and record its output.

Never patch without a test. A fix with no failing test first has no evidence that it addressed the reported behaviour.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The tests pass, so it works" | The tests cover the paths the author wrote. Wiring, startup, arguments, and output formatting can be broken with a green suite. |
| "Screenshots are overkill" | A UI change is verified by looking at the rendered result. An unread screenshot verifies nothing. |
| "I will describe what it should do" | A description is a prediction. Evidence is pasted output from a run that happened. |
| "I already know this code" | Familiarity predicts the intended behaviour, not the behaviour of the current change. |
| "Manual testing means I can skip the test" | The suite is what protects the behaviour on the next change. Manual testing does not run again. |

## Related skills

- `test-driven-development`: manual testing complements the suite and does not replace it. Every bug this skill finds returns to the red/green cycle.
- `verification-before-completion`: same evidence rule, applied to the completion claim itself.
- `subagent-driven-development`: the implementer report is where the recorded commands and output live.
