# agentic-swe-setup — Design

Date: 2026-08-02

## Purpose

Reproduce a working agentic SWE environment on a fresh machine with `just` recipes.
The environment is: Superpowers (process skills) + swe-skills (book-grounded craft
skills) + five model-tiered subagent roles + a global instructions file, installed
into Claude Code, OpenCode, or both.

The repo assumes Claude Code and/or OpenCode are already installed. If a harness is
absent the recipes warn and skip that half rather than failing.

## Scope

In scope:

- Installing Superpowers into both harnesses.
- Installing swe-skills into both harnesses.
- Installing five subagent role definitions into both harnesses.
- Installing one canonical `AGENTS.md` globally (not per-project) for both harnesses.
- A provider choice (Anthropic or OpenAI) for the OpenCode model ladder.
- `doctor`, `update`, and `uninstall` recipes.

Out of scope:

- Installing Claude Code or OpenCode themselves.
- Authenticating either harness or configuring API keys.
- Project-scoped installs. Everything here is user-scoped.

## Repository layout

```
agentic-swe-setup/
├── justfile
├── README.md
├── LICENSE
├── AGENTS.md                  # canonical global instructions
├── CLAUDE.md                  # "@AGENTS.md" — for this repo's own agents
├── agents/                    # canonical subagent roles, Claude Code frontmatter
│   ├── implementer-light.md
│   ├── implementer.md
│   ├── implementer-strong.md
│   ├── reviewer.md
│   └── reviewer-lite.md
├── opencode/
│   ├── anthropic.json         # managed keys, provider=anthropic (default)
│   └── openai.json            # managed keys, provider=openai
├── scripts/
│   ├── lib.sh                 # log/warn/symlink helpers
│   ├── doctor.sh
│   └── merge-opencode.sh      # jq deep-merge, comment guard, backup, manifest
└── docs/superpowers/specs/
```

`agents/reviewer-lite.md` deliberately corrects an existing inconsistency: the
current `~/.claude/agents/reviewer-light.md` declares `name: reviewer-lite`, so the
filename and the agent name disagree. The repo uses `reviewer-lite` for both.

## Component installation matrix

| Component | Claude Code | OpenCode |
|---|---|---|
| Superpowers | `claude plugin marketplace add anthropics/claude-plugins-official`, then `claude plugin install superpowers@claude-plugins-official` | jq-merge `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` |
| swe-skills | `~/.swe-skills/install.sh --scope=user --tool=claude` | `~/.swe-skills/install.sh --scope=user --tool=opencode` |
| Global instructions | symlink `AGENTS.md` → `~/.claude/CLAUDE.md` | symlink `AGENTS.md` → `~/.config/opencode/AGENTS.md` |
| Subagents | symlink `agents/*.md` → `~/.claude/agents/` | jq-merge `agent.*` into `~/.config/opencode/opencode.jsonc` |

Notes:

- The skills repository is `github.com/mhihasan/swe-skills`. Its `install.sh`,
  when piped from `curl`, clones to `$HOME/.swe-skills` and re-execs the local
  copy. The recipes invoke it the same way, so `~/.swe-skills` is the single
  checkout both harnesses symlink into.
- `install.sh` creates per-skill symlinks in the target skills directory and is
  safe to re-run.
- Superpowers is installed for Claude Code via the `claude plugin` CLI, which is
  non-interactive. No slash command is required.

## Global instructions

One file, `AGENTS.md` at the repo root, is the single source of truth. Install
symlinks it to both harness locations:

- `~/.claude/CLAUDE.md` — Claude Code's user-scoped memory file.
- `~/.config/opencode/AGENTS.md` — OpenCode's global instructions file.

Symlinks rather than copies: editing the repo file propagates to both harnesses
immediately, and the file stays git-tracked. This matches how swe-skills already
installs its skills.

If either target exists and is **not** a symlink into this repo, install backs it
up to `<path>.bak.<epoch>` before replacing it.

## Reasoning effort in OpenCode

This is the design decision that makes one config work across two providers.

OpenCode reads `reasoning_options` from models.dev and synthesizes a model
*variant* per effort level, mapping each to provider-specific parameters:

| Provider SDK | Generated variant parameters |
|---|---|
| `@ai-sdk/openai` | `{ reasoningEffort, reasoningSummary: "auto", include: ["reasoning.encrypted_content"] }` |
| `@ai-sdk/anthropic` | `{ thinking: { type: "adaptive" }, effort }` |

`agent.<name>.variant` selects one of those variants. It is therefore the
provider-agnostic lever: `variant: "medium"` produces the correct OpenAI
parameters under the OpenAI provider and the correct Anthropic parameters under
the Anthropic provider.

