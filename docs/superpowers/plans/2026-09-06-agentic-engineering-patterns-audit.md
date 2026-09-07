# Agentic Engineering Patterns Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the three missing pattern skills, fork two Superpowers skills with the guide's additions, fix the conflicts and stale references the audit found, and grade the Anthropic thinking ladder.

**Architecture:** Every deliverable is a markdown skill, a shell script, a JSON ladder entry, or a shell test, following the repo's existing layout: `skills/<name>/{SKILL.md,README.md}`, `tests/test_<name>.sh`, `scripts/lib.sh` as the registry. Skill correctness is pinned by content tests whose needles are whole sentences from the skill. No new subagent roles.

**Tech Stack:** bash, jq, git, markdown. Tests run through `just test` (`tests/run.sh` discovers `tests/test_*.sh`).

**Spec:** `docs/superpowers/specs/2026-09-06-agentic-engineering-patterns-audit-design.md`. Read it before any task; each task cites its section.

## Global Constraints

- Every skill directory has `SKILL.md` with frontmatter `name: <dir-name>` and `description:`, plus `README.md` for humans (`tests/test_local_skills.sh` enforces both).
- Skill prose: load `plain-technical-prose` and `de-slop` before writing; short sentences, no hype, no "it's worth noting". Load Superpowers `writing-skills` for skill structure.
- Test needles are whole sentences copied from the skill text. When a task lists a needle, the skill must contain that exact string.
- Size caps: `agentic-manual-testing` under 200 lines; `compound-step` under 150; `codebase-walkthrough` under 150.
- Forks copy upstream from `~/.superpowers/skills/<name>/` at commit `b36e082` (`git -C ~/.superpowers rev-parse --short HEAD`). Upstream text stays verbatim except the listed additions.
- Showboat is optional: named only as the format to use when a task asks for a demo or walkthrough document. Plain fenced blocks with pasted output are the default.
- Only Task 10 edits the ladder files and the README ladder section. Only Task 11 edits `scripts/lib.sh` and the README skill table. No other task touches `scripts/lib.sh` or `README.md`.
- Only Task 8 edits files under `skills/subagent-driven-development/` other than `scripts/test-summary` (Task 7).
- Every command a worker runs is awaited to completion; report exit code and output. Never report from a running handle.
- Commit messages: `type: summary` (`feat:`, `fix:`, `test:`, `docs:`).

## Task dependency notes

Wave 1 (disjoint files): Tasks 1, 2, 3, 4, 5, 6, 7, 9, 10.
Wave 2: Task 8 (after 7; names skills from 2, 3, 5), Task 11 (after 2–6 and 10).

---

### Task 1: Fix stale references outside SDD

Spec: Audit summary C5; section 9 baseline fix.

**Files:**
- Modify: `tests/test_local_skills.sh` (the routing needle, near line 30)
- Modify: `skills/routing-model-tiers/SKILL.md` (Overview paragraph)
- Modify: `skills/cross-checking-claims/SKILL.md` (Step 1, last paragraph)
- Test: `tests/test_local_skills.sh`

**Interfaces:**
- Produces: the phrase "`## Role routing and recovery`" as the SDD section other skills point at. Task 8 keeps that heading.

- [ ] **Step 1: Load `clean-coding`. Run the failing test**

Run: `bash tests/run.sh 2>&1 | grep -A2 test_local_skills`
Expected: `FAIL: routing skill names the rlm keywords and excludes the rest`

- [ ] **Step 2: Update the needle to the current sentence and add needles for the repoint**

Replace the `accepts \`name\` and \`model\` and nothing else` assertion with:

```bash
assert_contains "$routing" '`rlm()` accepts `name`, `model`, and optional `thinking`' \
    "routing skill names the rlm keywords"
assert_not_contains "$routing" "## Model Selection" \
    "routing skill no longer points at the removed SDD section"
assert_contains "$routing" '`## Role routing and recovery`' \
    "routing skill points at the SDD role section"
crosscheck=$(cat "$REPO_ROOT/skills/cross-checking-claims/SKILL.md")
assert_not_contains "$crosscheck" "## Model Selection" \
    "cross-checking skill no longer points at the removed SDD section"
assert_contains "$crosscheck" '`## Role routing and recovery`' \
    "cross-checking skill points at the SDD role section"
```

- [ ] **Step 3: Run the test; expect the two new `assert_not_contains` and `## Role routing` needles to fail**

Run: `bash tests/run.sh 2>&1 | grep -A6 test_local_skills`
Expected: FAIL lines for "no longer points at the removed SDD section" (both skills) and "points at the SDD role section" (both).

- [ ] **Step 4: Repoint both skills**

In `skills/routing-model-tiers/SKILL.md`, replace:

```
`subagent-driven-development`
`## Model Selection` is the overlapping authority: it ranks the roles of a plan by
tier and it is where the cost reasoning lives. Read it for role tiers, read this for
the per-dispatch decision, and follow it where the two ever disagree.
```

with:

```
`subagent-driven-development`
`## Role routing and recovery` is the overlapping authority: it names the role for
each dispatch and owns escalation. Read it for roles, read this for the per-dispatch
model decision, and follow it where the two ever disagree.
```

In `skills/cross-checking-claims/SKILL.md`, replace:

```
`subagent-driven-development` `## Model Selection` is the overlapping authority on
model choice. Follow it where it and this section ever disagree.
```

with:

```
`subagent-driven-development` `## Role routing and recovery` is the overlapping
authority on which role a dispatch gets. Follow it where it and this section ever
disagree.
```

- [ ] **Step 5: Run the full suite**

Run: `bash tests/run.sh`
Expected: `16/16 test files passed`

- [ ] **Step 6: Commit**

```bash
git add tests/test_local_skills.sh skills/routing-model-tiers/SKILL.md skills/cross-checking-claims/SKILL.md
git commit -m "fix: repoint stale SDD Model Selection references"
```

---

### Task 2: New skill `agentic-manual-testing`

Spec: section 1.

**Files:**
- Create: `skills/agentic-manual-testing/SKILL.md`
- Create: `skills/agentic-manual-testing/README.md`
- Test: `tests/test_agentic_manual_testing_skill.sh`

**Interfaces:**
- Produces: the skill name `agentic-manual-testing`, referenced by Tasks 5, 8, 9. Section heading `## Evidence` holds the evidence rule.

- [ ] **Step 1: Load `plain-technical-prose`, `de-slop`, and Superpowers `writing-skills`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/agentic-manual-testing"
skill="$root/SKILL.md"
assert_file "$skill" "agentic-manual-testing has a SKILL.md"
assert_file "$root/README.md" "agentic-manual-testing has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: agentic-manual-testing" "skill declares its name"
assert_contains "$body" "description: Use after the tests pass and before claiming a change works" \
    "skill triggers after green and before a completion claim"
