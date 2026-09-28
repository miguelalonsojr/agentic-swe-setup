#!/usr/bin/env bash
set -uo pipefail
. "$REPO_ROOT/tests/lib/sandbox.sh"
. "$REPO_ROOT/scripts/lib.sh"
stub_cmd claude
stub_cmd opencode
stub_cmd prime-agent
stub_cmd git
stub_swe_skills
stub_superpowers
legacy="$XDG_CONFIG_HOME/opencode/opencode.jsonc"
legacy_manifest="$XDG_CONFIG_HOME/opencode/.agentic-swe-setup.json"
claude_instructions="$HOME/.claude/CLAUDE.md"
mkdir -p "$(dirname "$legacy")" "$(dirname "$claude_instructions")"
printf '{"theme":"tokyonight"}\n' > "$legacy"
printf '{"provider":"openai"}\n' > "$legacy_manifest"
printf 'user instructions\n' > "$claude_instructions"
legacy_before=$(cksum "$legacy" "$legacy_manifest" "$claude_instructions")
pdir=$(prime_dir)
mkdir -p "$pdir/harness"
printf '{"theme":"tokyonight"}\n' > "$pdir/settings.json"
prime_before=$(jq -S . "$pdir/settings.json")
bash "$REPO_ROOT/scripts/install-prime.sh" openai >/dev/null 2>&1 || fail 'Prime install failed'
harness="$pdir/harness/harness_state.json"
tmp=$(mktemp)
jq '.entries.subagent.my_own = {id:"my_own",kind:"subagent",title:"mine",content:"mine",metadata:{}}' "$harness" > "$tmp" && mv "$tmp" "$harness"
bash "$REPO_ROOT/scripts/update.sh" >/dev/null 2>&1 || fail 'update failed'
assert_eq "$(jq -r .provider "$pdir/.agentic-swe-setup.json")" openai 'update kept OpenAI provider'
assert_eq "$(jq -r .defaultProvider "$pdir/settings.json")" openai-codex 'update kept Prime selector'
assert_eq "$(cksum "$legacy" "$legacy_manifest" "$claude_instructions")" "$legacy_before" 'update left legacy files untouched'
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail 'uninstall failed'
assert_eq "$(cksum "$legacy" "$legacy_manifest" "$claude_instructions")" "$legacy_before" 'uninstall left legacy files untouched'
[ ! -e "$pdir/AGENTS.md" ] || fail 'Prime instructions survived uninstall'
[ ! -e "$pdir/.agentic-swe-setup.json" ] || fail 'Prime manifest survived uninstall'
assert_eq "$(jq -S . "$pdir/settings.json")" "$prime_before" 'user settings preserved'
for a in "${PRIME_AGENTS[@]}"; do
    key=${a//-/_}
    assert_eq "$(jq -r --arg k "$key" '.entries.subagent | has($k)' "$harness")" false "managed spec $a removed"
done
assert_eq "$(jq -r .entries.subagent.my_own.title "$harness")" mine 'user spec preserved'
[ ! -e "$pdir/skills/brainstorming" ] || fail 'Prime Superpowers link survived'
[ ! -e "$pdir/skills/jira-fu" ] || fail 'Prime local link survived'
out=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1)
assert_contains "$out" "$SWE_SKILLS_DIR" 'shared swe-skills retained'
assert_contains "$out" "$SUPERPOWERS_DIR" 'shared superpowers retained'
[ -d "$SWE_SKILLS_DIR" ] || fail 'shared skills checkout removed'
[ -d "$SUPERPOWERS_DIR" ] || fail 'shared Superpowers checkout removed'
ln -s /etc/hostname "$pdir/AGENTS.md"
ln -s /etc/hostname "$pdir/skills/de-slop"
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail 'second uninstall failed'
assert_symlink_to "$pdir/AGENTS.md" /etc/hostname 'foreign link preserved'
assert_symlink_to "$pdir/skills/de-slop" /etc/hostname 'foreign shared skill preserved'
exit "$ASSERT_FAILURES"
