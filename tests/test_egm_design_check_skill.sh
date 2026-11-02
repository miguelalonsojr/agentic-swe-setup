#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

skill="$REPO_ROOT/skills/egm-design-check/SKILL.md"
readme="$REPO_ROOT/skills/egm-design-check/README.md"
assert_file "$skill" 'EGM skill exists'
assert_file "$readme" 'EGM README exists'
if [ -f "$skill" ]; then
    assert_eq "$(head -n 1 "$skill")" '---' 'frontmatter opens first'
    frontmatter=$(sed -n '2,/^---$/p' "$skill")
    assert_contains "$frontmatter" 'name: egm-design-check' 'stable invocation name'
    assert_contains "$frontmatter" 'disable-model-invocation: true' 'manual-only metadata'
    assert_contains "$frontmatter" 'description: Use when' 'explicit-request description'
    body=$(cat "$skill")
    for heading in '## Understanding' '## Material gaps' '## Coverage and limitations' '## Disposition'; do
        assert_contains "$body" "$heading" "report contract contains $heading"
    done
fi

# Complete policy sentences must survive both provider renders. These assertions
# pin the explicit gate rather than matching a loose EGM keyword in a heading.
policy=(
    'The EGM design check runs only when the user explicitly requests it for the current feature or an existing named document.'
    'An EGM mention in an article or document, or skill installation alone, does not select the check.'
    'For a selected full-path feature, run the enhanced EGM builder check once at the existing pre-approval point instead of the ordinary builder check.'
    'On fast or bounded work, EGM selection does not create a design document or upgrade the workflow; offer a review of an existing document or an explicit full-path choice.'
    'A resumed ordinary workflow with no evidence of an EGM request stays unselected and does not require an EGM-selection question.'
    'If an explicit EGM request or a recovered earlier opt-in has ambiguous feature or target scope, ask instead of inferring consent.'
    'For a natural-language request, load the skill from the configured Prime skill root and report a missing installation rather than searching other copies.'
)
for provider in anthropic openai; do
    render_agents_md prime "$provider" >/dev/null || fail "render Prime instructions for $provider"
done
for source in "$REPO_ROOT/AGENTS.md" "$(rendered_agents_md prime anthropic)" "$(rendered_agents_md prime openai)"; do
    if [ ! -f "$source" ]; then
        fail "instruction policy source missing: $source"
        continue
    fi
    for sentence in "${policy[@]}"; do
        grep -qxF "$sentence" "$source" || fail "missing EGM policy sentence in $source: $sentence"
    done
done


# Each installation case has a separate Prime destination. No case touches the
# user's Prime root or any shared checkout outside this sandbox.
stub_cmd prime-agent
stub_cmd git
stub_superpowers
mkdir -p "$SUPERPOWERS_DIR/skills/egm-design-check"
printf 'upstream EGM\n' > "$SUPERPOWERS_DIR/skills/egm-design-check/SKILL.md"
skill_source="$REPO_ROOT/skills/egm-design-check"

case_root() {
    export PRIME_AGENT_CODING_AGENT_DIR="$SANDBOX/cases/$1/prime"
    mkdir -p "$(prime_dir)/skills" "$(prime_dir)/harness"
    printf '{"userSetting":"keep"}\n' > "$(prime_dir)/settings.json"
    printf '{"userHarness":"keep"}\n' > "$(prime_dir)/harness/harness_state.json"
}
config_bytes() {
    cksum "$(prime_dir)/settings.json" "$(prime_dir)/harness/harness_state.json"
}

case_root absent
before=$(config_bytes)
for pass in first second; do
    output=$(bash "$REPO_ROOT/scripts/install-skills.sh" 2>&1); status=$?
    assert_eq "$status" 0 "$pass skill-only install succeeds: $output"
    assert_symlink_to "$(prime_dir)/skills/egm-design-check" "$skill_source" "$pass install owns EGM"
    assert_eq "$(config_bytes)" "$before" "$pass skill-only install preserves config bytes"
    [ ! -e "$(prime_dir)/.agentic-swe-setup.json" ] || fail "$pass skill-only install wrote manifest"
done

for form in absolute relative; do
    case_root "owned-$form"
    dest="$(prime_dir)/skills/egm-design-check"
    if [ "$form" = absolute ]; then
        ln -s "$skill_source" "$dest"
    else
        ln -s "$(realpath --relative-to="$(dirname "$dest")" "$skill_source")" "$dest"
    fi
    before=$(config_bytes)
    output=$(bash "$REPO_ROOT/scripts/install-skills.sh" 2>&1); status=$?
    assert_eq "$status" 0 "$form owned link accepted: $output"
    assert_symlink_to "$dest" "$skill_source" "$form owned link remains owned"
    assert_eq "$(config_bytes)" "$before" "$form owned link leaves config bytes"
done

