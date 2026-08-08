# Subagent dispatch policy — Design

Date: 2026-08-08

## Purpose

`subagents-2026-08-08.md` records a research session in which all seven subagents ran on
`anthropic/claude-opus-5`. The write-up names two mistakes: frontier-model budget spent on
enumeration work, and seven children sharing one model's priors, so their agreement carried
no independent evidence. It also names a third rule that was followed by reflex rather than
by process: verifying load-bearing claims against primary sources.

This design turns those three lessons into installed behaviour. Two new skills carry the
policy to all three harnesses. A new `cross-checker` role gives the decorrelation step a
dispatch target. Changes to `merge-prime.sh` and `AGENTS.md` repair a Prime Agent rendering
defect that made the existing model ladder partly invisible at dispatch time.

## The measured defect

The session write-up treats the tiering failure as a judgement error. It is at least partly
mechanical. Prime Agent renders continual-harness entries into the system prompt through two
hard-coded limits in `dist/core/refinement/refinement.js`:

```js
const DEFAULT_OVERVIEW_ENTRY_LIMIT = 6;   // line 12
const DEFAULT_OVERVIEW_CONTENT_LIMIT = 180; // line 14
```

Both call sites in `dist/core/system-prompt.js` (lines 54 and 82) pass neither option, so
neither limit can be raised from `settings.json` or by any installer.

Three consequences, all reproduced against the `harness_state.json` this repo installs.

Two of the eight managed roles never reach the system prompt. Entries are sorted by
`[path, title, id]` (`refinement.js:319`) and sliced to six. Running that comparator over the
installed specs leaves `reviewer` and `reviewer-lite` in the overflow, replaced by the line
`- +2 more subagent entries`. `reviewer` is the role subagent-driven-development dispatches
twice per task.

Every spec is truncated, and the truncated tail is always the dispatch form. Generated
`content` runs 200–330 characters against a budget of 180. All eight lose the
`Dispatch with: ... model="..."` line, so the roster names roles without showing a working
dispatch for any of them.

The `Thinking:` line the installer writes is false. `rlm()` destructures exactly
`{name, model}` and throws on any other keyword (`dist/core/agent-session.js:7768`). A child's
thinking level is `clampThinkingLevel(childModel, parentSessionLevel)` (line 7172), inherited
from the parent session. The installer spends 15 of its 180 characters asserting something no
dispatch can set, which contributes to the dispatch form falling off the end.

An agent reading that roster sees no usable dispatch form and two missing review roles.
Falling back to the model named in the `general` spec is the predictable outcome.

Claude Code and OpenCode do not have this defect. They read tiers from `agents/*.md`
frontmatter and from `opencode.jsonc` respectively, with no entry cap and no truncation. The
repair below is therefore Prime-specific, while the three policy lessons are not.

## Scope

In scope:

- Two harness-neutral skills under `skills/`, installed into all three harnesses.
- A ninth managed role, `cross-checker`, across all four ladder files and `agents/`.
- A rewritten subagent-spec generator in `merge-prime.sh` that fits the 180-character budget.
- A `hint` field in `prime/<provider>.json` to feed that generator.
- An authoritative role-to-selector table in the Prime Agent section of `AGENTS.md`.
- Tests and a `doctor.sh` line that keep the ceiling visible.

Out of scope:

- Raising Prime Agent's entry or content limits. They are hard-coded and not overridable.
- Generating `AGENTS.md` at install time. It stays a symlink so edits apply without a reinstall.
- Reordering specs by `path` to choose which six are visible. See Non-goals.
- Changing the existing three-model ladder.

## Skills

Both are markdown skills with a `SKILL.md` for agents and a `README.md` for humans, matching
`jira-fu` and the requirement in `tests/test_local_skills.sh`. Both are added to `LOCAL_SKILLS`
in `scripts/lib.sh`, which install, doctor, uninstall and the tests already read from.

They are split because they fire at different moments. A merged skill would be loaded at the
wrong one.

### `routing-model-tiers`

Description trigger: use when about to dispatch one or more subagents, especially a batch,
before choosing a model.

Core principle: the model is a per-task decision, not a session default.

Contents:

- The routing test. Ask whether the task produces a list or a verdict. Cataloguing licences,
  pulling version pins, listing a repository's contents and extracting an interface produce
  lists, and belong on the light tier. Synthesis, feasibility calls and trade-off judgements
  produce verdicts, and belong on the default or strong tier.
- Enumerate the available models before assuming. `await rlm.find_models("", limit=20)`
  returns 13 selectors in this environment; the installed ladder names three. The role roster
  is not the model menu.
