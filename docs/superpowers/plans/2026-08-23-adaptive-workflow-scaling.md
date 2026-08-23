# Adaptive Workflow Scaling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an effective fast path for trivial low-risk changes while preserving bounded and full workflows for higher-risk work.

**Architecture:** `AGENTS.md` remains the single policy source and rendered harness instructions inherit its shared workflow rules. Static shell assertions protect the classification boundary and verify that every harness render retains it; no upstream skill is copied or overridden.

**Tech Stack:** Markdown, Bash shell tests, `just`

**Spec:** `docs/superpowers/specs/2026-08-23-adaptive-workflow-scaling-design.md`

## Global Constraints

- The fast path applies only when every eligibility condition holds.
- The fast path affects at most two files and excludes public APIs, schemas, migrations, dependencies, security, authentication, concurrency, and destructive operations.
- Fast-path work skips brainstorming, written plans, worktrees, subagents, and formal review but retains diff inspection and focused verification.
- Bounded work retains short in-chat brainstorming and approval without design or implementation-plan documents.
- Architectural, unclear, cross-component, and high-risk work retains the full workflow.
- Classification can become heavier during a task but cannot become lighter.
- Do not fork or replace upstream Superpowers skills.
- Do not change model tiers, subagent definitions, or worktree mechanics.

---

### Task 1: Adaptive workflow policy and documentation

**Files:**
- Modify: `AGENTS.md:20-218`
- Modify: `tests/test_agents_md.sh:14-70`
- Modify: `tests/test_render_agents_md.sh:44-53`
- Modify: `README.md:63-79`
- Test: `tests/test_agents_md.sh`
- Test: `tests/test_render_agents_md.sh`

**Interfaces:**
- Consumes: `scripts/lib.sh::render_agents_md`, the existing `assert_contains` and `assert_not_contains` shell helpers, and the provider-specific `AGENTS.md` renderer.
- Produces: the `## Workflow Scaling` instruction contract in every rendered harness file. No programmatic API or shell function signature changes.

- [ ] **Step 1: Load the task-specific craft guidance**

Load `clean-coding` for clear assertion names and focused test clauses. Load `plain-technical-prose` and `de-slop` before editing `AGENTS.md` or `README.md`. Do not add abstractions or helper scripts.

- [ ] **Step 2: Add failing policy assertions**

Insert these assertions after `body=$(cat "$A")` in `tests/test_agents_md.sh`:

```bash
# Workflow classification must make the low-risk path effective rather than
# leaving the unconditional Superpowers precedence in control.
assert_contains "$body" "## Workflow Scaling"     "AGENTS.md defines workflow scaling"
assert_contains "$body" "The change affects at most two files."     "fast path has a file boundary"
assert_contains "$body" "The change is localized and easy to reverse."     "fast path requires reversibility"
assert_contains "$body" "The expected result is clear."     "fast path requires a clear result"
assert_contains "$body" "The change requires no cross-component coordination."     "fast path excludes component coordination"
assert_contains "$body" "One focused command can verify the result."     "fast path requires focused verification"
assert_contains "$body" "public API, schema, migration, dependency, security control, authentication flow, concurrent behavior, or destructive operation"     "fast path names every high-risk exclusion"
assert_contains "$body" 'Do not invoke `brainstorming`, `writing-plans`, worktree management, subagents, or formal review.'     "fast path skips heavy workflow steps"
assert_contains "$body" "Inspect the diff and run focused verification before reporting completion."     "fast path retains completion evidence"
assert_contains "$body" "Classification can become heavier after work starts. It cannot become lighter during the same task."     "workflow upgrades are one-way"
assert_contains "$body" "Workflow classification and the rules for the selected path."     "precedence uses workflow classification"
assert_contains "$body" "Applicable Superpowers workflow skills."     "precedence limits Superpowers to applicable skills"
```

In the existing all-renders loop in `tests/test_render_agents_md.sh`, replace the trailing shared-content assertions with:

```bash
        assert_contains "$body" "## Disagreement"             "$h keeps the shared opening"
        assert_contains "$body" "## Workflow Scaling"             "$h keeps workflow classification"
        assert_contains "$body" "### Precedence"             "$h keeps trailing shared content"
        assert_contains "$body" "Workflow classification and the rules for the selected path."             "$h keeps adaptive precedence"
        assert_contains "$body" "Applicable Superpowers workflow skills."             "$h keeps conditional Superpowers precedence"
```

- [ ] **Step 3: Run focused tests and confirm RED**

Run:

```bash
cd /home/miguelalonsojr/Projects/agentic-swe-setup
REPO_ROOT="$PWD" bash tests/test_agents_md.sh
REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh
```

Expected: both commands exit nonzero. The output names missing `Workflow Scaling` or adaptive-precedence clauses. No failure should come from a shell syntax error.

