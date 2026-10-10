#!/usr/bin/env bash
set -uo pipefail
# shellcheck source=/dev/null
. "$REPO_ROOT/tests/lib/sandbox.sh"

skills=(de-slop low-level-design clean-architecture clean-coding ddd-expert design-patterns-expert pragmatic-engineer system-designing)
counts=(1 6 36 12 11 28 12 14)
sentinels=(tropes.md deriving-the-model.md chapter-01-what-is-design-and-architecture.md ch01_clean_code.md ch01_crunching_knowledge.md chapter-01-oop-intro.md chapter-01-pragmatic-philosophy.md ch01-tradeoffs-architecture.md)

for i in "${!skills[@]}"; do
    refs="$REPO_ROOT/skills/${skills[$i]}/references"
    if [ ! -d "$refs" ]; then
        fail "missing reference directory: $refs"
        continue
    fi
    actual=$(find "$refs" -type f | wc -l)
    assert_eq "$actual" "${counts[$i]}" "${skills[$i]} reference file count"
    assert_file "$refs/${sentinels[$i]}" "${skills[$i]} sentinel"
done

for skill in confluence-diagrams generating-design-doc; do
    [ ! -e "$REPO_ROOT/skills/$skill/references" ] || fail "$skill must not have references"
done

exit "$ASSERT_FAILURES"
