# systematic-debugging

Fork of `~/.superpowers/skills/systematic-debugging` at upstream commit `b36e082`.

Upstream path: `superpowers/skills/systematic-debugging`.

## Additions

Phase 1, item 3 (Check Recent Changes) gains:

- `git log --oneline -20 -- <paths>` over the files involved, to seed the
  investigation with what changed and why.
- Bisect guidance for regressions: use `git bisect run` with a script that
  exercises the symptom, referencing `git-bisect.md`.
- Recovery commands for code that used to work: `git reflog`, `git stash list`,
  and `git log --all -S'<snippet>'`.

`git-bisect.md` is a new supporting technique file, linked from the "Supporting
Techniques" section of `SKILL.md`.

## Drift

`just update` refreshes `~/.superpowers` but does not touch `skills/`. When
upstream `systematic-debugging` changes, compare it against the pinned commit
above and re-apply the additions listed here by hand.
