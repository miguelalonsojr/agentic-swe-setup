# Subagent Dispatch Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the three dispatch lessons from `subagents-2026-08-08.md` as two harness-neutral skills and a `cross-checker` role, and repair the Prime Agent rendering defect that hides the model ladder at dispatch time.

**Architecture:** Six sequential tasks. Task 1 rewrites the Prime Agent subagent-spec generator to fit a 180-character render cap. Task 2 adds a ninth role across all four ladder files. Task 3 moves routing authority into `AGENTS.md` with a lockstep test. Tasks 4 and 5 add one skill each. Task 6 adds the reporting and documentation that keep the render cap visible.

**Tech Stack:** bash, jq, markdown. Tests are plain bash under `tests/`, auto-discovered by `tests/run.sh`.

Spec: `docs/superpowers/specs/2026-08-08-subagent-dispatch-policy-design.md`

## Global Constraints

- Every generated Prime Agent subagent spec `content` must be at most **180** characters. This is `DEFAULT_OVERVIEW_CONTENT_LIMIT` in Prime Agent's `dist/core/refinement/refinement.js:14` and cannot be raised by an installer.
- Every `hint` field in `prime/<provider>.json` must be at most **93** characters. One limit for both providers.
- Prime Agent renders at most **6** subagent entries per kind (`DEFAULT_OVERVIEW_ENTRY_LIMIT`, `refinement.js:12`). Nine roles will be installed. The `AGENTS.md` table, not the roster, is the complete list.
- `rlm()` accepts exactly the keywords `name` and `model`. Never write a `thinking` argument into any generated spec, skill, or doc.
- The OpenCode and Prime Agent ladders must name the same model for the same role. `tests/test_prime_configs.sh` enforces this.
- The anthropic ladder must continue to use exactly three distinct models.
- Run the full suite with `bash tests/run.sh` from the repo root. All test files must pass before any commit.
- Test files are discovered by glob (`tests/test_*.sh`). A new test file needs no registration.

---

### Task 1: Fit the Prime Agent spec generator inside the render cap