assert_contains "$body" "Never assume generated code works until it has been executed." \
    "skill states the core rule"
assert_contains "$body" "Passing tests are necessary, not sufficient." \
    "skill states tests are not sufficient"
assert_contains "$body" "Manual testing is not a substitute for tests." \
    "skill does not compete with TDD"
assert_contains "$body" "A bug found by manual testing is fixed with red/green TDD." \
    "skill routes found bugs back to TDD"
assert_contains "$body" "Output is pasted from the run, never typed." \
    "skill forbids typed evidence"
assert_contains "$body" 'name the exact command you would run' \
    "skill handles the cannot-run case"
for mech in '`python -c`' '`curl`' '`uvx rodney --help`' 'Playwright' 'under `/tmp`' '`uvx showboat --help`'; do
    assert_contains "$body" "$mech" "skill names mechanism $mech"
done
assert_contains "$body" "This is not a second test suite." "skill bounds its scope"
assert_contains "$body" "## Evidence" "skill has an evidence section"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
lines=$(wc -l < "$skill")
[ "$lines" -lt 200 ] || fail "SKILL.md under 200 lines; got $lines"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_agentic_manual_testing_skill.sh`
Expected: FAIL on "has a SKILL.md" and every needle.

- [ ] **Step 3: Write `SKILL.md`**

Frontmatter:

```
---
name: agentic-manual-testing
description: Use after the tests pass and before claiming a change works, is fixed, or is done - run the code the way a user would and record what happened. Also use when a task brief names a manual check, or when a change touches a CLI, an HTTP API, a web UI, a startup path, or a migration.
---
```

Sections, in order, with the needle sentences placed verbatim:

1. `# Agentic Manual Testing` — overview. Contains: "Never assume generated code works until it has been executed." "Passing tests are necessary, not sufficient." "Manual testing is not a substitute for tests." "A bug found by manual testing is fixed with red/green TDD."
2. `## Pick the mechanism by surface` — a table: Library or function → `python -c` or the language equivalent, or a scratch file under `/tmp` (never inside the repo). CLI → run it with real arguments, including `--help`. HTTP API → start the dev server, `curl` it, explore several endpoints and edge cases. Web UI → Playwright, `agent-browser`, or `uvx rodney --help`; take screenshots and read them. Startup and migrations → boot the app; run the migration against a scratch database.
3. `## Evidence` — "Record the command and its real output. Output is pasted from the run, never typed." Default location: the task report (SDD) or the final message and PR body. Showboat: "When the task asks for a demo document, run `uvx showboat --help` and use `note`, `exec`, and `image`." Cannot run: "If you cannot run the code in this environment, say so and name the exact command you would run."
4. `## Scope` — "A few happy-path cases and the edge cases the change touches, time-boxed. This is not a second test suite."
5. `## When it finds a bug` — write the failing test first, then fix. Never patch without a test.
6. `## Common Rationalizations` — table rows: "tests pass, so it works"; "screenshots are overkill"; "I will describe what it should do"; "I already know this code"; "manual testing means I can skip the test".
7. `## Related skills` — `test-driven-development` (complement, not substitute), `verification-before-completion` (same evidence rule), `subagent-driven-development` (report format).

- [ ] **Step 4: Write `README.md`**

