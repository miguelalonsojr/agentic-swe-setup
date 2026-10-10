# agentic-swe-setup

`just` installs Superpowers, repository-owned skills, model-tiered roles, and
rendered instructions for Prime Agent. Prime Agent must already be installed.

## Prerequisites

- Prime Agent, installed and authenticated.
- `just`, `git`, and `jq` on `PATH`.

## Quick start

```bash
just install                      # Prime Agent, provider=anthropic
just --set provider openai install  # Prime Agent, OpenAI provider
just doctor
```

## Recipes

| Recipe | What it does |
|---|---|
| `just` | Lists recipes. |
| `just install` | Installs Prime and prints the doctor report. |
| `just install-prime` | Installs Superpowers, repository-owned skills, roles, and instructions for Prime Agent. |
| `just install-skills` | Relinks repository-owned skills into Prime Agent. |
| `just doctor` | Reports Prime installation state without writing. |
| `just update` | Refreshes Superpowers and Prime links, retaining the installed provider. |
| `just uninstall` | Removes Prime-managed links, settings, and role specs. |
| `just test` | Runs the tests. |

`provider` defaults to `anthropic` and accepts `openai`. For OpenAI, Prime uses
`openai-codex/...` model selectors. `just update` reads the installed provider
from `~/.prime/agent/.agentic-swe-setup.json`.

## Installed files

Superpowers skills link from `~/.superpowers/skills/`; repository-owned skills
link from this checkout last, so `using-superpowers`, `systematic-debugging`,
and `finishing-a-development-branch` override the upstream versions.
`brainstorming` links from the upstream shared
`~/.superpowers/skills/brainstorming` checkout; there is no local fork.
The rendered `build/prime/<provider>/AGENTS.md` links to
`~/.prime/agent/AGENTS.md`. The 9 roles are installed as specs in
`~/.prime/agent/harness/harness_state.json`. Prime renders entries to
180 characters and shows six per kind; the full role/model table in the
rendered instructions is authoritative.

## Skills this repo ships

All 24 skills listed below live under this repository’s `skills/` directory and
are symlinked into Prime Agent. The old `~/.swe-skills` checkout is not needed
for installation or update. These commands do not clone or fetch `swe-skills`.

The local-only branch `local/original-skill-bundle` must remain checked out
while live skill links use this checkout. Switching branches or removing this
checkout can break those links.

| Skill | Use it when |
|---|---|
| `jira-fu` | Filing a Jira epic with stories and sub-tasks from a written backlog, or creating more issues than is sane to click through by hand. |
| `routing-model-tiers` | Selecting a model for each subagent dispatch. |
| `cross-checking-claims` | A subagent's finding is about to change a decision and needs an independent check and a primary source. |
| `search-fu` | The harness has no configured web search, or a search result needs reading at its source before a claim is made from it. |
| `plain-technical-prose` | Writing or revising prose that should read as a specification: docs, design specs, commit messages, PR descriptions, issue bodies. |
| `dispatching-parallel-agents` | Dispatching two or more independent tasks in parallel. |
| `subagent-driven-development` | Executing an implementation plan with independent tasks in the current session. |
| `using-git-worktrees` | Starting isolated feature work or executing an implementation plan. |
| `using-superpowers` | Starting a conversation and choosing applicable skills. Its announcement yields to another skill’s exact first-message format. |
| `agentic-manual-testing` | Tests pass and a change has a runnable surface: run it as a user would and record the evidence before claiming it works. |
| `compound-step` | A branch or plan finishes: turn rulings, recurring findings, and corrections into small updates to instructions, skills, or memory. |
| `codebase-walkthrough` | A human needs to understand code they did not write: a reading-order walkthrough with real snippets, and an interactive explanation on request. |
| `finishing-a-development-branch` | Implementation is complete: tidy history, size report, PR description contract, compound step, then merge or PR. Forked from Superpowers at commit `b36e082`. |
| `systematic-debugging` | Any bug or unexpected behavior, before proposing a fix. Forked from Superpowers at commit `b36e082`; adds `git bisect` and recovery. Its secret-safe `IDENTITY` checks and polluter-script command match v7.0.0. |
| `confluence-diagrams` | Rendering Mermaid diagrams as images on Confluence Cloud and checking the published page. |
| `de-slop` | Revising formulaic prose while preserving its facts and intended voice. |
| `generating-design-doc` | Documenting an existing codebase’s architecture from source evidence. |
| `low-level-design` | Designing object responsibilities and interactions for a bounded system. |
| `clean-architecture` | Reviewing module boundaries and dependency direction. |
| `clean-coding` | Reviewing names, functions, error paths, comments, and tests in a local change. |
| `ddd-expert` | Clarifying domain terms and business rules before choosing a model. |
| `design-patterns-expert` | Checking whether a named pattern fits a concrete design pressure. |
| `pragmatic-engineer` | Comparing options by reversibility, duplication, feedback, and risk. |
| `system-designing` | Designing distributed services around traffic, storage, consistency, and failure. |

