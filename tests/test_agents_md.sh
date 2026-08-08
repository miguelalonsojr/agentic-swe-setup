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
L="$REPO_ROOT/prime/anthropic.json"
assert_file "$A" "AGENTS.md exists"
body=$(cat "$A")

# Every managed role appears with the selector the ladder gives it.
for a in "${PRIME_AGENTS[@]}"; do
    model=$(jq -r --arg a "$a" '.agent[$a].model' "$L")
    assert_contains "$body" "| \`$a\` | \`$model\` |" \
        "AGENTS.md routing table has the row for $a"
done

# No stale rows for roles that no longer exist.
rows=$(grep -c '^| `[a-z-]\+` | `anthropic/' "$A")
assert_eq "$rows" "${#PRIME_AGENTS[@]}" \
    "AGENTS.md routing table has exactly one row per managed role"

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
