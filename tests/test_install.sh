#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

IC="$REPO_ROOT/scripts/install-claude.sh"
IO="$REPO_ROOT/scripts/install-opencode.sh"

# --- absent harnesses: warn, skip, exit 0 ---
out=$("$IC" 2>&1); assert_eq "$?" 0 "install-claude exits 0 without claude"
assert_contains "$out" "claude not on PATH" "warned about missing claude"
out=$("$IO" 2>&1); assert_eq "$?" 0 "install-opencode exits 0 without opencode"
assert_contains "$out" "opencode not on PATH" "warned about missing opencode"
[ -e "$(claude_dir)/CLAUDE.md" ] && fail "install-claude wrote despite no claude"

# --- missing jq: warn and skip the OpenCode half, still exit 0 ---
stub_cmd opencode
out=$(PATH="$(path_without jq)" "$IO" 2>&1)
assert_eq "$?" 0 "install-opencode exits 0 without jq"
assert_contains "$out" "jq not on PATH" "warned about missing jq"
[ -e "$(opencode_dir)/opencode.jsonc" ] && fail "wrote a config without jq"
rm -f "$SANDBOX/bin/opencode"

# --- missing git: fatal, because the skills install cannot proceed ---
stub_cmd claude
assert_status 1 env "PATH=$(path_without git)" "$IC"
rm -f "$SANDBOX/bin/claude"

# --- claude install ---
stub_cmd claude
stub_cmd git
stub_swe_skills

# A hand-rolled setup left reviewer-light.md behind, declaring name:
# reviewer-lite. Install must retire it, or two files claim that agent name.
mkdir -p "$(claude_dir)/agents"
printf -- '---\nname: reviewer-lite\n---\nstale\n' \
    > "$(claude_dir)/agents/reviewer-light.md"

"$IC" >/dev/null 2>&1 || fail "install-claude failed"

[ -e "$(claude_dir)/agents/reviewer-light.md" ] \
    && fail "install left the legacy reviewer-light.md in place"
n=$(find "$(claude_dir)/agents" -name 'reviewer-light.md.bak.*' | wc -l)
assert_eq "$n" 1 "install backed the legacy file up instead of deleting it"
# Exactly one file may declare the reviewer-lite agent name. -R, not -r:
# the installed agents are symlinks, which -r skips while recursing.
n=$(grep -Rl '^name: reviewer-lite$' "$(claude_dir)/agents" 2>/dev/null \
    --include='*.md' | wc -l)
assert_eq "$n" 1 "exactly one live file declares name: reviewer-lite"

for a in "${CLAUDE_AGENTS[@]}"; do
    assert_symlink_to "$(claude_dir)/agents/$a.md" \
        "$REPO_ROOT/agents/$a.md" "agent $a linked"
done
# Claude Code gets the rendering that carries its own harness section only.
assert_symlink_to "$(claude_dir)/CLAUDE.md" \
    "$(rendered_agents_md claude)" "global CLAUDE.md linked"
installed=$(cat "$(claude_dir)/CLAUDE.md")
assert_contains "$installed" "$(harness_heading claude)" "Claude Code section installed"
assert_not_contains "$installed" "$(harness_heading prime)" "Prime section not installed"
assert_symlink_to "$(claude_dir)/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "skills installed for claude"

log_out=$(cat "$SANDBOX/claude.log")
assert_contains "$log_out" "plugin marketplace add anthropics/claude-plugins-official" \
    "marketplace added"
assert_contains "$log_out" "plugin install superpowers@claude-plugins-official" \
    "plugin installed"

# `general` and `explore` are built in to Claude Code; do not install them.
[ -e "$(claude_dir)/agents/general.md" ] && fail "general.md should not be installed"
[ -e "$(claude_dir)/agents/explore.md" ] && fail "explore.md should not be installed"

# --- claude install is idempotent ---
"$IC" >/dev/null 2>&1 || fail "second install-claude failed"
assert_symlink_to "$(claude_dir)/agents/reviewer.md" \
    "$REPO_ROOT/agents/reviewer.md" "agent still linked after re-run"
n=$(find "$(claude_dir)" -name 'CLAUDE.md.bak.*' | wc -l)
assert_eq "$n" 0 "no spurious backup on re-run"

# --- opencode install, default provider ---
stub_cmd opencode
"$IO" >/dev/null 2>&1 || fail "install-opencode failed"
CFG="$(opencode_dir)/opencode.jsonc"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-opus-5" "default provider is anthropic"
assert_symlink_to "$(opencode_dir)/AGENTS.md" \
    "$(rendered_agents_md opencode)" "global AGENTS.md linked"
installed=$(cat "$(opencode_dir)/AGENTS.md")
assert_contains "$installed" "$(harness_heading opencode)" "OpenCode section installed"
assert_not_contains "$installed" "$(harness_heading claude)" "Claude section not installed"
assert_symlink_to "$(opencode_dir)/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "skills installed for opencode"

# --- opencode install, explicit provider ---
"$IO" openai >/dev/null 2>&1 || fail "install-opencode openai failed"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-terra" "explicit provider honoured"

# --- comment guard aborts the whole opencode install ---
rm -f "$(opencode_dir)/AGENTS.md"
cat > "$CFG" <<'EOF'
{
  // hand-annotated
  "theme": "tokyonight"
}
EOF
assert_status 2 "$IO" anthropic
[ -e "$(opencode_dir)/AGENTS.md" ] && \
    fail "install continued past the comment guard"

exit "$ASSERT_FAILURES"
