#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skills=(confluence-diagrams de-slop generating-design-doc low-level-design clean-architecture clean-coding ddd-expert design-patterns-expert pragmatic-engineer system-designing)
ref_skills=(de-slop low-level-design clean-architecture clean-coding ddd-expert design-patterns-expert pragmatic-engineer system-designing)
sentinels=(tropes.md deriving-the-model.md chapter-01-what-is-design-and-architecture.md ch01_clean_code.md ch01_crunching_knowledge.md chapter-01-oop-intro.md chapter-01-pragmatic-philosophy.md ch01-tradeoffs-architecture.md)

for skill in "${skills[@]}"; do
    guide="$REPO_ROOT/skills/$skill/SKILL.md"
    readme="$REPO_ROOT/skills/$skill/README.md"
    assert_file "$guide" "$skill guide"
    assert_file "$readme" "$skill README"
    if [ ! -f "$guide" ] || [ ! -f "$readme" ]; then
        continue
    fi
    [ -s "$readme" ] || fail "$skill README is empty"
    [ "$(head -n 1 "$guide")" = '---' ] || fail "$skill frontmatter missing"
    grep -qx "name: $skill" "$guide" || fail "$skill frontmatter name missing"
    grep -q '^description: Use when ' "$guide" || fail "$skill frontmatter description missing"
    grep -q '^## When to use$' "$guide" || fail "$skill use case section missing"
    grep -q '^## Verification$' "$guide" || fail "$skill verification section missing"
done

for i in "${!ref_skills[@]}"; do
    skill=${ref_skills[$i]}
    sentinel=${sentinels[$i]}
    guide="$REPO_ROOT/skills/$skill/SKILL.md"
    [ -f "$guide" ] || continue
    grep -Fq "(references/$sentinel)" "$guide" || fail "$skill reference link missing: $sentinel"
    [ -f "$(dirname "$guide")/references/$sentinel" ] || fail "$skill reference link unresolved: $sentinel"
done

exit "$ASSERT_FAILURES"