- [ ] **Step 4: Add the minimum workflow policy to `AGENTS.md`**

Insert this section before `## Coding Discipline`:

```markdown
## Workflow Scaling

Classify implementation work before selecting workflow skills. Use the fast path only when every eligibility condition holds. Use the bounded or full path when any required condition does not hold.

### Fast path

A task uses the fast path only when all of these conditions hold:

- The change affects at most two files.
- The change is localized and easy to reverse.
- The expected result is clear.
- The change requires no cross-component coordination.
- One focused command can verify the result.
- The change does not affect a public API, schema, migration, dependency, security control, authentication flow, concurrent behavior, or destructive operation.

Fast-path work follows these rules:

- Make the change directly and keep the edit surgical.
- Do not invoke `brainstorming`, `writing-plans`, worktree management, subagents, or formal review.
- Do not require a new test for documentation, formatting, or mechanical configuration changes.
- Add or update a focused test for a behavior change when practical.
- Inspect the diff and run focused verification before reporting completion.
- Load a craft skill only when the task needs its specific guidance.

A failure whose root cause is unknown does not qualify for the fast path. Use the bounded path with `systematic-debugging` unless the risk or scope requires the full path.

### Bounded path

Use the bounded path for a localized change to an existing flow when the task fails a fast-path condition but has no architectural or listed high-risk effect.

- Use the short in-chat `brainstorming` flow and obtain approval before implementation.
- Do not write a design document or implementation-plan document.
- Work directly unless isolation or delegation has a concrete benefit.
- Use tests and review in proportion to the change risk.
- Apply the coding discipline and verification rules below.

### Full path

Use the full path for architectural, unclear, cross-component, or high-risk work. Public APIs, schemas, migrations, dependencies, security, authentication, concurrency, and destructive operations are high-risk even when their diffs are small.

The full path retains the Superpowers design, planning, TDD, worktree, delegation, review, and verification workflows.

### Reclassification

Classification can become heavier after work starts. It cannot become lighter during the same task.

If fast-path work expands beyond two files or exposes new risk, stop direct implementation. Explain the new classification and obtain the approval required by the bounded or full path. Preserve existing edits, but do not extend them until approval.

An explicit user request for more process selects the heavier requested path. A request for less process can reduce optional ceremony but cannot remove a safety check required by a high-risk change.
```

Replace the existing `### Precedence` list with:

```markdown
### Precedence

1. Direct user instructions, subject to necessary safety checks.
2. Workflow classification and the rules for the selected path.
3. Applicable Superpowers workflow skills.
4. This file's phase mapping.
5. Advisory craft-skill guidance.

Superpowers workflows remain mandatory when the bounded or full path names them. They are not mandatory when the fast path explicitly excludes them. YAGNI overrides optional abstractions and unrelated work.
```

Do not change the harness-specific routing sections or any skill implementation.

- [ ] **Step 5: Run focused tests and confirm GREEN**

Run:

```bash
cd /home/miguelalonsojr/Projects/agentic-swe-setup
REPO_ROOT="$PWD" bash tests/test_agents_md.sh
REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh
```

Expected: both commands exit 0 without assertion failures.

- [ ] **Step 6: Document the adaptive workflow in `README.md`**

Insert this section before `### Why Prime Agent is different`:

```markdown
### Adaptive workflow

The rendered instructions scale process by change risk. Trivial low-risk changes use a fast path with a surgical edit and focused verification. Localized changes that need more care use a short in-chat approval flow. Architectural, unclear, cross-component, and high-risk changes retain the full design, planning, isolation, delegation, review, and verification workflow.

`AGENTS.md` defines the eligibility rules and precedence. The installer renders the same shared policy for Claude Code, OpenCode, and Prime Agent.
```

Do not copy the eligibility list into `README.md`.

- [ ] **Step 7: Run the complete test suite**

Run:

```bash
cd /home/miguelalonsojr/Projects/agentic-swe-setup
just test
```

Expected: every discovered `tests/test_*.sh` file passes and the final summary reports zero failures.

- [ ] **Step 8: Inspect the final diff and policy wording**

Run:

```bash
cd /home/miguelalonsojr/Projects/agentic-swe-setup
git diff --check
git diff -- AGENTS.md README.md tests/test_agents_md.sh tests/test_render_agents_md.sh
git grep -n "Superpowers workflow skills (process, TDD, verification)" -- AGENTS.md tests || true
```

Expected: `git diff --check` prints nothing. The diff contains only the approved policy, documentation, and static assertions. The final `git grep` prints nothing because the unconditional precedence wording has been removed.

- [ ] **Step 9: Commit the implementation**

```bash
cd /home/miguelalonsojr/Projects/agentic-swe-setup
git add AGENTS.md README.md tests/test_agents_md.sh tests/test_render_agents_md.sh
git commit -m "feat: scale workflow to task risk"
```
