#!/usr/bin/env bash
set -uo pipefail
. "$REPO_ROOT/tests/lib/sandbox.sh"
. "$REPO_ROOT/scripts/lib.sh"
stub_cmd claude
stub_cmd opencode
stub_cmd prime-agent
stub_cmd git
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
[ ! -e "$SWE_SKILLS_DIR" ] || fail 'install or update created an old checkout'
# A previous checkout is optional and must remain untouched during cleanup.
stub_swe_skills
# Old managed links are removed even for names outside the former fixed list.
ln -s "$SWE_SKILLS_DIR/skills/old-extra" "$pdir/skills/old-extra"
ln -s "$SWE_SKILLS_DIR/book-skills/old-book" "$pdir/skills/old-book"
ln -s "$(realpath -ms --relative-to="$pdir/skills" "$SWE_SKILLS_DIR/skills/old-relative")" \
    "$pdir/skills/old-relative"
ln -s "$SWE_SKILLS_DIR/skills/another-name" "$pdir/skills/old-mismatched"
ln -s "$SUPERPOWERS_DIR/skills/removed-upstream" "$pdir/skills/removed-upstream"
checkout_before=$(find "$SWE_SKILLS_DIR" "$SUPERPOWERS_DIR" -type f -exec cksum {} + | sort)
# Equivalent relative targets are owned too, but foreign and mismatched links are not.
ln -sfn "$(realpath -ms --relative-to="$pdir/skills" "$REPO_ROOT/skills/confluence-diagrams")" \
    "$pdir/skills/confluence-diagrams"
mkdir -p "$pdir/skills/user-skill"
printf 'user content\n' > "$pdir/skills/user-skill/SKILL.md"
ln -sfn "$(realpath -ms --relative-to="$pdir/skills" "$SUPERPOWERS_DIR/skills/writing-plans")" \
    "$pdir/skills/writing-plans"
ln -s "$SANDBOX/missing-foreign" "$pdir/skills/foreign"
ln -s "$SUPERPOWERS_DIR/skills/another-name" "$pdir/skills/mismatched"
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail 'uninstall failed'
for s in "${LOCAL_SKILLS[@]}" brainstorming writing-plans old-extra old-book old-relative removed-upstream; do
    [ ! -L "$pdir/skills/$s" ] || fail "dangling managed skill $s survived uninstall"
done
[ -L "$pdir/skills/foreign" ] || fail 'dangling foreign skill removed'
[ -L "$pdir/skills/mismatched" ] || fail 'mismatched shared skill removed'
[ -L "$pdir/skills/old-mismatched" ] || fail 'mismatched old shared skill removed'
assert_eq "$(cat "$pdir/skills/user-skill/SKILL.md")" 'user content' 'user directory preserved'
assert_eq "$(find "$SWE_SKILLS_DIR" "$SUPERPOWERS_DIR" -type f -exec cksum {} + | sort)" "$checkout_before" 'uninstall did not change shared checkout files'
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
assert_not_contains "$out" "rm -rf $SWE_SKILLS_DIR" 'no old checkout deletion advice'
assert_contains "$out" "$SUPERPOWERS_DIR" 'shared superpowers retained'
[ -d "$SWE_SKILLS_DIR" ] || fail 'shared skills checkout removed'
[ -d "$SUPERPOWERS_DIR" ] || fail 'shared Superpowers checkout removed'
ln -s /etc/hostname "$pdir/AGENTS.md"
ln -sfn /etc/hostname "$pdir/skills/de-slop"
ln -sfn "$REPO_ROOT/skills/search-fu" "$pdir/skills/clean-coding"
ln -sfn "$REPO_ROOT/README.md" "$pdir/skills/confluence-diagrams"
bash "$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail 'second uninstall failed'
assert_symlink_to "$pdir/AGENTS.md" /etc/hostname 'foreign link preserved'
assert_symlink_to "$pdir/skills/de-slop" /etc/hostname 'foreign shared skill preserved'
assert_symlink_to "$pdir/skills/clean-coding" "$REPO_ROOT/skills/search-fu" 'same-repo different skill preserved'
assert_symlink_to "$pdir/skills/confluence-diagrams" "$REPO_ROOT/README.md" 'same-repo different file preserved'

# Missing intermediate local sources: fixture scripts, never remove real skills.
fixture="$SANDBOX/fixture"
mkdir -p "$fixture/scripts"
cp "$REPO_ROOT/scripts/lib.sh" "$REPO_ROOT/scripts/uninstall.sh" "$fixture/scripts/"
export PRIME_AGENT_CODING_AGENT_DIR="$SANDBOX/fixture-prime"
mkdir -p "$PRIME_AGENT_CODING_AGENT_DIR/skills"
for s in confluence-diagrams low-level-design; do
    target="$fixture/skills/$s"
    if [ "$s" = low-level-design ]; then
        target=$(realpath -ms --relative-to="$PRIME_AGENT_CODING_AGENT_DIR/skills" "$target")
    fi
    ln -s "$target" "$PRIME_AGENT_CODING_AGENT_DIR/skills/$s"
done
ln -s "$fixture/README.md" "$PRIME_AGENT_CODING_AGENT_DIR/skills/clean-coding"
export SWE_SKILLS_DIR="$SANDBOX/missing-old-tree"
ln -s "$SWE_SKILLS_DIR/skills/old-extra" "$PRIME_AGENT_CODING_AGENT_DIR/skills/old-extra"
ln -s "$(realpath -ms --relative-to="$PRIME_AGENT_CODING_AGENT_DIR/skills" "$SWE_SKILLS_DIR/book-skills/old-book")" \
    "$PRIME_AGENT_CODING_AGENT_DIR/skills/old-book"
bash "$fixture/scripts/uninstall.sh" >/dev/null 2>&1 || fail 'fixture uninstall failed'
for s in confluence-diagrams low-level-design old-extra old-book; do
    [ ! -L "$PRIME_AGENT_CODING_AGENT_DIR/skills/$s" ] || fail "missing-intermediate local skill $s survived"
done
[ -L "$PRIME_AGENT_CODING_AGENT_DIR/skills/clean-coding" ] || fail 'fixture foreign same-repo target removed'
[ ! -e "$fixture/skills" ] || fail 'fixture missing source tree was created'
[ ! -e "$SWE_SKILLS_DIR" ] || fail 'fixture missing old checkout was created'
exit "$ASSERT_FAILURES"
