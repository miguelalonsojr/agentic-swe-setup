# Prime OpenAI Codex Selectors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate Prime Agent OpenAI role selectors that use the authenticated `openai-codex` provider.

**Architecture:** Prime’s provider configuration owns both default-provider selection and fully qualified selectors emitted into harness specs and rendered instructions. OpenCode remains a separate configuration with its existing `openai` selectors. Tests compare model IDs across harnesses while validating provider prefixes independently.

**Tech Stack:** Bash, jq, JSON, shell tests.

## Global Constraints

- Change only Prime Agent’s OpenAI provider selectors.
- Keep model IDs and thinking levels unchanged.
- Do not change OpenCode configuration.

---

### Task 1: Emit and verify Prime OpenAI Codex selectors

**Files:**
- Modify: `prime/openai.json`
- Modify: `tests/test_prime_configs.sh`
- Modify: `tests/test_render_agents_md.sh`
- Modify: `tests/test_install_prime.sh`
- Modify: `tests/test_uninstall.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: `scripts/merge-prime.sh` emits `.agent[*].model` into the harness state and `scripts/lib.sh` renders the Prime instruction table from `prime/openai.json`.
- Produces: Prime settings with `defaultProvider: "openai-codex"` and role selectors with the `openai-codex/` prefix.

- [ ] **Step 1: Load the `clean-coding` skill, then write failing tests**

Update the Prime-specific assertions to expect `openai-codex` for the default provider and `openai-codex/gpt-5.6-terra` in Prime generated output. In `tests/test_prime_configs.sh`, assert the Prime OpenAI model prefix separately and compare only its model ID after `/` with the OpenCode configuration.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test_prime_configs.sh && bash tests/test_render_agents_md.sh && bash tests/test_install_prime.sh && bash tests/test_uninstall.sh`

Expected: FAIL because `prime/openai.json` still emits `openai` selectors.

- [ ] **Step 3: Implement the minimal configuration and documentation changes**

Set `prime/openai.json` `settings.defaultProvider` to `openai-codex` and prefix every role model with `openai-codex/`. Update the README’s Prime section and tables to state that Prime’s OpenAI Codex authentication uses that provider name, while OpenCode retains `openai`.

- [ ] **Step 4: Run focused tests**

Run: `bash tests/test_prime_configs.sh && bash tests/test_render_agents_md.sh && bash tests/test_install_prime.sh && bash tests/test_uninstall.sh`

Expected: PASS.

- [ ] **Step 5: Run the full suite and verify a real selector**

Run: `just test && prime-agent --model openai-codex/gpt-5.6-terra -p 'say only ok'`

Expected: the test suite passes and Prime Agent prints `ok`.

- [ ] **Step 6: Commit**

```bash
git add prime/openai.json tests/test_prime_configs.sh tests/test_render_agents_md.sh tests/test_install_prime.sh tests/test_uninstall.sh README.md docs/superpowers/plans/2026-08-11-prime-openai-codex-selectors.md
git commit -m "fix: use OpenAI Codex selectors for Prime"
```
