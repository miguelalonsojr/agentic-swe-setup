# Controller-Managed Subagent Worktrees Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install repository-owned dispatch skills that use the largest safe subagent wave while isolating every concurrent writer in a controller-managed worktree.

**Architecture:** Each skill directory owns one policy boundary and its contract test. The shared installer registry links repository-owned skills after Superpowers and `agentic-swe-skills`, so matching names resolve to this repository while unrelated shared skills remain installed.

**Tech Stack:** Markdown skills, Bash installers, Git worktrees, shell contract tests

**Spec:** `docs/superpowers/specs/2026-08-22-controller-managed-subagent-worktrees-design.md`

## Global Constraints

- The repository owns `subagent-driven-development`, `dispatching-parallel-agents`, `routing-model-tiers`, and `using-git-worktrees`.
- Concurrent write-capable agents never share a worktree.
- The controller creates, records, integrates, and removes worker worktrees.
- Read-only agents can run concurrently in a stable worktree.
- A safe wave has satisfied dependencies and no unresolved file, interface, generated-artifact, or external-resource collision.
- Every implementation task uses TDD, task-scoped review, actual-diff validation, focused tests, and full-suite verification.
- Worker agents do not merge, rebase, cherry-pick, create worktrees, remove worktrees, or dispatch nested agents.
- Repository-owned skills link after Superpowers and `agentic-swe-skills` and override matching names only.
- Non-overlapping `agentic-swe-skills` entries keep their current installation behavior.
- Match the existing shell and Markdown style. Do not refactor unrelated installer or test code.

## File map

- `skills/dispatching-parallel-agents/`: dependency, collision, access-mode, and safe-wave policy.
- `skills/using-git-worktrees/`: controller and worker worktree lifecycle policy.
- `skills/subagent-driven-development/`: wave orchestration, worker prompts, review, ledger, and integration policy.
- `skills/routing-model-tiers/`: per-dispatch model selection that remains independent from isolation.
- `tests/test_*_skill.sh`: one contract test per newly imported skill component.
- `tests/test_local_skills.sh`: existing routing contract and generic local-skill lifecycle checks.
- `tests/lib/sandbox.sh`: fake shared skill trees, including intentional name collisions.
- `tests/test_install.sh`: Claude Code and OpenCode precedence checks.
- `tests/test_install_prime.sh`: Prime Agent precedence checks across Superpowers, `agentic-swe-skills`, and local skills.
- `scripts/lib.sh`: authoritative `LOCAL_SKILLS` registry consumed by install, doctor, update, and uninstall.
- `README.md`: human-facing list of repository-owned skills and precedence rule.

## Controller pressure-test preflight

The controller performs this preflight before Task 1. These are read-only subagent dispatches, not implementation tasks.

- [ ] Load `routing-model-tiers`, `dispatching-parallel-agents`, and `writing-skills`.
- [ ] Dispatch fresh read-only agents concurrently against the current installed skills with these scenarios:
  1. Two independent writers touch disjoint files and one read-only agent inspects documentation. Ask for the dispatch wave, worktree placement, and integration order.
  2. Two writers touch different files but change and consume the same public interface. Ask whether they can run in one wave and why.
  3. Two writers touch different source files but both update one lockfile and use one unnamespaced test database. The same collision rule applies to shared generated artifacts, migrations, and configuration. Ask for the collision decision.
  4. A writer returns a commit containing one declared file and one undeclared file. Ask for the integration decision.
- [ ] Tell every pressure-test agent to report findings only and make no edits.
- [ ] Record the exact unsafe action or rationalization from each result in the plan workspace as `pressure-red.md`.
- [ ] Confirm at least one current response either serializes independent writers unconditionally or permits concurrent writers without controller-created worktrees. If none does, record the already-correct behavior and retain the regression scenarios.

---

### Task 1: Parallel dispatch policy

**Files:**
- Create: `skills/dispatching-parallel-agents/SKILL.md`
- Create: `skills/dispatching-parallel-agents/README.md`
- Create: `tests/test_dispatching_parallel_agents_skill.sh`

**Interfaces:**
- Consumes: the task, dependency, collision, access-mode, and safe-wave terms from the approved spec.
- Produces: the safe-wave decision used by `subagent-driven-development`; the requirement that every concurrent writer receives a controller-created worktree.

- [ ] **Step 1: Load the craft and process skills**

