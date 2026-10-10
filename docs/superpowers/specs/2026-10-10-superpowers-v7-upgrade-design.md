# Superpowers v7.0.0 upgrade

## Intent

Update the Prime Agent installation to the published Superpowers v7.0.0 release without losing the repository's local skill additions. The `brainstorming` skill must come from upstream, not from a new fork. The repository's `AGENTS.md` workflow rules continue to govern approval and process scaling.

## Current state

The shared `~/.superpowers` checkout is clean at v6.4.2 (`8ca22dba9a94f28898bbce59f2537ff4d87c747d`). Upstream v7.0.0 points to `bb92a77741419a4ab5f06e711a283343f1ada0c3`. `scripts/lib.sh` fast-forwards the shared checkout; `scripts/install-prime.sh` links upstream skills first and repository-owned skills second. The repository forks `systematic-debugging` and `finishing-a-development-branch`. The baseline `just test` run passed 19 test files.

## Upgrade contract

- Bring the shared checkout to the v7.0.0 release commit and relink the Prime Agent skills using the existing installation flow. Preserve the existing fast-forward update behavior; do not add a version pin or vendor upstream files into the repository.
- Leave `brainstorming` entirely upstream. Its Prime Agent skill link must resolve to `~/.superpowers/skills/brainstorming`, containing the v7.0.0 rewrite. Do not create `skills/brainstorming`.
- Keep the local `systematic-debugging` Git history, bisect, and recovery additions. Replace its two diagnostic examples that print `IDENTITY` values with the v7.0.0 examples that report only set/unset or presence. Add `bash` to the polluter-script example in the fork's `root-cause-tracing.md`. Retain the fork's extra support file and link.
- Keep the local `finishing-a-development-branch` additions unchanged. Upstream did not change that skill between v6.4.2 and v7.0.0.
- Update fork provenance and drift documentation where it would otherwise imply that the v7.0.0 safety correction remains unapplied. Do not broaden the update to other local skills or change the installation architecture.

## Verification

- Compare each fork against upstream v7.0.0. Only the intended local additions should remain; the `systematic-debugging` secret checks and polluter-script example must match upstream.
- Run `just test` after repository changes and `just doctor` after refreshing the shared checkout and Prime Agent links. Confirm the checkout commit and the installed `brainstorming` symlink target.
- Exercise the installed skill path as a user would by reading `~/.prime/agent/skills/brainstorming/SKILL.md` through the symlink and checking that it contains v7.0.0's rewrite. Confirm the fork links still point to repository-owned skills.

## Limits

Updating `~/.superpowers` and relinking installed skills changes the local Prime Agent installation. This design does not modify the upstream repository, pin future updates, alter the forked branch-finishing workflow, or relax the approval gates in `AGENTS.md`.
