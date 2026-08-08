#!/usr/bin/env bash
# The skills this repo ships itself, as opposed to the shared swe-skills
# checkout: they must be linked on install, reported by doctor, and removed on
# uninstall, in both harnesses.
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# --- every declared skill exists in the repo, with the two required files ---
for s in "${LOCAL_SKILLS[@]}"; do
    assert_file "$REPO_ROOT/skills/$s/SKILL.md" "skills/$s has a SKILL.md"
    assert_file "$REPO_ROOT/skills/$s/README.md" "skills/$s has a README.md"
    body=$(cat "$REPO_ROOT/skills/$s/SKILL.md")
    assert_contains "$body" "name: $s" "skills/$s declares its own name"
    assert_contains "$body" "description:" "skills/$s has a description"
done

# The dispatch-policy skills are only correct if they carry the specific
# facts that make them correct. A skill that says "pick a good model" is
# the advice that already failed.
#
# Each needle is anchored on the whole claim, not on a distinctive token.
# A bare "clamped" would stay green if the thinking-level sentence were
# deleted and "capped at 20" reworded to "clamped to 20"; a bare
# "rlm.find_models" would stay green on a passing mention with the call
# itself gone.
routing=$(cat "$REPO_ROOT/skills/routing-model-tiers/SKILL.md")
assert_contains "$routing" 'rlm.find_models("", limit=20)' \
    "routing skill gives the model-menu call, with its capped limit"
assert_contains "$routing" 'accepts `name` and `model` and nothing else' \
    "routing skill names the rlm keywords and excludes the rest"
assert_contains "$routing" "clamped to the child model" \
    "routing skill states how thinking level is set"

# --- install-skills alone, with no harness present ---
out=$("$REPO_ROOT/scripts/install-skills.sh" 2>&1)
assert_eq "$?" 0 "install-skills exits 0 with no harness"
assert_contains "$out" "nothing to do" "install-skills said it had nothing to do"

# --- claude: linked by install-claude ---
stub_cmd claude
stub_cmd git
stub_swe_skills
"$REPO_ROOT/scripts/install-claude.sh" >/dev/null 2>&1 || fail "install-claude failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(claude_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "claude skill $s links into the repo"
done

# --- doctor reports them ---
out=$("$REPO_ROOT/scripts/doctor.sh" 2>&1)
for s in "${LOCAL_SKILLS[@]}"; do
    assert_contains "$out" "[ok]   local skill $s" "doctor sees claude skill $s"
done

# --- opencode: linked by install-skills, which is the standalone path ---
stub_cmd opencode
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "install-skills failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(opencode_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "opencode skill $s links into the repo"
done

# --- relinking is idempotent ---
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "second install-skills failed"
for s in "${LOCAL_SKILLS[@]}"; do
    assert_symlink_to "$(claude_dir)/skills/$s" "$REPO_ROOT/skills/$s" \
        "claude skill $s still linked after a second run"
done

# --- a real directory the user owns is backed up, never destroyed ---
first=${LOCAL_SKILLS[0]}
rm -f "$(claude_dir)/skills/$first"
mkdir -p "$(claude_dir)/skills/$first"
printf 'mine\n' > "$(claude_dir)/skills/$first/SKILL.md"
"$REPO_ROOT/scripts/install-skills.sh" >/dev/null 2>&1 || fail "install over a real dir failed"
n=$(find "$(claude_dir)/skills" -maxdepth 1 -name "$first.bak.*" | wc -l)
assert_eq "$n" 1 "a user-owned skill directory was backed up, not overwritten"

# --- uninstall removes only our links ---
"$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "uninstall failed"
for s in "${LOCAL_SKILLS[@]}"; do
    [ -L "$(claude_dir)/skills/$s" ] && fail "uninstall left the claude link for $s"
    [ -L "$(opencode_dir)/skills/$s" ] && fail "uninstall left the opencode link for $s"
done

# --- uninstall leaves a directory it does not own ---
rm -rf "$(claude_dir)/skills/$first"
mkdir -p "$(claude_dir)/skills/$first"
"$REPO_ROOT/scripts/uninstall.sh" >/dev/null 2>&1 || fail "second uninstall failed"
[ -d "$(claude_dir)/skills/$first" ] || fail "uninstall removed a directory it did not create"

exit "$ASSERT_FAILURES"
