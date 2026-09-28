# Prime-only Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Prime Agent the only supported harness, retire repo-managed legacy installations, and keep Anthropic and OpenAI Prime configurations.

**Architecture:** Keep Prime install/update/uninstall and provider rendering in the existing shell scripts. Isolate a one-time ownership-checked legacy retirement command from all routine Prime commands. Keep workflow policy in one Prime-only source and link local skills after upstream skills to preserve intentional forks.

**Tech Stack:** Bash, jq, just, Markdown, sandboxed Bash tests, Git.

**Spec:** `docs/superpowers/specs/2026-09-28-prime-only-setup-design.md`

## Global Constraints

- Prime Agent retains `prime/anthropic.json` and `prime/openai.json`; OpenAI Prime selectors use `openai-codex/...`.
- Routine install, update, doctor, and uninstall do not configure Claude Code or OpenCode.
- Legacy retirement removes owned links and only manifest-tracked OpenCode entries that still match installed values; unrelated or changed data remains.
- Uninstall the Claude Code Superpowers plugin using its CLI, but preserve the `~/.superpowers` and `~/.swe-skills` checkouts.
- Do not create OpenCode config backups or perform live Anthropic authentication tests. Static Anthropic config/render validation is required.
- Keep workflow fast-path exception, Prime role/model table, both local Superpowers fork overrides, and no implicit provider switching on update.
- Baseline before edits: `just test` passed 22/22 test files.

## Review Focus

1. A modified OpenCode agent/provider setting stays unchanged; `tests/test_retire_legacy.sh` covers it.
2. An unrelated or non-repo symlink stays untouched; `tests/test_retire_legacy.sh` covers it.
3. A malformed OpenCode config or absent manifest is not overwritten; `tests/test_retire_legacy.sh` covers it.
4. A Prime update under an OpenAI manifest keeps its provider and installed links; `tests/test_install_prime.sh` or `tests/test_prime_configs.sh` covers it.
5. Anthropic config remains renderable without an account; `tests/test_render_agents_md.sh` and `tests/test_prime_configs.sh` cover it.

---

### Task 1: One-time legacy retirement

**Files:**
- Create: `scripts/retire-legacy.sh`, `scripts/retire-legacy-managed.json` (historical provider-specific ownership fingerprints).
- Create: `tests/test_retire_legacy.sh`
- Modify: `tests/lib/sandbox.sh` only if fixture helpers need a safe stub for plugin discovery.

**Interfaces:**
- Consumes: current `scripts/lib.sh` path helpers; legacy manifest at `$(opencode_dir)/.agentic-swe-setup.json`; `opencode/{anthropic,openai}.json` while it still exists.
- Produces: `bash scripts/retire-legacy.sh`, an explicit, repeatable, ownership-checked command independent of Prime install/update/uninstall. `scripts/retire-legacy-managed.json` contains the exact `agent` and `provider.openai` values from the two historical `opencode/*.json` configs, keyed by manifest provider; the installer never reads this retirement-only file.

- [ ] **Step 1: Load the `clean-coding` skill, then write a failing sandbox test for the retirement contract.** Set up a manifest plus repo-owned and unrelated symlinks; stub `claude` so the invocation is logged. Assert these outcomes (use existing sandbox assertions):

```bash
bash "$REPO_ROOT/scripts/retire-legacy.sh"
assert_missing "$(opencode_dir)/AGENTS.md" "owned OpenCode link removed"
assert_file "$(prime_dir)/AGENTS.md" "Prime link preserved"
assert_contains "$(cat "$SANDBOX/claude.log")" 'plugin uninstall superpowers' 'Claude plugin retired'
assert_eq "$(jq -r '.theme' "$(opencode_dir)/opencode.jsonc")" 'tokyonight' 'unrelated theme preserved'
```

Include cases where managed agent/provider values match and are removed, where values differ and stay, where a link targets another directory and stays, where the manifest or plugin is absent, and where config is non-JSON and stays unmodified. Assert a nonzero status or explicit warning when the command cannot finish safely. Do not create backup files.

