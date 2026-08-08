#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

MERGE="$REPO_ROOT/scripts/merge-opencode.sh"
CFG="$(opencode_dir)/opencode.jsonc"
MAN="$(opencode_dir)/.agentic-swe-setup.json"
mkdir -p "$(opencode_dir)"

# --- creates a config from nothing ---
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed on a fresh install"
assert_file "$CFG" "merge created the config"
assert_eq "$(jq -r '."$schema"' "$CFG")" \
    "https://opencode.ai/config.json" "schema key present"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-opus-5" "anthropic reviewer merged"
assert_eq "$(jq -r '.agent["reviewer-final"].model' "$CFG")" \
    "anthropic/claude-fable-5" "anthropic final reviewer merged"
assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
    '(.plugin // []) | index($p) != null' "$CFG")" "true" "plugin merged"
assert_file "$MAN" "manifest written"
assert_eq "$(jq -r .provider "$MAN")" "anthropic" "manifest records provider"

# --- preserves unmanaged keys ---
cat > "$CFG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "tokyonight",
  "agent": { "my-own-agent": { "model": "openai/gpt-5.6-luna" } },
  "plugin": ["some-other-plugin@1.0.0"],
  "mcp": { "fetch": { "type": "local", "command": ["uvx", "mcp-server-fetch"] } }
}
EOF
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed over an existing config"
assert_eq "$(jq -r '.theme' "$CFG")" "tokyonight" "unmanaged top-level key kept"
assert_eq "$(jq -r '.agent["my-own-agent"].model' "$CFG")" \
    "openai/gpt-5.6-luna" "unmanaged agent kept"
assert_eq "$(jq -r '.mcp.fetch.type' "$CFG")" "local" "mcp block kept"
assert_eq "$(jq -r '.plugin | index("some-other-plugin@1.0.0") != null' "$CFG")" \
    "true" "other plugin kept"
assert_eq "$(jq -r '.agent | length' "$CFG")" "$(( ${#MANAGED_AGENTS[@]} + 1 ))" \
    "every managed agent plus the one unmanaged agent"

# --- plugin is appended, not duplicated ---
"$MERGE" anthropic >/dev/null 2>&1
assert_eq "$(jq -r --arg p "$SUPERPOWERS_PLUGIN" \
    '[.plugin[] | select(. == $p)] | length' "$CFG")" "1" "plugin not duplicated"

# --- a backup is written for every merge over an existing file ---
before=$(find "$(opencode_dir)" -maxdepth 1 -name 'opencode.jsonc.bak.*' | wc -l)
[ "$before" -ge 1 ] || fail "no backup written"

# --- provider switch: openai adds the provider block ---
"$MERGE" openai >/dev/null 2>&1 || fail "merge failed for openai"
assert_eq "$(jq -r '.provider.openai.options.store' "$CFG")" \
    "false" "openai provider block added"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "openai/gpt-5.6-terra" "openai reviewer merged"

# --- provider switch back: the openai block is removed, others survive ---
jq '.provider.anthropic = {"options": {"timeout": 60000}}' "$CFG" > "$CFG.tmp" \
    && mv "$CFG.tmp" "$CFG"
"$MERGE" anthropic >/dev/null 2>&1 || fail "merge failed switching back"
assert_eq "$(jq -r '.provider | has("openai")' "$CFG")" \
    "false" "openai provider block removed on switch"
assert_eq "$(jq -r '.provider.anthropic.options.timeout' "$CFG")" \
    "60000" "unmanaged provider entry survived"
assert_eq "$(jq -r '.agent.reviewer.model' "$CFG")" \
    "anthropic/claude-opus-5" "agents switched back"
# No stale OpenAI model strings anywhere in the managed agents.
for a in "${MANAGED_AGENTS[@]}"; do
    m=$(jq -r --arg a "$a" '.agent[$a].model' "$CFG")
    assert_not_contains "$m" "openai/" "agent $a has no stale openai model"
done

# --- provider object disappears entirely when nothing is left in it ---
cat > "$CFG" <<'EOF'
{"$schema": "https://opencode.ai/config.json",
 "provider": {"openai": {"options": {"store": false}}}}
EOF
"$MERGE" anthropic >/dev/null 2>&1
assert_eq "$(jq -r 'has("provider")' "$CFG")" \
    "false" "empty provider object deleted"

# --- comment guard: refuse, exit 2, change nothing ---
cat > "$CFG" <<'EOF'
{
  // my carefully annotated config
  "theme": "tokyonight"
}
EOF
sum_before=$(cksum < "$CFG")
assert_status 2 "$MERGE" anthropic
assert_eq "$(cksum < "$CFG")" "$sum_before" "comment guard left the file untouched"

# The guard must print the keys to add by hand.
guard_out=$("$MERGE" anthropic 2>&1)
assert_contains "$guard_out" "implementer-strong" "guard printed the managed keys"

# --- unknown provider is an error, not a silent no-op ---
rm -f "$CFG"
assert_status 1 "$MERGE" not-a-provider

exit "$ASSERT_FAILURES"
