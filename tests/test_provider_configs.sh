#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

for p in anthropic openai; do
    f="$REPO_ROOT/opencode/$p.json"
    assert_file "$f" "$p config exists"
    [ -f "$f" ] || continue

    jq -e . "$f" >/dev/null 2>&1 || fail "$p config is not valid JSON"

    # Every managed agent is present with a model.
    for a in "${MANAGED_AGENTS[@]}"; do
        model=$(jq -r --arg a "$a" '.agent[$a].model // ""' "$f")
        [ -n "$model" ] || fail "$p config missing model for agent $a"
        assert_contains "$model" "$p/" "$p agent $a uses the $p provider"
    done

    # No extra agents beyond the managed set.
    count=$(jq '.agent | length' "$f")
    assert_eq "$count" "${#MANAGED_AGENTS[@]}" "$p config agent count"

    # The superpowers plugin is declared.
    assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
        '(.plugin // []) | index($p) != null' "$f")" \
        "true" "$p config declares the superpowers plugin"

    # Effort is expressed as a variant, never as options.reasoningEffort.
    assert_eq "$(jq '[.agent[] | select(.options.reasoningEffort)] | length' "$f")" \
        0 "$p config uses variant, not options.reasoningEffort"

    # Subagents declare mode and description; primaries do not need to.
    for a in implementer-light implementer implementer-strong \
             reviewer reviewer-final reviewer-lite cross-checker; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].mode' "$f")" \
            "subagent" "$p agent $a is a subagent"
        desc=$(jq -r --arg a "$a" '.agent[$a].description // ""' "$f")
        [ -n "$desc" ] || fail "$p agent $a has no description"
    done

    # Reviewers and the cross-checker are read-only.
    for a in reviewer reviewer-final reviewer-lite cross-checker; do
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].permission.edit' "$f")" \
            "deny" "$p agent $a denies edit"
        assert_eq "$(jq -r --arg a "$a" '.agent[$a].permission.bash' "$f")" \
            "ask" "$p agent $a gates bash"
    done
done

# --- Anthropic specifics ---
a="$REPO_ROOT/opencode/anthropic.json"
assert_eq "$(jq -r '.agent["implementer-strong"].model' "$a")" \
    "anthropic/claude-fable-5" "anthropic strong tier"
assert_eq "$(jq -r '.agent.reviewer.model' "$a")" \
    "anthropic/claude-opus-5" "anthropic reviewer tier"
assert_eq "$(jq -r '.agent["reviewer-final"].model' "$a")" \
    "anthropic/claude-fable-5" "anthropic final-reviewer tier"
assert_eq "$(jq -r '.agent["implementer-light"].model' "$a")" \
    "anthropic/claude-sonnet-5" "anthropic light tier"
assert_eq "$(jq -r '.agent.implementer.model' "$a")" \
    "anthropic/claude-opus-5" "anthropic default tier"

# Three models, no more. Haiku is gone, so nothing is stuck on a two-rung
# variant table and every agent can carry an explicit variant.
assert_eq "$(jq -r '[.agent[].model] | unique | length' "$a")" \
    3 "anthropic ladder uses exactly three models"
assert_eq "$(jq -r '[.agent[].model] | map(select(test("haiku"))) | length' "$a")" \
    0 "no haiku left in the anthropic ladder"
assert_eq "$(jq -r '[.agent[] | select(has("variant") | not)] | length' "$a")" \
    0 "every anthropic agent declares a variant"

# Every agent runs at high. The tiers differ by model, not by rung.
assert_eq "$(jq -r '[.agent[].variant] | unique | join(",")' "$a")" \
    "high" "every anthropic agent runs at high"
for ag in implementer-strong reviewer-final; do
    assert_eq "$(jq -r --arg ag "$ag" '.agent[$ag].model' "$a")" \
        "anthropic/claude-fable-5" "anthropic $ag runs on fable"
done
# No provider block is needed for Anthropic.
assert_eq "$(jq -r 'has("provider")' "$a")" "false" "anthropic config has no provider block"

# --- OpenAI specifics ---
o="$REPO_ROOT/opencode/openai.json"
assert_eq "$(jq -r '.agent["implementer-strong"].model' "$o")" \
    "openai/gpt-5.6-sol" "openai strong tier"
assert_eq "$(jq -r '.agent["implementer-light"].variant' "$o")" \
    "low" "openai light tier variant"
assert_eq "$(jq -r '.provider.openai.options.store' "$o")" \
    "false" "openai config keeps store: false"
# reasoningSummary and include are covered by the generated variant.
assert_eq "$(jq -r '.provider.openai.options | has("reasoningSummary")' "$o")" \
    "false" "openai config drops reasoningSummary"

exit "$ASSERT_FAILURES"
