# Provider-Pure Rendered Instructions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Link provider-specific instruction renders so an installed OpenCode or Prime Agent configuration never contains the other provider’s model names.

**Architecture:** Keep `AGENTS.md` as the shared, provider-neutral source. `scripts/lib.sh` will render it to a harness-and-provider-scoped build path and generate Prime Agent’s model table and selector example from `prime/<provider>.json`; installers pass their selected provider through to that renderer.

**Tech Stack:** Bash, awk, jq, repository shell-test harness.

## Global Constraints

- OpenCode and Prime Agent each select exactly one provider per installation.
- Build output must be namespaced as `build/<harness>/<provider>/AGENTS.md`.
- The OpenAI render must contain no `anthropic` or `claude` strings; the Anthropic render must contain no `openai` strings.
- Model roles and selectors in Prime instructions must come from `prime/<provider>.json`.
- Do not alter Claude Code setup, model ladders, roles, or managed configuration merge semantics.

---

### Task 1: Render and link provider-pure instruction files

**Files:**
- Modify: `AGENTS.md`
- Modify: `scripts/lib.sh:147-195`
- Modify: `scripts/install-opencode.sh:31`
- Modify: `scripts/install-prime.sh:44`
- Modify: `tests/test_render_agents_md.sh`
- Modify: `tests/test_install.sh:84-101`
- Modify: `tests/test_install_prime.sh:119-139`

**Interfaces:**
- Consumes: `prime/<provider>.json`, whose `.agent` object maps every `PRIME_AGENTS` role to a `.model` selector.
- Produces: `render_agents_md <harness> <provider>` printing `build/<harness>/<provider>/AGENTS.md`; `rendered_agents_md <harness> <provider>` returning the same path.
- Produces: Prime render substitutions for `<!-- PRIME_AGENT_MODEL_TABLE -->` and `<!-- PRIME_AGENT_REVIEWER_MODEL -->` in `AGENTS.md`.

- [ ] **Step 1: Load the `clean-coding` skill, then write failing renderer tests**

Update `tests/test_render_agents_md.sh` so it renders both `anthropic` and `openai` for every member of `HARNESSES`. Assert each path ends in `build/$h/$provider/AGENTS.md`, its target harness heading is retained, and other harness headings are absent. For the Prime OpenAI render, assert:

```bash
assert_contains "$prime_openai" '| `reviewer` | `openai/gpt-5.6-terra` |'     "OpenAI Prime table uses the selected model"
assert_contains "$prime_openai" 'model="openai/gpt-5.6-terra"'     "OpenAI Prime example uses the selected model"
assert_not_contains "$prime_openai" 'anthropic' "OpenAI Prime render has no Anthropic selector"
assert_not_contains "$prime_openai" 'claude' "OpenAI Prime render has no Claude model name"
```

Mirror the absence/presence assertions for the Anthropic Prime render using `anthropic/claude-opus-5` and absence of `openai`. Add failure assertions for an unknown harness and provider:

```bash
assert_status 1 render_agents_md nonesuch openai
assert_status 1 render_agents_md prime not-a-provider
```

- [ ] **Step 2: Run the renderer test to verify it fails**

Run: `REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh`

Expected: FAIL because `render_agents_md` accepts only a harness and still emits the hard-coded Anthropic table at `build/prime/AGENTS.md`.

- [ ] **Step 3: Implement the minimal provider-aware renderer**

In `AGENTS.md`, replace the hard-coded Prime table with:

```markdown
<!-- PRIME_AGENT_MODEL_TABLE -->
```

Replace the hard-coded selector in the Prime `rlm(...)` example with:

```markdown
model="<!-- PRIME_AGENT_REVIEWER_MODEL -->"
```

Remove the sentence that names `provider=openai` and `prime/openai.json`.
The surrounding prose must remain provider-neutral so an Anthropic render does
not retain an OpenAI reference.

In `scripts/lib.sh`:

