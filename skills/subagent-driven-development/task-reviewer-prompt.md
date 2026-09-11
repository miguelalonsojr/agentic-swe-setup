# Task Reviewer Prompt Template

Use this template when dispatching a task reviewer subagent.

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  model: [MODEL — REQUIRED: choose per `routing-model-tiers`; role per SKILL.md `## Role routing and recovery`; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    Review Task N for specification compliance, then task quality. This is a
    task-scoped gate, not the final whole-branch review.

    Read the task brief: [BRIEF_FILE]
    Binding global constraints: [GLOBAL_CONSTRAINTS]
    Read the implementer's report: [REPORT_FILE]

    Review the complete worker commit range.
    Base: [BASE_SHA]
    Head: [HEAD_SHA]
    Diff file: [DIFF_FILE]

    Read [DIFF_FILE] first. It contains the commit list, stat, and full diff.
    Do not read changed files separately unless needed to judge a cut-off hunk;
    name that check in the report. Do not re-run Git commands unless the diff
    file is missing; then run `git diff --stat [BASE_SHA]..[HEAD_SHA]` and
    `git diff [BASE_SHA]..[HEAD_SHA]`. Do not crawl the broader codebase.
    Inspect outside the diff only for concrete named risks. Perform one focused
    check per risk and name the risk and check. Treat out-of-scope changes as
    blocking findings.

    This checkout is read-only. Do not mutate the working tree, index, HEAD,
    or branch state. Do not dispatch subagents.

    Treat report claims and rationales as unverified. Check them against the
    diff. Warnings or noise in reported test output are findings. Do not
    re-run the suite. Run only a focused test when a specific doubt remains.
    If commands cannot run, name the focused test that would resolve that doubt.
    If evidence is missing or garbled, report that gap rather than rerunning tests.

    Specification review:
    - identify missing, extra, or misunderstood requirements
    - check each listed file in a batched brief against its corresponding hunk
    - check documentation when documented behavior changes
    - use a warning verdict for requirements that cannot be verified from the diff

    Quality review:
    - check separation of concerns, error handling, duplication, edge cases,
      test intent, responsibilities, interfaces, and task-added file growth
    - give file:line evidence for every finding and affirmative check

    Calibrate severity. Critical and Important findings block the task.
    Important means incorrect or fragile behavior, a missed requirement, or
    merge-blocking maintainability damage. Broader coverage and polish are
    Minor. Label a plan-mandated defect as Important even if the brief asks
    for it.

    Return the report directly. Every line is a verdict, a finding with
    file:line evidence, or a check run. Use no preamble or closing summary:

    ### Spec Compliance
    - Spec compliant | Issues found: missing, extra, or misunderstood items
      with file:line evidence
    - Cannot verify from diff: requirements and the controller check needed

    ### Strengths
    Specific evidence of work done well.

    ### Issues
    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)
    Each issue gives file:line, defect, consequence, and fix when non-obvious.

    ### Assessment
    Task quality: Approved | Needs fixes
    Reasoning: 1-2 technical sentences.
```

**Placeholders:**
- `[MODEL]`: reviewer model per `routing-model-tiers`.
- `[BRIEF_FILE]`: task brief path.
- `[GLOBAL_CONSTRAINTS]`: binding design requirements copied verbatim.
- `[REPORT_FILE]`: implementer report path.
- `[BASE_SHA]`: commit before the task.
- `[HEAD_SHA]`: worker head commit.
- `[DIFF_FILE]`: controller-created review package path.
