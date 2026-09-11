# Subagent Skill Prose Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended) or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the context cost and reading time of the subagent workflow skills without changing their operational behavior.

**Architecture:** Keep each policy in the skill that owns its decision. Keep child prompts self-contained because workers and reviewers do not inherit the controller context. Preserve contracts through focused shell assertions and a requirement-to-section audit rather than by retaining exact prose.

**Tech Stack:** Markdown skills and prompts, Bash regression tests, Git

**Spec:** `docs/superpowers/specs/2026-09-11-subagent-skill-prose-consolidation-design.md`

## Global Constraints

- Preserve every operational rule, role boundary, threshold, state transition, and report contract.
- Do not add workflow behavior or a pressure-test framework.
- Do not claim improved agent compliance.
- Keep skill descriptions limited to trigger conditions rather than workflow summaries.
- Keep child prompts self-contained even when the controller skill contains a related rule.
- Do not remove a threshold, command contract, dispatch input, report field, state transition, stop condition, or recovery action to meet a word-count target.
- Replace exact-prose test assertions only with assertions that still identify the underlying contract.
- Keep all relative links and referenced scripts valid.
- The selected files must finish below the baseline totals of 10,559 words and 1,236 lines.
- `just test` must pass.
- User ruling: behavioral pressure scenarios are excluded from this pass. Do not create a failing pressure test or claim behavioral validation.

## File Responsibilities

- `skills/routing-model-tiers/SKILL.md`: model-tier selection and harness-specific model discovery and dispatch.
- `skills/cross-checking-claims/SKILL.md`: the gate, independent check, source check, and resolution of load-bearing claims.
- `tests/test_local_skills.sh`: structural contracts for routing and claim verification.
- `skills/dispatching-parallel-agents/SKILL.md`: dependency, collision, namespace, wave, and overlap policy.
- `tests/test_dispatching_parallel_agents_skill.sh`: structural contracts for parallel dispatch.
- `skills/subagent-driven-development/SKILL.md`: controller lifecycle, ledger recovery, role routing, review, integration, and completion.
- `skills/subagent-driven-development/implementer-prompt.md`: task contract for a writing worker.
- `skills/subagent-driven-development/task-reviewer-prompt.md`: first-pass task-review contract.
- `skills/subagent-driven-development/re-review-prompt.md`: scoped fix-review contract.
- `tests/test_subagent_driven_development_skill.sh`: structural contracts for SDD and its prompts.

The file layout remains unchanged. Chapter 13 of *Clean Architecture* calls this Common Closure: instructions and tests that change for the same policy remain together. Simon Brown's Chapter 34 guidance also favors boundaries with a clear contract. The controller policy and child prompts stay separate because they have different consumers.

---

### Task 1: Tighten model routing and claim verification

**Files:**
- Modify: `skills/routing-model-tiers/SKILL.md`
- Modify: `skills/cross-checking-claims/SKILL.md`
- Modify: `tests/test_local_skills.sh`

**Interfaces:**
- Consumes: role ownership and Prime Agent routing data from `AGENTS.md`
- Produces: model choice rules used by all dispatches and the independent-check procedure used before a load-bearing claim changes a decision

- [ ] **Step 1: Load guidance and record the baseline**

Load `clean-coding`, `writing-skills`, `de-slop`, and `plain-technical-prose`. The user excluded pressure tests, so use the shell tests as regression checks only.

Run:

```bash
wc -wl skills/routing-model-tiers/SKILL.md skills/cross-checking-claims/SKILL.md
REPO_ROOT=$PWD bash tests/test_local_skills.sh
```

Expected: record the counts; the test exits 0.

- [ ] **Step 2: Rewrite `routing-model-tiers` around its decisions**

Keep the trigger unchanged unless a shorter trigger-only description preserves the same discovery conditions. Use this order:

1. Policy ownership: parallel dispatch selects access and isolation; SDD selects roles and escalation; this skill selects the model.
2. Access and isolation: uncertain write scope requires read-only exploration; model capability never replaces worktree isolation.
3. Tier selection: retain list versus verdict, the one-pass light-tier floor, and separate enumeration from judgment.
4. Model discovery: retain the exact Prime, Claude, and OpenCode commands and Prime's `limit=20` constraint.
5. Harness dispatch: retain Prime's explicit `name`, `model`, and `thinking` call; inherited-model and thinking-clamp behavior; Claude per-dispatch selection; and OpenCode role-fixed selection.
6. Failure prevention: retain only cases that change the dispatch decision.

