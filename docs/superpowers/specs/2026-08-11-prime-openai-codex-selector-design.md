# Prime OpenAI Codex Selector Fix

## Problem

Prime Agent authenticates this installation under the `openai-codex` provider. The Prime role configuration instead emits `openai/gpt-5.6-*` selectors. A subagent dispatch cannot resolve those selectors and reports that no child models are available.

## Decision

Keep OpenCode configuration unchanged. Update only Prime Agent’s OpenAI configuration:

- Set `defaultProvider` to `openai-codex`.
- Set every Prime role selector to `openai-codex/gpt-5.6-*`.
- Keep the existing model IDs and thinking levels.
- Update Prime-specific tests and documentation to distinguish Prime’s `openai-codex` selectors from OpenCode’s `openai` selectors.

## Verification

The tests will assert the Prime provider and role prefixes separately from OpenCode. Re-running the Prime merge will write `openai-codex` defaults and selectors to the installed settings and harness state. A minimal Prime Agent invocation with the configured selector will verify that the authenticated provider can run a child model.
