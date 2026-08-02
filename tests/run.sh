#!/usr/bin/env bash
# Discover and run every tests/test_*.sh. Exits non-zero if any file fails.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

total=0
failed=0

for t in "$REPO_ROOT"/tests/test_*.sh; do
    [ -e "$t" ] || continue
    total=$((total + 1))
    printf '%s\n' "$(basename "$t")"
    if bash "$t"; then
        printf '  ok\n'
    else
        printf '  FAILED\n'
        failed=$((failed + 1))
    fi
done

printf '\n%d/%d test files passed\n' "$((total - failed))" "$total"
[ "$failed" -eq 0 ]