Delete the session anecdote, repeated cost rationale, repeated warnings, and duplicate authority statements.

- [ ] **Step 3: Rewrite `cross-checking-claims` around its gate and evidence**

Use this order:

1. Gate: ask whether a different answer changes what gets built, bought, or skipped.
2. Independent check: dispatch `cross-checker` on a different model line and send the question without the prior answer.
3. Source check: verify against the artifact itself; define acceptable and unacceptable sources.
4. Resolution: settle disagreement at the source, do not average verdicts, and mark unresolved claims unconfirmed where used.
5. Boundary: distinguish external factual claims from completion claims handled by `verification-before-completion`.

Remove the historical session narrative, named repository and paper anecdotes, duplicate explanations of correlated errors, and repeated statements that agreement is not evidence. Preserve the rule for a result already produced by the configured cross-checker model.

- [ ] **Step 4: Replace prose-bound assertions with contract assertions**

In `tests/test_local_skills.sh`, retain checks for model discovery, Prime dispatch parameters, thinking inheritance, access and isolation, uncertain-write exploration, the one-pass floor, list-versus-verdict routing, SDD role ownership, the load-bearing gate, the `cross-checker` role, question-without-answer anchoring, different-model dispatch, primary sources, disagreement resolution, unconfirmed results, and the boundary with completion verification.

Remove assertions for deleted anecdotes such as `dual-licensed`. Use unique clauses or command strings rather than isolated keywords.

- [ ] **Step 5: Verify and commit**

Run:

```bash
REPO_ROOT=$PWD bash tests/test_local_skills.sh
wc -wl skills/routing-model-tiers/SKILL.md skills/cross-checking-claims/SKILL.md
git diff --check
git diff -- skills/routing-model-tiers/SKILL.md skills/cross-checking-claims/SKILL.md tests/test_local_skills.sh
```

Expected: the test exits 0; both skills are shorter; the listed contracts remain.

Commit:

```bash
git add skills/routing-model-tiers/SKILL.md skills/cross-checking-claims/SKILL.md tests/test_local_skills.sh
git commit -m "docs: tighten subagent routing skills"
```

---

### Task 2: Tighten parallel dispatch policy

**Files:**
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `tests/test_dispatching_parallel_agents_skill.sh`

**Interfaces:**
- Consumes: the complete task list from a plan or controller
- Produces: task inventory, namespace rulings, collision graph, and largest safe wave for SDD

- [ ] **Step 1: Load guidance and record the baseline**

Load `clean-coding`, `writing-skills`, `de-slop`, and `plain-technical-prose`.

Run:

```bash
wc -wl skills/dispatching-parallel-agents/SKILL.md
REPO_ROOT=$PWD bash tests/test_dispatching_parallel_agents_skill.sh
```

Expected: record the count; the test exits 0.

- [ ] **Step 2: Rewrite the skill as one ordered policy**

Use these sections:

1. Task inventory: one row per task with dependencies, access mode, files, interfaces, generated artifacts, lockfiles, migrations, configuration, external resources, namespaces, edges, and rulings.
2. Collision rules: different files do not prove independence; record shared producers and consumers.
3. Namespace rules: only a controller-assigned, unique, explicit, testable namespace can remove an external-resource edge; repository-state edges remain.
4. Wave selection: preserve the six-step order, stable read-only inputs, one worktree per concurrent writer, sequential writers when worktrees are unavailable, and exploration for uncertain write scope.
5. Dispatch and integration: specify prompt fields and the response to unexpected overlap.

Remove the purpose restatement and repeated inventory and isolation paragraphs. Use one imperative for each rule.

- [ ] **Step 3: Keep structural assertions independent of wording**

Update `tests/test_dispatching_parallel_agents_skill.sh` only where wording changed. Retain assertions for every inventory field, dependency satisfaction, access classification, interface and shared-state collisions, namespace qualifications, controller-created worktrees, largest safe wave, uncertain-write exploration, and overlap handling.

- [ ] **Step 4: Verify and commit**

Run:

```bash
REPO_ROOT=$PWD bash tests/test_dispatching_parallel_agents_skill.sh
wc -wl skills/dispatching-parallel-agents/SKILL.md
git diff --check
git diff -- skills/dispatching-parallel-agents/SKILL.md tests/test_dispatching_parallel_agents_skill.sh
```

Expected: the test exits 0; the skill is shorter; its output and safety contracts remain.

Commit:

```bash
git add skills/dispatching-parallel-agents/SKILL.md tests/test_dispatching_parallel_agents_skill.sh
git commit -m "docs: tighten parallel dispatch policy"
```

---

### Task 3: Consolidate the SDD controller workflow

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `tests/test_subagent_driven_development_skill.sh`

**Interfaces:**
- Consumes: approved plan, safe-wave inventory, verified worktrees, model routing, task briefs, worker reports, and review packages
- Produces: reviewed commits integrated in dependency order, a recoverable ledger, verified waves, a final branch review, and explicit completion or escalation

- [ ] **Step 1: Load guidance and record the baseline**

Load `clean-coding`, `writing-skills`, `de-slop`, and `plain-technical-prose`.

Run:

```bash
wc -wl skills/subagent-driven-development/SKILL.md
REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh
```

Expected: record the count; the test exits 0.

- [ ] **Step 2: Build a preservation checklist from the current skill**

Before rewriting, list each imperative in the worker report under:

- required sub-skills and authority boundaries
- stop conditions and rulings
- workspace and ledger identity
- contradiction scan and plan needles
- role routing and status handling
- ledger states and restart actions
- wave setup and writer isolation
- brief, baseline, report, and review-package inputs
- task review and fix-loop thresholds
- scope checks, cherry-pick order, and verification
- final review, final fix limit, compound step, and cleanup

Use `git show HEAD:skills/subagent-driven-development/SKILL.md` as the source. The checklist is review evidence, not a tracked file.

- [ ] **Step 3: Rewrite the controller skill in execution order**

Keep the trigger. Use this order:

1. Preconditions and required policy skills.
2. Stop conditions and ruling format.
3. Workspace, ledger, plan, spec, and contradiction scan.
4. Role routing and ledger state table.
5. Restart reconciliation.
6. Safe-wave execution.
7. Implementer report statuses.
8. Task review.
9. Five-round fix loop.
10. Approval and integration.
11. Final review and single final fix.
12. Completion, compound step, cleanup, and branch finishing.

Keep commands, paths, state names, terminal records, review-package range rules, baseline failure details, thresholds, no-nested-dispatch rules, and prompt links.

Consolidate repeated rules into their execution section. State worktree isolation once in setup. State complete-range review and the ban on `HEAD~1` once in review packaging. Replace repeated recovery prose with one state-to-action table. Keep rationale only when it prevents a wrong action. Remove the large DOT diagram, repeated overview and continuity prose, and the rationalization table after preserving the direct rules.

- [ ] **Step 4: Update SDD structural assertions**

Adjust `tests/test_subagent_driven_development_skill.sh` for revised wording. Preserve checks for required sub-skills, authority boundaries, inventory fields, controller ownership, every ledger state, restart behavior, complete commit-range review, scope comparison, cherry-pick integration, focused and wave tests, five-round escalation, final review strength, one final fix dispatch, compound step, cleanup order, rulings, contradiction checks, baseline failure reporting, and prompt links.

Replace the assertion on the worked-example sentence with direct assertions on the ordered integration rules. Do not weaken a multi-clause rule to a single keyword.

- [ ] **Step 5: Compare the rewrite with the preservation checklist**

For every checklist entry from Step 2, cite the revised heading or line range that carries it. Restore missing rules. Record intentional removals only for explanations, anecdotes, diagrams, or duplicated prose that do not change an action.

- [ ] **Step 6: Verify and commit**

Run:

```bash
REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh
wc -wl skills/subagent-driven-development/SKILL.md
git diff --check
git diff -- skills/subagent-driven-development/SKILL.md tests/test_subagent_driven_development_skill.sh
```

Expected: the test exits 0; the skill is shorter; every checklist item maps to the revision.

Commit:

```bash
git add skills/subagent-driven-development/SKILL.md tests/test_subagent_driven_development_skill.sh
git commit -m "docs: consolidate subagent development workflow"
```

