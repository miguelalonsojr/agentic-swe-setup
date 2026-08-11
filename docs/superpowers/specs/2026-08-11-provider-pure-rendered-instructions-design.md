# Provider-Pure Rendered Instructions Design

## Goal

An OpenCode or Prime Agent installation must link an instruction file that names
only its selected provider. An OpenAI installation must not contain Anthropic or
Claude model references; an Anthropic installation must not contain OpenAI model
references.

## Scope

This change covers provider-selecting installations: OpenCode and Prime Agent.
Claude Code has no provider argument, so its agent definitions and `CLAUDE.md`
rendering remain outside this change. Source configuration files for both
providers also remain in the repository; the requirement applies to files built
for, and linked into, an installation.

## Current behavior

`render_agents_md` accepts only a harness name and writes to
`build/<harness>/AGENTS.md`. The shared Prime Agent section in the source
`AGENTS.md` contains an Anthropic routing table and example selector. Therefore,
a Prime Agent installation using `openai` links instructions with Anthropic and
Claude model names. The output path is also shared by provider, so a prior render
can be reused by a later installation for the other provider.

## Design

`render_agents_md` will accept both a harness and a provider. Its output path
will include both values:

```
build/<harness>/<provider>/AGENTS.md
```

The canonical `AGENTS.md` will retain provider-neutral instructions and use
markers for Prime Agent content that varies by provider:

- the role-to-model routing table;
- the model selector in the `rlm(...)` dispatch example.

While rendering the Prime Agent section, the library will load
`prime/<provider>.json` and generate those values from its `agent` entries. The
render fails for an unknown provider or a missing role/model instead of producing
partial instructions. OpenCode has no provider-specific prose today, but it will
call the same provider-aware renderer and link a provider-namespaced output.

Installers will pass their selected provider to the renderer. This binds every
linked output to the provider that generated its managed configuration. The
existing provider manifests continue to supply the provider used by `update.sh`.

## Error handling

- An unsupported provider fails before an instruction file is linked.
- A missing Prime configuration role or model fails rendering.
- Non-Prime renderers validate the provider against the repository's known
  provider configurations so output paths cannot be created for arbitrary names.
- Existing merge guards still prevent instruction rendering after an invalid user
  configuration aborts installation.

## Tests

Update renderer tests to cover every harness/provider pair and to assert that
rendered paths are provider-scoped. For Prime renders, assert each generated role
row and the example selector match `prime/<provider>.json`.

Update OpenCode and Prime installer tests to inspect the symlinked instruction
content after both provider installs. OpenAI content must contain OpenAI selectors
and no `anthropic` or `claude` strings. Anthropic content must contain Anthropic
selectors and no `openai` strings. The test suite will continue to confirm that
managed JSON configuration has no stale model selectors after a provider switch.

## Non-goals

- Supporting multiple selected providers in one harness installation.
- Removing provider-specific source files from the repository.
- Changing model ladders, agent roles, merge behavior, or Claude Code setup.