Three short paragraphs: what the skill is for; where it came from (the guide's "Agentic manual testing" chapter, `https://simonwillison.net/guides/agentic-engineering-patterns/agentic-manual-testing/`); why it is a skill and not a line in AGENTS.md (the mechanism table and evidence rule load at the moment of the completion claim).

- [ ] **Step 5: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_agentic_manual_testing_skill.sh; echo exit=$?`
Expected: no FAIL lines, `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add skills/agentic-manual-testing tests/test_agentic_manual_testing_skill.sh
git commit -m "feat: add agentic-manual-testing skill"
```

---

### Task 3: New skill `compound-step`

Spec: section 2.

**Files:**
- Create: `skills/compound-step/SKILL.md`
- Create: `skills/compound-step/README.md`
- Test: `tests/test_compound_step_skill.sh`

**Interfaces:**
- Produces: the skill name `compound-step`, referenced by Tasks 5 and 8. It accepts an optional ledger path in the dispatch text ("Ledger: <path>").

- [ ] **Step 1: Load `plain-technical-prose`, `de-slop`, and Superpowers `writing-skills`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/compound-step"
skill="$root/SKILL.md"
assert_file "$skill" "compound-step has a SKILL.md"
assert_file "$root/README.md" "compound-step has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: compound-step" "skill declares its name"
assert_contains "$body" "before the workspace is deleted" "skill runs before workspace deletion"
assert_contains "$body" "Keep an item only if it recurred, cost a fix round, or came from a human correction." \
    "skill states the keep threshold"
assert_contains "$body" 'lines that contain `Ruling:`' "skill harvests ledger rulings"
assert_contains "$body" "The human approves each item." "skill gates on human approval"
assert_contains "$body" "a commit separate from the feature work" "skill commits separately"
assert_contains "$body" '`refine`' "skill names the Prime Agent mechanism"
assert_contains "$body" '`writing-skills`' "skill routes new skills through writing-skills"
assert_contains "$body" "## Compound step" "skill defines the final-message section"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
assert_contains "$body" "It records what changed, not why the process failed." \
    "skill answers the git-history-is-the-record excuse"
lines=$(wc -l < "$skill")
[ "$lines" -lt 150 ] || fail "SKILL.md under 150 lines; got $lines"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_compound_step_skill.sh`
Expected: FAIL on every needle.

- [ ] **Step 3: Write `SKILL.md`**

Frontmatter:

```
---
name: compound-step
description: Use when a branch, plan, or multi-session task finishes - after the final review and before the workspace is deleted - or when the human asks what was learned. Turns rulings, review findings, surprises, and repeated fixes into small, evidence-backed updates to instructions, skills, or memory.
---
```

Sections:

1. `# Compound Step` — one paragraph: agents follow instructions; instructions improve only when someone writes the lesson down. Run this once per branch, before the workspace is deleted.
2. `## Harvest` — sources: the SDD ledger (lines that contain `Ruling:`, parked findings, deferred minors, tasks with two or more fix rounds); review findings that recurred across tasks; verification failures; human corrections during the session; items listed under "Follow-ups". If the dispatch names a ledger path, read it first.
3. `## Keep or drop` — "Keep an item only if it recurred, cost a fix round, or came from a human correction." Drop one-offs.
4. `## Classify` — table: project fact → the project's instruction file (`CLAUDE.md` or `AGENTS.md`); reusable procedure → a skill, new or existing, through `writing-skills`; durable preference or fact → memory (Prime Agent: `refine`; other harnesses: the instruction file); follow-up work → an issue or the follow-ups list; anything else → drop.
5. `## Propose and apply` — present a list: what, where, the evidence line. "The human approves each item." Apply approved items in a commit separate from the feature work.
6. `## Compound step` — the section to put in the final message: proposed, approved, applied, each as one line.
7. `## Common Rationalizations` — rows: "The git history is the record" → "It records what changed, not why the process failed."; "I will remember next time" → models do not; instructions do; "Too small to capture" → small items are what compound.
8. `## Related skills` — `writing-skills`; `finishing-a-development-branch`; `subagent-driven-development` Finish.

- [ ] **Step 4: Write `README.md`**

Origin: the guide's "AI should help us produce better code" chapter, section "Embrace the compound engineering loop" (`https://simonwillison.net/guides/agentic-engineering-patterns/better-code/`). Why a skill: it runs at one moment (branch finish) and needs the harvest and classify tables in context then.

- [ ] **Step 5: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_compound_step_skill.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add skills/compound-step tests/test_compound_step_skill.sh
git commit -m "feat: add compound-step skill"
```

---

### Task 4: New skill `codebase-walkthrough`

Spec: section 3.

**Files:**
- Create: `skills/codebase-walkthrough/SKILL.md`
- Create: `skills/codebase-walkthrough/README.md`
- Test: `tests/test_codebase_walkthrough_skill.sh`

**Interfaces:**
- Produces: the skill name `codebase-walkthrough`. Default output path `docs/walkthroughs/<slug>.md`.

- [ ] **Step 1: Load `plain-technical-prose`, `de-slop`, and Superpowers `writing-skills`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/codebase-walkthrough"
skill="$root/SKILL.md"
assert_file "$skill" "codebase-walkthrough has a SKILL.md"
assert_file "$root/README.md" "codebase-walkthrough has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: codebase-walkthrough" "skill declares its name"
assert_contains "$body" "Snippets are pulled by command, never hand-copied." "skill forbids hand-copied code"
assert_contains "$body" "sed -n" "skill names sed for snippets"
assert_contains "$body" 'git diff <base>..HEAD' "skill supports branch scope"
assert_contains "$body" 'docs/walkthroughs/<slug>.md' "skill has a default output path"
assert_contains "$body" "Ask before committing." "skill does not commit unasked"
assert_contains "$body" "entry point" "skill orders from the entry point"
assert_contains "$body" "single-file HTML animation" "skill offers an interactive explanation"
assert_contains "$body" "Only on request." "interactive explanation is opt-in"
assert_contains "$body" "It does not replace the review dispatch." "walkthrough is not a review"
assert_contains "$body" "light-tier read-only subagents" "large scope delegates reading"
assert_contains "$body" '`uvx showboat --help`' "skill names Showboat as the optional format"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
lines=$(wc -l < "$skill")
[ "$lines" -lt 150 ] || fail "SKILL.md under 150 lines; got $lines"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_codebase_walkthrough_skill.sh`
Expected: FAIL on every needle.

- [ ] **Step 3: Write `SKILL.md`**

Frontmatter:

```
---
name: codebase-walkthrough
description: Use when a human needs to understand code they did not write or do not remember - onboarding to a codebase, reviewing an agent-built branch before merge, or paying down cognitive debt on vibe-coded code. Produces a linear, reading-order walkthrough with real snippets, and on request an interactive explanation.
---
```

Sections:

1. `# Codebase Walkthrough` — overview: a walkthrough is a reading order plus real code. "It does not replace the review dispatch." It helps the human do the review the anti-patterns chapter requires of them.
2. `## Scope` — whole codebase, one subsystem, or a branch (`git diff <base>..HEAD`). For a branch, follow the change: entry point, data flow, tests.
3. `## Order` — read first, then plan: entry point → core flow → supporting modules → tests.
4. `## Snippets` — "Snippets are pulled by command, never hand-copied." Show `sed -n '12,40p' path/file.py`, `grep -n 'def ' path/file.py`, `git diff <base>..HEAD -- path`. Default format: a fenced block whose first line is the command, followed by the pasted output. "When the task asks for a Showboat document, run `uvx showboat --help` and use `exec` for every snippet."
5. `## Sections` — each: what it does, why it exists, how it connects, then the snippet.
6. `## Output` — the path the human names; default `docs/walkthroughs/<slug>.md`. "Ask before committing."
7. `## Large scope` — over a few thousand lines: dispatch light-tier read-only subagents for per-module notes; assemble in the root context.
8. `## Interactive explanation` — when a mechanism stays unclear after the walkthrough (an algorithm, a state machine, a scheduling loop), offer a single-file HTML animation with pause, step, and speed controls. Vanilla JS, no build step. "Only on request."
9. `## Common Rationalizations` — rows: "I will paraphrase the code" → paraphrase drifts from the code; pull the lines; "The README covers it" → the README says what it was meant to do; the walkthrough shows what it does; "A diff is a walkthrough" → a diff has no order and no why.
10. `## Related skills` — `generating-design-doc` (structured architecture document, a different artifact); `requesting-code-review`.

- [ ] **Step 4: Write `README.md`**

Origin: the guide's "Linear walkthroughs" and "Interactive explanations" chapters (`https://simonwillison.net/guides/agentic-engineering-patterns/linear-walkthroughs/`, `.../interactive-explanations/`). Note the difference from `generating-design-doc`.

- [ ] **Step 5: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_codebase_walkthrough_skill.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add skills/codebase-walkthrough tests/test_codebase_walkthrough_skill.sh
git commit -m "feat: add codebase-walkthrough skill"
```

---

### Task 5: Fork `finishing-a-development-branch`

Spec: section 4 and Fork policy.

**Files:**
- Create: `skills/finishing-a-development-branch/SKILL.md` (copy of `~/.superpowers/skills/finishing-a-development-branch/SKILL.md` plus additions)
- Create: `skills/finishing-a-development-branch/README.md`
- Test: `tests/test_finishing_a_development_branch_skill.sh`

**Interfaces:**
- Consumes: skill names `agentic-manual-testing` (Task 2) and `compound-step` (Task 3). Reference them by name only.
- Produces: the fork Task 8 points SDD at without the `superpowers:` prefix.

- [ ] **Step 1: Load `plain-technical-prose` and `de-slop`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/finishing-a-development-branch"
skill="$root/SKILL.md"
assert_file "$skill" "finishing-a-development-branch has a SKILL.md"
assert_file "$root/README.md" "finishing-a-development-branch has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: finishing-a-development-branch" "fork keeps the upstream name"
# Upstream anchors: prove this is a fork, not a rewrite.
assert_contains "$body" "## Step 1: Verify Tests" "fork keeps upstream Step 1"
assert_contains "$body" "Type 'discard' to confirm." "fork keeps the upstream discard gate"
assert_contains "$body" "## Step 6: Cleanup Workspace" "fork keeps upstream cleanup"
# Additions.
assert_contains "$body" "### Step 1b: Manual check" "fork adds the manual check"
assert_contains "$body" '`agentic-manual-testing`' "manual check names the skill"
assert_contains "$body" "### Step 1c: Tidy history" "fork adds history tidy"
assert_contains "$body" "Squash fix-round and WIP commits into the task commit they fix." "tidy squashes fix rounds"
assert_contains "$body" "Never rewrite commits already on a shared branch." "tidy protects shared history"
assert_contains "$body" "### Step 1d: Size report" "fork adds the size report"
assert_contains "$body" "Above 500 lines or 10 files, offer a split into stacked PRs by task." "size report has the threshold"
assert_contains "$body" "### PR description contract" "fork adds the PR contract"
assert_contains "$body" "reviewed the diff and this description" "PR contract has the author-reviewed line"
assert_contains "$body" "Present the PR body in chat and wait for approval before posting." "PR body is approved first"
assert_contains "$body" 'Run `compound-step` if it has not already run for this branch.' "fork hooks the compound step"
readme=$(cat "$root/README.md")
assert_contains "$readme" "b36e082" "README pins the upstream commit"
assert_contains "$readme" "superpowers/skills/finishing-a-development-branch" "README names the upstream path"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_finishing_a_development_branch_skill.sh`
Expected: FAIL on "has a SKILL.md" and every needle.

- [ ] **Step 3: Copy upstream and confirm the pin**

```bash
mkdir -p skills/finishing-a-development-branch
cp ~/.superpowers/skills/finishing-a-development-branch/SKILL.md skills/finishing-a-development-branch/SKILL.md
git -C ~/.superpowers rev-parse --short HEAD   # expect b36e082
```

If the short SHA is not `b36e082`, record the SHA you got in README.md instead and note it in your report.

- [ ] **Step 4: Insert the additions**

After Step 1's "If tests pass: continue to Step 2." insert three subsections:

```markdown
### Step 1b: Manual check

If the change has a runnable surface (CLI, HTTP API, web UI, startup path,
migration) and no manual-testing evidence exists yet, run
`agentic-manual-testing` now and keep its evidence for the PR body. If evidence
already exists in the task reports, point at it.

### Step 1c: Tidy history

```bash
git log --oneline <base-branch>..HEAD
```

Squash fix-round and WIP commits into the task commit they fix. Rewrite messages
to describe the change, not the process. Keep task boundaries as commits. Never
rewrite commits already on a shared branch. If the branch is already pushed, ask
before rewriting.

### Step 1d: Size report

```bash
git diff --stat <base-branch>..HEAD | tail -1
```

Report files and lines changed. Above 500 lines or 10 files, offer a split into
stacked PRs by task. The human decides.
```

Under "### Option 2: Push and Create PR", after the sentence ending "report the URL to your human partner.", insert:

```markdown
### PR description contract

The PR body carries:

- the goal and a link to the spec or issue
- what changed, per task or commit
- how it was tested: the test command and its result, and the manual-testing
  evidence with commands, output, and screenshots for UI
- rulings and deferred items
- one line stating that the author reviewed the diff and this description

Present the PR body in chat and wait for approval before posting.
```

Before "## Step 6: Cleanup Workspace", insert:

```markdown
## Step 5b: Compound step

Run `compound-step` if it has not already run for this branch. It reads the
ledger when one exists and proposes updates to instructions, skills, or memory.
Do this before any workspace is deleted.
```

Update the "## Overview" core-principle line to: "Verify tests → Manual check → Tidy history → Size report → Detect environment → Present options → Execute choice → Compound step → Clean up."

- [ ] **Step 5: Write `README.md`**

Contents: "Fork of `~/.superpowers/skills/finishing-a-development-branch` at upstream commit `b36e082`." Then a list "Additions" with the five insertions (Step 1b, 1c, 1d, PR description contract, Step 5b) and one line each on why. Then "Re-applying drift: diff the upstream file against this one; the additions are the only intended differences."

- [ ] **Step 6: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_finishing_a_development_branch_skill.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 7: Commit**

```bash
git add skills/finishing-a-development-branch tests/test_finishing_a_development_branch_skill.sh
git commit -m "feat: fork finishing-a-development-branch with tidy, size, PR contract, compound hook"
```

---

### Task 6: Fork `systematic-debugging`

Spec: section 5 and Fork policy.

**Files:**
- Create: `skills/systematic-debugging/` (copy of the whole upstream directory: `SKILL.md`, `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`, `condition-based-waiting-example.ts`, `find-polluter.sh`, `CREATION-LOG.md`, `test-academic.md`, `test-pressure-1.md`, `test-pressure-2.md`, `test-pressure-3.md`)
- Create: `skills/systematic-debugging/git-bisect.md`
- Create: `skills/systematic-debugging/README.md`
- Test: `tests/test_systematic_debugging_skill.sh`

**Interfaces:**
- Produces: the fork. `AGENTS.md` already names `systematic-debugging` without a prefix.

- [ ] **Step 1: Load `plain-technical-prose` and `de-slop`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/systematic-debugging"
skill="$root/SKILL.md"
assert_file "$skill" "systematic-debugging has a SKILL.md"
assert_file "$root/README.md" "systematic-debugging has a README.md"
assert_file "$root/git-bisect.md" "fork adds the bisect technique file"
assert_file "$root/root-cause-tracing.md" "fork keeps upstream technique files"
body=$(cat "$skill")
assert_contains "$body" "name: systematic-debugging" "fork keeps the upstream name"
assert_contains "$body" "### Phase 1: Root Cause Investigation" "fork keeps upstream Phase 1"
assert_contains "$body" "## The Four Phases" "fork keeps the upstream structure"
assert_contains "$body" 'git log --oneline -20 -- <paths>' "Phase 1 seeds from recent changes"
assert_contains "$body" 'If the bug is a regression, use `git bisect run`' "Phase 1 names bisect for regressions"
assert_contains "$body" "git-bisect.md" "SKILL.md points at the bisect file"
assert_contains "$body" "git reflog" "Phase 1 names reflog recovery"
assert_contains "$body" "git log --all -S" "Phase 1 names pickaxe search"
bisect=$(cat "$root/git-bisect.md")
assert_contains "$bisect" "git bisect start" "bisect file has the start command"
assert_contains "$bisect" "git bisect run" "bisect file has the run command"
assert_contains "$bisect" "exit 125" "bisect file explains the skip exit code"
assert_contains "$bisect" "git bisect reset" "bisect file resets afterwards"
readme=$(cat "$root/README.md")
assert_contains "$readme" "b36e082" "README pins the upstream commit"
assert_contains "$readme" "superpowers/skills/systematic-debugging" "README names the upstream path"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_systematic_debugging_skill.sh`
Expected: FAIL on every file and needle.

- [ ] **Step 3: Copy upstream**

```bash
mkdir -p skills/systematic-debugging
cp -r ~/.superpowers/skills/systematic-debugging/. skills/systematic-debugging/
git -C ~/.superpowers rev-parse --short HEAD   # expect b36e082
```

- [ ] **Step 4: Extend Phase 1 item 3 and add the technique file**

Replace the upstream item:

```
3. **Check Recent Changes**
   - What changed that could cause this?
   - Git diff, recent commits
   - New dependencies, config changes
   - Environmental differences
```

with:

```
3. **Check Recent Changes**
   - What changed that could cause this?
   - `git log --oneline -20 -- <paths>` over the files involved seeds the
     investigation with what changed and why
   - New dependencies, config changes
   - Environmental differences
   - If the bug is a regression, use `git bisect run` with a script that
     exercises the symptom: a failing test or a `python -c` check. Needs a
     known-good commit; ask, or use the last tag. See `git-bisect.md`.
   - If code that worked is gone: `git reflog`, `git stash list`, and
     `git log --all -S'<snippet>'` find it
```

Add to "## Supporting Techniques":

```
- **`git-bisect.md`** - Find the commit that introduced a regression with a binary search Git runs for you
```

Create `git-bisect.md`:

````markdown
# Git bisect for regressions

Bisect finds the first bad commit by binary search. You supply a good commit, a
bad commit, and a command that exits 0 when the symptom is absent and 1 when it
is present. Git does the rest.

## Recipe

```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit-or-tag>
git bisect run ./bisect-check.sh
git bisect reset
```

`bisect-check.sh` exercises the symptom and nothing else:

```bash
#!/usr/bin/env bash
# exit 0 = good, 1 = bad, 125 = cannot test this commit (skip it)
uv sync --quiet 2>/dev/null || exit 125
uv run pytest tests/test_thing.py::test_symptom -q >/dev/null 2>&1
```

A `python -c` check works when there is no test yet:

```bash
python -c 'from pkg import f; import sys; sys.exit(0 if f(3) == 9 else 1)' || exit 1
```

## Notes

- `exit 125` tells bisect to skip a commit that cannot be built or tested.
- Put the check script outside the repo (`/tmp`) so checkouts do not remove it.
- Always finish with `git bisect reset`; a half-finished bisect leaves HEAD detached.
- When bisect names the commit, read its diff before fixing anything. The commit
  is the trigger; the root cause may be older.
````

- [ ] **Step 5: Write `README.md`**

"Fork of `~/.superpowers/skills/systematic-debugging` at upstream commit `b36e082`." Additions: the Phase 1 item 3 bullets and `git-bisect.md`. Same drift note as Task 5.

- [ ] **Step 6: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_systematic_debugging_skill.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 7: Commit**

```bash
git add skills/systematic-debugging tests/test_systematic_debugging_skill.sh
git commit -m "feat: fork systematic-debugging with git bisect and recovery"
```

---

### Task 7: `test-summary` script for the SDD controller

Spec: section 7, third bullet; audit C6.

**Files:**
- Create: `skills/subagent-driven-development/scripts/test-summary` (executable bash)
- Test: `tests/test_test_summary.sh`

**Interfaces:**
- Produces: `test-summary [--log-dir DIR] -- CMD [ARGS...]`. Prints `exit=<code>` and `log=<path>` first. On exit 0, prints the last line of output. On non-zero, prints up to 20 lines matching failure markers, then the last 30 lines. Exits with CMD's exit code. Log dir default: `$SDD_TEST_LOG_DIR` if set, else `/tmp/test-summary`.

- [ ] **Step 1: Load `clean-coding`. Write the failing test**

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

script="$REPO_ROOT/skills/subagent-driven-development/scripts/test-summary"
assert_file "$script" "test-summary is present"
[ ! -f "$script" ] || [ -x "$script" ] || fail "test-summary is executable"
[ -x "$script" ] || exit "$ASSERT_FAILURES"

logdir="$SANDBOX/logs"

# Success: header lines plus the last line only.
out=$("$script" --log-dir "$logdir" -- bash -c 'printf "collecting\nline two\n42 passed in 0.3s\n"'; echo "status=$?")
assert_contains "$out" "exit=0" "success prints exit=0"
assert_contains "$out" "log=$logdir/" "success prints the log path"
assert_contains "$out" "42 passed in 0.3s" "success prints the summary line"
assert_not_contains "$out" "collecting" "success hides earlier output"
assert_contains "$out" "status=0" "success propagates exit 0"
log=$(ls "$logdir"/*.log | head -1)
assert_contains "$(cat "$log")" "collecting" "log keeps the full output"

# Failure: marker lines and tail, and the exit code propagates.
out=$("$script" --log-dir "$logdir" -- bash -c 'printf "ok 1\nnot ok 2 - thing\nFAIL: needle missing\n"; exit 3'; echo "status=$?")
assert_contains "$out" "exit=3" "failure prints the exit code"
assert_contains "$out" "not ok 2 - thing" "failure prints not-ok lines"
assert_contains "$out" "FAIL: needle missing" "failure prints FAIL lines"
assert_contains "$out" "status=3" "failure propagates the exit code"

# Usage error.
assert_status 2 "$script" --log-dir "$logdir"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 2: Run it to verify it fails**

Run: `REPO_ROOT=$PWD bash tests/test_test_summary.sh`
Expected: FAIL "test-summary is present".

- [ ] **Step 3: Write the script**

```bash
#!/usr/bin/env bash
# test-summary [--log-dir DIR] -- CMD [ARGS...]
#
# Run CMD, keep its full output in a log file, and print only what the
# controller needs: the exit code, the log path, the summary line on success,
# or the failure lines and tail on failure. Exits with CMD's exit code.
set -uo pipefail

usage() {
    printf 'usage: test-summary [--log-dir DIR] -- CMD [ARGS...]\n' >&2
    exit 2
}

log_dir="${SDD_TEST_LOG_DIR:-/tmp/test-summary}"
while [ $# -gt 0 ]; do
    case "$1" in
        --log-dir) [ $# -ge 2 ] || usage; log_dir=$2; shift 2 ;;
        --) shift; break ;;
        *) usage ;;
    esac