**Files:**
- Modify: `prime/anthropic.json` (add `hint` to all 8 existing roles)
- Modify: `prime/openai.json` (add `hint` to all 8 existing roles)
- Modify: `scripts/merge-prime.sh:75-95` (the `spec` jq function)
- Test: `tests/test_prime_configs.sh`, `tests/test_install_prime.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: a `hint` string field on every object under `.agent` in both `prime/*.json` files, and a generated `entries.subagent.<id>.content` of the form
  `await rlm(task, name="<role>", model="<selector>")[ | read-only] | <hint>`.
  Task 2 adds a ninth role that must follow the same shape.

- [ ] **Step 1: Load the craft skill**

Load the `clean-coding` skill. Apply its guidance on naming and on comments that explain why rather than what when you edit `merge-prime.sh`.

- [ ] **Step 2: Write the failing config test**

Add this loop to `tests/test_prime_configs.sh`, immediately after the existing `desc=` check inside the `for a in "${PRIME_AGENTS[@]}"` loop:

```bash
        # Prime Agent truncates a spec's content at 180 chars, so the spec
        # text cannot reuse the long OpenCode description. `hint` is the
        # short form written for that budget.
        hint=$(jq -r --arg a "$a" '.agent[$a].hint // ""' "$f")
        [ -n "$hint" ] || fail "$p prime agent $a has no hint"
        [ "${#hint}" -le 93 ] || \
            fail "$p prime agent $a hint is ${#hint} chars; the budget is 93"
```

- [ ] **Step 3: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A2 test_prime_configs`
Expected: FAILED, with 16 lines reading `FAIL: anthropic prime agent <role> has no hint` and the same for openai.

- [ ] **Step 4: Add the hint fields**

Add this `hint` key to each role object in **both** `prime/anthropic.json` and `prime/openai.json`. The text is identical across providers; only the model differs.

```
general              "primary agent for general coding and research work"
explore              "fast read-only exploration, enumeration, and lookups; the cheap tier for list-shaped work"
implementer-light    "one mechanical fully-specified task, 1-2 files; not for multi-file work or judgment"
implementer          "default implementer: multi-file, integration, debugging; writes tests per TDD"
implementer-strong   "escalation for BLOCKED tasks, fix round 4+, or tasks needing design judgment"
reviewer             "per-task spec + code-quality review of diffs; not the final review"
reviewer-final       "final whole-branch review before merge, after every per-task review has passed"
reviewer-lite        "scoped re-review of a small fix diff, after a full review passed"
```

- [ ] **Step 5: Run the config test to verify it passes**

Run: `bash tests/run.sh 2>&1 | grep -A2 test_prime_configs`
Expected: `ok`

- [ ] **Step 6: Write the failing installer test**

Add this block to `tests/test_install_prime.sh`, directly after the existing `for a in "${PRIME_AGENTS[@]}"` loop that checks `metadata.model`:

```bash
# Prime Agent renders a spec's content through compactText() at 180 chars
# (refinement.js:14). Before this was fixed, all eight specs overran and the
# truncated tail was always the dispatch form, so the roster named roles
# without showing a usable dispatch for any of them.
for a in "${PRIME_AGENTS[@]}"; do
    key=${a//-/_}
    content=$(jq -r --arg k "$key" '.entries.subagent[$k].content' "$HARNESS")
    [ "${#content}" -le 180 ] || \
        fail "spec $a content is ${#content} chars; the render cap is 180"

    # The dispatch form leads, so truncation can only ever cost the hint.
    model=$(jq -r --arg a "$a" '.agent[$a].model' "$REPO_ROOT/prime/anthropic.json")
    want="await rlm(task, name=\"$a\", model=\"$model\")"
    case "$content" in
        "$want"*) ;;
        *) fail "spec $a does not lead with its dispatch form: [$content]" ;;
    esac

    # rlm() takes only name and model (agent-session.js:7768); a child's
    # thinking level is inherited from the parent session and clamped.
    assert_not_contains "$content" "Thinking:" \
        "spec $a claims a thinking level no dispatch can set"
done
```

- [ ] **Step 7: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A6 test_install_prime`
Expected: FAILED, with `spec general content is 200 chars; the render cap is 180` and seven similar lines, plus eight `does not lead with its dispatch form` failures.

- [ ] **Step 8: Rewrite the generator**

In `scripts/merge-prime.sh`, replace the `content:` expression inside the `def spec($name; $cfg):` block. The current version is:

```jq
          content: (
            "Role: " + $name + "\n"
            + "Model: " + $cfg.model + "\n"
            + "Thinking: " + $cfg.thinking + "\n"
            + (if $cfg.readOnly then "Read-only: never edit files; report findings only.\n" else "" end)
            + "\n" + $cfg.description + "\n\n"
            + "Dispatch with:\n"
            + "    handle = await rlm(task, name=\"" + $name + "\", model=\"" + $cfg.model + "\")\n"
          ),
```

Replace it with:

```jq
          # Prime Agent truncates this at 180 chars and shows only six specs
          # per kind (refinement.js:12,14), neither of which an installer can
          # raise. So the dispatch form leads: truncation can then only cost
          # the hint, never the call an agent needs to make. The role name is
          # already printed from `title`, the selector is already in the
          # dispatch form, and rlm() cannot be passed a thinking level, so
          # none of those are repeated here.
          content: (
            "await rlm(task, name=\"" + $name + "\", model=\"" + $cfg.model + "\")"
            + (if $cfg.readOnly then " | read-only" else "" end)
            + " | " + $cfg.hint
          ),
```

Leave every other key in the `spec` function unchanged, including `metadata.thinking`, which records the tier for `settings.json` and is not a claim about a dispatch argument.

- [ ] **Step 9: Run the installer test to verify it passes**

Run: `bash tests/run.sh 2>&1 | grep -A2 test_install_prime`
Expected: `ok`

- [ ] **Step 10: Verify the whole suite is green**

Run: `bash tests/run.sh`
Expected: `11/11 test files passed`

- [ ] **Step 11: Commit**

```bash
git add prime/anthropic.json prime/openai.json scripts/merge-prime.sh \
        tests/test_prime_configs.sh tests/test_install_prime.sh
git commit -m "fix: fit Prime Agent subagent specs inside the 180-char render cap"
```

---

### Task 2: Add the cross-checker role

**Files:**
- Modify: `scripts/lib.sh:16-17` (`MANAGED_AGENTS`, `CLAUDE_AGENTS`)
- Create: `agents/cross-checker.md`
- Modify: `opencode/anthropic.json`, `opencode/openai.json`
- Modify: `prime/anthropic.json`, `prime/openai.json`
- Test: `tests/test_agents.sh`, `tests/test_provider_configs.sh`

**Interfaces:**
- Consumes: the `hint` field contract from Task 1.
- Produces: the role name `cross-checker` in `MANAGED_AGENTS` and `CLAUDE_AGENTS`. Task 3's `AGENTS.md` table iterates `PRIME_AGENTS` and will include it. Task 5's skill dispatches to it by name.

- [ ] **Step 1: Load the craft skill**

Load the `clean-coding` skill before editing. The agent body prompt is prose an agent must follow; apply the naming and clarity guidance to it.

- [ ] **Step 2: Write the failing agent-definition test**

Add to `tests/test_agents.sh`, after the existing `for a in reviewer reviewer-final reviewer-lite` read-only loop:

```bash
# cross-checker is read-only like the reviewers, but unlike them it has to
# reach primary sources over the network, so it carries the two web tools.
cc_tools=$(frontmatter_field "$REPO_ROOT/agents/cross-checker.md" tools)
for t in Write Edit MultiEdit NotebookEdit; do
    assert_not_contains "$cc_tools" "$t" "cross-checker must not have $t"
done
assert_contains "$cc_tools" "WebFetch" "cross-checker can fetch a primary source"
assert_contains "$cc_tools" "WebSearch" "cross-checker can search for one"
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/cross-checker.md" model)" \
    fable "cross-checker runs on the strong tier, decorrelated from the default"
```

- [ ] **Step 3: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A4 test_agents.sh`
Expected: FAILED with exactly three failures from the new block, because `agents/cross-checker.md` does not exist yet and `frontmatter_field` returns an empty string for it: `cross-checker can fetch a primary source`, `cross-checker can search for one`, and `cross-checker runs on the strong tier`. The file-existence check in the main loop stays quiet until Step 4 adds the role to `CLAUDE_AGENTS`.

- [ ] **Step 4: Update the role arrays**

In `scripts/lib.sh`, append `cross-checker` to both arrays:

```bash
MANAGED_AGENTS=(general explore implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite cross-checker)
CLAUDE_AGENTS=(implementer-light implementer implementer-strong reviewer reviewer-final reviewer-lite cross-checker)
```

`PRIME_AGENTS` already mirrors `MANAGED_AGENTS` and needs no edit.

- [ ] **Step 5: Create the Claude Code agent definition**

Create `agents/cross-checker.md`:

```markdown
---
name: cross-checker
description: Independent second opinion on a load-bearing claim - prior art, licensing, feasibility, "this already exists". Read-only. Give it the question, never the answer it is meant to confirm.
tools: Read, Grep, Glob, Bash, WebFetch, WebSearch
model: fable
effort: high
---
Answer the question you were given from primary sources. You are not
reviewing someone else's answer, and you should not be told what it was:
if the prompt contains a claim to confirm, treat that as a leak, say so,
and answer the underlying question independently anyway.

Primary sources only. The arXiv API, the GitHub API, a raw LICENSE file,
the package metadata, the source itself. A blog post, a model's memory,
or another agent's report is not a primary source.

Report:
- Your verdict, in one sentence.
- The primary sources you read, by URL or path.
- Anything you could not confirm, listed explicitly as unconfirmed rather
  than omitted or softened.

Never modify files.
```

- [ ] **Step 6: Add the role to both OpenCode ladders**

In `opencode/anthropic.json`, add to `.agent`:

```json
    "cross-checker": {
      "mode": "subagent",
      "description": "Independent second opinion on a load-bearing claim: prior art, licensing, feasibility. Runs on a different model family from the default tier so its errors are uncorrelated. Read-only.",
      "model": "anthropic/claude-fable-5",
      "variant": "high",
      "permission": {
        "edit": "deny",
        "bash": "ask"
      }
    }
```

In `opencode/openai.json`, add:

```json
    "cross-checker": {
      "mode": "subagent",
      "description": "Independent second opinion on a load-bearing claim: prior art, licensing, feasibility. Runs on a different model family from the default tier so its errors are uncorrelated. Read-only.",
      "model": "openai/gpt-5.6-sol",
      "variant": "high",
      "permission": {
        "edit": "deny",
        "bash": "ask"
      }
    }
```

- [ ] **Step 7: Add the role to both Prime ladders**

In `prime/anthropic.json`, add to `.agent`:

```json
    "cross-checker": {
      "mode": "subagent",
      "description": "Independent second opinion on a load-bearing claim: prior art, licensing, feasibility. Runs on a different model family from the default tier so its errors are uncorrelated. Read-only.",
      "hint": "independent second opinion on a load-bearing claim; give it the question, not the answer",
      "model": "anthropic/claude-fable-5",
      "thinking": "high",
      "readOnly": true
    }
```

In `prime/openai.json`, add:

```json
    "cross-checker": {
      "mode": "subagent",
      "description": "Independent second opinion on a load-bearing claim: prior art, licensing, feasibility. Runs on a different model family from the default tier so its errors are uncorrelated. Read-only.",
      "hint": "independent second opinion on a load-bearing claim; give it the question, not the answer",
      "model": "openai/gpt-5.6-sol",
      "thinking": "high",
      "readOnly": true
    }
```

- [ ] **Step 8: Extend the OpenCode read-only assertions**

In `tests/test_provider_configs.sh`, change the reviewer permission loop to include the new role:

```bash
    # Reviewers and the cross-checker are read-only.
    for a in reviewer reviewer-final reviewer-lite cross-checker; do
```

- [ ] **Step 9: Extend the Prime read-only assertions**

In `tests/test_prime_configs.sh`, change the two read-only loops to include the new role:

```bash
    for a in reviewer reviewer-final reviewer-lite cross-checker; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].readOnly' "$f")" "true" \
            "$p prime agent $a is read-only"
    done
```

and add `cross-checker` to the subagent-mode loop:

```bash
    for a in implementer-light implementer implementer-strong \
             reviewer reviewer-final reviewer-lite cross-checker; do
```

- [ ] **Step 10: Run the full suite**

Run: `bash tests/run.sh`
Expected: `11/11 test files passed`. The `exactly three models` assertion still holds because `cross-checker` reuses `claude-fable-5`. The `agent count` assertions now compare against 9.

- [ ] **Step 11: Verify the generated spec still fits**

Run:
```bash
bash -c 'REPO_ROOT=$PWD bash tests/test_install_prime.sh' 2>&1 | tail -5
```
Expected: no `render cap` failures. The `cross-checker` spec renders at 174 characters on anthropic, the longest of the nine.

- [ ] **Step 12: Commit**

```bash
git add scripts/lib.sh agents/cross-checker.md \
        opencode/anthropic.json opencode/openai.json \
        prime/anthropic.json prime/openai.json \
        tests/test_agents.sh tests/test_provider_configs.sh tests/test_prime_configs.sh
git commit -m "feat: add the cross-checker role for decorrelating load-bearing claims"
```

---

### Task 3: Move routing authority into AGENTS.md

**Files:**
- Modify: `AGENTS.md:95-122` (the `#### When running under Prime Agent` section)
- Create: `tests/test_agents_md.sh`

**Interfaces:**
- Consumes: the nine role names in `PRIME_AGENTS` and the models in `prime/anthropic.json`.
- Produces: a markdown table in `AGENTS.md` whose rows are `| \`<role>\` | \`<model>\` |`. Task 6 adds two more bullets to the same file in a different section.

- [ ] **Step 1: Load the craft skills**

Load `clean-coding` for the test script, and `de-slop` before writing the `AGENTS.md` prose. This file is read by humans and by three agent harnesses.

- [ ] **Step 2: Write the failing lockstep test**

Create `tests/test_agents_md.sh`:

```bash
#!/usr/bin/env bash
# The Prime Agent routing table in AGENTS.md is the authoritative role-to-model
# map, because Prime Agent renders its subagent roster through a 180-char
# summary and shows only six entries. A hand-maintained table can drift from
# the ladder it describes, so this test is the whole mitigation.
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

A="$REPO_ROOT/AGENTS.md"
L="$REPO_ROOT/prime/anthropic.json"
assert_file "$A" "AGENTS.md exists"
body=$(cat "$A")

# Every managed role appears with the selector the ladder gives it.
for a in "${PRIME_AGENTS[@]}"; do
    model=$(jq -r --arg a "$a" '.agent[$a].model' "$L")
    assert_contains "$body" "| \`$a\` | \`$model\` |" \
        "AGENTS.md routing table has the row for $a"
done

# No stale rows for roles that no longer exist.
rows=$(grep -c '^| `[a-z-]\+` | `anthropic/' "$A")
assert_eq "$rows" "${#PRIME_AGENTS[@]}" \
    "AGENTS.md routing table has exactly one row per managed role"

# The instruction this table replaces sent the agent to a truncated roster.
assert_not_contains "$body" "Look the role up in" \
    "the old rlm.harness roster lookup is gone"

# The render limits must be stated, or the table looks like duplication.
assert_contains "$body" "180" "AGENTS.md states the content render cap"
assert_contains "$body" "six" "AGENTS.md states the entry render cap"

# Prime Agent's selector format must be named as Prime's, so a Claude Code
# session reading the wrong subsection does not copy it into a Task dispatch.
assert_contains "$body" 'rlm(model=' "AGENTS.md names the selector format"

exit "$ASSERT_FAILURES"
```

- [ ] **Step 3: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A12 test_agents_md`
Expected: FAILED, with nine `routing table has the row for <role>` failures and `expected [9], got [0]`.

- [ ] **Step 4: Replace the roster-lookup instruction**

In `AGENTS.md`, inside `#### When running under Prime Agent`, delete this bullet and its code block:

```markdown
- Look the role up in `rlm.harness` (kind `subagent`, ids use
  underscores: `implementer_light`, `reviewer_final`). Each spec records
  the model and thinking level for its tier.
- Dispatch with the model from the spec, never the inherited default:

  ```python
  handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5")
  ```
```

The table rows must sit at column 0: `tests/test_agents_md.sh` anchors its
row match with `^|`, and a column-0 table also ends the lead-in paragraph
cleanly instead of orphaning the note that follows it. Replace the deleted
bullet with the following, copied byte-for-byte into `AGENTS.md`:

```markdown
The harness roster is a hint, not a lookup. Prime Agent summarises each
subagent spec to 180 characters and shows only six of them, so some roles
are missing from it and none of the entries shows a complete dispatch. This
table is authoritative. The model strings are Prime Agent `rlm(model=...)`
selectors and are not valid anywhere else.

| Role | Model |
|---|---|
| `implementer-light` | `anthropic/claude-sonnet-5` |
| `implementer` | `anthropic/claude-opus-5` |
| `implementer-strong` | `anthropic/claude-fable-5` |
| `reviewer` | `anthropic/claude-opus-5` |
| `reviewer-final` | `anthropic/claude-fable-5` |
| `reviewer-lite` | `anthropic/claude-sonnet-5` |
| `cross-checker` | `anthropic/claude-fable-5` |
| `explore` | `anthropic/claude-sonnet-5` |
| `general` | `anthropic/claude-opus-5` |

If you installed with `provider=openai`, the selectors are the ones in
`prime/openai.json`.

- Dispatch with the model from the table, never the one you are running on:

  ```python
  handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5")
  ```

- `rlm()` accepts `name` and `model` and nothing else. A child's thinking
  level is inherited from this session and clamped to the child's model, so
  there is no per-dispatch thinking argument to pass.
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bash tests/run.sh 2>&1 | grep -A2 test_agents_md`
Expected: `ok`

- [ ] **Step 6: Run the full suite**

Run: `bash tests/run.sh`
Expected: `12/12 test files passed`

- [ ] **Step 7: Commit**

```bash
git add AGENTS.md tests/test_agents_md.sh
git commit -m "fix: make the AGENTS.md table the authoritative Prime Agent routing map"
```

---

### Task 4: Add the routing-model-tiers skill

**Files:**
- Create: `skills/routing-model-tiers/SKILL.md`
- Create: `skills/routing-model-tiers/README.md`
- Modify: `scripts/lib.sh` (`LOCAL_SKILLS`)
- Test: `tests/test_local_skills.sh`

**Interfaces:**
- Consumes: the role names from Task 2.
- Produces: the skill name `routing-model-tiers` in `LOCAL_SKILLS`. Task 6 names it in `AGENTS.md` and `README.md`.

- [ ] **Step 1: Load the craft skills**

Load the `writing-skills` skill first, since it governs skill structure and the description-trigger format. Then load `de-slop` and apply it to the finished prose before committing.

- [ ] **Step 2: Write the failing test**

Add to `tests/test_local_skills.sh`, after the existing per-skill loop:

```bash
# The dispatch-policy skills are only correct if they carry the specific
# facts that make them correct. A skill that says "pick a good model" is
# the advice that already failed.
r=$(cat "$REPO_ROOT/skills/routing-model-tiers/SKILL.md")
assert_contains "$r" "rlm.find_models" "routing skill names the model-menu call"
assert_contains "$r" 'accepts `name` and `model`' "routing skill names the rlm keywords"
assert_contains "$r" "clamped" "routing skill states how thinking level is set"
```

- [ ] **Step 3: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A6 test_local_skills`
Expected: FAILED, with `expected a file: .../skills/routing-model-tiers/SKILL.md` once `LOCAL_SKILLS` is updated.

- [ ] **Step 4: Register the skill**

In `scripts/lib.sh`:

```bash
LOCAL_SKILLS=(jira-fu routing-model-tiers)
```

- [ ] **Step 5: Write the skill**

Create `skills/routing-model-tiers/SKILL.md` with this exact frontmatter:

```markdown
---
name: routing-model-tiers
description: Use when about to dispatch one or more subagents, especially a batch, before choosing which model each one runs on. Covers routing task types to model tiers, discovering the real model menu, and the per-harness dispatch mechanics.
---
```

The body must contain these sections, in this order, and these specific contents:

1. `## Overview` — the core principle stated once: the model is a per-task decision, not a session default. Name the failure it prevents: seven dispatches inheriting one role spec's model, with frontier budget spent on cataloguing licences and pulling version pins.

2. `## The Routing Test` — a decision table. Left column, what the task produces. Right column, the tier.
   - Produces a list: cataloguing licences, pulling version pins, listing a repository's contents, extracting an interface, reading files to answer a factual question. Light tier.
   - Produces a verdict: synthesis across sources, feasibility calls, trade-off judgements, design decisions, anything whose answer changes the plan. Default or strong tier.
   - Include the rule that a task producing a list of things it then has to judge is two tasks.

3. `## The Menu Is Bigger Than The Roster` — `await rlm.find_models("", limit=20)` returned 13 selectors in the environment this skill was written for, while the installed ladder names three. State that the role roster is not the model menu, and that `limit` is capped at 20.

4. `## Dispatch Mechanics By Harness` — three subsections.
   - Prime Agent: `handle = await rlm(task, name="reviewer", model="anthropic/claude-opus-5")`. State that `rlm()` accepts `name` and `model` and nothing else, and raises `Unsupported rlm.run kwargs` on anything else. State that the child's thinking level is inherited from the parent session and clamped to the child model, so it cannot be set per dispatch. Point at the `AGENTS.md` table as the role-to-model map and say why the harness roster is not it.
   - Claude Code: pass a model per dispatch, per the skill's native guidance.
   - OpenCode: the model is fixed by the agent definition; do not pass one.

5. `## Red Flags` — a two-column rationalisation table with at least these rows:
   - "I'll use the model I'm already on" -> that is a default, not a decision.
   - "It's all one research batch" -> a batch is many tasks, and they are not the same shape.
   - "The strong model is the safe choice" -> for enumeration it buys nothing and costs the budget you need for the judgement calls later.
   - "The spec names a model, so that's the model" -> the spec names the tier's model, for that role, not for the task you are dispatching now.

Do not include a `thinking` argument in any example.

- [ ] **Step 6: Write the human-facing README**

Create `skills/routing-model-tiers/README.md`. It explains where the skill came from: the 2026-08-08 session recorded in `subagents-2026-08-08.md`, in which all seven children ran on `anthropic/claude-opus-5` and the `explore` role, which exists for exactly this, was never used. Keep it under 40 lines. There is nothing to run by hand; say so.

- [ ] **Step 7: Run the tests**

Run: `bash tests/run.sh`
Expected: `12/12 test files passed`

- [ ] **Step 8: Verify the skill installs**

Run:
```bash
grep -n 'routing-model-tiers' scripts/lib.sh
bash -c 'REPO_ROOT=$PWD bash tests/test_local_skills.sh' 2>&1 | tail -3
```
Expected: the name appears in `LOCAL_SKILLS`, and the test file exits 0.

- [ ] **Step 9: Commit**

```bash
git add skills/routing-model-tiers scripts/lib.sh tests/test_local_skills.sh
git commit -m "feat: add the routing-model-tiers skill"
```

---

### Task 5: Add the cross-checking-claims skill

**Files:**
- Create: `skills/cross-checking-claims/SKILL.md`
- Create: `skills/cross-checking-claims/README.md`
- Modify: `scripts/lib.sh` (`LOCAL_SKILLS`)
- Test: `tests/test_local_skills.sh`

**Interfaces:**
- Consumes: the `cross-checker` role name from Task 2, and `routing-model-tiers` from Task 4 for the cross-reference.
- Produces: the skill name `cross-checking-claims` in `LOCAL_SKILLS`.

- [ ] **Step 1: Load the craft skills**

Load `writing-skills`, then `de-slop` before finalising the prose.

- [ ] **Step 2: Write the failing test**

Add to `tests/test_local_skills.sh`, below the `routing-model-tiers` assertions:

```bash
c=$(cat "$REPO_ROOT/skills/cross-checking-claims/SKILL.md")
assert_contains "$c" "cross-checker" "cross-check skill names its dispatch target"
assert_contains "$c" "primary source" "cross-check skill requires a primary source"
assert_contains "$c" "verification-before-completion" \
    "cross-check skill draws its boundary with the verification skill"
```

- [ ] **Step 3: Run it to make sure it fails**

Run: `bash tests/run.sh 2>&1 | grep -A6 test_local_skills`
Expected: FAILED, with `expected a file: .../skills/cross-checking-claims/SKILL.md`.

- [ ] **Step 4: Register the skill**

In `scripts/lib.sh`:

```bash
LOCAL_SKILLS=(jira-fu routing-model-tiers cross-checking-claims)
```

- [ ] **Step 4b: Add the README row this registration requires**

`tests/test_readme.sh:34-36` asserts that `README.md` names every entry in `LOCAL_SKILLS`, so
Step 4 turns the suite red on its own. Add one row to the "Skills this repo ships" table, below
the `routing-model-tiers` row that Task 4 added:

```markdown
| `cross-checking-claims` | A subagent's finding is about to change a decision and needs an independent check and a primary source. |
```

Change nothing else in `README.md`. The role counts and the ladder tables are Task 6's.

- [ ] **Step 5: Write the skill**

Create `skills/cross-checking-claims/SKILL.md` with this exact frontmatter:

```markdown
---
name: cross-checking-claims
description: Use when a subagent's finding is about to change a decision - prior art, licensing, feasibility, "this already exists" - before it is written into a design doc, plan, or decision log. Covers decorrelating agents and grounding claims in primary sources.
---
```

The body must contain these sections, in this order, and these specific contents:

1. `## Overview` — the core principle: correlated agents agree, and agreement is not evidence. State the observed signature from the source session: several children independently reported that their priors about the field were stale, which is one model's blind spot reported seven times rather than seven independent checks.

2. `## The Load-Bearing Test` — this skill is expensive and must not fire on everything. The gate: would a different answer change what gets built, bought, or skipped? If not, stop. Give examples that pass the gate (prior art, licence terms, hardware feasibility, "this library already does it") and examples that fail it (a function signature, a version number you can read).

3. `## Step 1: Decorrelate` — re-dispatch on a different model family or version. Dispatch to the `cross-checker` role. State the anchoring rule explicitly: give it the question, not the original answer, because an agent shown a claim tends to confirm it. State the residual case: if the original claim came from the model `cross-checker` names, pick another selector from `rlm.find_models()`. Cross-reference `routing-model-tiers` for the dispatch mechanics rather than repeating them.

4. `## Step 2: Ground` — a surviving claim is checked against a primary source. What counts: the arXiv API, the GitHub API, a raw `LICENSE` file, package metadata, the source itself. What does not: a blog post, a model's recollection, another agent's report, or two models agreeing. Include the worked example from the source session: a repository reported as Apache-2.0 that is in fact dual-licensed, caught by reading the licence files.

5. `## Disagreement Is The Signal` — when the two verdicts differ, that is the process working. Go to primary sources; do not average the answers or take the more confident one.

6. `## Unconfirmed Stays Unconfirmed` — a claim that survives neither step is written into the document flagged as unconfirmed, not omitted and not softened. The source session's unverified PULSE ablation reference is the example.

7. `## Boundary With verification-before-completion` — that skill verifies your own claims by running commands. This one verifies a subagent's claims about the world. Say which to reach for and do not restate the other's content.

- [ ] **Step 6: Write the human-facing README**

Create `skills/cross-checking-claims/README.md`. Explain the provenance: in the 2026-08-08 session, both errors that surfaced were caught by re-fetching primary sources in the main thread, not by one child contradicting another, and that check happened by reflex rather than by process. Keep it under 40 lines. Nothing to run by hand.

- [ ] **Step 7: Run the tests**

Run: `bash tests/run.sh`
Expected: `12/12 test files passed`

- [ ] **Step 8: Commit**

```bash
git add skills/cross-checking-claims scripts/lib.sh tests/test_local_skills.sh
git commit -m "feat: add the cross-checking-claims skill"
```

---

### Task 6: Report the render ceiling and document the change

**Files:**
- Modify: `scripts/doctor.sh` (the Prime Agent section, after the `PRIME_AGENTS` loop)
- Modify: `AGENTS.md` (the `### Subagent-driven development routing` section)
- Modify: `README.md`
- Modify: `tests/test_agents_md.sh` (created in Task 3)
- Test: `tests/test_readme.sh`, `tests/test_doctor.sh`, `tests/test_agents_md.sh`

**Interfaces:**
- Consumes: everything from Tasks 1 through 5.
- Produces: nothing later tasks depend on. This is the last task.

- [ ] **Step 1: Load the craft skills**

Load `clean-coding` for `doctor.sh`, and `de-slop` for the README and `AGENTS.md` prose.

- [ ] **Step 2: Write the failing README test**

Add to `tests/test_readme.sh`, before the final `exit`:

```bash
# The Prime Agent render ceiling is the reason the AGENTS.md table exists.
# A reader who does not know about it will think the table is duplication.
assert_contains "$body" "180" "README states the content render cap"
assert_contains "$body" "cross-checker" "README documents the cross-checker role"

# Role counts in prose drift silently: five of them were already wrong
# before cross-checker was added. Derive every count from the arrays that
# define it, so the next role added breaks a test instead of a sentence.
. "$REPO_ROOT/scripts/lib.sh"
assert_contains "$body" "Claude Code gets ${#CLAUDE_AGENTS[@]} subagents" \
    "README states the Claude Code subagent count"
assert_contains "$body" "receive all ${#MANAGED_AGENTS[@]}" \
    "README states the OpenCode and Prime subagent count"
assert_contains "$body" "for the ${#MANAGED_AGENTS[@]} managed agent names" \
    "README states the managed agent count for the OpenCode merge"
assert_contains "$body" "for the ${#PRIME_AGENTS[@]} managed roles" \
    "README states the managed role count for the Prime merge"
assert_contains "$body" "removes the ${#CLAUDE_AGENTS[@]} agent symlinks" \
    "README states how many agent symlinks uninstall removes"
assert_contains "$body" "${#SKILL_NAMES[@]} book-grounded" \
    "README states the book-skill count"
```

- [ ] **Step 3: Write the failing doctor test**

Add to `tests/test_doctor.sh`, next to the existing `subagent spec reviewer-final` assertion in the fully-installed section. That section already runs `stub_cmd prime-agent` and a real `install-prime.sh`, so no new setup is needed:

```bash
# Nine specs against a six-entry render limit: doctor must say so rather
# than let the overflow stay invisible, which is how it went unnoticed.
assert_contains "$out" "Prime Agent renders 6" \
    "doctor reports the subagent render limit"
```

- [ ] **Step 3b: Write the failing AGENTS.md role-list test**

Add to `tests/test_agents_md.sh`, before the final `exit`:

```bash
# AGENTS.md used to open this section with a hard-coded role count that
# nothing checked. A list can be verified against the array; a numeral in
# prose cannot, so the numeral is gone and the list is what gets asserted.
roles=$(awk '/defined in all three harnesses:/,/subagent-driven-development:/' "$A")
for a in "${CLAUDE_AGENTS[@]}"; do
    assert_contains "$roles" "$a" "AGENTS.md role list names $a"
done
assert_not_contains "$body" "Six role agents" "the stale role count is gone"
assert_not_contains "$body" "The same six roles" "the stale Prime role count is gone"
```

- [ ] **Step 4: Run all three to make sure they fail**

Run: `bash tests/run.sh 2>&1 | grep -B1 -A12 'test_readme\|test_doctor\|test_agents_md'`
Expected: FAILED in all three. `test_readme.sh` reports `[180] not found` plus six count failures; `test_doctor.sh` reports `[Prime Agent renders 6] not found`; `test_agents_md.sh` reports seven `role list names` failures and two stale-count failures.

- [ ] **Step 5: Add the doctor line**

In `scripts/doctor.sh`, immediately after the `for a in "${PRIME_AGENTS[@]}"` loop closes:

```bash
    # Prime Agent renders at most six subagent specs per kind into the system
    # prompt (refinement.js DEFAULT_OVERVIEW_ENTRY_LIMIT), so a ladder larger
    # than six is partly invisible there. Report the shortfall rather than
    # leaving it to be discovered.
    ok "${#PRIME_AGENTS[@]} managed subagent specs (Prime Agent renders 6; AGENTS.md table is authoritative)"
```

- [ ] **Step 6: Fix the role counts in AGENTS.md**

Two statements name a role count that nothing checks, and both are wrong. Delete the numerals rather than maintain them.

`AGENTS.md:61`, currently:

```markdown
Six role agents are defined in all three harnesses under the same
names: implementer-light, implementer, implementer-strong, reviewer,
reviewer-final, reviewer-lite. When executing superpowers
subagent-driven-development:
```

becomes:

```markdown
The same role agents are defined in all three harnesses:
implementer-light, implementer, implementer-strong, reviewer,
reviewer-final, reviewer-lite, cross-checker. When executing superpowers
subagent-driven-development:
```

`AGENTS.md:97`, currently "Prime Agent has no agent-definition files. The same six roles are installed as continual-harness subagent specs", becomes "Prime Agent has no agent-definition files. The same roles are installed as continual-harness subagent specs". `PRIME_AGENTS` has held eight roles since Prime Agent was added, so "six" was already wrong.

While in that section, add `cross-checker` to the routing bullet list:

```markdown
- A load-bearing claim that needs an independent check goes to
  `cross-checker`, on a different model family from whatever produced it.
```

- [ ] **Step 6b: Name the skills in AGENTS.md**

In `AGENTS.md`, in `### Subagent-driven development routing`, add these two bullets to the harness-neutral list before the per-harness subsections:

```markdown
- Before dispatching a batch of subagents, load the `routing-model-tiers`
  skill and pick a tier per task. Enumeration and lookup go to the light
  tier; synthesis and judgement go to the default or strong tier.
- Before a subagent's finding goes into a design doc, plan, or decision
  log, load the `cross-checking-claims` skill. It applies only to claims
  that would change the work if they were wrong.
```

- [ ] **Step 7: Update the README**

Five edits.

First, correct every role count. All five statements below are wrong today, before `cross-checker`; use digits so the test can derive them from the arrays.

| Line | Currently | Becomes |
|---|---|---|
| 62 | `Claude Code gets five subagents.` | `Claude Code gets 7 subagents.` |
| 63 | `only OpenCode and Prime Agent receive all seven.` | `only OpenCode and Prime Agent receive all 9.` |
| 208 | ``- `agent.*` for the seven managed agent names.`` | ``- `agent.*` for the 9 managed agent names.`` |
| 230 | `only `entries.subagent.*` for the eight managed roles` | `only `entries.subagent.*` for the 9 managed roles` |
| 245 | `It removes the five agent symlinks` | `It removes the 7 agent symlinks` |

Line 4 says "the eight book-grounded swe-skills", which is correct; change it to "the 8 book-grounded swe-skills" so the same test can hold it in place.

Then two content edits.

The two skill-table rows and the correction to the sentence below that table ("a `README.md`
for running it by hand", false once a script-less skill is listed) already landed in Tasks 4
and 5, because `tests/test_readme.sh:34-36` forces a skill's README row into the same task that
registers it. Verify both rows and the corrected sentence are present, and move on. Do not add
them again.

Add `cross-checker` to the three model-ladder tables (`opencode/anthropic.json`, `opencode/openai.json`, Claude Code frontmatter) with the strong-tier model, and note that it sits on the strong tier to stay decorrelated from the default tier rather than because the work is hard.

Extend "Why Prime Agent is different" with a third bullet:

```markdown
- **Role specs are summarised.** Prime Agent renders each harness entry to
  180 characters and shows six per kind, and neither limit is settable. Nine
  roles are installed, so the roster is incomplete by construction. Each spec
  leads with its dispatch form so truncation costs only the description, and
  the full role-to-model map lives in `AGENTS.md`.
```

- [ ] **Step 8: Run the full suite**

Run: `bash tests/run.sh`
Expected: `12/12 test files passed`

- [ ] **Step 9: Verify the installer end to end**

Run:
```bash
bash -c 'REPO_ROOT=$PWD bash tests/test_install_prime.sh' && echo "install-prime clean"
```
Expected: exit 0 and `install-prime clean`.

- [ ] **Step 10: Commit**

```bash
git add scripts/doctor.sh AGENTS.md README.md tests/test_readme.sh tests/test_doctor.sh
git commit -m "docs: document the dispatch policy, the new role, and the render ceiling"
```

---

## Verification

After Task 6, confirm the whole change against the spec:

```bash
bash tests/run.sh
```
Expected: `12/12 test files passed`.

Then confirm the defect this plan exists to fix is actually gone, by measuring the installed specs the way Prime Agent measures them:

```bash
jq -r '.entries.subagent | to_entries[] | "\(.value.content | length)\t\(.key)"' \
   "${PRIME_AGENT_CODING_AGENT_DIR:-$HOME/.prime/agent}/harness/harness_state.json" \
   | sort -rn
```
Expected: every length at or below 180, with `cross_checker` the longest at 174.

Finally, confirm no prose role count has drifted back:

```bash
grep -n -iE '\b(five|six|seven|eight|nine)\b' README.md AGENTS.md
```
Expected: no line that states a role or skill count. Word-form numerals are allowed only where they do not count managed roles.
