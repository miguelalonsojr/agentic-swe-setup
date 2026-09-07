#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/codebase-walkthrough"
skill="$root/SKILL.md"
assert_file "$skill" "codebase-walkthrough has a SKILL.md"
assert_file "$root/README.md" "codebase-walkthrough has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: codebase-walkthrough" "skill declares its name"
assert_contains "$body" "Snippets are pulled by command, never hand-copied." "skill forbids hand-copied code"
assert_contains "$body" "sed -n" "skill names sed for snippets"
assert_contains "$body" 'git diff <base>..HEAD' "skill supports branch scope"
assert_contains "$body" 'docs/walkthroughs/<slug>.md' "skill has a default output path"
assert_contains "$body" "Ask before committing." "skill does not commit unasked"
assert_contains "$body" "entry point" "skill orders from the entry point"
assert_contains "$body" "single-file HTML animation" "skill offers an interactive explanation"
assert_contains "$body" "Only on request." "interactive explanation is opt-in"
assert_contains "$body" "It does not replace the review dispatch." "walkthrough is not a review"
assert_contains "$body" "light-tier read-only subagents" "large scope delegates reading"
assert_contains "$body" '`uvx showboat --help`' "skill names Showboat as the optional format"
assert_contains "$body" "## Common Rationalizations" "skill has a rationalizations table"
lines=$(wc -l < "$skill")
[ "$lines" -lt 150 ] || fail "SKILL.md under 150 lines; got $lines"

exit "$ASSERT_FAILURES"
