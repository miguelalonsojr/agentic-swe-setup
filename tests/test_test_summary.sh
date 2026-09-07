#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

script="$REPO_ROOT/skills/subagent-driven-development/scripts/test-summary"
assert_file "$script" "test-summary is present"
[ ! -f "$script" ] || [ -x "$script" ] || fail "test-summary is executable"
[ -x "$script" ] || exit "$ASSERT_FAILURES"

logdir="$SANDBOX/logs"

# Success: header lines plus the last line only.
out=$("$script" --log-dir "$logdir" -- bash -c 'printf "collecting\nline two\n42 passed in 0.3s\n"'; echo "status=$?")
assert_contains "$out" "exit=0" "success prints exit=0"
assert_contains "$out" "log=$logdir/" "success prints the log path"
assert_contains "$out" "42 passed in 0.3s" "success prints the summary line"
assert_not_contains "$out" "collecting" "success hides earlier output"
assert_contains "$out" "status=0" "success propagates exit 0"
log=$(ls "$logdir"/*.log | head -1)
assert_contains "$(cat "$log")" "collecting" "log keeps the full output"

# Failure: marker lines and tail, and the exit code propagates.
out=$("$script" --log-dir "$logdir" -- bash -c 'printf "ok 1\nnot ok 2 - thing\nFAIL: needle missing\n"; exit 3'; echo "status=$?")
assert_contains "$out" "exit=3" "failure prints the exit code"
assert_contains "$out" "not ok 2 - thing" "failure prints not-ok lines"
assert_contains "$out" "FAIL: needle missing" "failure prints FAIL lines"
assert_contains "$out" "status=3" "failure propagates the exit code"

# Usage error.
assert_status 2 "$script" --log-dir "$logdir"

exit "$ASSERT_FAILURES"
