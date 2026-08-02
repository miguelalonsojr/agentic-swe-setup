# agentic-swe-setup

A `just`-driven installer that reproduces one agentic SWE environment across two
harnesses. It sets up the Superpowers workflow plugin, the eight book-grounded
swe-skills, five model-tiered subagent roles, and a single global `AGENTS.md`,
into Claude Code, OpenCode, or both. The repo configures harnesses; it does not
install them.

## Prerequisites

- Claude Code and/or OpenCode, already installed and authenticated.
- `just`, `git`, and `jq` on `PATH`.

Installing with only one harness is supported. A missing `claude` or `opencode`
is warned about and skipped, and the run still exits 0. A missing `jq` skips the
OpenCode half the same way. A missing `git` is fatal, because the skills
checkout cannot proceed without it.

## Quick start

```bash
git clone <this repo>
cd agentic-swe-setup
just install                      # both harnesses, provider=anthropic
just install provider=openai      # both harnesses, OpenAI ladder
just doctor                       # what is and is not installed
```

## Recipes

| Recipe | What it does |
|---|---|
| `just` | Lists the recipes. |
| `just install` | Runs both installs, then prints the doctor report. |
| `just install-claude` | Superpowers, swe-skills, subagents, and instructions for Claude Code. |
| `just install-opencode` | Superpowers, swe-skills, agents, and instructions for OpenCode. |
| `just doctor` | Reports what is and is not installed. Writes nothing, always exits 0. |
| `just update` | Refreshes the plugin, skills, and links in place. |
| `just uninstall` | Removes this repo's symlinks and managed config keys. |
| `just test` | Runs the test suite. |

`provider` is the only knob. It defaults to `anthropic` and accepts `openai`. It
applies to the OpenCode ladder only; Claude Code tiers live in `agents/*.md`.

## What gets installed where

| Component | Claude Code | OpenCode |
|---|---|---|
| Superpowers | `claude plugin marketplace add anthropics/claude-plugins-official`, then `claude plugin install superpowers@claude-plugins-official` | jq-merge `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` |
| swe-skills | `~/.swe-skills/install.sh --scope=user --tool=claude` | `~/.swe-skills/install.sh --scope=user --tool=opencode` |
| Global instructions | symlink `AGENTS.md` to `~/.claude/CLAUDE.md` | symlink `AGENTS.md` to `~/.config/opencode/AGENTS.md` |
| Subagents | symlink `agents/*.md` into `~/.claude/agents/` | jq-merge `agent.*` into `~/.config/opencode/opencode.jsonc` |

`~/.swe-skills` is a single shared checkout that both harnesses symlink into.
Everything is user-scoped. Nothing is written per-project.

Claude Code gets five subagents. `general` and `explore` are built in there, so
only OpenCode receives all seven.

## The model ladder

### Anthropic (default), `opencode/anthropic.json`

| Agent | Model | Variant |
|---|---|---|
| `general` | `anthropic/claude-sonnet-5` | `medium` |
| `explore` | `anthropic/claude-haiku-4-5` | `high` |
| `implementer-light` | `anthropic/claude-haiku-4-5` | *(none)* |
| `implementer` | `anthropic/claude-sonnet-5` | `medium` |
| `implementer-strong` | `anthropic/claude-fable-5` | `high` |
| `reviewer` | `anthropic/claude-fable-5` | `high` |
| `reviewer-lite` | `anthropic/claude-sonnet-5` | `medium` |

Haiku exposes only two variants, `high` and `max`, because OpenCode builds its
variants from a thinking-token budget rather than an effort scale. That is why
`implementer-light` carries no variant and `explore` uses `high`. Sonnet and
Fable expose `low` through `max`. The evidence is recorded in
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
| `reviewer` | `openai/gpt-5.6-sol` | `high` |
| `reviewer-lite` | `openai/gpt-5.6-terra` | `medium` |

This file also sets `provider.openai.options.store` to `false`.

### Claude Code

Tiers live in the frontmatter of each `agents/*.md`.

| Agent | Model | Effort |
|---|---|---|
| `implementer-light` | `haiku` | `low` |
| `implementer` | `sonnet` | `medium` |
| `implementer-strong` | `fable` | `high` |
| `reviewer` | `fable` | `high` |
| `reviewer-lite` | `sonnet` | `medium` |

Both reviewers restrict `tools` to `Read, Grep, Glob, Bash`, so a review
dispatch cannot write files.

## Changing models

Edit `opencode/<provider>.json` for OpenCode, or the frontmatter in `agents/*.md`
for Claude Code, then re-run `just install`.

The two take effect differently. Agent files are symlinked, so an edit to
`agents/*.md` applies with no reinstall. OpenCode config lives in a merged copy,
so a change there needs `just install` or `just update` to re-merge.

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

## Uninstall

```bash
just uninstall
```

It removes the five agent symlinks, both global instruction symlinks, the skill
symlinks, and the managed keys from `opencode.jsonc`. A symlink that does not
resolve into this repo is left alone and reported.

Three things survive on purpose, because other tooling may depend on them:

| Left behind | Remove with |
|---|---|
| the `~/.swe-skills` checkout | `rm -rf ~/.swe-skills` |
| the Superpowers plugin | `claude plugin uninstall superpowers` |
| `opencode.jsonc.bak.*` backups | `rm ~/.config/opencode/opencode.jsonc.bak.*` |
