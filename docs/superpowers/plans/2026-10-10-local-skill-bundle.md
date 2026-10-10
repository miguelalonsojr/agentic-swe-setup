# Local Skill Bundle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install ten repository-owned skill guides and local reference folders without fetching `swe-skills`.

**Architecture:** The existing `skills/` tree owns all ten new skill names alongside current local skills. Installation links Superpowers first and all repo-owned skills last. The eight copied `references/` trees are local-only content committed on an untracked-by-remote branch; the guides and installer do not depend on `~/.swe-skills` at runtime.

**Tech Stack:** Bash, Markdown, Python standard library for local copy/hash verification, Git, `just`.

**Spec:** `docs/superpowers/specs/2026-10-10-local-skill-bundle-design.md`

## Global Constraints

- Branch: `local/original-skill-bundle` without an upstream. Do not create a worktree, add `.gitignore`, merge into `main`, or push.
- Source checkout: `~/.swe-skills` at `809dee1bf63c3360eb7412f3498f0fa4c76af38e`. Copy only its eight `references/` folders byte-for-byte before writing new skill guides; never copy source `SKILL.md`, scripts, or other files. Do not alter attribution in copied references. No PDFs or ebooks are present or added.
- All ten new directories belong under this repository's `skills/`: `confluence-diagrams`, `de-slop`, `generating-design-doc`, `low-level-design`, `clean-architecture`, `clean-coding`, `ddd-expert`, `design-patterns-expert`, `pragmatic-engineer`, `system-designing`.
- Each new `SKILL.md` and README must use independently written prose. The eight guides with local `references/` must link to actual relative files; `confluence-diagrams` and `generating-design-doc` are self-contained. First release is concise, not equivalent to the old reference tree. Confluence upload guidance must discover a real tool and verify the rendered page rather than inventing an API.
- Install/update must not clone or fetch `swe-skills`; doctor must check local link targets for all 23 repository-owned skills; uninstall must not delete or mutate the old checkout. Superpowers fork precedence and Prime provider merge stay unchanged.

## Review Focus

- No `~/.swe-skills` checkout exists: Prime install/update succeeds without trying its URL (Task 3 sandbox test).
- A Superpowers skill name collides with a repository-owned skill: the installed link points to the repository copy (Task 3 collision test).
- A repo-owned skill link points outside the repository or its target is missing: doctor reports a warning rather than a false OK (Task 4 doctor test).
- A user-owned installed directory occupies a skill name: link creation backs it up instead of deleting it (existing `tests/test_lib.sh`, Task 3 installation test).
- Uninstall encounters foreign links and dangling old shared links: it preserves foreign links and removes only matching managed links (Task 4 uninstall test).

---

### Task 1: Copy only the local reference trees

**Files:** Create `skills/{de-slop,low-level-design,clean-architecture,clean-coding,ddd-expert,design-patterns-expert,pragmatic-engineer,system-designing}/references/` and `tests/test_local_references.sh`.

**Interfaces:** Produces eight immutable local reference trees for Task 2's relative Markdown links. Counts by skill in the order above: 1, 6, 36, 12, 11, 28, 12, 14 files (120 total). No test may require the source checkout after this task.

- [ ] **Step 1: Load `clean-coding`, then add `tests/test_local_references.sh`.** Assert each expected reference directory contains its specified file count and one sentinel: `de-slop/tropes.md`, `low-level-design/deriving-the-model.md`, `clean-architecture/chapter-01-what-is-design-and-architecture.md`, `clean-coding/ch01_clean_code.md`, `ddd-expert/ch01_crunching_knowledge.md`, `design-patterns-expert/chapter-01-oop-intro.md`, `pragmatic-engineer/chapter-01-pragmatic-philosophy.md`, `system-designing/ch01-tradeoffs-architecture.md`. Assert no `references/` exists for the other two skills. Source `tests/lib/sandbox.sh` for assertions.
- [ ] **Step 2: Run `REPO_ROOT="$PWD" bash tests/test_local_references.sh`.** Expect missing-directory failures (RED), not a missing dependency.
- [ ] **Step 3: Copy the eight folders with `shutil.copytree` from the pinned local checkout.** Do not open source skill prose. Compare sorted relative file paths and SHA-256 bytes source to destination with Python; require exactly 120 matches and no extras. Stop if source HEAD differs from the pinned commit.
- [ ] **Step 4: Run the focused test and `just test`.** Expect all 20 test files to pass. Inspect `git diff --check` and `git status --short` to ensure only the eight reference trees and test are new.
- [ ] **Step 5: Commit** only these copied trees and the focused test as `chore: preserve local skill references`.

### Task 2: Write ten original first-version skill guides

**Files:** Create `skills/<name>/SKILL.md` and `skills/<name>/README.md` for each of the ten names in Global Constraints; create `tests/test_original_skill_guides.sh`.

**Interfaces:** Consumes Task 1 reference paths; produces ten triggerable skill directories with existing names. For each of the eight, link at least one exact existing `references/<sentinel>` file from Task 1. The two without references remain self-contained.

