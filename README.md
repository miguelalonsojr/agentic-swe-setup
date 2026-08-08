# agentic-swe-setup

A `just`-driven installer that reproduces one agentic SWE environment across
three harnesses. It sets up the Superpowers workflow skills, the eight
book-grounded swe-skills, model-tiered subagent roles, and a single global
`AGENTS.md`, into Claude Code, OpenCode, Prime Agent, or any combination. The
repo configures harnesses; it does not install them.

## Prerequisites

- Claude Code, OpenCode, and/or Prime Agent, already installed and authenticated.
- `just`, `git`, and `jq` on `PATH`.

Installing with only one harness is supported. A missing `claude`, `opencode`,
or `prime-agent` is warned about and skipped, and the run still exits 0. A
missing `jq` skips the OpenCode and Prime Agent halves the same way. A missing
`git` is fatal, because the skills checkout cannot proceed without it.

## Quick start

```bash
git clone <this repo>
cd agentic-swe-setup
just install                      # every harness, provider=anthropic
just install provider=openai      # every harness, OpenAI ladder
just doctor                       # what is and is not installed
```

## Recipes

| Recipe | What it does |
|---|---|
| `just` | Lists the recipes. |
| `just install` | Runs all three installs, then prints the doctor report. |
| `just install-claude` | Superpowers, swe-skills, subagents, and instructions for Claude Code. |
| `just install-opencode` | Superpowers, swe-skills, agents, and instructions for OpenCode. |
| `just install-prime` | Superpowers, swe-skills, subagent specs, and instructions for Prime Agent. |
| `just install-skills` | Relinks only this repo's own skills, into whichever harnesses are present. |
| `just doctor` | Reports what is and is not installed. Writes nothing, always exits 0. |
| `just update` | Refreshes the plugin, skills, and links in place. |
| `just uninstall` | Removes this repo's symlinks and managed config keys. |
| `just test` | Runs the test suite. |

`provider` is the only knob. It defaults to `anthropic` and accepts `openai`. It
applies to the OpenCode and Prime Agent ladders; Claude Code tiers live in
`agents/*.md`.

## What gets installed where

| Component | Claude Code | OpenCode | Prime Agent |
|---|---|---|---|
| Superpowers | `claude plugin marketplace add anthropics/claude-plugins-official`, then `claude plugin install superpowers@claude-plugins-official` | jq-merge `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` | symlink `~/.superpowers/skills/*` into `~/.prime/agent/skills/` |
| swe-skills | `~/.swe-skills/install.sh --scope=user --tool=claude` | `~/.swe-skills/install.sh --scope=user --tool=opencode` | symlink `~/.swe-skills/{skills,book-skills}/*` into `~/.prime/agent/skills/` |
| Global instructions | symlink `AGENTS.md` to `~/.claude/CLAUDE.md` | symlink `AGENTS.md` to `~/.config/opencode/AGENTS.md` | symlink `AGENTS.md` to `~/.prime/agent/AGENTS.md` |
| Subagents | symlink `agents/*.md` into `~/.claude/agents/` | jq-merge `agent.*` into `~/.config/opencode/opencode.jsonc` | jq-merge subagent specs into `~/.prime/agent/harness/harness_state.json` |
| Model defaults | agent frontmatter | same `opencode.jsonc` merge | jq-merge into `~/.prime/agent/settings.json` |
| Local skills | symlink `skills/*` into `~/.claude/skills/` | symlink `skills/*` into `~/.config/opencode/skills/` | symlink `skills/*` into `~/.prime/agent/skills/` |

`~/.swe-skills` is a single shared checkout that every harness symlinks into.
Everything is user-scoped. Nothing is written per-project.

Claude Code gets five subagents. `general` and `explore` are built in there, so
only OpenCode and Prime Agent receive all seven.

### Why Prime Agent is different

Prime Agent has no plugin system and no agent-definition files, so two things
are installed differently rather than skipped:

- **Superpowers** is cloned to `~/.superpowers` and its `skills/*` are
  symlinked in. They are ordinary `SKILL.md` directories, so Prime Agent loads
  them natively; only the plugin wrapper is missing, not the skills.
