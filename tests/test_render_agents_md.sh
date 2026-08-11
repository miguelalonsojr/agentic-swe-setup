#!/usr/bin/env bash
# Each harness gets its own rendering of AGENTS.md: the shared body plus its
# own "When running under ..." section, and neither of the other two. The
# sections are dispatch instructions that contradict each other across
# harnesses, so shipping all three to every harness is what this replaces.
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

SRC="$REPO_ROOT/AGENTS.md"

# The headings are matched literally, so a reworded one must fail here rather
# than silently render a file with no harness section at all.
for h in "${HARNESSES[@]}"; do
    heading=$(harness_heading "$h") || fail "no heading defined for $h"
    grep -qxF "$heading" "$SRC" || fail "AGENTS.md has no section: $heading"
done

for h in "${HARNESSES[@]}"; do
    out=$(render_agents_md "$h") || { fail "render_agents_md $h failed"; continue; }
    assert_file "$out" "rendered AGENTS.md for $h"
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

# Body content unique to one harness must travel with its heading, not just
# the heading itself: dropping a heading and keeping its bullets would pass
# every assertion above.
claude_body=$(cat "$(render_agents_md claude)")
prime_body=$(cat "$(render_agents_md prime)")
opencode_body=$(cat "$(render_agents_md opencode)")
assert_not_contains "$claude_body" 'rlm(model=' "claude drops Prime's selector form"
assert_not_contains "$claude_body" "opencode.json" "claude drops OpenCode's config reference"
assert_not_contains "$opencode_body" "agent frontmatter models are fallbacks" \
    "opencode drops Claude Code's frontmatter note"
assert_not_contains "$prime_body" "reasoning effort are fixed" \
    "prime drops OpenCode's fixed-model note"

# The shared body survives in every rendering.
for h in "${HARNESSES[@]}"; do
    body=$(cat "$(render_agents_md "$h")")
    assert_contains "$body" "## Disagreement" "$h keeps the shared opening"
    assert_contains "$body" "### Precedence" "$h keeps the section after the harness blocks"
    assert_contains "$body" "Superpowers workflow skills (process, TDD, verification)" \
        "$h keeps the trailing shared content"
done

# The Prime routing table is Prime's alone; it names selectors that are not
# valid in the other two harnesses.
assert_contains "$prime_body" '| `reviewer` |' "prime keeps the routing table"
assert_not_contains "$claude_body" '| `reviewer` |' "claude drops the routing table"

# Rendering is a pure function of AGENTS.md: a second run must not append.
first=$(render_agents_md prime)
a=$(wc -l < "$first")
render_agents_md prime >/dev/null
b=$(wc -l < "$first")
assert_eq "$b" "$a" "re-rendering is idempotent"

# An unknown harness is a programming error, not a silently empty file.
assert_status 1 render_agents_md nonesuch

exit "$ASSERT_FAILURES"