- [ ] **Step 2: Run `bash tests/test_retire_legacy.sh` and observe failure because the command does not exist.**
- [ ] **Step 3: Implement the narrow retirement command.** Validate manifest and config before writes. Compare named managed entries against `scripts/retire-legacy-managed.json` and delete only equal values. Remove only symlinks whose realpaths match known repo or shared-checkout skill paths. If `claude` exists, inspect `claude plugin list --json` for an installed `superpowers` entry before `claude plugin uninstall superpowers`; treat an absent entry as already retired and an unreadable list as an error. Preserve Prime files. A second run must not delete additional user data.
- [ ] **Step 4: Run `bash tests/test_retire_legacy.sh` and `git diff --check`; inspect the failure/skip messages.** Commit only Task 1 files as `feat: add safe legacy harness retirement`.

### Task 2: Prime-only command surface

**Files:**
- Modify: `justfile`, `scripts/lib.sh`, `scripts/install-prime.sh`, `scripts/install-skills.sh`, `scripts/update.sh`, `scripts/doctor.sh`, `scripts/uninstall.sh`, `scripts/merge-prime.sh` where text references old harnesses.
- Delete: `scripts/install-claude.sh`, `scripts/install-opencode.sh`, `scripts/merge-opencode.sh`, `opencode/anthropic.json`, `opencode/openai.json`, `agents/*.md`, `CLAUDE.md` after checking Prime has no consumer.
- Modify/delete old harness tests: `tests/test_install.sh`, `tests/test_merge_opencode.sh`, `tests/test_provider_configs.sh`, `tests/test_agents.sh`, `tests/test_render_agents_md.sh`, `tests/test_install_prime.sh`, `tests/test_prime_configs.sh`, `tests/test_uninstall.sh`, `tests/test_doctor.sh`, `tests/test_lib.sh`, `tests/test_local_skills.sh`, `tests/test_agents_md.sh` as required by the changed public commands.

**Interfaces:**
- Consumes: Task 1 retirement script's independent ownership helpers; the two Prime provider JSON files.
- Produces: Prime-only recipes and shell entry points; `render_agents_md prime PROVIDER` or a simplified equivalent returning `build/prime/PROVIDER/AGENTS.md`; unchanged provider choice in update; regular uninstall removes Prime-managed items only.

- [ ] **Step 1: Load the `clean-coding` skill, then change sandbox tests first.** Assert `justfile` has `install` delegating to `install-prime`, that `update.sh` never calls a legacy installer, and that `uninstall.sh` leaves a fixture `$(opencode_dir)/opencode.jsonc` and `$(claude_dir)/CLAUDE.md` untouched. Make existing Prime tests cover both provider renders and the manifest provider surviving `update.sh`.

```bash
assert_contains "$(cat "$REPO_ROOT/justfile")" 'install: install-prime' 'only Prime installed'
assert_eq "$(jq -r '.provider' "$(prime_dir)/.agentic-swe-setup.json")" 'openai' 'update kept provider'
```

Remove old-harness-only tests rather than changing them into vacuous passes. Adapt shared tests to the retained Prime behavior. Keep static validation of `prime/anthropic.json` (no live API call).

- [ ] **Step 2: Run focused tests (`bash tests/test_install_prime.sh`, `bash tests/test_uninstall.sh`, `bash tests/test_render_agents_md.sh`) and observe the new contract fail.**
- [ ] **Step 3: Implement the smallest Prime-only shell changes.** Remove unused OpenCode/Claude helpers and installed config paths; keep minimal legacy helpers solely in Task 1's script. Preserve Prime settings merge and model validation. Do not implicitly update or uninstall the legacy harnesses. Retain `~/.superpowers` and `~/.swe-skills` on regular uninstall.
- [ ] **Step 4: Run `just test`, inspect its count/output, `git diff --check`, and the exact removed paths.** Commit Task 2 changes as `refactor: make setup commands prime-only`.

