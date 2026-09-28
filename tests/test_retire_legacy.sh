#!/usr/bin/env bash
set -uo pipefail
. "$REPO_ROOT/tests/lib/sandbox.sh"
. "$REPO_ROOT/scripts/lib.sh"
assert_missing() { [ ! -e "$1" ] && [ ! -L "$1" ] || fail "$2: $1"; }
RETIRE="$REPO_ROOT/scripts/retire-legacy.sh"
OC=$(opencode_dir)
CFG="$OC/opencode.jsonc"
MAN="$OC/.agentic-swe-setup.json"
mkdir -p "$OC/skills" "$(claude_dir)/agents" "$(claude_dir)/skills" "$(prime_dir)"
ln -s "$REPO_ROOT/AGENTS.md" "$(prime_dir)/AGENTS.md"
cat > "$SANDBOX/bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SANDBOX/claude.log"
case "$*" in
  'plugin list --json') cat "$SANDBOX/plugins.json" ;;
  'plugin uninstall superpowers') exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$SANDBOX/bin/claude"
export SANDBOX
printf '[{"id":"superpowers@claude-plugins-official"}]\n' > "$SANDBOX/plugins.json"
cat > "$MAN" <<'EOF'
{"provider":"openai","agents":["general","reviewer"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
jq -n --slurpfile owned "$REPO_ROOT/scripts/retire-legacy-managed.json" '{theme:"tokyonight",agent:{general:$owned[0].openai.agent.general,reviewer:{model:"custom/model"},mine:{model:"local/model"}},provider:{openai:$owned[0].openai.provider.openai},plugin:["superpowers@git+https://github.com/obra/superpowers.git","my-plugin"]}' > "$CFG"
ln -s "$REPO_ROOT/AGENTS.md" "$OC/AGENTS.md"
ln -s "$REPO_ROOT/agents/reviewer.md" "$(claude_dir)/agents/reviewer.md"
mkdir -p "$SANDBOX/external" "$SWE_SKILLS_DIR/skills/clean-coding"
ln -s "$SANDBOX/external" "$OC/skills/routing-model-tiers"
ln -s "$SWE_SKILLS_DIR/skills/clean-coding" "$(claude_dir)/skills/clean-coding"
output=$(bash "$RETIRE" 2>&1); status=$?
assert_eq "$status" '0' 'retirement with retained changed entries exits cleanly'
assert_missing "$OC/AGENTS.md" 'owned OpenCode link removed'
assert_missing "$(claude_dir)/agents/reviewer.md" 'owned Claude link removed'
assert_missing "$(claude_dir)/skills/clean-coding" 'shared checkout skill removed'
assert_file "$(prime_dir)/AGENTS.md" 'Prime link preserved'
assert_contains "$(cat "$SANDBOX/claude.log")" 'plugin uninstall superpowers' 'Claude plugin retired'
assert_eq "$(jq -r '.theme' "$CFG")" 'tokyonight' 'unrelated theme preserved'
assert_eq "$(jq -r '.agent | has("general")' "$CFG")" 'false' 'equal agent removed'
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" 'custom/model' 'changed agent preserved'
assert_eq "$(jq -r '.agent.mine.model' "$CFG")" 'local/model' 'unmanaged agent preserved'
assert_eq "$(jq -r '.provider | has("openai")' "$CFG")" 'false' 'equal provider removed'
assert_eq "$(jq -r '.plugin | join(",")' "$CFG")" 'my-plugin' 'only recorded plugin removed'
[ -L "$OC/skills/routing-model-tiers" ] || fail 'external symlink was removed'
assert_contains "$output" 'reviewer' 'changed agent reported'
assert_missing "$MAN" 'completed manifest removed'
[ "$(find "$OC" -maxdepth 1 -name 'opencode.jsonc.bak.*' | wc -l)" -eq 0 ] || fail 'retirement created a backup'
cp "$CFG" "$SANDBOX/after-first.json"
printf '[]\n' > "$SANDBOX/plugins.json"
output=$(bash "$RETIRE" 2>&1); status=$?
assert_eq "$status" '0' 'repeated run succeeds'
assert_eq "$(cksum < "$CFG")" "$(cksum < "$SANDBOX/after-first.json")" 'repeated run leaves config alone'
assert_eq "$(grep -c 'plugin uninstall superpowers' "$SANDBOX/claude.log")" '1' 'absent Claude plugin not uninstalled'
jq ".openai" "$REPO_ROOT/scripts/retire-legacy-managed.json" > "$CFG"
jq '.provider.openai.options.store = true' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
cat > "$MAN" <<'EOF'
{"provider":"openai","agents":["general"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
output=$(bash "$RETIRE" 2>&1); status=$?
assert_eq "$status" '0' 'changed provider explicitly retained'
assert_eq "$(jq -r '.provider.openai.options.store' "$CFG")" 'true' 'changed provider preserved'
assert_contains "$output" 'provider.openai' 'changed provider reported'
# Anthropic has no managed provider block; unrelated provider survives.
cat > "$MAN" <<'EOF'
{"provider":"anthropic","agents":["general"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
jq -n --slurpfile owned "$REPO_ROOT/scripts/retire-legacy-managed.json" '{theme:"tokyonight",agent:{general:$owned[0].anthropic.agent.general},provider:{openai:{options:{store:true}}},plugin:["my-plugin"]}' > "$CFG"
output=$(bash "$RETIRE" 2>&1); status=$?
assert_eq "$status" '0' 'anthropic retirement succeeds'
assert_eq "$(jq -r '.agent | has("general")' "$CFG")" 'false' 'anthropic agent removed'
assert_eq "$(jq -r '.provider.openai.options.store' "$CFG")" 'true' 'unmanaged provider preserved'

# Unreadable plugin list must not result in a false successful retirement.
cat > "$MAN" <<'EOF'
{"provider":"anthropic","agents":["general"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
printf 'not-json\n' > "$SANDBOX/plugins.json"
before=$(cksum < "$CFG")
output=$(bash "$RETIRE" 2>&1); status=$?
[ "$status" -ne 0 ] || fail 'unreadable plugin list unexpectedly succeeded'
assert_eq "$(cksum < "$CFG")" "$before" 'plugin preflight did not edit config'
assert_file "$MAN" 'manifest retained on plugin failure'
printf '[]\n' > "$SANDBOX/plugins.json"

printf '// user comment\n{"theme":"tokyonight"}\n' > "$CFG"
cat > "$MAN" <<'EOF'
{"provider":"anthropic","agents":["general"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
before=$(cksum < "$CFG")
output=$(bash "$RETIRE" 2>&1); status=$?
[ "$status" -ne 0 ] || fail 'non-JSON config unexpectedly succeeded'
assert_eq "$(cksum < "$CFG")" "$before" 'non-JSON config unchanged'
assert_file "$MAN" 'manifest retained on unsafe config'
assert_contains "$output" 'strict JSON' 'invalid config explained'
printf '{broken' > "$MAN"
before=$(cksum < "$CFG")
output=$(bash "$RETIRE" 2>&1); status=$?
[ "$status" -ne 0 ] || fail 'invalid manifest unexpectedly succeeded'
assert_eq "$(cksum < "$CFG")" "$before" 'invalid manifest did not touch config'
assert_file "$MAN" 'invalid manifest retained'

cat > "$MAN" <<'EOF'
{"provider":"openai","agents":["general"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
jq -n --slurpfile owned "$REPO_ROOT/scripts/retire-legacy-managed.json" '{theme:"tokyonight",agent:{general:$owned[0].openai.agent.general}}' > "$CFG"
# Unknown plugin-list shapes must fail before editing any owned item.
for invalid in '{"installed":[],"available":[{"name":"superpowers"}]}' '42' '[{"id":"superpowers@claude-plugins-official"},{"id":"superpowers@claude-plugins-official"}]' $'{"installed":[]}\n[]' $'[{"id":"superpowers@claude-plugins-official"}]\n[]'; do
    printf '%s\n' "$invalid" > "$SANDBOX/plugins.json"
    ln -sfn "$REPO_ROOT/AGENTS.md" "$OC/AGENTS.md"
    before=$(cksum < "$CFG")
    output=$(bash "$RETIRE" 2>&1); status=$?
    [ "$status" -ne 0 ] || fail "unknown plugin list succeeded: $invalid"
    assert_eq "$(cksum < "$CFG")" "$before" 'unknown plugin list changed config'
    [ -L "$OC/AGENTS.md" ] || fail 'unknown plugin list removed owned link'
    assert_file "$MAN" 'unknown plugin list removed manifest'
done
printf '[]\n' > "$SANDBOX/plugins.json"

# A missing source is still a known link; another dangling source is not.
rm -f "$OC/AGENTS.md"
ln -s "$REPO_ROOT/build/opencode/openai/AGENTS.md" "$OC/AGENTS.md"
ln -sfn "$REPO_ROOT/agents/reviewer.md" "$(claude_dir)/agents/reviewer.md"
rm -rf "$SWE_SKILLS_DIR/skills/clean-coding"
ln -sfn "$SWE_SKILLS_DIR/skills/clean-coding" "$(claude_dir)/skills/clean-coding"
ln -s "$SANDBOX/nonexistent/skills/routing-model-tiers" "$OC/skills/routing-model-tiers.unrelated"
ln -s "$SANDBOX/nonexistent/skills/superpowers" "$OC/skills/superpowers"
output=$(bash "$RETIRE" 2>&1); status=$?
assert_eq "$status" '0' 'dangling sources retire safely'
assert_missing "$OC/AGENTS.md" 'dangling generated OpenCode link removed'
assert_missing "$(claude_dir)/agents/reviewer.md" 'dangling agent link removed'
assert_missing "$(claude_dir)/skills/clean-coding" 'dangling shared skill link removed'
[ -L "$OC/skills/superpowers" ] || fail 'unrelated dangling link removed'

# Standalone command must run with lib path helpers deleted.
mkdir -p "$SANDBOX/retire-copy/scripts"
cp "$RETIRE" "$SANDBOX/retire-copy/scripts/retire-legacy.sh"
cp "$REPO_ROOT/scripts/retire-legacy-managed.json" "$SANDBOX/retire-copy/scripts/retire-legacy-managed.json"
cat > "$SANDBOX/retire-copy/scripts/lib.sh" <<'EOF'
REPO_ROOT="${ORIGINAL_REPO_ROOT:?}"
have() { command -v "$1" >/dev/null 2>&1; }
log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
EOF
export ORIGINAL_REPO_ROOT="$REPO_ROOT"
ln -sfn "$REPO_ROOT/AGENTS.md" "$OC/AGENTS.md"
output=$(bash "$SANDBOX/retire-copy/scripts/retire-legacy.sh" 2>&1); status=$?
assert_eq "$status" '0' 'standalone retirement without legacy lib helpers'
assert_missing "$OC/AGENTS.md" 'standalone retirement removed owned link'
exit "$ASSERT_FAILURES"