- Per-harness dispatch mechanics, including the Prime Agent constraint that `rlm()` accepts
  only `name` and `model`, and that thinking level is inherited from the parent session and
  clamped to the child model, never passed per dispatch.
- A rationalisation table in the Superpowers house style, covering "I will use the model I am
  already on", "this is one research batch so it gets one model", and "the strong model is
  the safe choice".

### `cross-checking-claims`

Description trigger: use when a subagent's finding is about to change a decision — prior art,
licensing, feasibility, "this already exists" — before it is written into a design doc, plan
or decision log.

Core principle: correlated agents agree, and agreement is not evidence.

Contents:

- The load-bearing test, which keeps the skill from firing on everything. Would a different
  answer change what gets built, bought or skipped? If not, stop here.
- Decorrelate first. Re-dispatch on a different model family or version. Give the
  cross-checker the question, not the original answer, so it cannot anchor. If the original
  claim came from the model the `cross-checker` spec names, choose another selector from
  `find_models()`.
- Ground second. A surviving claim is verified against a primary source: the arXiv API, the
  GitHub API, the raw `LICENSE` file. Two models agreeing is not a primary source.
- Disagreement is the signal to go to primary sources, not a failure of the process.
- A claim that cannot be confirmed stays flagged as unconfirmed in the document rather than
  being promoted quietly. The session's PULSE ablation reference is the worked example.
- The boundary with `verification-before-completion`: that skill verifies your own claims by
  running commands, this one verifies a subagent's claims about the world. The skills
  cross-reference rather than restate each other.

## The `cross-checker` role

`MANAGED_AGENTS` goes from eight roles to nine and `CLAUDE_AGENTS` from six to seven.
`PRIME_AGENTS` continues to mirror `MANAGED_AGENTS`.

| Field | anthropic | openai |
|---|---|---|
| model | `anthropic/claude-fable-5` | `openai/gpt-5.6-sol` |
| thinking | `high` | `high` |
| mode | `subagent` | `subagent` |
| readOnly | `true` | `true` |

It takes the strong tier's model on purpose. The default tier produces most claims, so the
strong tier is decorrelated from them by model family, and the load-bearing test keeps the
role rare enough to afford it. The anthropic ladder still uses exactly three models, so the
existing assertion in `test_prime_configs.sh` holds unchanged.

A fixed model cannot decorrelate a claim that came from that same model. That case is handled
by a rule in `cross-checking-claims`, because a 180-character spec cannot carry it.

`agents/cross-checker.md` uses `model: fable`, `effort: high`, and
`tools: Read, Grep, Glob, Bash, WebFetch, WebSearch`. It is read-only like the three
reviewers, but unlike them it has to reach primary sources on the network.

## The Prime Agent spec generator

The generator in `merge-prime.sh` currently emits `Role:`, `Model:`, `Thinking:`, the
description, and a `Dispatch with:` line. The replacement puts the dispatch form first, so the
part an agent needs survives truncation, followed by an optional read-only flag and the hint:

```
await rlm(task, name="reviewer", model="anthropic/claude-opus-5") | read-only | per-task spec + code-quality review of diffs; not the final review
```

`Role:` is dropped because the rendered line already prints the entry title. `Model:` is
dropped because the dispatch form contains the selector. `Thinking:` is dropped because it is
false.

The budget holds. The longest case is `reviewer-final` on the anthropic ladder: a 72-character
dispatch form, 12 characters for the read-only flag and 3 for the separator, totalling 87 and
leaving 93 characters for the hint. Checked against the hints written for all nine roles on
both providers, the longest rendered spec is `cross-checker` on anthropic at 174 characters.

`prime/anthropic.json` and `prime/openai.json` therefore gain a `hint` field per role, at most
93 characters, written by hand. One limit applies to both providers: the OpenAI selectors are
shorter, so a hint that fits the anthropic worst case fits everywhere. The hint is not derived by truncating `description` in jq:
automatic truncation would reproduce the mutilation this change removes, at a different
offset. `description` stays long, because OpenCode and Claude Code have no cap and use it.

Everything else about the merge is unchanged: the same managed key set, the same
`metadata.managed_by` marker, the same preserved `created_at`, the same comment guard.

## `AGENTS.md`

Two harness-neutral bullets in `### Subagent-driven development routing` name the new skills
at their moments, following the convention the file already uses for craft skills.

In `#### When running under Prime Agent`, this bullet is removed:

> Look the role up in `rlm.harness` (kind `subagent`, ids use underscores...)

It directs the agent at a roster that shows six of nine entries and truncates every one. It is
replaced by a short statement of the ceiling and the authoritative table:

| Role | Model |
|---|---|
| implementer-light | `anthropic/claude-sonnet-5` |
| implementer | `anthropic/claude-opus-5` |
| implementer-strong | `anthropic/claude-fable-5` |
| reviewer | `anthropic/claude-opus-5` |
| reviewer-final | `anthropic/claude-fable-5` |
| reviewer-lite | `anthropic/claude-sonnet-5` |
| cross-checker | `anthropic/claude-fable-5` |
| explore | `anthropic/claude-sonnet-5` |
| general | `anthropic/claude-opus-5` |

The table shows the default anthropic ladder, with one line pointing at `prime/openai.json`
for the other provider. The lead-in names the format as Prime Agent's `rlm(model=...)`
selector, so a Claude Code session reading the wrong subsection does not copy a selector into
a Task dispatch that expects `opus` or `sonnet`.

This puts Prime-specific model strings in a file all three harnesses read. That is the
existing structure of the file, which already spends 48 of its 128 lines on three per-harness
subsections. The Prime section grows from 28 lines to about 42. There is no alternative on
Prime Agent: `dist/core/resource-loader.js:30` loads one global context file per directory,
taking the first of `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, `CLAUDE.MD`, with no include
mechanism and no second file.

## Guards

The defect this design repairs was silent for as long as it existed. These checks make a
recurrence loud.

| Check | Test |
|---|---|
| every generated spec `content` is at most 180 characters, all nine roles, both providers | `test_install_prime.sh` |
| generated content starts with the complete dispatch form, closing `")` included | `test_install_prime.sh` |
| generated content contains no `Thinking:` | `test_install_prime.sh` |
| every role has a `hint` of at most 93 characters | `test_prime_configs.sh` |
| the `AGENTS.md` Prime table matches `prime/anthropic.json` row for row, with no stale rows | new `tests/test_agents_md.sh`, auto-discovered by `run.sh` |
| `cross-checker` is present in all four ladder files and the ladders stay in lockstep | `test_prime_configs.sh`, `test_provider_configs.sh` |
| the anthropic ladder still uses exactly three models | `test_prime_configs.sh` |
| `cross-checker` has no write tools | `test_agents.sh` |
| both skills have a `SKILL.md` and a `README.md` and declare their own name | `test_local_skills.sh`, already generic over `LOCAL_SKILLS` |
| the README documents both skills and the new role | `test_readme.sh` |

`doctor.sh` gains one line under the Prime Agent section, reporting the count against the
limit rather than leaving the overflow invisible:

```
[ok]   9 managed subagent specs (Prime Agent renders 6; AGENTS.md table is authoritative)
```

## Files changed

```
AGENTS.md                              routing bullets, Prime table replaces the roster lookup
README.md                              new skills, new role, the rendering ceiling
agents/cross-checker.md                new
opencode/anthropic.json                + cross-checker
opencode/openai.json                   + cross-checker
prime/anthropic.json                   + cross-checker, + hint per role
prime/openai.json                      + cross-checker, + hint per role
scripts/lib.sh                         MANAGED_AGENTS, CLAUDE_AGENTS, LOCAL_SKILLS
scripts/merge-prime.sh                 new spec content generator
scripts/doctor.sh                      spec count against the render limit
skills/routing-model-tiers/            new: SKILL.md, README.md
skills/cross-checking-claims/          new: SKILL.md, README.md
tests/test_agents.sh                   cross-checker frontmatter and tools
tests/test_agents_md.sh                new: AGENTS.md table matches the ladder
tests/test_install_prime.sh            content length, dispatch form, no Thinking
tests/test_prime_configs.sh            hint length, cross-checker, lockstep
tests/test_provider_configs.sh         cross-checker
tests/test_readme.sh                   new skills and role documented
```

## Non-goals

Entries are sorted by `[path, title, id]`, so renaming `path` would choose which six roles win
the visible slots. This design does not do that. It would buy ordering for a roster whose
authority has moved to `AGENTS.md`, and it would depend on a comparator detail that is not
part of any documented interface. The `doctor.sh` line reports the same information honestly.

## Risks

The `AGENTS.md` table is maintained by hand and can drift from `prime/anthropic.json`.
`tests/test_agents_md.sh` is the whole mitigation, and it follows the lockstep pattern that
`test_prime_configs.sh` already uses between the OpenCode and Prime ladders.

The 180-character and six-entry limits are Prime Agent implementation details. If a future
release changes them, the generated specs stay valid — they get shorter than they need to be,
and the guard tests keep passing. If a release raises the entry limit, the `doctor.sh` line
becomes conservative rather than wrong.

Adding a ninth role widens the overflow from two hidden specs to three. This is acceptable
only because the table in `AGENTS.md` is authoritative and complete. If that table is ever
removed, the overflow becomes a real loss again.