# A collision must fail both entry points before replacing the destination or
# rewriting managed configuration. Existing local-over-upstream overrides work.
for form in file directory live dangling wrong-repo upstream legacy; do
    for entry in skills full; do
        case_root "foreign-$form-$entry"
        dest="$(prime_dir)/skills/egm-design-check"
        case "$form" in
            file) printf 'foreign EGM\n' > "$dest" ;;
            directory) mkdir "$dest"; printf 'foreign EGM\n' > "$dest/keep" ;;
            live) printf 'foreign EGM\n' > "$SANDBOX/foreign-$form-$entry"; ln -s "$SANDBOX/foreign-$form-$entry" "$dest" ;;
            dangling) ln -s "$SANDBOX/missing-$form-$entry" "$dest" ;;
            wrong-repo) ln -s "$REPO_ROOT/skills/de-slop" "$dest" ;;
            upstream) ln -s "$SUPERPOWERS_DIR/skills/egm-design-check" "$dest" ;;
            legacy) mkdir -p "$SWE_SKILLS_DIR/skills/egm-design-check"; ln -s "$SWE_SKILLS_DIR/skills/egm-design-check" "$dest" ;;
        esac
        before=$(config_bytes)
        if [ -L "$dest" ]; then before_target=$(readlink "$dest"); else before_target=''; fi
        if [ "$entry" = skills ]; then command="$REPO_ROOT/scripts/install-skills.sh"; else command="$REPO_ROOT/scripts/install-prime.sh"; fi
        output=$(bash "$command" 2>&1); status=$?
        [ "$status" -ne 0 ] || fail "$form $entry install must refuse foreign EGM"
        assert_contains "$output" "$dest" "$form $entry refusal names occupied path"
        if [ -n "$before_target" ]; then
            assert_eq "$(readlink "$dest")" "$before_target" "$form $entry foreign target preserved"
        elif [ "$form" = directory ]; then
            assert_eq "$(cat "$dest/keep")" 'foreign EGM' "$entry foreign directory preserved"
        else
            assert_eq "$(cat "$dest")" 'foreign EGM' "$entry foreign file preserved"
        fi
        assert_eq "$(config_bytes)" "$before" "$form $entry config bytes preserved"
        [ ! -e "$(prime_dir)/.agentic-swe-setup.json" ] || fail "$form $entry wrote manifest"
        backups=$(find "$(prime_dir)" -name 'egm-design-check.bak.*' -o -name 'settings.json.bak.*')
        assert_eq "$backups" '' "$form $entry refusal made no backup"
    done
done

case_root upstream-fresh
output=$(bash "$REPO_ROOT/scripts/install-prime.sh" 2>&1); status=$?
assert_eq "$status" 0 "full install accepts fresh upstream collision: $output"
assert_symlink_to "$(prime_dir)/skills/egm-design-check" "$skill_source" 'local EGM wins same-name upstream skill'
assert_symlink_to "$(prime_dir)/skills/subagent-driven-development" "$REPO_ROOT/skills/subagent-driven-development" 'other local override remains'

case_root uninstall-owned
owned_dest="$(prime_dir)/skills/egm-design-check"
ln -s "$(realpath --relative-to="$(dirname "$owned_dest")" "$skill_source")" "$owned_dest"
output=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1); status=$?
assert_eq "$status" 0 "uninstall owned relative link: $output"
[ ! -L "$owned_dest" ] || fail 'uninstall left owned relative EGM link'
assert_file "$skill_source/SKILL.md" 'uninstall preserves source skill'

for form in file directory live dangling wrong-repo upstream legacy; do
    case_root "uninstall-$form"
    dest="$(prime_dir)/skills/egm-design-check"
    case "$form" in
        file) printf 'foreign EGM\n' > "$dest" ;;
        directory) mkdir "$dest"; printf 'foreign EGM\n' > "$dest/keep" ;;
        live) ln -s "$SUPERPOWERS_DIR/skills/egm-design-check/SKILL.md" "$dest" ;;
        dangling) ln -s "$SANDBOX/uninstall-missing" "$dest" ;;
        wrong-repo) ln -s "$REPO_ROOT/skills/de-slop" "$dest" ;;
        upstream) ln -s "$SUPERPOWERS_DIR/skills/egm-design-check" "$dest" ;;
        legacy) ln -s "$SWE_SKILLS_DIR/skills/egm-design-check" "$dest" ;;
    esac
    if [ -L "$dest" ]; then original=$(readlink "$dest"); else original=''; fi
    output=$(bash "$REPO_ROOT/scripts/uninstall.sh" 2>&1); status=$?
    assert_eq "$status" 0 "uninstall preserves $form foreign EGM: $output"
    if [ -n "$original" ]; then
        assert_eq "$(readlink "$dest")" "$original" "uninstall preserves $form link"
    elif [ "$form" = directory ]; then
        assert_eq "$(cat "$dest/keep")" 'foreign EGM' 'uninstall preserves foreign directory'
    else
        assert_eq "$(cat "$dest")" 'foreign EGM' 'uninstall preserves foreign file'
    fi
done

# Missing-source ownership is tested with a disposable repository, never by
# removing the real skill from this checkout.
fixture="$SANDBOX/disposable-repo"
mkdir -p "$fixture/scripts" "$fixture/skills/egm-design-check"
cp "$REPO_ROOT/scripts/lib.sh" "$REPO_ROOT/scripts/uninstall.sh" "$fixture/scripts/"
case_root dangling-owned
ln -s "$fixture/skills/egm-design-check" "$(prime_dir)/skills/egm-design-check"
rmdir "$fixture/skills/egm-design-check"
output=$(bash "$fixture/scripts/uninstall.sh" 2>&1); status=$?
assert_eq "$status" 0 "uninstall dangling owned link: $output"
[ ! -L "$(prime_dir)/skills/egm-design-check" ] || fail 'uninstall left dangling owned EGM link'

exit "$ASSERT_FAILURES"
