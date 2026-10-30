# Selective Upstream Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the audited local fixes and Superpowers v7.0.1 while preserving local workflows and live Prime configuration.

**Architecture:** Keep the shared upstream skill checkout and existing local directory overrides. Two isolated writers can update the SDD helpers and the policy/provenance documents independently; the controller integrates reviewed commits before the controlled live refresh.

**Tech Stack:** Bash, Git, Markdown, jq, just.

**Spec:** `docs/superpowers/specs/2026-10-29-selective-upstream-updates-design.md`

## Global Constraints

- Keep existing argument validation, output naming, and invocation contract.
- Preserve any existing file byte-for-byte, including an empty file.
- Keep hashed workspace identity and the in-repository plan restriction.
- Keep all fast-path exclusions and all full-path safety gates.
- Do not create a local brainstorming fork or change the SDD workflow.
- Do not run just update or an installer.
- Do not alter provider JSON files or installer behavior.
- No new skills, wholesale fork replacement, compaction-policy change, model-ladder update, installer redesign, swe-skills fetch, license change to unrelated material, publication, or remote push.

## Review Focus

- Equal or divergent commit ranges must exit 3 before creating or modifying output (Task 1).
- A valid multi-commit range must retain the complete range, not only its last commit (Task 1).
- An existing empty or customized workspace .gitignore must survive repeated calls byte-for-byte; a missing file must receive the default (Task 1).
- The bounded-path instruction must survive both provider renders without weakening fast/full gates (Task 2).
- Live settings, harness state, and installation manifest must remain byte-identical during tests and deployment (controller checks).

## Execution and isolation

The baseline `just test` passed 21/21 test files at `47feeb8ee63a7345132852595781900522652652`; log: `/tmp/agentic-swe-selective-update-hl_s2lo_/baseline/just-test.log`. The approved design is committed as `a5b05c793174044123de22337b34098d34cb1f36` on `chore/selective-upstream-updates`.

Use SDD's plan-specific ledger and capture the post-plan-commit controller HEAD as the wave base. Provision two writer worktrees sequentially with `worker-worktree`, then dispatch Tasks 1 and 2 together. Both have no task dependency. Their tracked files do not overlap; each suite writes generated `build/` files only in its own worktree and uses the existing sandbox configuration roots. No writer may change the real shared checkout, user configuration, symlinks, primary branch, or Git worktree registrations. Record namespace/path/base values before dispatch. Snapshot protected live file hashes before the wave and compare after it. Existing primary-render hashes may change only during the authorized final regeneration, never during writer tests.

---

### Task 1: Preserve workspace policy and reject invalid review ranges

**Files:**
- Modify: `skills/subagent-driven-development/scripts/review-package`
- Modify: `skills/subagent-driven-development/scripts/sdd-workspace`
- Modify: `tests/test_subagent_driven_development_skill.sh`
- Modify: `skills/subagent-driven-development/README.md`

**Interfaces:**
- Consumes: `review-package PLAN_FILE BASE HEAD [OUTFILE]` and `sdd-workspace PLAN_FILE` in a consumer Git repository.
- Produces: exit 3 for non-ancestor or empty review ranges before output writes; unchanged valid review content; create-only workspace .gitignore. No other task consumes a changed interface.

- [ ] **Step 1:** Load `clean-coding`, `test-driven-development` (including `writing-good-tests.md`), and `agentic-manual-testing`. Inspect current sandbox and Git-fixture conventions. Add behavior regressions: equal and divergent ranges reject with exit 3 and leave absent/existing output untouched; valid two-commit ranges include both changes; missing .gitignore becomes `*\n`; custom and empty existing .gitignore files remain byte-identical on repeat calls. Retain the existing canonical-path and same-basename isolation checks. Use real scratch Git histories, not mocks of Git decisions.
- [ ] **Step 2:** Run `REPO_ROOT="$PWD" bash tests/test_subagent_driven_development_skill.sh`. Record the expected failures for invalid-range acceptance and ignore-file replacement before implementation. Fix fixture errors rather than treating them as RED.
- [ ] **Step 3:** Port only upstream's ancestry/nonempty guards and create-only ignore-file check. The source guards are in Superpowers `5bf4e78011075bcfc0dc295f0724994cd123ee71` and `bb92a77741419a4ab5f06e711a283343f1ada0c3`; the audited clone is `/tmp/agentic-swe-upstream-audit-47iazbh3/superpowers/source`. Keep local workspace hashing, path restrictions, and helper execution style unchanged.
- [ ] **Step 4:** Load `de-slop` and `plain-technical-prose`; briefly document the helper contracts and upstream reconciliation SHAs in the SDD README. Run the focused command, `just test`, and `git diff --check`. Expect the focused command to exit 0 and all 21 test files to pass. Exercise both CLIs manually in a separate scratch consumer repo; record commands, exit statuses, generated package content, and preserved ignore bytes.
- [ ] **Step 5:** Self-review and commit only the declared files. Report the full ordered commit range, RED/GREEN evidence, suite result, and manual evidence; no nested agents.