Load `writing-skills`, `clean-coding`, and `plain-technical-prose`. Apply `writing-skills` RED-GREEN-REFACTOR to the skill contract. Apply prose rules during the refactor step.

- [ ] **Step 2: Write the failing contract test**

Create `tests/test_dispatching_parallel_agents_skill.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skill="$REPO_ROOT/skills/dispatching-parallel-agents/SKILL.md"
assert_file "$skill" "dispatching-parallel-agents has a SKILL.md"
body=$(cat "$skill")
assert_contains "$body" 'Classify every task as `read-only` or `write-capable`' \
    "parallel skill classifies access mode"
assert_contains "$body" "A different file does not prove independence" \
    "parallel skill checks interfaces and shared state"
assert_contains "$body" "Dispatch the largest safe wave" \
    "parallel skill maximizes safe concurrency"
assert_contains "$body" "controller-created worktree" \
    "parallel skill isolates every concurrent writer"
assert_contains "$body" "lockfiles, generated artifacts, migrations, and configuration" \
    "parallel skill checks generated shared state"
assert_contains "$body" "ports, databases, services, and test fixtures" \
    "parallel skill checks external shared state"
assert_contains "$body" "Unexpected overlap" \
    "parallel skill stops unsafe integration"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 3: Run the contract test and verify RED**

Run: `REPO_ROOT="$PWD" bash tests/test_dispatching_parallel_agents_skill.sh`

Expected: FAIL because `skills/dispatching-parallel-agents/SKILL.md` does not exist.

- [ ] **Step 4: Import and rewrite the skill**

Copy the installed upstream skill as the starting point:

```bash
cp -aL "$HOME/.superpowers/skills/dispatching-parallel-agents" skills/
```

Rewrite `SKILL.md` around this decision order:

```text
1. Map dependencies.
2. Classify every task as read-only or write-capable.
3. Map file, interface, generated-artifact, and external-resource collisions.
4. Namespace external resources when the namespace is explicit and testable.
5. Dispatch the largest safe wave.
6. Run read-only tasks in a stable worktree.
7. Give every concurrent writer a controller-created worktree.
8. Review actual diffs and integrate approved commits sequentially.
```

The skill must state these rules without qualification:

```text
A different file does not prove independence. Two tasks collide when one changes an interface, generated artifact, migration, lockfile, configuration, or external resource that the other consumes.

Never dispatch concurrent write-capable agents into one worktree. If isolated worktrees are unavailable, keep writers sequential and continue to parallelize read-only work.

Unexpected overlap stops integration of the affected tasks. Preserve both worker branches, update the collision map, and rerun or revise the later task against the integrated state.
```

Keep focused prompts, output contracts, full-suite verification, and the rule that shared-state tasks run sequentially. Remove the example that implies disjoint test files alone prove safe parallel writes.

Create `README.md` that names the upstream source, the local override, the access modes, and the relationship to `using-git-worktrees` and `subagent-driven-development`.

- [ ] **Step 5: Run the skill test and full suite**

Run: `REPO_ROOT="$PWD" bash tests/test_dispatching_parallel_agents_skill.sh`

Expected: PASS.

Run: `just test`

Expected: all test files pass.

- [ ] **Step 6: Commit**

```bash
git add skills/dispatching-parallel-agents tests/test_dispatching_parallel_agents_skill.sh
git commit -m "feat: define safe parallel subagent waves"
```

---

### Task 2: Controller-managed worktree policy

**Files:**
- Create: `skills/using-git-worktrees/SKILL.md`
- Create: `skills/using-git-worktrees/README.md`
- Create: `tests/test_using_git_worktrees_skill.sh`

**Interfaces:**
- Consumes: a task ID, slug, recorded base commit, and access mode from the controller.
- Produces: a validated worker path and branch based at the requested commit; safe cleanup rules used after integration or abandonment.

- [ ] **Step 1: Load the craft and process skills**

Load `writing-skills`, `clean-coding`, and `plain-technical-prose`. Apply `writing-skills` RED-GREEN-REFACTOR to the skill contract.

- [ ] **Step 2: Write the failing contract test**

Create `tests/test_using_git_worktrees_skill.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skill="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
assert_file "$skill" "using-git-worktrees has a SKILL.md"
body=$(cat "$skill")
assert_contains "$body" "The controller creates and removes worker worktrees" \
    "worktree skill assigns lifecycle ownership"
assert_contains "$body" "Create worker worktrees sequentially before dispatching the wave" \
    "worktree skill avoids Git metadata lock races"
