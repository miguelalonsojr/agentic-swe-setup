# Verification: OpenCode `variant` as a provider-agnostic effort lever

Date: 2026-08-02
OpenCode version: 1.18.11

## Claim under test

OpenCode synthesizes a model variant per reasoning-effort level from
models.dev metadata and maps each to provider-specific parameters:

| Provider SDK | Generated parameters |
|---|---|
| `@ai-sdk/openai` | `{ reasoningEffort, reasoningSummary: "auto", include: [...] }` |
| `@ai-sdk/anthropic` | `{ thinking: { type: "adaptive" }, effort }` |

If true, `agent.<name>.variant` works across both providers where
`agent.<name>.options.reasoningEffort` works only for OpenAI.

## Environment limits on this machine

`opencode auth list` reports one credential, OpenAI oauth. There are no
Anthropic credentials, so any Anthropic completion fails before reaching the
model. The OpenAI account is over its usage limit: every request logs
`AI_APICallError: The usage limit has been reached` and OpenCode retries with
backoff until the command is killed.

Both limits block the live-completion checks (Steps 3, 4, 5). They do not block
the metadata checks, which is where the claim is actually decided: check 6 below
reads the variant table OpenCode itself generates per model, including the
generated provider parameters. That is direct evidence for the claim rather than
inference from a completion succeeding.

## Checks

### 1. CLI exposes --variant
Command: `opencode run --help 2>&1 | grep -i -A1 variant`
Result: PASS
Output:
```
      --variant      model variant (provider-specific reasoning effort, e.g., high, max, minimal)
                                                                                            [string]
```

### 2. models.dev effort levels
Command:
```bash
curl -fsSL https://models.dev/api.json \
  | jq '.anthropic.models
        | {"claude-sonnet-5", "claude-fable-5", "claude-haiku-4-5"}
        | map_values(.reasoning_options)'
```
Result: PASS, with a shape correction
Output:
```json
{
  "claude-sonnet-5": [
    { "type": "toggle" },
    { "type": "effort", "values": ["low", "medium", "high", "xhigh", "max"] }
  ],
  "claude-fable-5": [
    { "type": "effort", "values": ["low", "medium", "high", "xhigh", "max"] }
  ],
  "claude-haiku-4-5": [
    { "type": "budget_tokens", "min": 1024 }
  ]
}
```

`reasoning_options` is an array of option objects, not the single object the
plan predicted, and `claude-sonnet-5` carries an extra `toggle` entry. The
substance holds: Sonnet and Fable advertise the five effort levels, Haiku
advertises `budget_tokens` and no effort list.

Read alone this looks like it contradicts the spec's "Haiku exposes only
high/max". It does not. This is the raw input to OpenCode, not the result.
Check 6 shows what OpenCode synthesizes from it.

### 3. Valid variant accepted on an Anthropic model
Result: NOT RUN — no Anthropic credentials in OpenCode.
Output:
```
Error: {
  "name": "UnknownError",
  "data": {
    "message": "Unexpected server error. Check server logs for details.",
    "ref": "err_20015c0e"
  }
}
```
The same error appears with `--variant medium` and with no `--variant` at all,
so it reflects the missing credential, not the variant.

### 4. Unavailable variant rejected on Haiku
Result: NOT RUN — same missing Anthropic credentials.

A related question was answerable and the answer is worth recording. OpenCode
does not validate variant names on the client. Running
`opencode run --model openai/gpt-5.6-terra --variant totally-bogus-xyz 'hi'`
produced no validation error; the log goes straight to
`message=stream providerID=openai modelID=gpt-5.6-terra` and then fails on the
usage limit like any other request. A misspelled variant therefore fails quietly
rather than loudly. See the caveat below.

### 5. OpenAI variant equivalent to reasoningEffort
Result: NOT RUN — OpenAI account over its usage limit.
Output:
```
timestamp=2026-08-02T18:07:30.519Z level=ERROR message="stream error" providerID=openai modelID=gpt-5.6-terra error.error="AI_APICallError: The usage limit has been reached"
```
The request reached the provider with `--variant medium` applied, so the variant
was accepted through config and dispatch. Only the completion failed.

### 6. Generated variant tables per model (added)

This check was not in the plan. It replaces what Steps 3 to 5 were meant to
establish and tests the claim more directly, by reading the variant map OpenCode
builds for each model.

Anthropic is not a configured provider here (`opencode models anthropic` returns
`Provider not found: anthropic`), so the Anthropic half was read through an
isolated throwaway config with a placeholder key. `XDG_CONFIG_HOME` and
`XDG_DATA_HOME` both pointed at a temp directory; the real config was not
touched. Listing models needs no valid key.

Command: `opencode models openai --verbose`, `.variants` for `gpt-5.6-terra`
Result: PASS
Output:
```json
{
  "none":   { "reasoningEffort": "none",   "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] },
  "low":    { "reasoningEffort": "low",    "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] },
  "medium": { "reasoningEffort": "medium", "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] },
  "high":   { "reasoningEffort": "high",   "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] },
  "xhigh":  { "reasoningEffort": "xhigh",  "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] },
  "max":    { "reasoningEffort": "max",    "reasoningSummary": "auto", "include": ["reasoning.encrypted_content"] }
}
```

Command: `opencode models anthropic --verbose`, `.variants` for `claude-fable-5`
and `claude-sonnet-5` (both identical)
Result: PASS
Output:
```json
{
  "low":    { "thinking": { "type": "adaptive", "display": "summarized" }, "effort": "low" },
  "medium": { "thinking": { "type": "adaptive", "display": "summarized" }, "effort": "medium" },
  "high":   { "thinking": { "type": "adaptive", "display": "summarized" }, "effort": "high" },
  "xhigh":  { "thinking": { "type": "adaptive", "display": "summarized" }, "effort": "xhigh" },
  "max":    { "thinking": { "type": "adaptive", "display": "summarized" }, "effort": "max" }
}
```

Command: same, for `claude-haiku-4-5`
Result: PASS
Output:
```json
{
  "high": { "thinking": { "type": "enabled", "budgetTokens": 16000 } },
  "max":  { "thinking": { "type": "enabled", "budgetTokens": 31999 } }
}
```

Three things follow. The OpenAI table matches the claimed
`@ai-sdk/openai` shape exactly. The Anthropic table matches the claimed
`@ai-sdk/anthropic` shape, plus an undocumented `display: "summarized"` key.
Haiku gets exactly two rungs, `high` and `max`, built from `budget_tokens`
rather than an effort list, which is what the spec asserted.

## Verdict

CONFIRMED — use `variant` in both provider files, as designed.

`variant` is a real per-model construct that OpenCode maps to the correct
parameters for each provider SDK, so one config shape serves both providers and
`options.reasoningEffort` is not needed.

Two things to carry into Task 4:

Haiku has `high` and `max` and nothing else. `implementer-light` on
`anthropic/claude-haiku-4-5` gets no variant, and `explore` on the same model
uses `high`. Both planned settings are valid as written.

Variant names are not validated on the client. A typo in
`agent.<name>.variant` will not raise an error, it will silently apply no
variant, so the names in `opencode/anthropic.json` and `opencode/openai.json`
have to be right by inspection. The Task 4 tests assert exact variant strings,
which is what covers this.

Steps 3 to 5 stay NOT RUN. Re-run them once Anthropic credentials are added and
the OpenAI usage limit resets, if a live end-to-end confirmation is wanted.