### Task 2: Preserve bounded workflow and correct upstream provenance

**Files:**
- Modify: `AGENTS.md`
- Modify: `tests/test_agents_md.sh`
- Modify: `tests/test_render_agents_md.sh`
- Modify: `README.md`
- Modify: `skills/plain-technical-prose/README.md`

**Interfaces:**
- Consumes: existing source instructions, `render_agents_md prime PROVIDER`, upstream brainstorming at `2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`, and philpax LICENSE at `290bdaa4ff475aebdaca67391227d35af6dc5c50`.
- Produces: explicit bounded-path mapping in source and both provider renders; accurate v7.0.1/update and license documentation. No runtime configuration change.

- [ ] **Step 1:** Load `clean-coding` and `test-driven-development`. Add one source assertion and provider-loop render assertions for this exact, unique sentence:

In-chat approval replaces the upstream written-design gate on the bounded path; do not invoke `writing-plans`.

- [ ] **Step 2:** Run `REPO_ROOT="$PWD" bash tests/test_agents_md.sh` and `REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh` before editing instructions. Record failures for the missing sentence; retain every existing fast/full/approval assertion.
- [ ] **Step 3:** Load `de-slop` and `plain-technical-prose`. Add the sentence within the existing bounded-path section without changing its other rules. Add a concise main README note on v7.0.1 compatibility and that `just update` reapplies repository-managed defaults, not only skills. Correct the prose-skill README's no-license claim with the current upstream Unlicense link; retain attribution and the name-only local delta. Do not edit either SKILL.md, the model ladder, or unrelated historical documentation.
- [ ] **Step 4:** Rerun both focused commands, `just test`, and `git diff --check`. Expect both focused commands to exit 0 and all 21 test files to pass. Inspect actual generated Anthropic/OpenAI instructions and confirm they contain the sentence and preserve provider-specific routing.
- [ ] **Step 5:** Self-review and commit only the declared files. Report the full commit range and test evidence. The controller, not this writer, runs the fresh-context scenario checks below; no nested agents.

## Controller review and installation

- [ ] Review each complete writer range before cherry-picking. Integrate sequentially, run covering tests after each integration and the full suite after the wave, record source-to-integration SHAs and exact terminal cleanup authorizations, then clean writer worktrees through the helper. Use the SDD review/fix limits; do not replace them with ad-hoc controller fixes.
- [ ] Run separate read-only fresh-context checks against the integrated AGENTS.md and audited v7.0.1 brainstorming: (a) a fully specified one-file README typo remains fast, with no brainstorming or plan; (b) an approved, three-file local presentation change with no API/security/concurrency effect remains bounded, with in-chat approval and no design/plan files; (c) a one-file public-API change remains full, with design/plan approval before implementation. Record actions and reasons. A conflicting result blocks deployment and requires a reported policy/design decision, not an unapproved skill fork.
- [ ] Request strongest whole-branch review, including deferred findings and all verification evidence. Complete the permitted final fix/re-review, run the final suite and diff checks, and run the compound step. Retain evidence outside deleted SDD workspaces.
- [ ] The user approved local integration into main, not publication. Recheck primary cleanliness, expected base, and no active Git operation; fast-forward local main to the reviewed feature HEAD only. Stop if primary has diverged. Do not push. Regenerate only the installed provider's AGENTS.md using `render_agents_md`; verify its existing installed link still resolves to that primary-checkout file. Do not merge settings, rewrite role specs, or relink skills.
- [ ] Verify the clean shared Superpowers origin is `https://github.com/obra/superpowers`, branch main, starting SHA `bb92a77741419a4ab5f06e711a283343f1ada0c3`. Fetch and verify tag v7.0.1 resolves to `2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`; verify ancestry and fast-forward to that exact SHA, never an unverified remote HEAD. Stop on any preflight mismatch; do not reset changes.
- [ ] Run `just test` and `just doctor` from the integrated primary checkout. Verify actual upstream/local skill targets, exact upstream SHA, unchanged settings/harness/manifest hashes, and expected rendered instruction content. Report any partial deployment explicitly rather than claiming an atomic update. Record final commits and verification results before removing the isolated feature worktree.
