#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- path resolvers honour the sandbox ---
assert_eq "$(swe_skills_dir)" "$SWE_SKILLS_DIR" "swe_skills_dir"

# --- constants ---
assert_eq "${#PRIME_AGENTS[@]}" 9 "managed agent count"
assert_eq "${#SKILL_NAMES[@]}" 8 "skill count"

# --- have ---
assert_status 0 have bash
assert_status 1 have definitely-not-a-real-command-xyz

# --- link_into creates a symlink ---
src="$SANDBOX/src.txt"
echo hello > "$src"
link_into "$src" "$HOME/nested/dest.txt"
assert_symlink_to "$HOME/nested/dest.txt" "$src" "link_into creates symlink"

# --- link_into backs up a real file it would clobber ---
real="$HOME/real.txt"
echo original > "$real"
link_into "$src" "$real" 2>/dev/null
assert_symlink_to "$real" "$src" "link_into replaced real file"
backups=$(find "$HOME" -maxdepth 1 -name 'real.txt.bak.*' | wc -l)
assert_eq "$backups" 1 "link_into wrote exactly one backup"
assert_eq "$(cat "$HOME"/real.txt.bak.*)" "original" "backup kept contents"

# --- link_into is idempotent ---
link_into "$src" "$real"
assert_symlink_to "$real" "$src" "link_into idempotent"
backups=$(find "$HOME" -maxdepth 1 -name 'real.txt.bak.*' | wc -l)
assert_eq "$backups" 1 "no second backup for an existing symlink"

# --- links_into_repo ---
ln -sfn "$REPO_ROOT/AGENTS.md" "$HOME/inrepo.md"
assert_status 0 links_into_repo "$HOME/inrepo.md"
assert_status 1 links_into_repo "$HOME/nested/dest.txt"
assert_status 1 links_into_repo "$HOME/does-not-exist"

# --- Prime-only provider paths and headings ---
assert_eq "${HARNESSES[*]}" prime "only Prime harness rendered"
assert_eq "$(harness_heading prime)" '#### When running under Prime Agent'     "Prime heading"
assert_status 1 harness_heading opencode
assert_eq "$(rendered_agents_md prime openai)"     "$REPO_ROOT/build/prime/openai/AGENTS.md" "Prime provider render path"
exit "$ASSERT_FAILURES"
