#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

DOCTOR="$REPO_ROOT/scripts/doctor.sh"

# --- with neither harness present it still exits 0 and says so ---
out=$("$DOCTOR" 2>&1); status=$?
assert_eq "$status" 0 "doctor exits 0 with nothing installed"
assert_contains "$out" "[skip] claude not installed" "skips absent claude"
assert_contains "$out" "[skip] opencode not installed" "skips absent opencode"
assert_contains "$out" "[skip] prime-agent not installed" "skips absent prime-agent"
assert_contains "$out" "[warn]" "warns about something"

# --- doctor never writes ---
before=$(find "$HOME" | sort | cksum)
"$DOCTOR" >/dev/null 2>&1
assert_eq "$(find "$HOME" | sort | cksum)" "$before" "doctor changed nothing"

# --- a fully installed sandbox reports green ---
stub_cmd_output claude "superpowers@claude-plugins-official  6.2.0  enabled"
stub_cmd opencode
stub_cmd prime-agent
stub_cmd git
stub_swe_skills
stub_superpowers

bash "$REPO_ROOT/scripts/install-claude.sh"   >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-opencode.sh" anthropic >/dev/null 2>&1
bash "$REPO_ROOT/scripts/install-prime.sh"    anthropic >/dev/null 2>&1

out=$("$DOCTOR" 2>&1)
assert_contains "$out" "[ok]   superpowers plugin installed" "claude plugin ok"
assert_contains "$out" "[ok]   agent reviewer-lite" "claude agent ok"
assert_contains "$out" "[ok]   global CLAUDE.md linked" "claude memory ok"
assert_contains "$out" "[ok]   provider: anthropic" "opencode provider ok"
assert_contains "$out" "[ok]   global AGENTS.md linked" "opencode instructions ok"
assert_not_contains "$out" "[warn] agent reviewer" "no agent warnings"
# Prime Agent: model tier, every role spec, and superpowers-as-skills.
assert_contains "$out" "[ok]   default model: claude-opus-5" "prime model tier ok"
assert_contains "$out" "[ok]   subagent spec reviewer-final" "prime role spec ok"
# Nine specs against a six-entry render limit: doctor must say so rather
# than let the overflow stay invisible, which is how it went unnoticed.
assert_contains "$out" "Prime Agent renders 6" \
    "doctor reports the subagent render limit"
assert_contains "$out" "[ok]   superpowers skill brainstorming" "prime superpowers ok"
assert_not_contains "$out" "[warn] subagent spec" "no prime spec warnings"

# --- a link that points somewhere else is reported, not silently accepted ---
ln -sfn /etc/hostname "$(claude_dir)/CLAUDE.md"
out=$("$DOCTOR" 2>&1)
assert_contains "$out" "[warn] global CLAUDE.md not linked from this repo" \
    "foreign symlink flagged"

exit "$ASSERT_FAILURES"
