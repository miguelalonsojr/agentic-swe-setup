#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skill="$REPO_ROOT/skills/dispatching-parallel-agents/SKILL.md"
assert_file "$skill" "dispatching-parallel-agents has a SKILL.md"
body=$(cat "$skill")
assert_contains "$body" '`read-only` or `write-capable`' "parallel skill classifies access mode"
assert_contains "$body" "satisfied dependencies and resolved collision edges" "parallel skill requires satisfied dependencies"
assert_contains "$body" "Dispatch the largest safe wave" "parallel skill maximizes safe concurrency"
assert_contains "$body" "controller-created worktree" "parallel skill isolates every concurrent writer"
for inventory_row in \
    '| Dependencies and access mode | Prerequisites and `read-only` or `write-capable` |' \
    '| Repository scope | Files, interfaces, generated artifacts, lockfiles, migrations, and configuration read or changed |' \
    '| External scope | Resources such as ports, databases, services, and test fixtures; controller-assigned namespaces |' \
    '| Graph | Collision edges, their producers and consumers, and rulings that add or remove edges |'; do
    assert_contains "$body" "$inventory_row" "parallel skill retains complete inventory row: $inventory_row"
done
assert_contains "$body" "one task produces or writes shared state and another task consumes, produces, or writes it" "parallel skill detects writer-mediated shared-state collisions"
assert_contains "$body" "different files or disjoint test files" "parallel skill rejects file-only independence"
assert_contains "$body" "controller assigns a namespace before dispatch" "parallel skill assigns namespaces before dispatch"
assert_contains "$body" "unique in the wave, explicit, and testable" "parallel skill qualifies namespaces"
assert_contains "$body" "Retain repository-state edges" "parallel skill preserves repository-state collisions"
assert_contains "$body" "uncertain write scope" "parallel skill explores uncertain writes"
assert_contains "$body" "unexpected overlap" "parallel skill stops unsafe integration"

exit "$ASSERT_FAILURES"
