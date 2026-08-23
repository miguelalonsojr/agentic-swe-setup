#!/usr/bin/env bash
# Each harness gets a provider-scoped rendering of AGENTS.md: the shared body
# plus its own "When running under ..." section, and neither of the other two.
set -uo pipefail
. "$REPO_ROOT/tests/lib/sandbox.sh"
. "$REPO_ROOT/scripts/lib.sh"

SRC="$REPO_ROOT/AGENTS.md"
PROVIDERS=(anthropic openai)

for h in "${HARNESSES[@]}"; do
    heading=$(harness_heading "$h") || fail "no heading defined for $h"
    grep -qxF "$heading" "$SRC" || fail "AGENTS.md has no section: $heading"
done

for h in "${HARNESSES[@]}"; do
    for provider in "${PROVIDERS[@]}"; do
        out=$(render_agents_md "$h" "$provider") || {
            fail "render_agents_md $h $provider failed"
            continue
        }
        assert_file "$out" "rendered AGENTS.md for $h/$provider"
        assert_eq "$out" "$REPO_ROOT/build/$h/$provider/AGENTS.md"             "$h/$provider uses a provider-scoped path"
        body=$(cat "$out")
        for other in "${HARNESSES[@]}"; do
            heading=$(harness_heading "$other")
            if [ "$other" = "$h" ]; then
                assert_contains "$body" "$heading" "$h keeps its own section"
            else
                assert_not_contains "$body" "$heading" "$h drops the $other section"
            fi
        done
    done
done

claude_body=$(cat "$(rendered_agents_md claude anthropic)")
opencode_body=$(cat "$(rendered_agents_md opencode anthropic)")
prime_anthropic=$(cat "$(rendered_agents_md prime anthropic)")
prime_openai=$(cat "$(rendered_agents_md prime openai)")
assert_not_contains "$claude_body" 'rlm(model=' "claude drops Prime's selector form"
assert_not_contains "$claude_body" "opencode.json" "claude drops OpenCode's config reference"
assert_not_contains "$opencode_body" "agent frontmatter models are fallbacks"     "opencode drops Claude Code's frontmatter note"
assert_not_contains "$prime_anthropic" "reasoning effort are fixed"     "prime drops OpenCode's fixed-model note"

for h in "${HARNESSES[@]}"; do
    for provider in "${PROVIDERS[@]}"; do
        body=$(cat "$(rendered_agents_md "$h" "$provider")")
        assert_contains "$body" "## Disagreement"             "$h keeps the shared opening"
        assert_contains "$body" "## Workflow Scaling"             "$h keeps workflow classification"
        assert_contains "$body" "### Precedence"             "$h keeps trailing shared content"
        assert_contains "$body" "A task uses the fast path only when all of these conditions hold:"             "$h keeps the conjunctive fast-path gate"
        assert_contains "$body" $'2. Workflow classification and the rules for the selected path.\n3. Applicable Superpowers workflow skills.'             "$h puts workflow classification immediately before applicable Superpowers skills"
        assert_contains "$body" "### Bounded path"             "$h keeps the bounded path"
        assert_contains "$body" 'Use the short in-chat `brainstorming` flow and obtain approval before implementation.'             "$h keeps bounded-path approval"
        assert_contains "$body" "Do not write a design document or implementation-plan document."             "$h keeps bounded-path document exclusions"
        assert_contains "$body" "### Full path"             "$h keeps the full path"
        assert_contains "$body" "Use the full path for architectural, unclear, cross-component, or high-risk work."             "$h keeps full-path selection criteria"
        assert_contains "$body" "The full path retains the Superpowers design, planning, TDD, worktree, delegation, review, and verification workflows."             "$h keeps the complete full workflow"
        assert_contains "$body" "They are not mandatory when the fast path explicitly excludes them."             "$h keeps the fast-path precedence exception"
    done
done

assert_contains "$prime_openai" '| Role | Model | Thinking |' \
    "Prime renders a Markdown table header"
assert_contains "$prime_openai" '|---|---|---|' \
    "Prime renders a Markdown table separator"
assert_contains "$prime_openai" '| `reviewer` | `openai-codex/gpt-5.6-terra` | `high` |'     "OpenAI Prime table uses the selected model"
assert_contains "$prime_openai" '| `implementer-light` | `openai-codex/gpt-5.6-luna` | `low` |' \
    "OpenAI Prime table uses implementer-light thinking"
assert_contains "$prime_openai" 'model="openai-codex/gpt-5.6-terra", thinking="high"'     "OpenAI Prime example uses the selected model"
assert_not_contains "$prime_openai" 'anthropic' "OpenAI Prime render has no Anthropic selector"
assert_not_contains "$prime_openai" 'claude' "OpenAI Prime render has no Claude model name"
assert_contains "$prime_anthropic" '| `reviewer` | `anthropic/claude-opus-5` | `high` |'     "Anthropic Prime table uses the selected model"
assert_contains "$prime_anthropic" 'model="anthropic/claude-opus-5", thinking="high"'     "Anthropic Prime example uses the selected model"
assert_not_contains "$prime_anthropic" 'openai' "Anthropic Prime render has no OpenAI selector"

