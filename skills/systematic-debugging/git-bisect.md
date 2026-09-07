# Git bisect for regressions

Bisect finds the first bad commit by binary search. You supply a good commit, a
bad commit, and a command that exits 0 when the symptom is absent and 1 when it
is present. Git does the rest.

## Recipe

```bash
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit-or-tag>
git bisect run ./bisect-check.sh
git bisect reset
```

`bisect-check.sh` exercises the symptom and nothing else:

```bash
#!/usr/bin/env bash
# exit 0 = good, 1 = bad, 125 = cannot test this commit (skip it)
uv sync --quiet 2>/dev/null || exit 125
uv run pytest tests/test_thing.py::test_symptom -q >/dev/null 2>&1
```

A `python -c` check works when there is no test yet:

```bash
python -c 'from pkg import f; import sys; sys.exit(0 if f(3) == 9 else 1)' || exit 1
```

## Notes

- `exit 125` tells bisect to skip a commit that cannot be built or tested.
- Put the check script outside the repo (`/tmp`) so checkouts do not remove it.
- Always finish with `git bisect reset`; a half-finished bisect leaves HEAD detached.
- When bisect names the commit, read its diff before fixing anything. The commit
  is the trigger; the root cause may be older.