By contrast, `agent.<name>.options` is a raw pass-through to the provider SDK.
The `options: { reasoningEffort: "medium" }` form in the current live config is
OpenAI-specific and is silently ignored by the Anthropic provider. Both provider
files therefore use `variant`, not `options`, for effort.

**Verification requirement.** This behavior is read from the compiled OpenCode
bundle, not from published documentation. Before the provider files are
finalized, an implementation task must confirm empirically against a live
`opencode` run that `agent.<name>.variant` selects the expected effort for an
Anthropic model. If it does not hold, fall back to per-provider raw `options`
blocks, which requires the two provider files to diverge in shape rather than
only in values.

### Haiku constraint

`claude-haiku-4-5` declares `reasoning_options: [{ type: "budget_tokens", min: 1024 }]`
rather than an `effort` list. OpenCode synthesizes only `high` and `max` variants
for it — there is no `low` or `medium`. Two consequences, both intentional:

- `implementer-light` gets no `variant`. The `low` rung does not exist on Haiku,
  and mechanical single-file tasks do not need extended thinking. This is the
  cheapest correct option.
- `explore` gets `high` instead of `medium`, the nearest available rung.

## Model ladders

### Anthropic (default) — `opencode/anthropic.json`

| Agent | Model | Variant |
|---|---|---|
| `general` | `anthropic/claude-sonnet-5` | `medium` |
| `explore` | `anthropic/claude-haiku-4-5` | `high` |
| `implementer-light` | `anthropic/claude-haiku-4-5` | *(none)* |
| `implementer` | `anthropic/claude-sonnet-5` | `medium` |
| `implementer-strong` | `anthropic/claude-fable-5` | `high` |
| `reviewer` | `anthropic/claude-fable-5` | `high` |
| `reviewer-lite` | `anthropic/claude-sonnet-5` | `medium` |

No `provider` block is required for Anthropic.

### OpenAI — `opencode/openai.json`

| Agent | Model | Variant |
|---|---|---|
| `general` | `openai/gpt-5.6-terra` | `medium` |
| `explore` | `openai/gpt-5.6-luna` | `medium` |
| `implementer-light` | `openai/gpt-5.6-luna` | `low` |
| `implementer` | `openai/gpt-5.6-terra` | `medium` |
| `implementer-strong` | `openai/gpt-5.6-sol` | `high` |
| `reviewer` | `openai/gpt-5.6-sol` | `high` |
| `reviewer-lite` | `openai/gpt-5.6-terra` | `medium` |

The OpenAI file retains a `provider.openai.options` block containing
`store: false`. The `reasoningSummary` and `include` settings from the current
live config are dropped because the generated variant already sets both; `store`
is not covered by variants and must stay.

### Claude Code — `agents/*.md`

Claude Code runs Anthropic models only, so its agent files carry fixed model
frontmatter matching the Anthropic ladder above. There is no provider knob.

| Agent | Model | Effort | Tools |
|---|---|---|---|
| `implementer-light` | `haiku` | `low` | default |
| `implementer` | `sonnet` | `medium` | default |
| `implementer-strong` | `fable` | `high` | default |
| `reviewer` | `fable` | `high` | `Read, Grep, Glob, Bash` |
| `reviewer-lite` | `sonnet` | `medium` | `Read, Grep, Glob, Bash` |

Claude Code accepts short model aliases in agent frontmatter, and its `effort`
field is independent of the OpenCode variant mechanism, so `low` is available
here even though the OpenCode Haiku variant is not. Descriptions and body prompts
carry over from the current live files unchanged.

The two `reviewer` agents keep their read-only tool restriction, which is the
mechanism enforcing that review dispatches cannot modify files.

## The OpenCode merge

`scripts/merge-opencode.sh <provider>` owns a fixed set of key paths in
`~/.config/opencode/opencode.jsonc` and leaves everything else alone.

Managed key paths:

- `agent.general`
- `agent.explore`
- `agent.implementer-light`
- `agent.implementer`
- `agent.implementer-strong`
- `agent.reviewer`
- `agent.reviewer-lite`
- `provider.openai` (populated by the OpenAI variant; **deleted** by the Anthropic
  variant, so switching provider does not strand an orphaned block)
- `plugin` (append-and-dedupe, never replace)

Only `provider.openai` is managed, not the whole `provider` object. A user-added
`provider.<other>` block is left untouched by either variant.

Procedure:

1. **Comment guard.** If the target file exists and `jq . <file>` fails, abort
   with a non-zero exit, print the exact key paths and values the user must add
   by hand, and change nothing. `jq` cannot parse JSONC comments, and silently
   stripping them would destroy user-authored content. No backup is written on
   this path because no write is attempted.
