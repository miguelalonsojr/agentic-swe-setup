#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/finishing-a-development-branch"
skill="$root/SKILL.md"
assert_file "$skill" "finishing-a-development-branch has a SKILL.md"
assert_file "$root/README.md" "finishing-a-development-branch has a README.md"
body=$(cat "$skill")
assert_contains "$body" "name: finishing-a-development-branch" "fork keeps the upstream name"
# Upstream anchors: prove this is a fork, not a rewrite.
assert_contains "$body" "## Step 1: Verify Tests" "fork keeps upstream Step 1"
assert_contains "$body" "Type 'discard' to confirm." "fork keeps the upstream discard gate"
assert_contains "$body" "## Step 6: Cleanup Workspace" "fork keeps upstream cleanup"
# Additions.
assert_contains "$body" "### Step 1b: Manual check" "fork adds the manual check"
assert_contains "$body" '`agentic-manual-testing`' "manual check names the skill"
assert_contains "$body" "### Step 1c: Tidy history" "fork adds history tidy"
assert_contains "$body" "Squash fix-round and WIP commits into the task commit they fix." "tidy squashes fix rounds"
assert_contains "$body" "Never rewrite commits already on a shared branch." "tidy protects shared history"
assert_contains "$body" "### Step 1d: Size report" "fork adds the size report"
assert_contains "$body" "Above 500 lines or 10 files, offer a split into stacked PRs by task." "size report has the threshold"
assert_contains "$body" "### PR description contract" "fork adds the PR contract"
assert_contains "$body" "reviewed the diff and this description" "PR contract has the author-reviewed line"
assert_contains "$body" "Present the PR body in chat and wait for approval before posting." "PR body is approved first"
assert_contains "$body" 'Run `compound-step` if it has not already run for this branch.' "fork hooks the compound step"
readme=$(cat "$root/README.md")
assert_contains "$readme" "b36e082" "README pins the upstream commit"
assert_contains "$readme" "superpowers/skills/finishing-a-development-branch" "README names the upstream path"

exit "$ASSERT_FAILURES"