assert_contains "$body" 'git worktree add "$path" -b "$branch" "$base"' \
    "worktree skill creates from the recorded base"
assert_contains "$body" 'git -C "$path" rev-parse HEAD' \
    "worktree skill verifies the worker base"
assert_contains "$body" "Workers must not create, remove, merge, rebase, or cherry-pick" \
    "worktree skill limits worker Git authority"
assert_contains "$body" 'git -C "$path" status --porcelain' \
    "worktree skill checks dirty state before cleanup"
assert_contains "$body" "explicitly abandoned" \
    "worktree skill guards destructive cleanup"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 3: Run the contract test and verify RED**

Run: `REPO_ROOT="$PWD" bash tests/test_using_git_worktrees_skill.sh`

Expected: FAIL because `skills/using-git-worktrees/SKILL.md` does not exist.

- [ ] **Step 4: Import and extend the skill**

Copy the installed upstream skill:

```bash
cp -aL "$HOME/.superpowers/skills/using-git-worktrees" skills/
```

Retain controller-worktree detection, native-tool preference, ignore checks, setup, and clean-baseline verification. Add a worker-worktree section with this ownership rule and command sequence:

```text
The controller creates and removes worker worktrees. Workers only use the path in their dispatch brief.

Create worker worktrees sequentially before dispatching the wave. Concurrent `git worktree add` commands can contend on shared Git metadata.
```

```bash
base=$(git rev-parse HEAD)
main_worktree=$(git worktree list --porcelain | awk '$1 == "worktree" {print $2; exit}')
path="$main_worktree/.worktrees/$plan_slug/task-$task_id-$task_slug"
branch="sdd/$plan_slug/task-$task_id-$task_slug"
git worktree add "$path" -b "$branch" "$base"
test "$(git -C "$path" rev-parse HEAD)" = "$base"
```

Require the controller to record `path`, `branch`, `base`, and task ownership before dispatch. Require worker branches to start from the integration HEAD recorded for that wave.

Add this worker restriction:

```text
Workers must not create, remove, merge, rebase, or cherry-pick worktrees or branches. A worker commits only its task changes on the supplied branch.
```

Add cleanup checks using:

```bash
git -C "$path" status --porcelain
git worktree remove "$path"
git branch -D "$branch"
```

A dirty worktree must not be force-removed. Verify the expected path and branch before removal. Delete the branch with `git branch -D` only after the ledger records its integration commit or an explicit abandonment ruling, because a cherry-picked worker commit is not an ancestor of the integration branch.

Create `README.md` that distinguishes the controller worktree from per-writer worktrees and states that local links override the upstream skill.

- [ ] **Step 5: Run the skill test and full suite**

Run: `REPO_ROOT="$PWD" bash tests/test_using_git_worktrees_skill.sh`

Expected: PASS.

Run: `just test`

Expected: all test files pass.

- [ ] **Step 6: Commit**

```bash
git add skills/using-git-worktrees tests/test_using_git_worktrees_skill.sh
git commit -m "feat: define controller-managed worker worktrees"
```

---

### Task 3: Wave-based subagent-driven development

**Files:**
- Create: `skills/subagent-driven-development/SKILL.md`
- Create: `skills/subagent-driven-development/README.md`
- Create: `skills/subagent-driven-development/implementer-prompt.md`
- Create: `skills/subagent-driven-development/task-reviewer-prompt.md`
- Create: `skills/subagent-driven-development/re-review-prompt.md`
- Create: `skills/subagent-driven-development/scripts/review-package`
- Create: `skills/subagent-driven-development/scripts/sdd-workspace`
- Create: `skills/subagent-driven-development/scripts/task-brief`
- Create: `tests/test_subagent_driven_development_skill.sh`

**Interfaces:**
- Consumes: the safe-wave decision from `dispatching-parallel-agents` and worker paths from `using-git-worktrees`.
- Produces: reviewed worker commits integrated one at a time into the controller branch; a ledger that supports recovery after compaction.

- [ ] **Step 1: Load the craft and process skills**

Load `writing-skills`, `clean-coding`, and `plain-technical-prose`. Preserve the existing review and escalation behavior unless the approved design changes it.

- [ ] **Step 2: Write the failing contract test**

