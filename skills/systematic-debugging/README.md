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

## Upstream reconciliation

`b36e082` is the original fork base. The fork also incorporates the
Superpowers v7.0.0 presence-only `IDENTITY` checks, which do not print secret
values, and the `bash ./find-polluter.sh` support-document command.

`just update` refreshes `~/.superpowers` but does not touch `skills/`. When
upstream `systematic-debugging` changes, compare it against v7.0.0 and re-apply
the additions listed here by hand.
