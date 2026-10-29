# Selective upstream updates design

## Intent

Adopt the audited Superpowers fixes and v7.0.1 without changing Prime model defaults, replacing the local parallel-development workflow, or reintroducing the unavailable swe-skills dependency.

## Approach

Keep upstream brainstorming linked from the shared checkout. Clarify the existing bounded-path instruction in AGENTS.md: in-chat approval is its design approval; the upstream written-design and writing-plans requirements apply to the full path, not the bounded path. This keeps the existing policy and avoids maintaining another skill fork. A local brainstorming fork would remove the contradictory source text, but would duplicate the whole skill and require future manual reconciliation. Keeping v7.0.0 would avoid the new conflict but would omit the context-first questioning and smaller skill loads.

## Changes

1. Port only the ancestor and nonempty-range checks into the local review-package helper. Both invalid cases exit 3 before creating or changing the output file. Valid multi-commit ancestor ranges retain their full review content. Keep existing argument validation, output naming, and invocation contract.
2. Make sdd-workspace create its parent .gitignore only when absent. Preserve any existing file byte-for-byte, including an empty file. Keep hashed workspace identity and the in-repository plan restriction.
3. Clarify the bounded-path mapping in AGENTS.md and test that both provider renders retain it. Keep all fast-path exclusions and all full-path safety gates. Do not create a local brainstorming fork or change the SDD workflow.
4. Correct the plain-technical-prose README to identify the current upstream Unlicense and retain attribution. Do not change its SKILL.md or any swe-skills-derived material. Add concise reconciliation provenance to the SDD README and describe the v7.0.1 workflow compatibility and update caveat in the main README.
5. After review and authorized local integration, fast-forward the clean shared ~/.superpowers checkout from bb92a77741419a4ab5f06e711a283343f1ada0c3 to exactly v7.0.1 commit 2ce8aa15d05bd57213e6f746f953aafb7ded7a8b. Verify the tag, origin, branch, expected starting SHA, and ancestry immediately before applying it. Stop if the preflight differs; do not reset or discard changes. Do not run just update or an installer. Existing directory symlinks already expose the updated upstream files.

## Isolation and installation

Implement in an isolated feature worktree with isolated child writer worktrees for independent tasks. The primary checkout must remain on its current branch while work is in progress, because live local-skill links point into it. After the branch passes review, local integration into main requires user approval; do not push or create a PR. Regenerate the installed-provider AGENTS.md from the primary checkout without merging settings or relinking skills. If integration is not approved, leave the reviewed branch intact and defer the live Superpowers refresh so installed policy and upstream behavior stay consistent.

Snapshot and compare the real settings.json, harness_state.json, and installation manifest around all tests and installation work. Preserve their bytes, not just the current gpt-6-astra/max fields. Do not alter provider JSON files or installer behavior. The primary checkout and ~/.superpowers must be clean at completion, apart from authorized commits.

## Verification

Run the documented just test suite before the first edit. Add focused regressions and observe each intended failure before changing the helper behavior. Cover equal and divergent commit ranges, valid multi-commit ranges, untouched output on rejection, missing and existing .gitignore files, an empty existing .gitignore, and stable same-basename workspace isolation. Check the clarified policy in source and both generated provider instructions. Exercise the helper CLIs in a scratch consumer repository and run the full suite after integration. Use read-only scenario checks with the v7.0.1 brainstorming source for fast, bounded, and high-risk work; record any conflict rather than adding another fork without approval. Verify the installed upstream SHA, actual skill symlink targets, doctor report, and unchanged live configuration hashes.

## Non-goals

No new skills, wholesale fork replacement, compaction-policy change, model-ladder update, installer redesign, swe-skills fetch, license change to unrelated material, publication, or remote push.
