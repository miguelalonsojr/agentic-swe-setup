# Scoped Re-Review Prompt Template

Use this template when dispatching a re-review after a fix round.

Select `[MODEL]` and `[THINKING]` from the provider-specific `AGENTS.md` table per `routing-model-tiers`; select `[ROLE]` per `SKILL.md` `## Role routing and recovery`. Dispatch in the Prime Agent REPL:

```python
handle = await rlm.spawn(task, name="[ROLE]", model="[MODEL]", thinking="[THINKING]")
```

Set `task` to the prompt below. The handle confirms admission, not completion. The child must reply explicitly with `await agent_message.send(message, receiver_role="parent")`. Await any nonblocking `bash(...)` test or commit handle before reporting output or an exact SHA.

```text
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

Send the report to the parent with `await agent_message.send(message, receiver_role="parent")`. Every line is a verdict, a finding with
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
- `[MODEL]` and `[THINKING]`: provider-specific reviewer settings per `routing-model-tiers`.
- `[ROLE]`: selected reviewer role per `SKILL.md` `## Role routing and recovery`.
- `[BRIEF_FILE]`: task brief path.
- `[FINDINGS]`: copied Critical/Important findings and specification gaps.
- `[REPORT_FILE]`: implementer report with appended fix reports.
- `[FIX_BASE_SHA]`: head reviewed in the prior round.
- `[HEAD_SHA]`: current head commit.
- `[DIFF_FILE]`: controller-created fix review package path.
