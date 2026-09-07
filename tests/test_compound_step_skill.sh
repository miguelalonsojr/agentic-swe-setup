#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/compound-step"
skill="$root/SKILL.md"
assert_file "$skill" "compound-step has a SKILL.md"
assert_file "$root/README.md" "compound-step has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: compound-step" "skill declares its name"
assert_contains "$body" "before the workspace is deleted" "skill runs before workspace deletion"
assert_contains "$body" "Keep an item only if it recurred, cost a fix round, or came from a human correction." \
    "skill states the keep threshold"
assert_contains "$body" 'lines that contain `Ruling:`' "skill harvests ledger rulings"
assert_contains "$body" "The human approves each item." "skill gates on human approval"
assert_contains "$body" "a commit separate from the feature work" "skill commits separately"
assert_contains "$body" '`refine`' "skill names the Prime Agent mechanism"
assert_contains "$body" '`writing-skills`' "skill routes new skills through writing-skills"
assert_contains "$body" "## Compound step" "skill defines the final-message section"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
assert_contains "$body" "It records what changed, not why the process failed." \
    "skill answers the git-history-is-the-record excuse"
lines=$(wc -l < "$skill")
[ "$lines" -lt 150 ] || fail "SKILL.md under 150 lines; got $lines"

exit "$ASSERT_FAILURES"