---

### Task 4: Tighten SDD child prompts and verify the stack

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Modify: `skills/subagent-driven-development/re-review-prompt.md`
- Modify: `tests/test_subagent_driven_development_skill.sh`

**Interfaces:**
- Consumes: controller-supplied brief, worktree, report, constraints, findings, SHAs, and diff-package paths
- Produces: implementer status and report; first-pass spec and quality verdicts; scoped finding verdicts after fixes

- [ ] **Step 1: Load guidance and record the baseline**

Load `clean-coding`, `writing-skills`, `de-slop`, and `plain-technical-prose`.

Run:

```bash
wc -wl skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/task-reviewer-prompt.md skills/subagent-driven-development/re-review-prompt.md
REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh
```

Expected: record the counts; the test exits 0.

- [ ] **Step 2: Tighten the implementer prompt without making it context-dependent**

Keep the task, brief, context, worktree, report, access limits, early questions, escalation conditions, exact scope, TDD, test cadence, manual testing, commit, self-review, Git restrictions, no nested dispatch, fix-report behavior, report fields, four statuses, and under-15-line response contract.

Merge repeated question and escalation prose. Replace the long self-review questionnaire with a compact checklist covering completeness, scope, naming, maintainability, test intent, edge cases, and clean output. Keep the full file report separate from the short reply.

- [ ] **Step 3: Tighten the task-reviewer prompt**

Keep the brief, global constraints, report, base, head, diff path, read-only rule, no nested dispatch, diff-first review, narrowly justified external inspection, complete range, blocking out-of-scope changes, distrust of claims, test evidence, focused-test exception, separate spec and quality review, warning verdict, documentation check, file-line evidence, severity calibration, plan-mandated defects, output headings, and task-quality verdict.

Remove repeated explanations about context lines, review seats, report optimism, and test reruns after preserving each direct instruction once.

- [ ] **Step 4: Tighten the scoped re-review prompt**

Keep the brief, findings, report, fix base, head, diff path, read-only rule, no nested dispatch, one verdict per finding, fix-diff scope, new-breakage severity, non-blocking outside observations, covering-test evidence, focused-test exception, and exact final verdict.

Remove explanations already implied by the direct scope and verdict rules.

- [ ] **Step 5: Strengthen prompt contract assertions**

Update `tests/test_subagent_driven_development_skill.sh` to assert each prompt's required inputs, write restrictions, no-nested-dispatch rule, test evidence, report or verdict fields, and output statuses. Use unique contract clauses rather than headings alone.

- [ ] **Step 6: Run complete verification**

Run:

```bash
REPO_ROOT=$PWD bash tests/test_local_skills.sh
REPO_ROOT=$PWD bash tests/test_dispatching_parallel_agents_skill.sh
REPO_ROOT=$PWD bash tests/test_subagent_driven_development_skill.sh
find skills/routing-model-tiers skills/dispatching-parallel-agents skills/subagent-driven-development skills/cross-checking-claims -type f -name '*.md' -print0 | xargs -0 grep -nE 'TBD|TODO|fill in details|implement later'
wc -wl   skills/routing-model-tiers/SKILL.md   skills/dispatching-parallel-agents/SKILL.md   skills/subagent-driven-development/SKILL.md   skills/subagent-driven-development/implementer-prompt.md   skills/subagent-driven-development/task-reviewer-prompt.md   skills/subagent-driven-development/re-review-prompt.md   skills/cross-checking-claims/SKILL.md
just test
git diff --check
```

Expected: focused tests exit 0; the placeholder scan prints no matches; combined totals are below 10,559 words and 1,236 lines; `just test` reports `22/22 test files passed`; `git diff --check` exits 0.

- [ ] **Step 7: Audit and commit**

Compare the stack against the spec. Confirm that each skill owns one policy, child prompts remain self-contained, relative links resolve, and completion text does not claim improved compliance.

Commit:

```bash
git add   skills/subagent-driven-development/implementer-prompt.md   skills/subagent-driven-development/task-reviewer-prompt.md   skills/subagent-driven-development/re-review-prompt.md   tests/test_subagent_driven_development_skill.sh
git commit -m "docs: tighten subagent worker prompts"
```
