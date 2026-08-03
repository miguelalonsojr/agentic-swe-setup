#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"
# shellcheck source=/dev/null
. "$REPO_ROOT/scripts/lib.sh"

# frontmatter_field FILE KEY — first-level YAML scalar out of the frontmatter.
frontmatter_field() {
    awk -v key="$2" '
        NR == 1 && $0 == "---" { inside = 1; next }
        inside && $0 == "---"  { exit }
        inside {
            split($0, kv, ": ")
            if (kv[1] == key) { sub("^" key ": ", ""); print; exit }
        }
    ' "$1"
}

for a in "${CLAUDE_AGENTS[@]}"; do
    f="$REPO_ROOT/agents/$a.md"
    assert_file "$f" "agent definition exists"
    [ -f "$f" ] || continue

    assert_eq "$(head -n1 "$f")" "---" "$a starts with frontmatter"
    assert_eq "$(frontmatter_field "$f" name)" "$a" "$a name matches filename"

    desc=$(frontmatter_field "$f" description)
    [ -n "$desc" ] || fail "$a has no description"

    model=$(frontmatter_field "$f" model)
    case "$model" in
        sonnet|opus|fable) ;;
        *) fail "$a model must be sonnet, opus, or fable; got [$model]" ;;
    esac

    # Every tier reasons hard; only the rung differs.
    effort=$(frontmatter_field "$f" effort)
    case "$effort" in
        high|xhigh) ;;
        *) fail "$a effort must be high or xhigh; got [$effort]" ;;
    esac

    # A body prompt after the closing --- is required.
    # Print every line that follows the second "---" delimiter.
    body=$(awk 'seen >= 2 { print } /^---$/ { seen++ }' "$f")
    [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] \
        || fail "$a has an empty body prompt"
done

# The two reviewers must be read-only.
for a in reviewer reviewer-lite; do
    tools=$(frontmatter_field "$REPO_ROOT/agents/$a.md" tools)
    assert_eq "$tools" "Read, Grep, Glob, Bash" "$a is read-only"
done

# Three tiers: sonnet light, opus default, fable strong.
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-light.md" model)" \
    sonnet "implementer-light uses sonnet"
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer.md" model)" \
    opus "implementer uses opus"
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-strong.md" model)" \
    fable "implementer-strong uses fable"

# xhigh is reserved for the strong tier, so an escalation is a real step up.
for a in implementer-strong reviewer; do
    assert_eq "$(frontmatter_field "$REPO_ROOT/agents/$a.md" effort)" \
        xhigh "$a reasons at xhigh"
done
for a in implementer-light implementer reviewer-lite; do
    assert_eq "$(frontmatter_field "$REPO_ROOT/agents/$a.md" effort)" \
        high "$a reasons at high"
done

# Haiku is gone from the ladder entirely.
for f in "$REPO_ROOT"/agents/*.md; do
    grep -q '^model: haiku$' "$f" && fail "$(basename "$f") still uses haiku"
done

# The old misnamed file must not come back.
[ -e "$REPO_ROOT/agents/reviewer-light.md" ] && fail "reviewer-light.md should be reviewer-lite.md"

exit "$ASSERT_FAILURES"
