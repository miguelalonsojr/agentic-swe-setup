# Scoped Re-Review Prompt Template

Use this template when dispatching a re-review after a fix round.

```
Subagent (general-purpose):
  description: "Re-review Task N fix round R"
  model: [MODEL — REQUIRED: choose per `routing-model-tiers`; role per SKILL.md `## Role routing and recovery`; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    Re-review one task fix round. Verdict every prior finding and inspect only
    the fix diff for breakage introduced by the fix.

    Read the task brief: [BRIEF_FILE]
    Findings under verification: [FINDINGS]
    Read the implementer's appended fix report: [REPORT_FILE]

    Fix base: [FIX_BASE_SHA]
    Head: [HEAD_SHA]
    Diff file: [DIFF_FILE]

    Read [DIFF_FILE] first. Do not re-run Git commands unless it is missing;
    then run `git diff --stat [FIX_BASE_SHA]..[HEAD_SHA]` and
    `git diff [FIX_BASE_SHA]..[HEAD_SHA]`.

    This checkout is read-only. Do not mutate the working tree, index, HEAD,
    or branch state. Do not dispatch subagents.

    Verdict each finding in order with file:line evidence. A finding is
    ADDRESSED only when its specific defect no longer exists. Do not re-review
    code outside the fix diff. Record an outside observation as non-blocking
    under Out-of-Scope Observations.

    Confirm that the fix report names covering tests and includes their output.
    Verify claims against the diff. Do not re-run the suite. Run only a focused
    test when a specific doubt remains.

    Return the report directly. Every line is a verdict, a finding with
    file:line evidence, or a check run. Use no preamble or closing summary:

    ### Finding Verdicts
    For each finding in order: [finding] - ADDRESSED | NOT ADDRESSED, with
    file:line evidence.

    ### New Breakage in the Fix Diff
    Fix-introduced breakage with Critical, Important, or Minor severity and
    file:line evidence. Write None if clean.

    ### Out-of-Scope Observations
    Non-blocking issues outside the fix diff. Write None if none.

    ### Verdict
    Fix round: [All findings addressed, no new Critical/Important breakage |
    Findings remain open] - list open findings.
```

**Placeholders:**
- `[MODEL]`: reviewer model per `routing-model-tiers`.
- `[BRIEF_FILE]`: task brief path.
- `[FINDINGS]`: copied Critical/Important findings and specification gaps.
- `[REPORT_FILE]`: implementer report with appended fix reports.
- `[FIX_BASE_SHA]`: head reviewed in the prior round.
- `[HEAD_SHA]`: current head commit.
- `[DIFF_FILE]`: controller-created fix review package path.
