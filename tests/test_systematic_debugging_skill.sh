#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

root="$REPO_ROOT/skills/systematic-debugging"
skill="$root/SKILL.md"
assert_file "$skill" "systematic-debugging has a SKILL.md"
assert_file "$root/README.md" "systematic-debugging has a README.md"
assert_file "$root/git-bisect.md" "fork adds the bisect technique file"
assert_file "$root/root-cause-tracing.md" "fork keeps upstream technique files"
body=$(cat "$skill")
assert_contains "$body" "name: systematic-debugging" "fork keeps the upstream name"
assert_contains "$body" "### Phase 1: Root Cause Investigation" "fork keeps upstream Phase 1"
assert_contains "$body" "## The Four Phases" "fork keeps the upstream structure"
assert_contains "$body" 'git log --oneline -20 -- <paths>' "Phase 1 seeds from recent changes"
assert_contains "$body" 'If the bug is a regression, use `git bisect run`' "Phase 1 names bisect for regressions"
assert_contains "$body" "git-bisect.md" "SKILL.md points at the bisect file"
assert_contains "$body" "git reflog" "Phase 1 names reflog recovery"
assert_contains "$body" "git log --all -S" "Phase 1 names pickaxe search"
bisect=$(cat "$root/git-bisect.md")
assert_contains "$bisect" "git bisect start" "bisect file has the start command"
assert_contains "$bisect" "git bisect run" "bisect file has the run command"
assert_contains "$bisect" "exit 125" "bisect file explains the skip exit code"
assert_contains "$bisect" "git bisect reset" "bisect file resets afterwards"
readme=$(cat "$root/README.md")
assert_contains "$readme" "b36e082" "README pins the upstream commit"
assert_contains "$readme" "superpowers/skills/systematic-debugging" "README names the upstream path"

exit "$ASSERT_FAILURES"