Create `tests/test_subagent_driven_development_skill.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/subagent-driven-development"
assert_file "$root/SKILL.md" "subagent-driven-development has a SKILL.md"
assert_file "$root/implementer-prompt.md" "implementer prompt is present"
assert_file "$root/task-reviewer-prompt.md" "task reviewer prompt is present"
assert_file "$root/re-review-prompt.md" "re-review prompt is present"
for script in review-package sdd-workspace task-brief; do
    assert_file "$root/scripts/$script" "SDD script $script is present"
    [ -x "$root/scripts/$script" ] || fail "SDD script $script is executable"
done
body=$(cat "$root/SKILL.md")
assert_contains "$body" "Build the dependency and collision graph" \
    "SDD skill plans safe waves"
assert_contains "$body" "Dispatch every task in the largest safe wave" \
    "SDD skill maximizes safe delegation"
assert_contains "$body" "Never implement an eligible task in the controller" \
    "SDD controller delegates implementation"
assert_contains "$body" "Review each worker commit before integration" \
    "SDD skill keeps the task review gate"
assert_contains "$body" 'git diff --name-only "$base" "$commit"' \
    "SDD skill validates actual scope"
assert_contains "$body" 'git cherry-pick "$commit"' \
    "SDD skill integrates commits rather than copying files"
assert_contains "$body" "focused tests after each integrated commit" \
    "SDD skill verifies incremental integration"
assert_contains "$body" "full suite after each wave" \
    "SDD skill verifies combined behavior"
assert_contains "$body" "worker worktree" \
    "SDD ledger records worker isolation"
implementer=$(cat "$root/implementer-prompt.md")
assert_contains "$implementer" "Do not merge, rebase, cherry-pick, or create or remove worktrees" \
    "implementer prompt limits Git authority"
assert_contains "$implementer" "actual files changed" \
    "implementer reports its real scope"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 3: Run the contract test and verify RED**

Run: `REPO_ROOT="$PWD" bash tests/test_subagent_driven_development_skill.sh`

Expected: FAIL because the local skill directory does not exist.

- [ ] **Step 4: Import the complete upstream component**

Copy all prompts and scripts, preserving executable bits:

```bash
cp -aL "$HOME/.superpowers/skills/subagent-driven-development" skills/
```

Create `skills/subagent-driven-development/README.md` separately. Do not replace or omit the copied prompt and script files.

- [ ] **Step 5: Replace the single-writer loop with safe waves**

Keep the existing ledger, brief, report, review-package, fix-loop, final-review, and escalation mechanics. Replace the unconditional rule `Never dispatch multiple implementation subagents in parallel` with this sequence:

```text
1. Build the dependency and collision graph from every plan task.
2. Dispatch every task in the largest safe wave.
3. Create and record one worker worktree for each write-capable task before dispatch.
4. Run each task's implementation, fix loop, and task review in its worker worktree.
5. Review each worker commit before integration.
6. Compare the actual diff with the declared scope.
7. Cherry-pick approved commits into the controller branch one at a time in dependency order.
8. Run focused tests after each integrated commit and the full suite after each wave.
9. Recompute the graph and dispatch the next wave.
```

Add these exact controller rules:

```text
Never implement an eligible task in the controller. The controller owns planning, dispatch, review coordination, integration, verification, and recovery.

Review each worker commit before integration. Use `git diff --name-only "$base" "$commit"` to compare the actual files with the declared scope. Integrate an approved commit with `git cherry-pick "$commit"`.
```

The ledger must record each task's dependencies, collision edges, access mode, worktree, branch, base, worker identity, report, commit, review status, integration commit, and cleanup state.

An unexpected overlap freezes only the affected integrations. Preserve the worker branches, integrate the selected first task, and revise or rerun the later task against the new integration HEAD.

- [ ] **Step 6: Update the worker and reviewer prompts**

The implementer prompt must require the supplied worktree path, TDD, task-only commits, actual files changed, and the existing status/report contract. Add:

```text
Do not merge, rebase, cherry-pick, or create or remove worktrees. Do not dispatch subagents. Work only in the supplied worker worktree and commit only this task's changes.
```

The task reviewer remains read-only. It reviews the worker commit before integration and reports out-of-scope changes as blocking findings. The re-review prompt remains scoped to the fix diff.

Create `README.md` that explains the local override, safe waves, per-writer worktrees, task review, sequential commit integration, and final review.

- [ ] **Step 7: Run the skill test and full suite**

Run: `REPO_ROOT="$PWD" bash tests/test_subagent_driven_development_skill.sh`

Expected: PASS.

Run: `just test`

Expected: all test files pass.

- [ ] **Step 8: Commit**

```bash
git add skills/subagent-driven-development tests/test_subagent_driven_development_skill.sh
git commit -m "feat: execute implementation tasks in isolated waves"
```

---

### Task 4: Isolation-aware model routing

**Files:**
- Modify: `skills/routing-model-tiers/SKILL.md`
- Modify: `skills/routing-model-tiers/README.md`
- Modify: `tests/test_local_skills.sh`

**Interfaces:**
- Consumes: a task output, role, complexity, risk, and access mode.
- Produces: one explicit model choice per dispatch. It does not alter the safe-wave or worktree decision.

- [ ] **Step 1: Load the craft and process skills**

Load `writing-skills`, `clean-coding`, and `plain-technical-prose`. Preserve the existing model-menu, list-versus-verdict, harness mechanics, and Prime Agent assertions.

- [ ] **Step 2: Extend the failing routing contract**

Add these assertions beside the existing routing assertions in `tests/test_local_skills.sh`:

```bash
assert_contains "$routing" "Choose access mode and isolation before model tier" \
    "routing skill keeps isolation ahead of model choice"
