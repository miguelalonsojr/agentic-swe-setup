#!/usr/bin/env bash
# The Prime Agent routing table in AGENTS.md is the authoritative role-to-model
# map, because Prime Agent renders its subagent roster through a 180-char
# summary and shows only six entries. A hand-maintained table can drift from
# the ladder it describes, so this test is the whole mitigation.
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

A="$REPO_ROOT/AGENTS.md"
assert_file "$A" "AGENTS.md exists"
body=$(cat "$A")

# Workflow classification must make the low-risk path effective rather than
# leaving the unconditional Superpowers precedence in control.
assert_contains "$body" "## Workflow Scaling"     "AGENTS.md defines workflow scaling"
assert_contains "$body" "The change affects at most two files."     "fast path has a file boundary"
assert_contains "$body" "The change is localized and easy to reverse."     "fast path requires reversibility"
assert_contains "$body" "The expected result is clear."     "fast path requires a clear result"
assert_contains "$body" "The change requires no cross-component coordination."     "fast path excludes component coordination"
assert_contains "$body" "One focused command can verify the result."     "fast path requires focused verification"
assert_contains "$body" "public API, schema, migration, dependency, security control, authentication flow, concurrent behavior, or destructive operation"     "fast path names every high-risk exclusion"
assert_contains "$body" 'Do not invoke `brainstorming`, `writing-plans`, worktree management, subagents, or formal review.'     "fast path skips heavy workflow steps"
assert_contains "$body" "Inspect the diff and run focused verification before reporting completion."     "fast path retains completion evidence"
assert_contains "$body" "Classification can become heavier after work starts. It cannot become lighter during the same task."     "workflow upgrades are one-way"
assert_contains "$body" "Workflow classification and the rules for the selected path."     "precedence uses workflow classification"
assert_contains "$body" "Applicable Superpowers workflow skills."     "precedence limits Superpowers to applicable skills"
assert_contains "$body" "### Bounded path"     "AGENTS.md defines the bounded path"
assert_contains "$body" 'Use the short in-chat `brainstorming` flow and obtain approval before implementation.'     "bounded path requires approval"
assert_contains "$body" "Do not write a design document or implementation-plan document."     "bounded path excludes design and implementation-plan documents"
assert_contains "$body" "### Full path"     "AGENTS.md defines the full path"
assert_contains "$body" "Use the full path for architectural, unclear, cross-component, or high-risk work."     "full path names its selection criteria"
assert_contains "$body" "The full path retains the Superpowers design, planning, TDD, worktree, delegation, review, and verification workflows."     "full path retains the complete workflow"
assert_contains "$body" "They are not mandatory when the fast path explicitly excludes them."     "fast-path exclusions override otherwise applicable Superpowers workflows"

# Provider-selected renders populate this marker from the ladder; keeping only
# the marker in the source prevents one provider's selectors leaking into
# another provider's installed instructions.
assert_contains "$body" '<!-- PRIME_AGENT_ROLE_ROUTING_TABLE -->' \
    "AGENTS.md has the Prime role-routing-table marker"
assert_contains "$body" '<!-- PRIME_AGENT_REVIEWER_MODEL -->' \
    "AGENTS.md has the Prime reviewer-model marker"
assert_contains "$body" '<!-- PRIME_AGENT_REVIEWER_THINKING -->' \
    "AGENTS.md has the Prime reviewer-thinking marker"
assert_not_contains "$body" '| `reviewer` | `anthropic/' \
    "AGENTS.md has no hard-coded Anthropic Prime table"

# The instruction this table replaces sent the agent to a truncated roster.
assert_not_contains "$body" "Look the role up in" \
    "the old rlm.harness roster lookup is gone"

# The render limits must be stated, or the table looks like duplication.
# Anchored on the whole render-cap clause, not a bare "180" or "six". Either
# alone would be satisfied by any unrelated number or word elsewhere in the
# file — including a role count written back into this section, which is
# exactly the drift the assertions below exist to catch.
assert_contains "$body" "180 characters and shows only six" \
    "AGENTS.md states the render caps (180 chars, six entries)"

# Prime Agent's selector format must be named as Prime's, so a Claude Code
# session reading the wrong subsection does not copy it into a Task dispatch.
assert_contains "$body" 'rlm(model=' "AGENTS.md names the selector format"

# AGENTS.md used to open this section with a hard-coded role count that
# nothing checked. A list can be verified against the array; a numeral in
# prose cannot, so the numeral is gone and the list is what gets asserted.
#
# The extract stops at the first blank line rather than at a second prose
# phrase. A range bounded by prose runs to EOF the moment its closing phrase
# is reworded, and $roles would then swallow the routing table below, where
# every role name appears — so the check would pass with the role list
# deleted. Verify the slice is a slice before trusting anything in it.
roles=$(awk '/defined in all three harnesses:/{found = 1} found && /^$/{exit} found' "$A")
[ -n "$roles" ] || fail "AGENTS.md role list is missing"
assert_not_contains "$roles" '| `' \
    "the role list extract stops short of the routing table"

# Needles carry the list's own delimiter. assert_contains is a substring
# match, so a bare `implementer` is satisfied by `implementer-light` and a
# bare `reviewer` by `reviewer-final`: two of these names would be unguarded
# without the trailing comma, and deleting them from AGENTS.md would not fail.
last_role=${CLAUDE_AGENTS[${#CLAUDE_AGENTS[@]}-1]}
for a in "${CLAUDE_AGENTS[@]}"; do
    if [ "$a" = "$last_role" ]; then delim="."; else delim=","; fi
    assert_contains "$roles" "$a$delim" "AGENTS.md role list names $a"
done
assert_not_contains "$body" "Six role agents" "the stale role count is gone"
assert_not_contains "$body" "The same six roles" "the stale Prime role count is gone"

exit "$ASSERT_FAILURES"
