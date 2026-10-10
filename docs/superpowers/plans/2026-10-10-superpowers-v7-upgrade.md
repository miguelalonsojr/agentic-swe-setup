# Superpowers v7.0.0 Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install upstream Superpowers v7.0.0 while preserving the local forks and removing the secret-leaking examples in `systematic-debugging`.

**Architecture:** The shared checkout supplies upstream skills, including `brainstorming`. Repository-owned skills overlay only the two existing forks. No installer change or version pin is needed because the existing checkout-update and link order support this release.

**Tech Stack:** Git, Bash, Markdown, `just`.

**Spec:** `docs/superpowers/specs/2026-10-10-superpowers-v7-upgrade-design.md`

## Global Constraints

- The shared checkout must reach v7.0.0 commit `bb92a77741419a4ab5f06e711a283343f1ada0c3` through a clean fast-forward; keep existing fast-forward behavior without a version pin.
- Prime Agent's `brainstorming` link must resolve to `~/.superpowers/skills/brainstorming`. Do not create `skills/brainstorming`.
- Keep both local forks and their additions; leave `finishing-a-development-branch/SKILL.md` unchanged.
- The two `systematic-debugging` secret checks and the polluter-script example must match upstream v7.0.0. The diagnostic examples must not print `IDENTITY` values.
- Keep `AGENTS.md` approval gates unchanged; no broad installation refactor.

## Review Focus

- `IDENTITY` is set to a nonempty secret: a documented diagnostic must report `SET` or presence, never print the value (Task 1 assertions and manual example check).
- `IDENTITY` is absent: the documented diagnostic must report `UNSET` or absence without failing (Task 1 assertions and manual example check).
- The upstream checkout contains a new `brainstorming` file: the installed link must resolve to the shared checkout, not a local fork (existing `tests/test_install_prime.sh` link check; final install check).
- Repository-owned forks share skill names with upstream: both installed links must resolve to this repository (existing `tests/test_local_skills.sh` loop; final install check).
- A dirty shared checkout blocks updating rather than discarding local changes (existing checkout guard in `scripts/lib.sh`; final preflight check).

---

### Task 1: Reconcile the debugging fork with upstream v7.0.0

**Files:**
- Modify: `skills/systematic-debugging/SKILL.md` (the two environment checks only).
- Modify: `skills/systematic-debugging/root-cause-tracing.md` (polluter example only).
- Modify: `skills/systematic-debugging/README.md` (record fork base and v7.0.0 reconciliation).
- Modify: `README.md` (explain v7.0.0 reconciliation and upstream `brainstorming` link while retaining the fork's original base citation).
- Modify: `tests/test_local_skills.sh` (focused skill text assertions).

**Interfaces:**
- Consumes: upstream v7.0.0 files at `skills/systematic-debugging/{SKILL.md,root-cause-tracing.md}` and existing `link_skill_tree`/`link_local_skills` behavior.
- Produces: the two existing fork skill directories with their original links and an updated `systematic-debugging` text contract. No new API, link, or checkout procedure.

- [ ] **Step 1: Load the `clean-coding` skill, then add a focused failing test** to `tests/test_local_skills.sh`. Assert that `systematic-debugging/SKILL.md` includes the v7.0.0 presence-only commands `echo "IDENTITY: $([ -n "${IDENTITY:-}" ] && echo SET || echo UNSET)"` and `printenv IDENTITY >/dev/null 2>&1 && echo "IDENTITY in environment" || echo "IDENTITY not in environment"`, and does not include `env | grep IDENTITY` or `${IDENTITY:+SET}${IDENTITY:-UNSET}`. Assert that `root-cause-tracing.md` includes `bash ./find-polluter.sh '.git' 'src/**/*.test.ts'`. Use single-quoted shell literals for the `IDENTITY` commands so the test never expands the variable. Use a double-quoted literal for the polluter example, which contains single quotes.
- [ ] **Step 2: Run `bash tests/test_local_skills.sh`** with `REPO_ROOT` exported as the repository root. Expect a failed assertion for the missing v7.0.0 examples; record RED. Use `bash(...)` as a nonblocking handle and await completion.
- [ ] **Step 3: Update only the specified fork lines and provenance prose.** Copy the three example lines from upstream v7.0.0 exactly. Leave `skills/finishing-a-development-branch/SKILL.md` alone. Keep `b36e082` as historical fork base in the README files; add that the debugging fork incorporates v7.0.0's secret-safe examples and the support-document command. State that `brainstorming` comes from the upstream shared checkout.
- [ ] **Step 4: Run `bash tests/test_local_skills.sh` with `REPO_ROOT` exported, then `just test`.** Expect the focused test to pass and all 19 test files to pass. Exercise both v7.0.0 sample checks with `IDENTITY=private-value` and with `IDENTITY` absent; output must report only status, never `private-value`. Check `git diff --check` and compare the two fork skills with upstream v7.0.0; only the existing local additions should differ.
- [ ] **Step 5: Commit** `skills/systematic-debugging/SKILL.md`, `skills/systematic-debugging/root-cause-tracing.md`, `skills/systematic-debugging/README.md`, `README.md`, and `tests/test_local_skills.sh` with message `fix: reconcile debugging fork with Superpowers v7`.

## Release installation (after Task 1 is reviewed and integrated)

- [ ] Confirm `~/.superpowers` is clean and its origin is `https://github.com/obra/superpowers`; `git ls-remote` and the local ref must identify v7.0.0 at `bb92a77741419a4ab5f06e711a283343f1ada0c3`. Stop and report if the fast-forward target differs, the checkout is dirty, or origin differs; do not reset or overwrite it.
- [ ] Run `just update` to fast-forward the shared checkout and relink Prime Agent skills. Await completion; if it skips because a prerequisite is missing, stop rather than reporting success.
- [ ] Verify the checkout is at the v7.0.0 commit, `just doctor` succeeds, and `~/.prime/agent/skills/brainstorming` resolves to `~/.superpowers/skills/brainstorming`. Read the installed `SKILL.md` through that link and confirm its v7.0.0 `# Brainstorming` heading and `## Play It Back` section. Confirm both fork links resolve to the local repo and `skills/brainstorming` does not exist. Run `just test` and `git diff --check` again after installation.