assert_contains "$routing" "Model choice does not change isolation requirements" \
    "routing skill cannot buy out of a worktree"
assert_contains "$routing" "read-only exploration dispatch" \
    "routing skill uses exploration before uncertain writes"
assert_contains "$routing" "largest safe wave" \
    "routing skill points dispatch volume to the parallel policy"
```

- [ ] **Step 3: Run the contract test and verify RED**

Run: `REPO_ROOT="$PWD" bash tests/test_local_skills.sh`

Expected: FAIL on the first new routing assertion.

- [ ] **Step 4: Add the isolation boundary**

Add a concise section after `## The Routing Test`:

```markdown
## Access mode and isolation

Choose access mode and isolation before model tier. Use `dispatching-parallel-agents` to build the largest safe wave and `using-git-worktrees` to isolate write-capable workers.

Model choice does not change isolation requirements. A stronger model does not make shared writes safe, and a light model still needs a worker worktree when it can edit.

When write scope is uncertain, use a read-only exploration dispatch first. Update the dependency and collision map before routing the implementation task.
```

Update `README.md` so its Related section names the local `dispatching-parallel-agents`, `using-git-worktrees`, and `subagent-driven-development` skills.

- [ ] **Step 5: Run the routing test and full suite**

Run: `REPO_ROOT="$PWD" bash tests/test_local_skills.sh`

Expected: PASS.

Run: `just test`

Expected: all test files pass.

- [ ] **Step 6: Commit**

```bash
git add skills/routing-model-tiers tests/test_local_skills.sh
git commit -m "docs: separate model routing from worker isolation"
```

---

### Task 5: Installer precedence and repository documentation

**Files:**
- Modify: `scripts/lib.sh`
- Modify: `tests/lib/sandbox.sh`
- Modify: `tests/test_install.sh`
- Modify: `tests/test_install_prime.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: the four complete skill directories from Tasks 1 through 4.
- Produces: authoritative local links in Claude Code, OpenCode, and Prime Agent after shared skill installation; unrelated shared links remain intact.

- [ ] **Step 1: Load the craft and process skills**

Load `clean-coding` and `plain-technical-prose`. Use shell TDD. Keep precedence in the existing central registry and link order rather than adding per-skill installer branches.

- [ ] **Step 2: Make the fake shared checkout contain collisions**

In `stub_swe_skills` in `tests/lib/sandbox.sh`, create stub entries for:

```bash
local s
for s in de-slop dispatching-parallel-agents routing-model-tiers \
         subagent-driven-development using-git-worktrees; do
    mkdir -p "$SWE_SKILLS_DIR/skills/$s"
    printf -- '---\nname: %s\ndescription: shared stub\n---\n' "$s" \
        > "$SWE_SKILLS_DIR/skills/$s/SKILL.md"
done
```

Keep `book-skills/clean-coding` and the existing generic install loop. The fake checkout now represents one unrelated skill and all four name collisions.

- [ ] **Step 3: Add failing Claude Code and OpenCode precedence assertions**

After each harness install in `tests/test_install.sh`, add:

```bash
for s in dispatching-parallel-agents routing-model-tiers \
         subagent-driven-development using-git-worktrees; do
    assert_symlink_to "$(claude_dir)/skills/$s" \
        "$REPO_ROOT/skills/$s" "local skill $s overrides shared skill for claude"