### Task 3: Instructions, skill entry points, and user docs

**Files:**
- Modify: `AGENTS.md`, `README.md`, `skills/routing-model-tiers/SKILL.md`, `skills/subagent-driven-development/{SKILL.md,implementer-prompt.md,task-reviewer-prompt.md,re-review-prompt.md}`; inspect other active local skill files for stale harness commands before changing them.
- Modify: `tests/test_agents_md.sh`, `tests/test_render_agents_md.sh`, `tests/test_subagent_driven_development_skill.sh`, `tests/test_readme.sh`, and any existing targeted skill tests whose assertions depend on old invocation text.
- Remove obsolete ignored artifact `build/prime/AGENTS.md` from the working installation; do not commit ignored generated files.

**Interfaces:**
- Consumes: Prime provider-specific model render from Task 2 and current Prime skill APIs.
- Produces: one Prime-only source policy, native `rlm.spawn(...)` dispatch templates with explicit parent replies, correct skill-relative script paths, and Prime-only README including explicit retirement command.

- [ ] **Step 1: Load the `clean-coding` skill before test edits and `de-slop` before prose.** Write failing assertions for absence of active `#### When running under OpenCode`/Claude sections, presence of the Prime model table, Prime-native template dispatch, and real script paths. Update README tests for Prime-only recipes and both provider names; keep the fast-path precedence check and fork precedence checks.

```bash
! grep -q '^#### When running under OpenCode' "$REPO_ROOT/AGENTS.md" || fail 'obsolete dispatch policy'
grep -q 'rlm.spawn' "$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md" || fail 'Prime dispatch missing'
```

- [ ] **Step 2: Run `bash tests/test_agents_md.sh`, `bash tests/test_subagent_driven_development_skill.sh`, and `bash tests/test_readme.sh` to observe expected failures.**
- [ ] **Step 3: Trim only active conflicting or duplicated language.** Keep the table generated from the two provider configs, explain intentional fork precedence, and use the exact Prime native skill and messaging API. Do not edit archived design records or upstream checkouts to force their prose to match.
- [ ] **Step 4: Run `just test`, render both providers, check fork link targets in a sandbox, and inspect `git diff --check`.** Commit Task 3 files as `docs: align instructions and skills with Prime Agent`.

### Task 4: Apply upstream update and retire current home installation

**Files:**
- No repository source edits unless verification exposes a task-owned defect; record upstream revision and cleanup outcomes in the final report.
- External: `~/.superpowers` checkout, legacy Claude/OpenCode links and config, Claude Superpowers plugin, Prime installed render and links.

**Interfaces:**
- Consumes: all three previous tasks, real installed legacy manifest, Prime OpenAI provider manifest, upstream `obra/superpowers` main.
- Produces: clean, Prime-only installed home state; no change to the swe-skills checkout when current.

- [ ] **Step 1: Load the `clean-coding` skill for script verification and `agentic-manual-testing` for the runnable commands.** Recheck `~/.superpowers` worktree cleanliness and remote HEAD. If it remains a fast-forward update, run the project's Prime update command with its existing OpenAI provider; ensure `~/.swe-skills` has no pending update. Do not force a dirty or diverged checkout.
- [ ] **Step 2: Exercise install/update/doctor/uninstall with a sandboxed `HOME` and `PRIME_AGENT_CODING_AGENT_DIR`, then manually check the real Prime/OpenAI install, model table, and fork links.** Avoid a live Anthropic model request; validate its JSON and render only.
- [ ] **Step 3: Run `bash scripts/retire-legacy.sh` on the real home only after sandbox test success.** Inspect its exact report for skipped user-modified entries, absence of legacy owned links and plugin, and unchanged Prime OpenAI provider. If cleanup is incomplete, report what remains and do not force-remove it.
- [ ] **Step 4: Run final `just test`, `git diff --check`, `git status --short`, and `git -C ~/.superpowers rev-parse HEAD`.** Give exact file-count pass result and upstream SHA. Only claim functionality demonstrated by these checks.