assert_contains "$prime_anthropic" '| `reviewer` |' "prime keeps the routing table"
assert_not_contains "$claude_body" '| `reviewer` |' "claude drops the routing table"

first=$(render_agents_md prime anthropic)
a=$(wc -l < "$first")
render_agents_md prime anthropic >/dev/null
b=$(wc -l < "$first")
assert_eq "$b" "$a" "re-rendering is idempotent"

assert_status 1 render_agents_md nonesuch openai
assert_status 1 render_agents_md prime not-a-provider
# A provider must name a repository config, not a path which reaches one.
assert_status 1 render_agents_md prime ../prime/anthropic

# Missing, null, empty, and malformed model selectors must reject a provider config rather
# than produce instructions with an unusable dispatch model. Thinking must be
# an RLM-supported non-empty string. Use a temporary provider file so the
# repository ladders remain untouched.
malformed_provider="test-malformed-renderer-$$"
malformed_config="$REPO_ROOT/prime/$malformed_provider.json"
malformed_base=$(mktemp "$REPO_ROOT/prime/$malformed_provider.base.XXXXXX")
jq --arg provider "$malformed_provider" \
    '.agent |= with_entries(.value.model |= sub("^anthropic/"; $provider + "/"))' \
    "$REPO_ROOT/prime/anthropic.json" > "$malformed_base"
for agent in "${PRIME_AGENTS[@]}"; do
    for mutation in missing null empty malformed; do
        case "$mutation" in
            missing) jq --arg agent "$agent" 'del(.agent[$agent].model)' \
                "$malformed_base" > "$malformed_config" ;;
            null) jq --arg agent "$agent" '.agent[$agent].model = null' \
                "$malformed_base" > "$malformed_config" ;;
            empty) jq --arg agent "$agent" '.agent[$agent].model = ""' \
                "$malformed_base" > "$malformed_config" ;;
            malformed) jq --arg agent "$agent" '.agent[$agent].model = "not-a-selector"' \
                "$malformed_base" > "$malformed_config" ;;
        esac
        assert_status 1 render_agents_md prime "$malformed_provider"
    done
    for mutation in missing null empty nonstring unsupported; do
        case "$mutation" in
            missing) jq --arg agent "$agent" 'del(.agent[$agent].thinking)' \
                "$malformed_base" > "$malformed_config" ;;
            null) jq --arg agent "$agent" '.agent[$agent].thinking = null' \
                "$malformed_base" > "$malformed_config" ;;
            empty) jq --arg agent "$agent" '.agent[$agent].thinking = ""' \
                "$malformed_base" > "$malformed_config" ;;
            nonstring) jq --arg agent "$agent" '.agent[$agent].thinking = 1' \
                "$malformed_base" > "$malformed_config" ;;
            unsupported) jq --arg agent "$agent" '.agent[$agent].thinking = "unsupported"' \
                "$malformed_base" > "$malformed_config" ;;
        esac
        assert_status 1 render_agents_md prime "$malformed_provider"
    done
done
# The renderer separately reads reviewer fields for the dispatch example; keep
# those validations covered even though reviewer also appears in the role table.
for mutation in missing null empty nonstring unsupported; do
    case "$mutation" in
        missing) jq 'del(.agent.reviewer.thinking)' "$malformed_base" \
            > "$malformed_config" ;;
        null) jq '.agent.reviewer.thinking = null' "$malformed_base" \
            > "$malformed_config" ;;
        empty) jq '.agent.reviewer.thinking = ""' "$malformed_base" \
            > "$malformed_config" ;;
        nonstring) jq '.agent.reviewer.thinking = 1' "$malformed_base" \
            > "$malformed_config" ;;
        unsupported) jq '.agent.reviewer.thinking = "unsupported"' "$malformed_base" \
            > "$malformed_config" ;;
    esac
    assert_status 1 render_agents_md prime "$malformed_provider"
done

# A directory at the publication path makes mv succeed by moving a temporary
# file into it. Treat that as a publication failure, not a successful render.
blocked_out=$(rendered_agents_md opencode "$malformed_provider")
rm -rf "$blocked_out"
mkdir -p "$blocked_out"
assert_status 1 render_agents_md opencode "$malformed_provider"
[ -d "$blocked_out" ] || fail "failed publication replaced the blocked output directory"
rm -rf "$blocked_out" "$malformed_config" "$malformed_base"

exit "$ASSERT_FAILURES"