- **Roles** become continual-harness subagent specs in
  `harness/harness_state.json`, keyed with underscores (`reviewer_final`). Each
  spec records the model and thinking level for its tier, and the agent passes
  that model to `rlm(..., model=...)` when it dispatches.

Prime Agent also cannot restrict a child's tools, so read-only reviewers are
enforced by instruction in the spec text rather than by permission. This is a
real weakening compared to the other two harnesses, where a reviewer physically
cannot write.

## Skills this repo ships

Most skills come from the shared `~/.swe-skills` checkout. A few live here,
under `skills/`, and are symlinked into every harness:

| Skill | Use it when |
|---|---|
| `jira-fu` | Filing a Jira epic with stories and sub-tasks from a written backlog, or creating more issues than is sane to click through by hand. |
| `routing-model-tiers` | Dispatching subagents, especially a batch, and choosing which model each one runs on. |

Each has a `SKILL.md` for agents and a `README.md` for humans. Add
one by dropping a directory into `skills/` and adding its name to
`LOCAL_SKILLS` in `scripts/lib.sh`; install, doctor, uninstall and the tests
all read from that array.

`just install-skills` relinks them without touching plugins or re-cloning
swe-skills, which is the fast path while editing one.

Install also retires agent filenames this project shipped under previously. The
one case today is `~/.claude/agents/reviewer-light.md`, which declared
`name: reviewer-lite` and would otherwise sit alongside the current
`reviewer-lite.md` with both claiming that name. A real file is moved to
`reviewer-light.md.bak.<timestamp>` rather than deleted.

## The model ladder

### Anthropic (default), `opencode/anthropic.json`

Three tiers, distinguished by model. Every tier reasons at `high`, so the cheap
tier is still a careful one and escalating means a stronger model rather than
more thinking on the same one.

| Tier | Agent | Model | Variant |
|---|---|---|---|
| light | `explore` | `anthropic/claude-sonnet-5` | `high` |
| light | `implementer-light` | `anthropic/claude-sonnet-5` | `high` |
| light | `reviewer-lite` | `anthropic/claude-sonnet-5` | `high` |
| default | `general` | `anthropic/claude-opus-5` | `high` |
| default | `implementer` | `anthropic/claude-opus-5` | `high` |
| default | `reviewer` | `anthropic/claude-opus-5` | `high` |
| strong | `implementer-strong` | `anthropic/claude-fable-5` | `high` |
| strong | `reviewer-final` | `anthropic/claude-fable-5` | `high` |

The per-task reviewer sits on the default tier: reviews run twice per task
(spec compliance plus code quality), so they dominate strong-tier spend if
routed there. The strong model is reserved for the two places its judgment
gates an outcome: escalated implementations and the final whole-branch
review before merge.

All three models also accept `xhigh` and `max` if you want to raise the strong
tier later.

All three models expose the full `low` through `max` variant range. Haiku, which
earlier versions used for the light tier, exposed only `high` and `max` because
OpenCode builds its variants from a thinking-token budget rather than an effort
scale, so `implementer-light` could not carry a variant at all. Dropping it
removes that special case. The variant tables are recorded in
`docs/verification/opencode-variant.md`.

No `provider` block is needed for Anthropic.

### OpenAI, `opencode/openai.json`

| Agent | Model | Variant |
|---|---|---|
| `general` | `openai/gpt-5.6-terra` | `medium` |
| `explore` | `openai/gpt-5.6-luna` | `medium` |
| `implementer-light` | `openai/gpt-5.6-luna` | `low` |
| `implementer` | `openai/gpt-5.6-terra` | `medium` |
| `implementer-strong` | `openai/gpt-5.6-sol` | `high` |
| `reviewer` | `openai/gpt-5.6-terra` | `high` |
| `reviewer-final` | `openai/gpt-5.6-sol` | `high` |
| `reviewer-lite` | `openai/gpt-5.6-terra` | `medium` |

This file also sets `provider.openai.options.store` to `false`.

### Prime Agent, `prime/anthropic.json` and `prime/openai.json`

