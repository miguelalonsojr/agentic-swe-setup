#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

skill="$REPO_ROOT/skills/egm-design-check/SKILL.md"
readme="$REPO_ROOT/skills/egm-design-check/README.md"
assert_file "$skill" 'EGM skill exists'
assert_file "$readme" 'EGM README exists'
if [ -f "$skill" ]; then
    assert_eq "$(head -n 1 "$skill")" '---' 'frontmatter opens first'
    frontmatter=$(sed -n '2,/^---$/p' "$skill")
    assert_contains "$frontmatter" 'name: egm-design-check' 'stable invocation name'
    assert_contains "$frontmatter" 'disable-model-invocation: true' 'manual-only metadata'
    assert_contains "$frontmatter" 'description: Use when' 'explicit-request description'
    body=$(cat "$skill")
    for heading in '## Understanding' '## Material gaps' '## Coverage and limitations' '## Disposition'; do
        assert_contains "$body" "$heading" "report contract contains $heading"
    done
fi

# Complete policy sentences must survive both provider renders. These assertions
# pin the explicit gate rather than matching a loose EGM keyword in a heading.
policy=(
    'The EGM design check runs only when the user explicitly requests it for the current feature or an existing named document.'
    'An EGM mention in an article or document, or skill installation alone, does not select the check.'
    'For a selected full-path feature, run the enhanced EGM builder check once at the existing pre-approval point instead of the ordinary builder check.'
    'On fast or bounded work, EGM selection does not create a design document or upgrade the workflow; offer a review of an existing document or an explicit full-path choice.'
    'A resumed ordinary workflow with no evidence of an EGM request stays unselected and does not require an EGM-selection question.'
    'If an explicit EGM request or a recovered earlier opt-in has ambiguous feature or target scope, ask instead of inferring consent.'
    'For a natural-language request, load the skill from the configured Prime skill root and report a missing installation rather than searching other copies.'
)
for provider in anthropic openai; do
    render_agents_md prime "$provider" >/dev/null || fail "render Prime instructions for $provider"
done
for source in "$REPO_ROOT/AGENTS.md" "$(rendered_agents_md prime anthropic)" "$(rendered_agents_md prime openai)"; do
    if [ ! -f "$source" ]; then
        fail "instruction policy source missing: $source"
        continue
    fi
    for sentence in "${policy[@]}"; do
        grep -qxF "$sentence" "$source" || fail "missing EGM policy sentence in $source: $sentence"
    done
done

exit "$ASSERT_FAILURES"
