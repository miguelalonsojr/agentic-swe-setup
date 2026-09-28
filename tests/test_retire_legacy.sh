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
printf '[{"name":"superpowers"}]\n' > "$SANDBOX/plugins.json"
cat > "$MAN" <<'EOF'
{"provider":"openai","agents":["general","reviewer"],"plugin":"superpowers@git+https://github.com/obra/superpowers.git","provider_key":"provider.openai"}
EOF
jq -n --slurpfile owned "$REPO_ROOT/opencode/openai.json" '{theme:"tokyonight",agent:{general:$owned[0].agent.general,reviewer:{model:"custom/model"},mine:{model:"local/model"}},provider:{openai:$owned[0].provider.openai},plugin:["superpowers@git+https://github.com/obra/superpowers.git","my-plugin"]}' > "$CFG"
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
cp "$REPO_ROOT/opencode/openai.json" "$CFG"
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
jq -n --slurpfile owned "$REPO_ROOT/opencode/anthropic.json" '{theme:"tokyonight",agent:{general:$owned[0].agent.general},provider:{openai:{options:{store:true}}},plugin:["my-plugin"]}' > "$CFG"
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
exit "$ASSERT_FAILURES"