Same roles and same model per role as the OpenCode ladder; a test asserts the
two stay in lockstep. OpenCode's `variant` becomes Prime Agent's `thinking`,
and `settings` carries the session defaults:

| Key | Anthropic | OpenAI |
|---|---|---|
| `defaultProvider` | `anthropic` | `openai` |
| `defaultModel` | `claude-opus-5` | `gpt-5.6-terra` |
| `defaultThinkingLevel` | `high` | `medium` |

`defaultModel` is a bare model id; `defaultProvider` supplies the prefix. The
per-agent `model` fields keep the `provider/id` form that `rlm(model=...)`
expects.

### Claude Code

Tiers live in the frontmatter of each `agents/*.md`.

| Agent | Model | Effort |
|---|---|---|
| `implementer-light` | `sonnet` | `high` |
| `implementer` | `opus` | `high` |
| `implementer-strong` | `fable` | `high` |
| `reviewer` | `opus` | `high` |
| `reviewer-final` | `fable` | `high` |
| `reviewer-lite` | `sonnet` | `high` |

All three reviewers restrict `tools` to `Read, Grep, Glob, Bash`, so a
review dispatch cannot write files.

## Changing models

Edit `opencode/<provider>.json` for OpenCode, `prime/<provider>.json` for Prime
Agent, or the frontmatter in `agents/*.md` for Claude Code, then re-run
`just install`.

They take effect differently. Agent files are symlinked, so an edit to
`agents/*.md` applies with no reinstall. OpenCode and Prime Agent config lives
in a merged copy, so a change to either needs `just install` or `just update`
to re-merge.

OpenCode does not validate variant names. A typo applies no variant instead of
raising an error, so check spelling against the tables above.

## What the OpenCode merge touches

The merge owns a fixed key set and rewrites only that:

- `agent.*` for the seven managed agent names.
- `plugin`, appended and de-duplicated. Other plugins keep their order.
- `provider.openai`, added for the OpenAI ladder and removed when switching away.
- `$schema`, set only when absent.

Every other key is preserved, including `theme`, `mcp`, unmanaged agents, and
other `provider.*` entries. A timestamped `opencode.jsonc.bak.*` is written
before each merge, and `~/.config/opencode/.agentic-swe-setup.json` records what
was installed so `uninstall` knows what to take back out.

A config containing JSONC comments is refused rather than rewritten. `jq` cannot
round-trip comments, so the merge exits 2, changes nothing, and prints the keys
to add by hand.

## What the Prime Agent merge touches

Two files, each with a fixed key set:

- `settings.json` — only `defaultProvider`, `defaultModel`, and
  `defaultThinkingLevel`. Every other setting, including `theme` and `skills`,
  is preserved, and the manifest records which keys were written so
  `uninstall` removes exactly those.
- `harness/harness_state.json` — only `entries.subagent.*` for the eight
  managed roles. Each carries `metadata.managed_by: agentic-swe-setup`, so
  specs the agent refined for itself are never touched. Re-running preserves
  each spec's original `created_at`.

A timestamped `settings.json.bak.*` is written before each merge, and the same
comment guard applies: a `settings.json` that is not strict JSON is refused
with exit 2 rather than rewritten.

## Uninstall

```bash
just uninstall
```

It removes the five agent symlinks, all three global instruction symlinks, the
skill symlinks, the managed keys from `opencode.jsonc`, and the managed
settings keys and subagent specs from Prime Agent. A symlink that does not
resolve into this repo is left alone and reported.

Some things survive on purpose, because other tooling may depend on them:

| Left behind | Remove with |
|---|---|
| the `~/.swe-skills` checkout | `rm -rf ~/.swe-skills` |
| the `~/.superpowers` checkout | `rm -rf ~/.superpowers` |
| the Superpowers plugin | `claude plugin uninstall superpowers` |
| `opencode.jsonc.bak.*` backups | `rm ~/.config/opencode/opencode.jsonc.bak.*` |
| `settings.json.bak.*` backups | `rm ~/.prime/agent/settings.json.bak.*` |