2. **Backup.** Copy the existing file to `opencode.jsonc.bak.<epoch>`.
3. **Merge.** Deep-merge the managed keys. Each managed `agent.*` object is
   replaced wholesale, so switching provider does not leave stale keys from the
   other provider's shape. `plugin` is treated as a set: the Superpowers entry is
   appended if absent, and any other plugins the user has are preserved.
4. **Manifest.** Write `~/.config/opencode/.agentic-swe-setup.json` recording the
   managed key paths, the selected provider, and the backup path, so `uninstall`
   removes exactly what was added.

If the target file does not exist, it is created containing only the managed keys
plus the `$schema` reference.

Anything outside the managed set — other agents, other providers, MCP servers,
formatter config, keybindings — is never read or written.

## Recipes

```
just install                       # both harnesses; warns and skips a missing one
just install-claude
just install-opencode              # provider=anthropic (default)
just install-opencode provider=openai
just doctor
just update
just uninstall
```

`provider` is a `just` variable with default `anthropic`. `just install` passes
it through, so `just install provider=openai` works too.

### `install`

Runs `install-claude` and `install-opencode` in sequence, then prints a `doctor`
summary. A harness that is absent is warned about and skipped; the recipe still
exits 0 provided everything it actually attempted succeeded.

### `doctor`

Read-only. Changes nothing, always exits 0, and reports:

- Presence of `claude`, `opencode`, `git`, and `jq` on `PATH`.
- Whether Superpowers is installed in each present harness.
- Whether `~/.swe-skills` exists and is a git checkout.
- Whether each of the eight skills is symlinked in each harness's skills dir.
- Whether the global instructions symlink exists and points into this repo.
- Whether each of the five agent definitions is installed in each harness.
- Which provider the OpenCode manifest records.

`doctor` is also the basis for the warn-on-missing-harness behavior: install
recipes call the same detection helpers from `scripts/lib.sh`.

### `update`

- `git -C ~/.swe-skills pull --ff-only`, then re-run its `install.sh` for each
  present harness so newly added skills get linked.
- `claude plugin update superpowers` if `claude` is present.
- Re-create the agent and instruction symlinks (idempotent).
- Re-run the OpenCode merge with the provider recorded in the manifest.

`update` does not change the provider. Switching provider is `just
install-opencode provider=<other>`.

### `uninstall`

- Remove the symlinks this repo created: agent files, global instructions, and
  the swe-skills links in both harness skills dirs.
- Remove the managed keys from `opencode.jsonc` per the manifest, leaving all
  other keys intact.
- Restore a backed-up global instructions file if one was displaced at install.
- Leave `~/.swe-skills` and the Superpowers plugin in place; both are shared
  installs that other tooling may depend on. Print how to remove them manually.

## Dependency and failure handling

| Dependency | Missing behavior |
|---|---|
| `claude` | Warn, skip the Claude Code half. |
| `opencode` | Warn, skip the OpenCode half. |
| `git` | Fatal — the skills install cannot proceed without it. |
| `jq` | Warn, skip the OpenCode merge. The Claude Code half still runs. |

Rationale for warn-not-fail: the repo's job is to configure whichever harnesses
are present. A machine with only one of the two is a legitimate target, and a
hard failure would make `just install` useless there.

A file operation that fails for any other reason — permission denied, a symlink
target that is an unexpected real directory — is fatal and reported with the
offending path.

## Idempotency

Every recipe is safe to re-run:

- Symlink creation uses `ln -sfn`, which replaces an existing symlink in place.
- `claude plugin install` and `claude plugin marketplace add` are no-ops when the
  plugin or marketplace is already present.
- `swe-skills/install.sh` replaces managed symlinks and skips real directories
  that lack a `SKILL.md`.
- The OpenCode merge is a deterministic function of the provider file and the
  existing config's unmanaged keys.

## Testing

- **`doctor` on a machine with both harnesses** reports every check green after
  `just install`.
- **Comment guard.** A config containing a `//` comment causes
  `merge-opencode.sh` to exit non-zero, print the manual instructions, and leave
  the file byte-identical.
- **Unmanaged-key preservation.** A config with an extra agent, an extra plugin,
  and an MCP server block retains all three after a merge.
- **Provider switch.** Merging `anthropic` then `openai` leaves no Anthropic
  model strings in the managed agent keys. Merging `openai` then `anthropic`
  removes the `provider.openai` block while preserving any other `provider.*`
  entry.
- **Missing harness.** With `opencode` removed from `PATH`, `just install`
  warns, completes the Claude Code half, and exits 0.
- **Uninstall round-trip.** `install` then `uninstall` returns `opencode.jsonc`
  to a state equivalent to its pre-install content, and removes all symlinks.
- **Variant behavior.** A live `opencode` run confirms `variant` selects the
  expected reasoning effort for an Anthropic model. This gates finalizing the
  provider files.
