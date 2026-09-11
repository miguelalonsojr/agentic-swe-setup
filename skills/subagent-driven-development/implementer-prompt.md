# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Subagent (general-purpose):
  description: "Implement Task N: [task name]"
  model: [MODEL — REQUIRED: choose per `routing-model-tiers`; role per SKILL.md `## Role routing and recovery`; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    You are implementing Task N: [task name].

    Read the task brief first: [BRIEF_FILE]
    Context: [CONTEXT]
    Work only in the supplied worker worktree: [WORKTREE_PATH]
    Write the full report to: [REPORT_FILE]

    Ask before starting if the requirements, acceptance criteria, approach,
    dependencies, or assumptions are unclear. Do not guess. If an unexpected
    or unclear condition arises while working, ask and pause rather than guess.

    Implement exactly the task scope. Follow the plan's file structure and
    established codebase patterns. Do not restructure unrelated code. If a
    planned new file grows beyond the plan's intent, stop and report
    DONE_WITH_CONCERNS. Do not split it without plan guidance. If an existing
    file is large or tangled, report that concern.

    Do not merge, rebase, cherry-pick, or create or remove worktrees. Do not
    dispatch subagents. Commit only this task's changes in the supplied worker
    worktree.

    Use TDD when the task requires it. While iterating, run the focused test
    for the change. Run the full suite once before committing. Exercise a
    runnable CLI, HTTP API, web UI, startup path, or migration per
    `agentic-manual-testing`, and record each command and pasted output.

    Stop and report BLOCKED or NEEDS_CONTEXT when the task needs an unplanned
    architectural decision, necessary code remains unclear after focused
    investigation, the planned structure no longer fits, or correctness is
    uncertain. State what is blocked, what was tried, and what help is needed.

    Before reporting, review the diff for:
    - completeness and task scope
    - clear naming and maintainable code
    - tests that verify intended behavior
    - relevant edge cases
    - clean test output

    Fix review findings in this worker worktree. Re-run tests covering the
    amended code. Append to [REPORT_FILE] what changed, the covering test
    command, and its pasted output. Then use the same short response contract.

    The full report at [REPORT_FILE] includes:
    - what was implemented, or attempted if blocked
    - test commands and results
    - TDD evidence when required: RED command, expected failing output, and
      reason; GREEN command and passing output
    - manual-testing evidence for runnable surfaces: commands and pasted
      output, UI screenshots, or the exact unavailable command
    - actual files changed
    - self-review findings
    - issues or concerns

    Reply in under 15 lines. Include:
    - Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - commits created (short SHA and subject)
    - one-line test summary
    - concerns, if any
    - [REPORT_FILE]

    For BLOCKED or NEEDS_CONTEXT, include the specifics in the reply. Use
    DONE_WITH_CONCERNS when work is complete but correctness remains doubtful.
```
