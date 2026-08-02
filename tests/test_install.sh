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
"$IC" >/dev/null 2>&1 || fail "install-claude failed"

for a in "${CLAUDE_AGENTS[@]}"; do
    assert_symlink_to "$(claude_dir)/agents/$a.md" \
        "$REPO_ROOT/agents/$a.md" "agent $a linked"
done
assert_symlink_to "$(claude_dir)/CLAUDE.md" \
    "$REPO_ROOT/AGENTS.md" "global CLAUDE.md linked"
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
    "anthropic/claude-fable-5" "default provider is anthropic"
assert_symlink_to "$(opencode_dir)/AGENTS.md" \
    "$REPO_ROOT/AGENTS.md" "global AGENTS.md linked"
assert_symlink_to "$(opencode_dir)/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "skills installed for opencode"

# --- opencode install, explicit provider ---
"$IO" openai >/dev/null 2>&1 || fail "install-opencode openai failed"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-sol" "explicit provider honoured"

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