done
[ $# -gt 0 ] || usage

mkdir -p "$log_dir"
log="$log_dir/$(date -u +%Y%m%dT%H%M%SZ)-$$.log"

"$@" >"$log" 2>&1
code=$?

printf 'exit=%s\n' "$code"
printf 'log=%s\n' "$log"

if [ "$code" -eq 0 ]; then
    tail -n 1 "$log"
    exit 0
fi

grep -E 'FAIL|FAILED|not ok|Error|error:|✗' "$log" | head -n 20
printf -- '--- last 30 lines ---\n'
tail -n 30 "$log"
exit "$code"
```

```bash
chmod +x skills/subagent-driven-development/scripts/test-summary
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `REPO_ROOT=$PWD bash tests/test_test_summary.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/scripts/test-summary tests/test_test_summary.sh
git commit -m "feat: add test-summary script for SDD controllers"
```

---

### Task 8: SDD prose edits

Spec: section 7 (all bullets except the script). Depends on Task 7 (script name) and on the names from Tasks 2, 3, 5.

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/re-review-prompt.md`
- Modify: `skills/subagent-driven-development/README.md`
- Test: `tests/test_subagent_driven_development_skill.sh`

**Interfaces:**
- Consumes: `scripts/test-summary` (Task 7); skill names `agentic-manual-testing`, `compound-step`, `finishing-a-development-branch`.
- Produces: heading `## Role routing and recovery` unchanged (Task 1 points at it).

- [ ] **Step 1: Load `plain-technical-prose`. Add failing needles to the SDD test**

Append before `implementer=$(cat ...)`:

```bash
assert_contains "$body" "scripts/test-summary" "SDD controller runs tests through test-summary"
assert_contains "$body" 'Run `compound-step`' "SDD Finish runs the compound step"
assert_contains "$body" "before deleting the workspace" "compound step precedes workspace deletion"
assert_not_contains "$body" "superpowers:using-git-worktrees" "SDD names the forked worktree skill without the plugin prefix"
assert_not_contains "$body" "superpowers:finishing-a-development-branch" "SDD names the forked finishing skill without the plugin prefix"
assert_contains "$body" "superpowers:requesting-code-review" "SDD keeps the prefix for skills this repo does not fork"
assert_contains "$body" "## Role routing and recovery" "SDD keeps the role section other skills point at"
for f in implementer-prompt task-reviewer-prompt re-review-prompt; do
    assert_not_contains "$(cat "$root/$f.md")" "Model Selection" "$f no longer points at the removed section"
    assert_contains "$(cat "$root/$f.md")" 'choose per `routing-model-tiers`' "$f points at routing-model-tiers"
done
```

Append after the existing `implementer=` needles:

```bash
assert_contains "$implementer" 'exercise the change per `agentic-manual-testing`' "implementer prompt names the manual check"
assert_contains "$implementer" "Manual testing evidence" "implementer report carries manual evidence"
reviewer=$(cat "$root/task-reviewer-prompt.md")
assert_contains "$reviewer" "was the documentation updated?" "reviewer checks documentation"
```

- [ ] **Step 2: Run it to verify the new needles fail**

Run: `REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh`
Expected: FAIL for each new needle; existing needles pass.

- [ ] **Step 3: Edit `SKILL.md`**

Replace the two `"Use superpowers:finishing-a-development-branch"` graph labels and the final `Use superpowers:finishing-a-development-branch.` with `finishing-a-development-branch` (no prefix). Replace both `superpowers:using-git-worktrees` occurrences with `using-git-worktrees`. Leave `superpowers:requesting-code-review's` as is.

In "### 1. Run safe waves", replace step 10:

```
10. Run focused tests after each integrated commit and the full suite after each wave.
```

with:

```
10. Run focused tests after each integrated commit and the full suite after each wave, through this skill's `scripts/test-summary -- <command>`; read its summary, and open the log path only when something failed.
```

In "## Finish", replace:

```
When the final whole-branch review is clean and its fixes are merged,
delete this plan's workspace (`rm -rf <workspace>`) — the git history is
the record now. Sibling directories belong to other plans; leave them
alone.
```

with:

```
When the final whole-branch review is clean and its fixes are merged, two
steps remain. Run `compound-step` with the ledger path
(`Ledger: <workspace>/progress.md`) before deleting the workspace. Then delete
this plan's workspace (`rm -rf <workspace>`) — the git history is the record
of the code, and the compound step is the record of the process. Sibling
directories belong to other plans; leave them alone.
```

- [ ] **Step 4: Edit the three prompt files**

In each of `implementer-prompt.md`, `task-reviewer-prompt.md`, `re-review-prompt.md`, replace every

```
choose per SKILL.md Model Selection
```

with

```
choose per `routing-model-tiers`; role per SKILL.md `## Role routing and recovery`
```

and every `per SKILL.md Model Selection` in the placeholder lists at the bottom with `per `routing-model-tiers``.

In `implementer-prompt.md`, replace step 3 of "## Your Job":

```
    3. Verify implementation works
```

with:

```
    3. Verify: run the covering tests; then exercise the change per `agentic-manual-testing`
       when it has a runnable surface (CLI, HTTP API, web UI, startup path, migration),
       and record the commands and their pasted output in the report
```

In the "## Report Format" list, after the TDD Evidence block add:

```
    - **Manual testing evidence** (when the change has a runnable surface):
      each command run and its pasted output; screenshots for UI; or the exact
      command you would have run if you could not run it here
```

In `task-reviewer-prompt.md`, under "## Part 1: Spec Compliance" after the "Misunderstood" bullet add:

```
    - **Docs:** if the change alters documented behavior, was the documentation
      updated? A missing doc update is a Missing finding.
```

- [ ] **Step 5: Update `README.md`**

Add one paragraph: the controller runs integration tests through `scripts/test-summary`, and Finish runs `compound-step` before the workspace is deleted. Forked skills are named without the `superpowers:` prefix.

- [ ] **Step 6: Run the SDD test and the suite**

Run: `REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh; echo exit=$?`
Expected: `exit=0`.
Run: `bash tests/run.sh`
Expected: all files ok.

- [ ] **Step 7: Commit**

```bash
git add skills/subagent-driven-development tests/test_subagent_driven_development_skill.sh
git commit -m "feat: SDD names manual testing, doc check, test-summary, compound step"
```

---

### Task 9: `AGENTS.md` edits

Spec: section 6.

**Files:**
- Modify: `AGENTS.md` (Workflow Scaling and Coding Discipline sections)
- Test: `tests/test_agents_md.sh`

**Interfaces:**
- Consumes: skill name `agentic-manual-testing` (Task 2).
- Produces: the shared body every harness render carries. Do not touch the three `When running under` sections or the Prime markers.

- [ ] **Step 1: Load `plain-technical-prose`. Add failing needles**

Append to `tests/test_agents_md.sh` before the Prime marker assertions:

```bash
assert_contains "$body" "### Spike" "AGENTS.md defines the spike path"
assert_contains "$body" "A feasibility question whose output is an answer, not code you keep." "spike is defined by its output"
assert_contains "$body" 'The fast path uses no `brainstorming`; the bounded path is `brainstorming`'"'"'s bounded path; the full path is `brainstorming`'"'"'s architectural path; a spike is `brainstorming`'"'"'s spike.' "AGENTS.md maps its paths onto brainstorming's"
assert_contains "$body" "run the test suite with the project's documented command before the first edit" "AGENTS.md runs the tests first"
assert_contains "$body" 'list them under "Follow-ups" in the final message' "AGENTS.md captures follow-ups"
assert_contains "$body" "never fold them into the current diff" "follow-ups stay out of the diff"
assert_contains "$body" "Passing tests are necessary, not sufficient." "AGENTS.md requires manual exercise"
assert_contains "$body" '`agentic-manual-testing`' "AGENTS.md names the manual testing skill"
assert_contains "$body" 'Clone repos to `/tmp`' "AGENTS.md reads reference code from /tmp"
assert_contains "$body" "never commit reference copies" "reference copies stay out of commits"
assert_contains "$body" "update the documentation that describes it" "AGENTS.md keeps docs current"
```

- [ ] **Step 2: Run it to verify the new needles fail**

Run: `REPO_ROOT=$PWD bash tests/test_agents_md.sh`
Expected: FAIL for each new needle.

- [ ] **Step 3: Edit `AGENTS.md`**

In "## Workflow Scaling", after the "### Full path" subsection and before "### Reclassification", add:

```markdown
### Spike

A spike is a feasibility question whose output is an answer, not code you keep.
Present the question and what you will try in two or three sentences, get a nod,
then find out as cheaply as correctness allows. Label anything you build as
throwaway. Keeping the code is a new request; classify it.

### Path mapping

The fast path uses no `brainstorming`; the bounded path is `brainstorming`'s bounded path; the full path is `brainstorming`'s architectural path; a spike is `brainstorming`'s spike.
```

At the top of "## Coding Discipline", after the two-sentence intro, add:

```markdown
### First run the tests

On an existing project, run the test suite with the project's documented command before the first edit, and report the count and result. This applies on every path.
```

In "### Surgical changes", replace:

```
- Remove imports, variables, functions, or files that your own change makes
  unused. Mention unrelated dead code; do not delete it unless asked.
```

with:

```
- Remove imports, variables, functions, or files that your own change makes
  unused. For unrelated dead code, smells, and refactor opportunities you
  notice, list them under "Follow-ups" in the final message; never fold them
  into the current diff. After the goal lands, offer to dispatch each as its own
  small task.
```

After "### Goal-driven execution", add:

```markdown
### Exercise the code

Passing tests are necessary, not sufficient. Before claiming a change works,
exercise it as a user would (`agentic-manual-testing`) when it has a runnable
surface.

### Reference code

When the user points at an example — a repo, a file, a URL — read the real
thing. Clone repos to `/tmp`, fetch raw source with `curl`, and never commit
reference copies.
```

In "### Simplicity first", add a final bullet:

```
- If a change alters documented behavior, update the documentation that describes it.
```

- [ ] **Step 4: Run the AGENTS.md tests and the render test**

Run: `REPO_ROOT=$PWD bash tests/test_agents_md.sh; echo exit=$?`
Expected: `exit=0`.
Run: `REPO_ROOT=$PWD bash tests/test_render_agents_md.sh; echo exit=$?`
Expected: `exit=0`.

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md tests/test_agents_md.sh
git commit -m "feat: AGENTS.md adds spike, first-run-tests, follow-ups, manual exercise, reference code"
```

---

### Task 10: Thinking ladder

Spec: section 8.

**Files:**
- Modify: `prime/anthropic.json`
- Modify: `opencode/anthropic.json`
- Modify: `agents/implementer-light.md`, `agents/reviewer-lite.md` (`effort: medium`); `agents/implementer-strong.md`, `agents/reviewer-final.md` (`effort: xhigh`)
- Modify: `README.md` lines 146-160 (Anthropic ladder table and its paragraph), lines 175-177, lines 227-233 (Claude Code table)
- Test: `tests/test_prime_configs.sh`, `tests/test_provider_configs.sh`, `tests/test_agents.sh`

**Interfaces:**
- Produces: the ladder values Task 11's README skill-table edit must not touch.

- [ ] **Step 1: Verify Claude Code accepts `effort: xhigh` in agent frontmatter**

Run:

```bash
curl -fsSL https://docs.claude.com/en/docs/claude-code/sub-agents | grep -o -i 'xhigh' | head -1
```

If the output is `xhigh`, use `xhigh` for the two strong Claude Code agents. If it is empty or the fetch fails, use `high` for them, keep `xhigh` for Prime and OpenCode, and record in the README Claude Code table note: "Claude Code frontmatter accepts `high` as the top verified level; raise to `xhigh` once the sub-agents documentation lists it." Put the command and its output in your report.

- [ ] **Step 2: Load `clean-coding`. Replace the all-high assertions with per-role ones**

In `tests/test_prime_configs.sh`, replace lines 116-117 (`every anthropic prime agent runs at high`) with:

In that file `$a` is already the path to `prime/anthropic.json`, so the loop variable is `ag`:

```bash
for ag in explore implementer-light reviewer-lite; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].thinking' "$a")" "medium" "anthropic prime $ag runs at medium"
done
for ag in general implementer reviewer cross-checker; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].thinking' "$a")" "high" "anthropic prime $ag runs at high"
done
for ag in implementer-strong reviewer-final; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].thinking' "$a")" "xhigh" "anthropic prime $ag runs at xhigh"
done
```

In `tests/test_provider_configs.sh`, `$a` is the path to `opencode/anthropic.json`. Replace lines 75-77 (the comment "Every agent runs at high" and the `unique | join` assertion) with:

```bash
# Light tier at medium, default at high, strong at xhigh; cross-checker at high.
for ag in explore implementer-light reviewer-lite; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].variant' "$a")" "medium" "anthropic $ag runs at medium"
done
for ag in general implementer reviewer cross-checker; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].variant' "$a")" "high" "anthropic $ag runs at high"
done
for ag in implementer-strong reviewer-final; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].variant' "$a")" "xhigh" "anthropic $ag runs at xhigh"
done
```

In `tests/test_agents.sh`, replace:

```bash
    # Every tier reasons hard; only the rung differs.
    effort=$(frontmatter_field "$f" effort)
    case "$effort" in
        high|xhigh) ;;
        *) fail "$a effort must be high or xhigh; got [$effort]" ;;
    esac
```

with:

```bash
    # Light tier reasons at medium, default at high, strong at xhigh.
    effort=$(frontmatter_field "$f" effort)
    case "$a" in
        implementer-light|reviewer-lite) want=medium ;;
        implementer-strong|reviewer-final) want=xhigh ;;
        *) want=high ;;
    esac
    assert_eq "$effort" "$want" "$a effort"
```

If Step 1 fell back to `high` on Claude Code, use `want=high` for the strong pair and say so in a comment.

- [ ] **Step 3: Run the three tests to verify they fail**

Run: `for t in test_prime_configs test_provider_configs test_agents; do REPO_ROOT=$PWD bash tests/$t.sh; done`
Expected: FAIL lines for medium and xhigh roles.

- [ ] **Step 4: Edit the ladder files**

```bash
for a in explore implementer-light reviewer-lite; do
    jq --arg a "$a" '.agent[$a].thinking = "medium"' prime/anthropic.json > /tmp/p.json && mv /tmp/p.json prime/anthropic.json
    jq --arg a "$a" '.agent[$a].variant = "medium"' opencode/anthropic.json > /tmp/o.json && mv /tmp/o.json opencode/anthropic.json
done
for a in implementer-strong reviewer-final; do
    jq --arg a "$a" '.agent[$a].thinking = "xhigh"' prime/anthropic.json > /tmp/p.json && mv /tmp/p.json prime/anthropic.json
    jq --arg a "$a" '.agent[$a].variant = "xhigh"' opencode/anthropic.json > /tmp/o.json && mv /tmp/o.json opencode/anthropic.json
done
```

Check the diff keeps two-space indentation and key order (`git diff --stat` should show only value lines). If `jq` reformatted the file, reapply the edits by hand instead.

Edit the four `agents/*.md` frontmatter `effort:` lines to the values in Step 2.

- [ ] **Step 5: Update the README ladder section**

Replace the paragraph starting "Three tiers, distinguished by model. Every tier reasons at `high`" with:

```
Three tiers, distinguished by model and by thinking level. The light tier runs
at `medium` because its work is one pass over a known target; the default tier
runs at `high`; the strong tier runs at `xhigh` because it is dispatched rarely
and its judgment gates an outcome. `cross-checker` stays at `high`: it reads
primary sources, which does not need deeper reasoning.
```

Update the Anthropic table variants: `explore`, `implementer-light`, `reviewer-lite` → `medium`; `implementer-strong`, `reviewer-final` → `xhigh`; the rest `high`. Replace "All three models also accept `xhigh` and `max` if you want to raise the strong tier later." with "All three models also accept `max` if you want to raise the strong tier further." Update the Claude Code table effort column the same way (or with the Step 1 fallback).

- [ ] **Step 6: Run the suite**

Run: `bash tests/run.sh`
Expected: all files ok, including `test_render_agents_md.sh` (the reviewer row it checks stays `high`).

- [ ] **Step 7: Commit**

```bash
git add prime/anthropic.json opencode/anthropic.json agents/*.md README.md tests/test_prime_configs.sh tests/test_provider_configs.sh tests/test_agents.sh
git commit -m "feat: grade the anthropic thinking ladder medium/high/xhigh"
```

---

### Task 11: Register the skills and document them

Spec: section 9. Depends on Tasks 2-6 (directories) and Task 10 (README ladder edits land first).

**Files:**
- Modify: `scripts/lib.sh` (`LOCAL_SKILLS`)
- Modify: `README.md` ("## Skills this repo ships" table and the paragraph after it)
- Test: `tests/test_local_skills.sh`, `tests/test_readme.sh`, `tests/test_install.sh`, `tests/test_doctor.sh`, `tests/test_uninstall.sh`

**Interfaces:**
- Consumes: the five directories `skills/agentic-manual-testing`, `skills/compound-step`, `skills/codebase-walkthrough`, `skills/finishing-a-development-branch`, `skills/systematic-debugging`.

- [ ] **Step 1: Load `plain-technical-prose`. Add failing needles**

Append to `tests/test_local_skills.sh` before `exit`:

```bash
for s in agentic-manual-testing compound-step codebase-walkthrough finishing-a-development-branch systematic-debugging; do
    case " ${LOCAL_SKILLS[*]} " in
        *" $s "*) ;;
        *) fail "LOCAL_SKILLS registers $s" ;;
    esac
done
readme=$(cat "$REPO_ROOT/README.md")
for s in agentic-manual-testing compound-step codebase-walkthrough finishing-a-development-branch systematic-debugging; do
    assert_contains "$readme" "| \`$s\` |" "README skill table lists $s"
done
assert_contains "$readme" "Forked from Superpowers at commit \`b36e082\`" "README names the fork pin"
```

- [ ] **Step 2: Run it to verify the new needles fail**

Run: `REPO_ROOT=$PWD bash tests/test_local_skills.sh`
Expected: FAIL for the five registrations, five table rows, and the fork pin.

- [ ] **Step 3: Register in `scripts/lib.sh`**

```bash
LOCAL_SKILLS=(jira-fu routing-model-tiers cross-checking-claims search-fu
              plain-technical-prose dispatching-parallel-agents
              subagent-driven-development using-git-worktrees
              agentic-manual-testing compound-step codebase-walkthrough
              finishing-a-development-branch systematic-debugging)
```

- [ ] **Step 4: Update the README skill table**

Add rows to "## Skills this repo ships":

```
| `agentic-manual-testing` | Tests pass and a change has a runnable surface: run it as a user would and record the evidence before claiming it works. |
| `compound-step` | A branch or plan finishes: turn rulings, recurring findings, and corrections into small updates to instructions, skills, or memory. |
| `codebase-walkthrough` | A human needs to understand code they did not write: a reading-order walkthrough with real snippets, and an interactive explanation on request. |
| `finishing-a-development-branch` | Implementation is complete: tidy history, size report, PR description contract, compound step, then merge or PR. Forked from Superpowers at commit `b36e082`. |
| `systematic-debugging` | Any bug or unexpected behavior, before proposing a fix. Forked from Superpowers at commit `b36e082`; adds `git bisect` and recovery. |
```

After the sentence "A repository-owned skill therefore replaces an installed skill with the same name.", add: "On Claude Code, Superpowers is a plugin, so a forked skill coexists with `superpowers:<name>`; the rendered instructions name forks without the prefix so the fork is the one loaded."

- [ ] **Step 5: Run the full suite**

Run: `bash tests/run.sh`
Expected: `22/22 test files passed` (16 existing plus the six added by Tasks 2-7).

- [ ] **Step 6: Commit**

```bash
git add scripts/lib.sh README.md tests/test_local_skills.sh
git commit -m "feat: register the new and forked skills"
```

---

## Self-review

Spec coverage: section 1 → Task 2; 2 → Task 3; 3 → Task 4; 4 → Task 5; 5 → Task 6; 6 → Task 9; 7 → Tasks 7, 8; C5 outside SDD → Task 1; 8 → Task 10; 9 → Tasks 2-7 tests, Task 11 registration, Task 1 baseline fix. Fork policy → Tasks 5, 6 README, Task 11 README note. Non-goals: no task creates a role or touches `opencode/openai.json`, `prime/openai.json`, or the OpenAI README tables.

Type consistency: `scripts/test-summary` flag `--log-dir` and separator `--` match between Task 7's script and test and Task 8's SKILL.md sentence. Skill names match across Tasks 2-5, 8, 9, 11. The SDD heading `## Role routing and recovery` is asserted in Task 8 and referenced in Task 1.
