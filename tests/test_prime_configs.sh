#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# Prime Agent keeps OpenCode's model IDs per role, but provider selectors may
# differ because Prime Agent authenticates OpenAI Codex as `openai-codex`.
VALID_THINKING="off minimal low medium high xhigh max"

assert_valid_thinking() {
    local thinking=$1 message=$2
    assert_contains " $VALID_THINKING " " $thinking " "$message"
}

# `max` is accepted by RLM and must remain valid in both role and default
# configuration fields.
max_config=$(mktemp)
jq '.agent.general.thinking = "max" | .settings.defaultThinkingLevel = "max"' \
    "$REPO_ROOT/prime/anthropic.json" > "$max_config"
assert_valid_thinking "$(jq -r '.agent.general.thinking' "$max_config")" \
    "config validation accepts max role thinking"
assert_valid_thinking "$(jq -r '.settings.defaultThinkingLevel' "$max_config")" \
    "config validation accepts max default thinking"
rm -f "$max_config"

for p in anthropic openai; do
    f="$REPO_ROOT/prime/$p.json"
    o="$REPO_ROOT/opencode/$p.json"
    assert_file "$f" "$p prime config exists"
    [ -f "$f" ] || continue

    jq -e . "$f" >/dev/null 2>&1 || fail "$p prime config is not valid JSON"

    for a in "${PRIME_AGENTS[@]}"; do
        model=$(jq -r --arg a "$a" '.agent[$a].model // ""' "$f")
        [ -n "$model" ] || fail "$p prime config missing model for $a"
        provider=$p
        [ "$p" = "openai" ] && provider="openai-codex"
        assert_contains "$model" "$provider/" "$p agent $a uses the $provider provider"

        # Same model ID as the OpenCode ladder for the same role.
        assert_eq "${model#*/}" "$(jq -r --arg a "$a" '.agent[$a].model | split("/")[1]' "$o")" \
            "$p agent $a matches the opencode model ID"

        think=$(jq -r --arg a "$a" '.agent[$a].thinking // ""' "$f")
        assert_valid_thinking "$think" "$p agent $a has a valid thinking level"

        desc=$(jq -r --arg a "$a" '.agent[$a].description // ""' "$f")
        [ -n "$desc" ] || fail "$p prime agent $a has no description"

        # Prime Agent truncates a spec's content at 180 chars, so the spec
        # text cannot reuse the long OpenCode description. `hint` is the
        # short form written for that budget.
        hint=$(jq -r --arg a "$a" '.agent[$a].hint // ""' "$f")
        [ -n "$hint" ] || fail "$p prime agent $a has no hint"
        [ "${#hint}" -le 93 ] || \
            fail "$p prime agent $a hint is ${#hint} chars; the budget is 93"
    done

    # No extra agents beyond the managed set.
    assert_eq "$(jq '.agent | length' "$f")" "${#PRIME_AGENTS[@]}" \
        "$p prime config agent count"

    # Prime Agent has no per-agent permission system, so read-only intent is
    # carried by a flag the installer turns into spec text.
    for a in reviewer reviewer-final reviewer-lite cross-checker; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].readOnly' "$f")" "true" \
            "$p prime agent $a is read-only"
    done
    for a in implementer implementer-light implementer-strong; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a] | has("readOnly")' "$f")" \
            "false" "$p prime agent $a is not marked read-only"
    done

    # Every dispatch target is a subagent; general and explore are not.
    for a in implementer-light implementer implementer-strong \
             reviewer reviewer-final reviewer-lite cross-checker; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].mode' "$f")" "subagent" \
            "$p prime agent $a is a subagent"
    done
    for a in general explore; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a] | has("mode")' "$f")" \
            "false" "$p prime agent $a is a primary, not a subagent"
    done

    # Settings must name a provider and a bare model id (no provider prefix:
    # defaultProvider already carries it).
    provider=$p
    [ "$p" = "openai" ] && provider="openai-codex"
    assert_eq "$(jq -r '.settings.defaultProvider' "$f")" "$provider" \
        "$p settings name the provider"
    dm=$(jq -r '.settings.defaultModel' "$f")
    assert_not_contains "$dm" "/" "$p defaultModel is a bare id"
    assert_eq "$(jq -r '.agent.general.model' "$f")" "$provider/$dm" \
        "$p defaultModel matches the general agent"
    assert_valid_thinking "$(jq -r '.settings.defaultThinkingLevel' "$f")" \
        "$p defaultThinkingLevel is valid"

    # OpenCode's variant keys must not leak into the Prime config.
    assert_eq "$(jq '[.agent[] | select(has("variant"))] | length' "$f")" 0 \
        "$p prime config uses thinking, not variant"
    assert_eq "$(jq 'has("plugin")' "$f")" "false" \
        "$p prime config declares no plugin (Prime Agent has no plugin system)"
done

# --- Anthropic specifics: three models, escalation on fable ---
a="$REPO_ROOT/prime/anthropic.json"
assert_eq "$(jq -r '[.agent[].model] | unique | length' "$a")" 3 \
    "anthropic prime ladder uses exactly three models"
for ag in implementer-strong reviewer-final; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].model' "$a")" \
        "anthropic/claude-fable-5" "anthropic prime $ag runs on fable"
done
assert_eq "$(jq -r '[.agent[].thinking] | unique | join(",")' "$a")" "high" \
    "every anthropic prime agent runs at high"

# --- OpenAI specifics: effort varies by tier ---
o="$REPO_ROOT/prime/openai.json"
assert_eq "$(jq -r '.agent["implementer-light"].thinking' "$o")" "low" \
    "openai prime light tier thinks less"
assert_eq "$(jq -r '.agent["implementer-strong"].thinking' "$o")" "high" \
    "openai prime strong tier thinks more"

# --- Compaction: compact before OpenAI's long-context price tier ---
# The openai-codex gpt-5.6 models have a 272k context window and OpenAI bills
# input at a premium above roughly that threshold. reserveTokens: 22000 makes
# auto-compaction fire at 250k (trigger = window - reserveTokens), leaving a
# one-turn margin under the tier. Anthropic carries the Prime Agent defaults
# explicitly so switching providers resets the OpenAI-tuned values: the merge
# is a shallow right-biased object merge, so each block must name every key
# the other sets.
for p in anthropic openai; do
    f="$REPO_ROOT/prime/$p.json"
    assert_eq "$(jq -r '.settings.compaction.enabled' "$f")" "true" \
        "$p prime compaction is enabled"
    assert_eq "$(jq -c '.settings.compaction | keys' "$f")" \
        '["enabled","keepRecentTokens","reserveTokens"]' \
        "$p prime compaction block names every managed key"
done
assert_eq "$(jq -r '.settings.compaction.reserveTokens' "$o")" 22000 \
    "openai prime compaction triggers at 250k of the 272k window"
assert_eq "$(jq -r '.settings.compaction.reserveTokens' "$a")" 16384 \
    "anthropic prime compaction keeps the default reserve"

exit "$ASSERT_FAILURES"