- [ ] **Step 1: Load `writing-skills` and `clean-coding`.** Add focused test assertions for frontmatter `name` and `description`, an explicit use case and verification section for every guide, and resolvable relative links to each sentinel in Task 1. Use `tests/lib/sandbox.sh`; do not read old `SKILL.md` text. Record one pressure scenario for the diagram upload guide and one for a book-topic guide before writing new prose, then rerun those scenarios against the new guides.
- [ ] **Step 2: Run `REPO_ROOT="$PWD" bash tests/test_original_skill_guides.sh`.** Expect missing new guides (RED).
- [ ] **Step 3: Write original `SKILL.md` and README pairs.** Keep each guide concise and task-specific. Use clear trigger descriptions, steps, checks, and limits. Link the eight reference sentinels from Task 1 using valid relative paths; do not quote their prose. The diagram guide must refuse an upload when no attachment interface is available.
- [ ] **Step 4: Run the focused test, pressure checks, and `just test`.** Expect all 21 test files to pass. Verify new guides are not byte-identical to old `SKILL.md` files without copying old text into reports.
- [ ] **Step 5: Commit** the 20 guide files and focused test as `feat: add original local skill guides`.

### Task 3: Remove the shared checkout from installation

**Files:** Modify `scripts/lib.sh`, `scripts/install-prime.sh`, `scripts/update.sh`, `README.md`, `tests/test_lib.sh`, and `tests/test_install_prime.sh`. Retain `scripts/install-skills.sh` unless a focused test proves it needs change.

**Interfaces:** Extend `LOCAL_SKILLS` with the ten names from Task 2. Remove `SWE_SKILLS_REPO` and `ensure_swe_skills` from install/update. Keep `SKILL_NAMES` and `swe_skills_dir` temporarily because existing doctor/uninstall still use them; Task 4 removes `SKILL_NAMES` and retains `swe_skills_dir` only for safe previous-install link cleanup. The existing `link_local_skills` links every listed name after `link_skill_tree` links Superpowers.

- [ ] **Step 1: Load `clean-coding`, then change install/lib tests first.** In `tests/test_install_prime.sh`, simulate an absent `SWE_SKILLS_DIR`, assert all ten links target `$REPO_ROOT/skills/<name>`, and create a stub Superpowers `de-slop` entry to verify collision precedence. In `tests/test_lib.sh`, require 23 local names and no `ensure_swe_skills` function. Add an update-path assertion using a sandbox without `swe-skills`; preserve provider selection.
- [ ] **Step 2: Run the focused install/lib/update tests.** Expect old code to fail due to attempts to use the missing checkout (RED).
- [ ] **Step 3: Remove the shared checkout ensure/link calls and register all ten repo-owned skills.** Update the README skill table and ownership sentence now so its existing dynamic name tests stay green; leave detailed uninstall prose for Task 4. Keep Superpowers ensure/link order and provider merge untouched. Do not change `retire-legacy.sh`.
- [ ] **Step 4: Run focused tests, then `just test`.** Expect all 21 test files to pass with no old checkout. Check `git diff --check`.
- [ ] **Step 5: Commit** scripts, README ownership/table lines, and focused tests as `fix: install skill bundle from repository`.

### Task 4: Update diagnosis, uninstall, and user instructions

**Files:** Modify `scripts/lib.sh`, `scripts/doctor.sh`, `scripts/uninstall.sh`, `README.md`, `AGENTS.md`, `tests/test_lib.sh`, `tests/test_doctor.sh`, `tests/test_uninstall.sh`, `tests/test_readme.sh`. Leave `scripts/retire-legacy.sh` unchanged.

**Interfaces:** Consumes the 23-name `LOCAL_SKILLS` list from Task 3. Remove `SKILL_NAMES` from `scripts/lib.sh` after doctor and uninstall stop using it; retain `swe_skills_dir` for lexical comparison of stale previous-install links only. Doctor checks all links into this repo; uninstall unlinks only owned local, old managed, and Superpowers links without fetching the old checkout.

- [ ] **Step 1: Load `clean-coding` and `de-slop`.** Add a doctor test with no `SWE_SKILLS_DIR` and a foreign link for one new skill; require a warning for the foreign link and no missing-checkout warning. Add uninstall tests for repo-owned new links, dangling previous-version shared links, and foreign links. Update `tests/test_lib.sh` to stop asserting `SKILL_NAMES`. Update README tests to require local ownership and absence of an install-time `swe-skills` dependency.
- [ ] **Step 2: Run focused doctor/uninstall/README tests.** Expect failures from old shared checkout assumptions (RED).
- [ ] **Step 3: Update doctor/uninstall and prose minimally.** Keep user-owned links and unrelated settings intact. Replace the source `AGENTS.md` claim of installed `swe-agent-skills` prose with accurate local-guide and reference wording; preserve skill-load phase mapping. README names all ten and warns that this local-only branch must remain checked out for live skill links.
- [ ] **Step 4: Run focused tests and `just test`.** Expect 21/21 test files, no warnings except intended sandbox foreign-link warnings; check `git diff --check`.
- [ ] **Step 5: Commit** these changes as `docs: document and verify repository-owned skills`.

## Local installation and final checks

- [ ] Review the full local branch diff independently, including unexpected files and attribution preserved in the eight copied reference trees. Resolve blocking findings without reading copied prose into new guides.
- [ ] Run `just test` and sandboxed install/update/doctor/uninstall with `SWE_SKILLS_DIR` absent. Run `just install-skills` from this stable checkout, then `just doctor`; inspect all ten new symlink targets and the two Superpowers forks. If `just doctor` reports other pre-existing warnings, distinguish them from this change.
- [ ] Record the local commit SHAs and clean branch status. Leave `local/original-skill-bundle` checked out with no upstream; do not push, merge, or add `.gitignore`.