Repository-owned skills link after Superpowers, so the local
`using-superpowers`, `systematic-debugging`, and
`finishing-a-development-branch` forks take precedence. A same-name
repository skill also wins a Superpowers collision.

Each has a `SKILL.md` for agents, and a `README.md` aimed at a human. `jira-fu`
and `search-fu` ship a script, and their `README.md` covers running it by hand.
The rest are prose, so their `README.md` records where the skill came from
instead. Add one by dropping a directory into `skills/` and adding its
name to `LOCAL_SKILLS` in `scripts/lib.sh`; installation and the skill-name
tests read from that array.

`just install-skills` relinks these repository-owned skills without a
checkout refresh.

## Model ladder: `prime/anthropic.json` and `prime/openai.json`

Prime uses the `openai-codex` provider selector for its OpenAI Codex
authentication. Both provider files define each role's model and thinking level.
`settings` carries the session defaults:

| Key | Anthropic | OpenAI |
|---|---|---|
| `defaultProvider` | `anthropic` | `openai-codex` |
| `defaultModel` | `claude-opus-5` | `gpt-6-sol` |
| `defaultThinkingLevel` | `high` | `medium` |

Prime Agent's model catalog assigns a 272,000-token context window to
`openai-codex/gpt-6-*`. The same GPT-6 models expose a 1,050,000-token
window through the OpenAI API, with long-context API pricing above 272,000
input tokens. This setup uses `openai-codex`. Its 22,000-token reserve triggers
automatic compaction above 250,000 tokens and keeps the most recent 20,000
tokens unsummarized.

`defaultModel` is a bare model ID; `defaultProvider` supplies the prefix. The
per-agent `model` fields use the `provider/id` selector that
`rlm.spawn(task, ..., model=...)` expects. Prime's OpenAI roles use Luna 6 for exploration and mechanical tasks,
Sol 6 for general work and per-task reviews, and Astra for escalations, final
reviews, and independent checks.

| Agent | Prime OpenAI model | Thinking |
|---|---|---|
| `general` | `openai-codex/gpt-6-sol` | `medium` |
| `explore` | `openai-codex/gpt-6-luna` | `medium` |
| `implementer-light` | `openai-codex/gpt-6-luna` | `low` |
| `implementer` | `openai-codex/gpt-6-sol` | `medium` |
| `implementer-strong` | `openai-codex/gpt-6-astra` | `high` |
| `reviewer` | `openai-codex/gpt-6-sol` | `high` |
| `reviewer-final` | `openai-codex/gpt-6-astra` | `high` |
| `reviewer-lite` | `openai-codex/gpt-6-sol` | `medium` |
| `cross-checker` | `openai-codex/gpt-6-astra` | `high` |

## What the Prime Agent merge touches

Two files, each with a fixed key set:

- `settings.json` — only `defaultProvider`, `defaultModel`, and
  `defaultThinkingLevel`. Every other setting, including `theme` and `skills`,
  is preserved, and the manifest records which keys were written so
  `uninstall` removes exactly those.
- `harness/harness_state.json` — `entries.subagent.*` for the 9 managed roles
  and nothing else. Each carries `metadata.managed_by: agentic-swe-setup`, so
  specs the agent refined for itself are never touched. Re-running preserves
  each spec's original `created_at`.

A timestamped `settings.json.bak.*` is written before each merge, and the same
comment guard applies: a `settings.json` that is not strict JSON is refused
with exit 2 rather than rewritten.

## Legacy retirement

Normal install, update, doctor, and uninstall do not touch Claude Code or
OpenCode. To retire this repository's old installations separately, run
`bash scripts/retire-legacy.sh` after reviewing its ownership checks and
warnings. The retirement uninstalls the Claude Code Superpowers plugin. It leaves unrelated files and modified config entries alone.

## Uninstall

`just uninstall` removes Prime-managed links, settings keys, and role specs.
It removes exact repository-owned skill links and matching old managed links,
including dangling links. Foreign mappings and user skill directories stay.
It leaves the Superpowers checkout in place and does not change an old
`~/.swe-skills` checkout. It does not remove the Claude Superpowers plugin or
change OpenCode configuration.
