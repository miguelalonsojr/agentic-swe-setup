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
assert_contains "$body" "180" "AGENTS.md states the content render cap"
assert_contains "$body" "six" "AGENTS.md states the entry render cap"

# Prime Agent's selector format must be named as Prime's, so a Claude Code
# session reading the wrong subsection does not copy it into a Task dispatch.
assert_contains "$body" 'rlm(model=' "AGENTS.md names the selector format"

exit "$ASSERT_FAILURES"
