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
        haiku|sonnet|fable) ;;
        *) fail "$a model must be haiku, sonnet, or fable; got [$model]" ;;
    esac

    effort=$(frontmatter_field "$f" effort)
    case "$effort" in
        low|medium|high) ;;
        *) fail "$a effort must be low, medium, or high; got [$effort]" ;;
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

# The strong tier must outrank the default tier.
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-strong.md" model)" \
    fable "implementer-strong uses fable"
assert_eq "$(frontmatter_field "$REPO_ROOT/agents/implementer-light.md" model)" \
    haiku "implementer-light uses haiku"

# The old misnamed file must not come back.
[ -e "$REPO_ROOT/agents/reviewer-light.md" ] && fail "reviewer-light.md should be reviewer-lite.md"

exit "$ASSERT_FAILURES"
