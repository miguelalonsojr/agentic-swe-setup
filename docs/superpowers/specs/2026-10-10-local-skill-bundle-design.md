# Local skill bundle design

## Intent

Keep the ten skill topics available on this machine without an install-time dependency on the unavailable `mhihasan/swe-skills` repository. Preserve the existing skill names and reference folders for local use. New `SKILL.md` and README text must be independently written. This is a local-only change, not a new public release of the copied reference material.

## Inputs and scope

The local `~/.swe-skills` checkout is at commit `809dee1bf63c3360eb7412f3498f0fa4c76af38e`. Its `skills/` group contains `confluence-diagrams`, `de-slop`, `generating-design-doc`, and `low-level-design`. Its `book-skills/` group contains `clean-architecture`, `clean-coding`, `ddd-expert`, `design-patterns-expert`, `pragmatic-engineer`, and `system-designing`. Place all ten new skill directories under this repository's existing `skills/` directory so installation uses the existing local-skill convention.

Eight source directories contain a `references/` folder: every listed skill except `confluence-diagrams` and `generating-design-doc`. Copy those eight folders byte-for-byte to the corresponding local skill directories before writing the new guides. Do not copy the source `SKILL.md`, other source files, or skill scripts. The source checkout has no book PDFs or ebooks; none will be added. Preserve any attribution in the copied reference files unchanged.

Each new skill has an original `SKILL.md` with the existing skill name in YAML frontmatter, a concrete trigger description, and a concise workflow with verification and limits. Each has a human-facing README. The eight skills with copied references must link to the actual copied relative reference paths. The other two must be self-contained. The first version is a functional starting point, not a claim of parity with the old 133-file skill tree. In particular, `confluence-diagrams` must discover an available attachment interface and verify the rendered page; it must not invent an upload API. Book-topic skills may point to the local references but must not copy their prose into the new guides.

## Installation and migration

`just install-prime` must use the upstream Superpowers checkout, then link repository-owned skills last. `just install-skills` must link the same repository-owned skills. Neither install nor `just update` may clone or fetch `swe-skills`. Doctor must check that all 23 repository-owned skills resolve into this repository, rather than merely existing; the old shared checkout is not a prerequisite. Uninstall must remove only links this setup owns. It may recognize links created by the previous `swe-skills` installation for cleanup, but must not delete or modify the old checkout. Leave the separate legacy retirement script's Claude/legacy ownership checks intact.

Update the README and the installed instruction source where they describe shared skill ownership or imply the new guides contain the old detailed book material. Keep the existing Superpowers fork precedence and Prime provider merge behavior. Do not add dependencies, change the skill names, or reorganize other local skills.

## Verification

The baseline `just test` run passed 19/19 test files. Add focused tests that first fail under the old shared-checkout installation. Test install/update/doctor/uninstall with no `~/.swe-skills` checkout and assert local link targets, including a name also supplied by Superpowers. Check YAML frontmatter and each required relative reference link without needing the source checkout. Compare byte hashes of all copied reference files with the local source checkout during implementation; do not make the test suite depend on that checkout. Run `just test`, `just doctor`, and a sandboxed install/update/uninstall sequence, then check live Prime skill links from the stable repository path while the local branch is checked out.

## Local-only boundary

Use branch `local/original-skill-bundle` without an upstream. Commit the copied references, original guides, scripts, tests, and docs locally, as requested. Do not create a worktree, add `.gitignore`, merge into `main`, or push. Switching the working directory back to `main` will make installed links to new skill directories unavailable. A later push of this branch or of a local `main` containing it would publish the copied references; this work does not authorize that operation.
