#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

stub_cmd claude
stub_cmd opencode
stub_cmd prime-agent
stub_cmd git
stub_swe_skills
stub_superpowers

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

# Prime Agent settings the user owns, plus a spec this repo must never remove.
PDIR="$(prime_dir)"
PMAN="$PDIR/.agentic-swe-setup.json"
PHARNESS="$PDIR/harness/harness_state.json"
mkdir -p "$PDIR/harness"
printf '{"theme":"tokyonight"}\n' > "$PDIR/settings.json"
prime_pristine=$(jq -S . "$PDIR/settings.json")

bash "$REPO_ROOT/scripts/install-claude.sh"   >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-opencode.sh" openai >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-prime.sh"    openai >/dev/null 2>&1

tmp=$(mktemp)
jq '.entries.subagent.my_own = {id:"my_own",kind:"subagent",title:"mine",
    content:"mine",metadata:{}}' "$PHARNESS" > "$tmp" && mv "$tmp" "$PHARNESS"

# --- update keeps the recorded provider ---
bash "$REPO_ROOT/scripts/update.sh" >/dev/null 2>&1 || fail "update failed"
assert_eq "$(jq -r .provider "$MAN")" "openai" "update kept the provider"
assert_eq "$(jq -r .provider "$PMAN")" "openai" "update kept the prime provider"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-terra" "update re-merged the same provider"
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

# --- Prime Agent: managed keys and specs go, the user's own stay ---
[ -e "$PDIR/AGENTS.md" ] && fail "prime AGENTS.md survived uninstall"
[ -e "$PMAN" ] && fail "prime manifest survived uninstall"
assert_eq "$(jq -S . "$PDIR/settings.json")" "$prime_pristine" \
    "prime settings restored to their pre-install state"
for a in "${PRIME_AGENTS[@]}"; do
    key=${a//-/_}
    assert_eq "$(jq -r --arg k "$key" '.entries.subagent | has($k)' "$PHARNESS")" \
        "false" "managed spec $a removed"
done
assert_eq "$(jq -r '.entries.subagent.my_own.title' "$PHARNESS")" "mine" \
    "unmanaged spec survived uninstall"
[ -e "$PDIR/skills/brainstorming" ] && fail "prime superpowers skill survived"
[ -e "$PDIR/skills/jira-fu" ] && fail "prime local skill survived"

# --- shared installs are left alone, with instructions printed ---
[ -d "$SWE_SKILLS_DIR" ] || fail "uninstall removed the shared swe-skills checkout"
out=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1)
assert_contains "$out" "$SWE_SKILLS_DIR" "printed how to remove swe-skills"
assert_contains "$out" "claude plugin uninstall" "printed how to remove superpowers"
[ -d "$SUPERPOWERS_DIR" ] || fail "uninstall removed the shared superpowers checkout"
assert_contains "$out" "$SUPERPOWERS_DIR" "printed how to remove superpowers checkout"

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
