#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skill="$REPO_ROOT/skills/dispatching-parallel-agents/SKILL.md"
assert_file "$skill" "dispatching-parallel-agents has a SKILL.md"
body=$(cat "$skill")
assert_contains "$body" 'Classify every task as `read-only` or `write-capable`'     "parallel skill classifies access mode"
assert_contains "$body" "A different file does not prove independence"     "parallel skill checks interfaces and shared state"
assert_contains "$body" "Dispatch the largest safe wave"     "parallel skill maximizes safe concurrency"
assert_contains "$body" "A safe wave contains only tasks whose dependencies are satisfied and whose collision edges are resolved"     "parallel skill requires satisfied dependencies"
assert_contains "$body" "controller-created worktree"     "parallel skill isolates every concurrent writer"
for item in "expected files" "interfaces" "generated artifacts" "lockfiles" "migrations" "configuration" "external resources"; do
    assert_contains "$body" "$item" "parallel skill inventories $item"
done
assert_contains "$body" "controller assigns it before dispatch"     "parallel skill assigns namespaces before dispatch"
assert_contains "$body" "unique among tasks in the wave"     "parallel skill requires wave-unique namespaces"
assert_contains "$body" "explicit and testable"     "parallel skill requires testable namespaces"
assert_contains "$body" "namespace ruling adds or removes"     "parallel skill records namespace edge rulings"
assert_contains "$body" "Unexpected overlap"     "parallel skill stops unsafe integration"

exit "$ASSERT_FAILURES"
