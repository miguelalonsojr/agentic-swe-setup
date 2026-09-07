#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/agentic-manual-testing"
skill="$root/SKILL.md"
assert_file "$skill" "agentic-manual-testing has a SKILL.md"
assert_file "$root/README.md" "agentic-manual-testing has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: agentic-manual-testing" "skill declares its name"
assert_contains "$body" "description: Use after the tests pass and before claiming a change works" \
    "skill triggers after green and before a completion claim"
assert_contains "$body" "Never assume generated code works until it has been executed." \
    "skill states the core rule"
assert_contains "$body" "Passing tests are necessary, not sufficient." \
    "skill states tests are not sufficient"
assert_contains "$body" "Manual testing is not a substitute for tests." \
    "skill does not compete with TDD"
assert_contains "$body" "A bug found by manual testing is fixed with red/green TDD." \
    "skill routes found bugs back to TDD"
assert_contains "$body" "Output is pasted from the run, never typed." \
    "skill forbids typed evidence"
assert_contains "$body" 'name the exact command you would run' \
    "skill handles the cannot-run case"
for mech in '`python -c`' '`curl`' '`uvx rodney --help`' 'Playwright' 'under `/tmp`' '`uvx showboat --help`'; do
    assert_contains "$body" "$mech" "skill names mechanism $mech"
done
assert_contains "$body" "This is not a second test suite." "skill bounds its scope"
assert_contains "$body" "## Evidence" "skill has an evidence section"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
lines=$(wc -l < "$skill")
[ "$lines" -lt 200 ] || fail "SKILL.md under 200 lines; got $lines"

exit "$ASSERT_FAILURES"
