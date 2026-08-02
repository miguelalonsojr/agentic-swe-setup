#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- path resolvers honour the sandbox ---
assert_eq "$(claude_dir)" "$HOME/.claude" "claude_dir"
assert_eq "$(opencode_dir)" "$XDG_CONFIG_HOME/opencode" "opencode_dir"
assert_eq "$(swe_skills_dir)" "$SWE_SKILLS_DIR" "swe_skills_dir"

# --- constants ---
assert_eq "$SUPERPOWERS_PLUGIN" \
    "superpowers@git+https://github.com/obra/superpowers.git" "plugin string"
assert_eq "${#MANAGED_AGENTS[@]}" 7 "managed agent count"
assert_eq "${#CLAUDE_AGENTS[@]}" 5 "claude agent count"
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

# --- run_swe_skills_install drives the checkout's install.sh ---
stub_swe_skills
run_swe_skills_install claude
assert_symlink_to "$HOME/.claude/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "swe-skills claude link"
run_swe_skills_install opencode
assert_symlink_to "$XDG_CONFIG_HOME/opencode/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "swe-skills opencode link"

exit "$ASSERT_FAILURES"
