#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

IP="$REPO_ROOT/scripts/install-prime.sh"
PDIR="$(prime_dir)"
SETTINGS="$PDIR/settings.json"
HARNESS="$PDIR/harness/harness_state.json"
MANIFEST="$PDIR/.agentic-swe-setup.json"

# --- absent harness: warn, skip, exit 0 ---
out=$("$IP" 2>&1); assert_eq "$?" 0 "install-prime exits 0 without prime-agent"
assert_contains "$out" "prime-agent not on PATH" "warned about missing prime-agent"
[ -e "$SETTINGS" ] && fail "install-prime wrote despite no prime-agent"

# --- missing jq: warn and skip, still exit 0 ---
stub_cmd prime-agent
out=$(PATH="$(path_without jq)" "$IP" 2>&1)
assert_eq "$?" 0 "install-prime exits 0 without jq"
assert_contains "$out" "jq not on PATH" "warned about missing jq"
[ -e "$SETTINGS" ] && fail "install-prime wrote a config without jq"

# --- full install ---
stub_cmd git
stub_swe_skills
stub_superpowers
"$IP" >/dev/null 2>&1 || fail "install-prime failed"

# Settings carry the model defaults.
assert_eq "$(jq -r '.defaultProvider' "$SETTINGS")" "anthropic" "default provider"
assert_eq "$(jq -r '.defaultModel' "$SETTINGS")" "claude-opus-5" "default model"
assert_eq "$(jq -r '.defaultThinkingLevel' "$SETTINGS")" "high" "default thinking"

# Every role became a harness subagent spec, keyed with underscores.
for a in "${PRIME_AGENTS[@]}"; do
    key=${a//-/_}
    assert_eq "$(jq -r --arg k "$key" '.entries.subagent[$k].kind' "$HARNESS")" \
        "subagent" "spec $a is a subagent entry"
    assert_eq "$(jq -r --arg k "$key" '.entries.subagent[$k].metadata.managed_by' \
        "$HARNESS")" "agentic-swe-setup" "spec $a is marked managed"
    model=$(jq -r --arg k "$key" '.entries.subagent[$k].metadata.model' "$HARNESS")
    assert_eq "$model" "$(jq -r --arg a "$a" '.agent[$a].model' \
        "$REPO_ROOT/prime/anthropic.json")" "spec $a records its model"
    # The spec text must name the model, or a dispatch cannot use it.
    assert_contains "$(jq -r --arg k "$key" '.entries.subagent[$k].content' \
        "$HARNESS")" "$model" "spec $a content names its model"
done

# Prime Agent renders a spec's content through compactText() at 180 chars
# (refinement.js:14). Before this was fixed, all eight specs overran and the
# truncated tail was always the dispatch form, so the roster named roles
# without showing a usable dispatch for any of them.
for a in "${PRIME_AGENTS[@]}"; do
    key=${a//-/_}
    content=$(jq -r --arg k "$key" '.entries.subagent[$k].content' "$HARNESS")
    [ "${#content}" -le 180 ] || \
        fail "spec $a content is ${#content} chars; the render cap is 180"

    # The dispatch form leads, so truncation can only ever cost the hint.
    model=$(jq -r --arg a "$a" '.agent[$a].model' "$REPO_ROOT/prime/anthropic.json")
    want="await rlm(task, name=\"$a\", model=\"$model\")"
    case "$content" in
        "$want"*) ;;
        *) fail "spec $a does not lead with its dispatch form: [$content]" ;;
    esac

    # rlm() takes only name and model (agent-session.js:7768); a child's
    # thinking level is inherited from the parent session and clamped.
    assert_not_contains "$content" "Thinking:" \
        "spec $a claims a thinking level no dispatch can set"
done

# Read-only intent survives into the spec text.
assert_contains "$(jq -r '.entries.subagent.reviewer_final.content' "$HARNESS")" \
    "read-only" "reviewer-final spec is read-only"
assert_not_contains "$(jq -r '.entries.subagent.implementer.content' "$HARNESS")" \
    "read-only" "implementer spec is not read-only"

# Skills: superpowers, swe-skills, and this repo's own, all in one directory.
assert_symlink_to "$PDIR/skills/brainstorming" \
    "$SUPERPOWERS_DIR/skills/brainstorming" "superpowers skill linked"
assert_symlink_to "$PDIR/skills/de-slop" \
    "$SWE_SKILLS_DIR/skills/de-slop" "swe-skill linked"
assert_symlink_to "$PDIR/skills/clean-coding" \
    "$SWE_SKILLS_DIR/book-skills/clean-coding" "book-skill linked"
assert_symlink_to "$PDIR/skills/jira-fu" \
    "$REPO_ROOT/skills/jira-fu" "local skill linked"
[ -e "$PDIR/skills/not-a-skill" ] && fail "linked a directory with no SKILL.md"

assert_symlink_to "$PDIR/AGENTS.md" "$REPO_ROOT/AGENTS.md" "instructions linked"
assert_eq "$(jq -r '.provider' "$MANIFEST")" "anthropic" "manifest records provider"

# --- idempotent, and created_at is preserved across re-runs ---
first=$(jq -r '.entries.subagent.reviewer.created_at' "$HARNESS")
sleep 1
"$IP" >/dev/null 2>&1 || fail "second install-prime failed"
assert_eq "$(jq -r '.entries.subagent.reviewer.created_at' "$HARNESS")" "$first" \
    "created_at preserved on re-run"
n=$(find "$PDIR" -name 'AGENTS.md.bak.*' | wc -l)
assert_eq "$n" 0 "no spurious backup on re-run"

# --- explicit provider ---
"$IP" openai >/dev/null 2>&1 || fail "install-prime openai failed"
assert_eq "$(jq -r '.defaultProvider' "$SETTINGS")" "openai" "explicit provider honoured"
assert_eq "$(jq -r '.entries.subagent.reviewer.metadata.model' "$HARNESS")" \
    "openai/gpt-5.6-terra" "specs re-pointed at the openai ladder"

# --- unmanaged state survives a merge ---
tmp=$(mktemp)
jq '.theme = "tokyonight"' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
jq '.entries.subagent.my_own = {id:"my_own",kind:"subagent",title:"mine",
    content:"mine",metadata:{}}' "$HARNESS" > "$tmp" && mv "$tmp" "$HARNESS"
"$IP" anthropic >/dev/null 2>&1 || fail "third install-prime failed"
assert_eq "$(jq -r '.theme' "$SETTINGS")" "tokyonight" "unmanaged setting survived"
assert_eq "$(jq -r '.entries.subagent.my_own.title' "$HARNESS")" "mine" \
    "unmanaged subagent spec survived"

# --- comment guard aborts the whole install ---
rm -f "$PDIR/AGENTS.md"
cat > "$SETTINGS" <<'EOF'
{
  // hand-annotated
  "theme": "tokyonight"
}
EOF
assert_status 2 "$IP" anthropic
[ -e "$PDIR/AGENTS.md" ] && fail "install continued past the comment guard"

exit "$ASSERT_FAILURES"