done
assert_symlink_to "$(claude_dir)/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "non-overlapping claude skill remains shared"
```

Use the same loop with `$(opencode_dir)` after OpenCode installation. After the second Claude install, assert `subagent-driven-development` still resolves to `$REPO_ROOT/skills/subagent-driven-development`.

- [ ] **Step 4: Add failing Prime Agent precedence assertions**

In the Prime skill assertions in `tests/test_install_prime.sh`, add:

```bash
for s in dispatching-parallel-agents routing-model-tiers \
         subagent-driven-development using-git-worktrees; do
    assert_symlink_to "$PDIR/skills/$s" \
        "$REPO_ROOT/skills/$s" "local skill $s overrides shared skills for Prime"
done
assert_symlink_to "$PDIR/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "non-overlapping Prime skill remains shared"
```

This specifically proves that the local `subagent-driven-development` replaces the Superpowers copy linked earlier and that all shared-name collisions resolve locally.

- [ ] **Step 5: Run installer tests and verify RED**

Run: `REPO_ROOT="$PWD" bash tests/test_install.sh`

Expected: FAIL because the three newly imported skills are not in `LOCAL_SKILLS` and therefore do not replace the shared stubs.

Run: `REPO_ROOT="$PWD" bash tests/test_install_prime.sh`

Expected: FAIL for the same precedence reason.

- [ ] **Step 6: Register all four local skills**

Update the existing `LOCAL_SKILLS` array in `scripts/lib.sh` to contain each name exactly once:

```bash
LOCAL_SKILLS=(jira-fu routing-model-tiers cross-checking-claims search-fu
              plain-technical-prose dispatching-parallel-agents
              subagent-driven-development using-git-worktrees)
```

Do not change the installer order. Claude Code and OpenCode already run `agentic-swe-skills` before `link_local_skills`. Prime Agent already links Superpowers and `agentic-swe-skills` before `link_local_skills`.

- [ ] **Step 7: Document ownership and precedence**

Add the three new names to the local-skills table in `README.md`. Update the `routing-model-tiers` row to mention per-dispatch model selection only. Add this paragraph after the table:

```markdown
Repository-owned skills link after Superpowers and `agentic-swe-skills`. A repository-owned skill therefore replaces an installed skill with the same name. Skills with other names remain linked from their shared checkout.
```

- [ ] **Step 8: Run focused lifecycle and precedence tests**

Run:

```bash
REPO_ROOT="$PWD" bash tests/test_install.sh
REPO_ROOT="$PWD" bash tests/test_install_prime.sh
REPO_ROOT="$PWD" bash tests/test_local_skills.sh
REPO_ROOT="$PWD" bash tests/test_doctor.sh
REPO_ROOT="$PWD" bash tests/test_uninstall.sh
REPO_ROOT="$PWD" bash tests/test_readme.sh
```

Expected: all selected test files pass. The generic `LOCAL_SKILLS` loops verify directory structure, `install-skills.sh`, doctor, idempotency, and uninstall for the newly registered names.

- [ ] **Step 9: Run the full suite**

Run: `just test`

Expected: all test files pass with no warnings or failures.

- [ ] **Step 10: Commit**

```bash
git add scripts/lib.sh tests/lib/sandbox.sh tests/test_install.sh \
    tests/test_install_prime.sh README.md
git commit -m "feat: install local dispatch skills with precedence"
```

---

## Controller pressure-test GREEN gate

The controller performs this gate after Task 5 and before the final whole-branch review.

- [ ] Load the repository-owned `routing-model-tiers`, `dispatching-parallel-agents`, `using-git-worktrees`, and `subagent-driven-development` skills.
- [ ] Dispatch fresh read-only agents against the same four preflight scenarios. Tell them to report findings only and make no edits.
- [ ] Require the independent-writer scenario to produce one safe wave with a separate controller-created worktree per writer and concurrent read-only work.
- [ ] Require the shared-interface, lockfile, generated-artifact, and unnamespaced-resource scenarios to create collision edges or sequential work.
- [ ] Require the undeclared-file scenario to block integration pending review and graph correction.
- [ ] Record results in the plan workspace as `pressure-green.md` and compare them with `pressure-red.md`.
- [ ] If a fresh agent finds a loophole, add one failing contract assertion, revise only the owning skill, and rerun the affected pressure scenario.
- [ ] Run `just test` after the last skill revision.
- [ ] Proceed to the final whole-branch review only when the pressure scenarios and shell suite pass.