1. Change `rendered_agents_md` to accept `harness` and `provider`, and return `"$REPO_ROOT/build/$harness/$provider/AGENTS.md"`.
2. Change `render_agents_md` to require both arguments, validate the harness with `harness_heading`, validate that `prime/$provider.json` exists, and keep the existing harness-section filtering behavior.
3. For the Prime harness, use `jq -r` and the ordered `PRIME_AGENTS` list to generate rows in this exact form:

```bash
printf '| `%s` | `%s` |\n' "$agent" "$model"
```

Generate the reviewer model from `.agent.reviewer.model`. Fail if either lookup is missing, null, or empty. Replace the two markers only after filtering; use a temporary file and an `awk` substitution that safely prints the generated multiline table.
4. Do not substitute Prime markers for other harnesses because their section filtering removes those markers.

Update `install-opencode.sh` and `install-prime.sh` to call:

```bash
instructions=$(render_agents_md opencode "$provider") || die "could not render AGENTS.md for OpenCode"
instructions=$(render_agents_md prime "$provider") || die "could not render AGENTS.md for Prime Agent"
```

- [ ] **Step 4: Run the renderer test to verify it passes**

Run: `REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh`

Expected: PASS with provider-scoped output paths and provider-pure Prime content.

- [ ] **Step 5: Write failing installer regression tests**

In `tests/test_install.sh`, after `"$IO" openai`, update the symlink expectation to:

```bash
assert_symlink_to "$(opencode_dir)/AGENTS.md"     "$(rendered_agents_md opencode openai)" "OpenCode instructions use the OpenAI render"
```

Then assert the installed file has neither provider leak:

```bash
installed=$(cat "$(opencode_dir)/AGENTS.md")
assert_not_contains "$installed" 'anthropic' "OpenAI OpenCode instructions have no Anthropic selector"
assert_not_contains "$installed" 'claude' "OpenAI OpenCode instructions have no Claude model name"
```

In `tests/test_install_prime.sh`, after `"$IP" openai`, assert the link targets `$(rendered_agents_md prime openai)` and add the same two negative assertions plus an assertion for `openai/gpt-5.6-terra`. Reinstall each harness with `anthropic` and assert its link targets the Anthropic render and contains no `openai`.

Update every existing test call to `rendered_agents_md` or `render_agents_md` with the provider that its test installs.

- [ ] **Step 6: Run installer tests to verify they fail**

Run:

```bash
REPO_ROOT="$PWD" bash tests/test_install.sh
REPO_ROOT="$PWD" bash tests/test_install_prime.sh
```

Expected: FAIL before the renderer and installer changes because the old renderer does not accept a provider and its output path is not provider-scoped.

- [ ] **Step 7: Complete the installer wiring and preserve existing behavior**

Apply the installer calls described in Step 3. Ensure all test references use the two-argument renderer interface. Do not change `merge-opencode.sh`, `merge-prime.sh`, `update.sh`, or `uninstall.sh`: manifests already persist the selected provider and uninstall only checks whether links resolve into the repository.

- [ ] **Step 8: Run targeted tests to verify they pass**

Run:

```bash
REPO_ROOT="$PWD" bash tests/test_render_agents_md.sh
REPO_ROOT="$PWD" bash tests/test_install.sh
REPO_ROOT="$PWD" bash tests/test_install_prime.sh
```

Expected: all three exit 0.

- [ ] **Step 9: Run the full test suite**

Run: `REPO_ROOT="$PWD" bash tests/run.sh`

Expected: all test scripts pass. This catches callers such as doctor and uninstall tests that resolve generated instruction paths.

- [ ] **Step 10: Commit**

```bash
git add AGENTS.md scripts/lib.sh scripts/install-opencode.sh scripts/install-prime.sh \
  tests/test_render_agents_md.sh tests/test_install.sh tests/test_install_prime.sh
git commit -m "fix: render provider-pure instructions"
```

## Self-review

- Spec coverage: Task 1 changes the renderer path, dynamic Prime table, dynamic selector example, both provider-selecting installers, and provider-switch regressions.
- Placeholder scan: no unfinished implementation markers are present.
- Type consistency: every renderer caller uses `render_agents_md <harness> <provider>` and every expected path uses `rendered_agents_md <harness> <provider>`.
