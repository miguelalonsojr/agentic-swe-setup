#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

stub_cmd claude
stub_cmd opencode
stub_cmd git
stub_swe_skills

CFG="$(opencode_dir)/opencode.jsonc"
MAN="$(opencode_dir)/.agentic-swe-setup.json"
mkdir -p "$(opencode_dir)"

# A pre-existing config with keys this repo must never touch.
cat > "$CFG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "tokyonight",
  "agent": { "my-own-agent": { "model": "openai/gpt-5.6-luna" } },
  "plugin": ["some-other-plugin@1.0.0"],
  "provider": { "anthropic": { "options": { "timeout": 60000 } } }
}
EOF
pristine=$(jq -S . "$CFG")

bash "$REPO_ROOT/scripts/install-claude.sh"   >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-opencode.sh" openai >/dev/null 2>&1

# --- update keeps the recorded provider ---
bash "$REPO_ROOT/scripts/update.sh" >/dev/null 2>&1 || fail "update failed"
assert_eq "$(jq -r .provider "$MAN")" "openai" "update kept the provider"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-sol" "update re-merged the same provider"
assert_symlink_to "$(claude_dir)/agents/reviewer.md" \
    "$REPO_ROOT/agents/reviewer.md" "update relinked agents"

# --- uninstall removes only what we added ---
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "uninstall failed"

for a in "${CLAUDE_AGENTS[@]}"; do
    [ -e "$(claude_dir)/agents/$a.md" ] && fail "agent $a survived uninstall"
done
[ -e "$(claude_dir)/CLAUDE.md" ]   && fail "CLAUDE.md survived uninstall"
[ -e "$(opencode_dir)/AGENTS.md" ] && fail "AGENTS.md survived uninstall"
[ -e "$MAN" ] && fail "manifest survived uninstall"

assert_eq "$(jq -S . "$CFG")" "$pristine" "config restored to its pre-install state"

# --- shared installs are left alone, with instructions printed ---
[ -d "$SWE_SKILLS_DIR" ] || fail "uninstall removed the shared swe-skills checkout"
out=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1)
assert_contains "$out" "$SWE_SKILLS_DIR" "printed how to remove swe-skills"
assert_contains "$out" "claude plugin uninstall" "printed how to remove superpowers"

# --- uninstall is safe to run twice ---
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 \
    || fail "second uninstall failed"

# --- uninstall leaves a foreign symlink alone ---
mkdir -p "$(claude_dir)"
ln -sfn /etc/hostname "$(claude_dir)/CLAUDE.md"
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1
assert_symlink_to "$(claude_dir)/CLAUDE.md" /etc/hostname \
    "foreign CLAUDE.md left in place"

exit "$ASSERT_FAILURES"
