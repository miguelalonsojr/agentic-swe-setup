# Optional EGM-inspired design check

## Intent and selected approach

Add an explicitly requested comprehension check without replacing the existing engineering workflow. The user accepted per-feature selection before design approval and one-off checks of an existing document. This is EGM-inspired support, not the upstream plugin or a claim of full EGM compatibility.

Two approaches were considered:

- **Selected: extend the existing design review point.** A repository-owned, manual-only Markdown skill adds a cold-reader explanation to the existing builder check. It reuses current documents, model routing, approval, and implementation controls. The cost is maintaining a small local adaptation.
- **Not selected: a separate full EGM design mode.** This would retain more upstream authoring and review behavior but require a complete bundle, more host adaptation, and explicit switching between two design processes. That exceeds the requested scope.

No upstream plugin, runtime package, model profile, or new memory service is required. The article and upstream repository are references; the guidance will be written locally and credited. Do not commit the user's PDF or reference checkouts.

## User-facing behavior

The proposed skill is `egm-design-check`. Its availability does not activate it.

**Per-feature:** A request such as “Use the EGM comprehension check for this feature before I approve the design” selects the named feature. During full-path work, it replaces the ordinary builder-check dispatch at the existing pre-approval point with one enhanced dispatch. It does not run both checks. The enhanced check must retain the builder check's material planning questions.

Selection neither creates a design document on a fast/bounded task nor silently upgrades its workflow. If no design-review point applies, explain that limitation; the user can request a check of an existing document or explicitly choose the full path. If the feature is ambiguous, ask which feature before recording selection.

**One-off:** An explicit request to check an existing design or plan document runs immediately as a review-only operation. Proposed native invocation is `/skill:egm-design-check <document-path>`; natural-language requests must also work through the explicit instruction gate. It does not edit the document, start implementation, or select EGM for subsequent work.

Per-feature selection stays with the current feature's conversation and ordinary recovery context; it is not a global preference or a second state database. If a resumed session cannot establish the scoped request, ask rather than infer consent. Mentions of EGM in a document, article, or general discussion are not activation requests.

## One owner for each responsibility

- **Project instructions** own the explicit opt-in condition and the narrow replacement of the existing builder check. They override generic skill-discovery rules for this manual-only extension. All other fast/bounded/full rules remain unchanged.
- **The new skill** owns the comprehension task, neutral dispatch packet, and report contract. It has no independent authoring, implementation, remediation, or retry pipeline.
- **Existing model routing** selects the current `general` role for this builder-style check. No new role IDs, model defaults, or thinking settings are added.
- **Existing authoring and human approval** resolve findings and approve the design. A clean report is neither approval to implement nor proof of correctness.
- **Existing specs and plans** remain the design authorities; **the SDD ledger** remains the execution recovery authority. No parallel EGM versions of those artifacts are created.

The feature check runs on the design available before approval. It must not demand the implementation plan that the normal workflow writes afterward. Checking a later plan is a separate explicit one-off request, not a new automatic gate.

## Reviewer inputs and output

Use one fresh RLM child. Give it the target's absolute path, any explicitly selected companion documents, the standard review instructions, and a unique report identifier. It may read source files referenced by those documents. Do not pass a private feature summary, parent transcript, author answers, or unpublished rationale. The reviewer must not retrieve parent/sibling conversation or memory to fill gaps. It must not spawn agents, execute project code or tests, or edit files.

The report contains:

1. **Understanding:** intended outcome, relevant current behavior, proposed changes, constraints, and how success would be demonstrated. Distinguish what the documents say from inference and cite the material read.
2. **Material gaps:** missing facts, ambiguities, conflicting statements, or assumptions that would change the design or prevent planning. Identify where each belongs in the existing document. Do not demand details appropriately left to planning or implementation.
3. **Coverage and limitations:** target/revision inspected, supporting files actually read, missing or inaccessible references, and any known context contamination or failed review work.
4. **Disposition:** `No material gaps found`, `Needs clarification`, or `Incomplete`.

Do not treat missing reads, a failed/timed-out child, or unavailable fresh delegation as a clean result. If author-only context is exposed or fresh review cannot be established, return `Incomplete`; do not substitute an author-context review. Wait for the actual child result before reporting completion.

The controller saves that result under a unique path in the existing session/task artifact area and returns a short summary and link. It does not overwrite the target, another review, or the SDD ledger. Review reports are evidence, not a new source of design truth. Document changes follow existing authoring and approval rules. No automatic correction or repeat-until-clean loop is added.

## Availability and safety limits

Ship one self-contained Markdown skill through the repository's existing skill distribution, with `disable-model-invocation: true` and an explicit-request description. Add only the narrow instruction entry point needed for natural-language selection and builder-check replacement; do not fork upstream brainstorming or change `using-superpowers` to adopt EGM generally.

Adding the new skill must refuse an occupied foreign destination rather than replace it. Preserve current local-over-upstream behavior for existing skills; do not broaden the installer change into unrelated ownership cleanup. Uninstall must remove only the new skill's owned link. No EGM settings, provider keys, role specs, compaction settings, or separate installer/manifest are introduced. Actual live installation and local-main integration need later approval; do not run `just install` or `just update` as part of this feature.

Prime's manual-only flag concerns discovery, not file-access permissions. Fresh child conversation history is not filesystem or global-guidance isolation. Prime reviewers are instructed to be read-only; this feature does not claim tool-enforced read-only access or modify Prime Agent to supply it. Report this as a cold-reader check with these limits, not as secure sandboxing.

## Verification before release

- Keep ordinary fast, bounded, and full-path scenarios unchanged when EGM is not selected, including when its files are installed or a user merely discusses the article.
- Demonstrate manual-only discovery and explicit invocation in the target Prime environment. Do not rely on frontmatter presence alone or promise hot refresh; a fresh session is acceptable.
- Use behavior-first skill tests: observe the existing builder check's baseline output, then verify that the extension reconstructs the design and identifies missing acceptance/context without inventing it. Test feature selection, one-off use, and ambiguous/missing targets.
- Verify with an author-only marker that a real child does not receive parent-only facts; inspect the actual child result and resource reads. Include shared-policy/memory exposure in the limits. A no-write trial establishes observed behavior, not permission enforcement.
- Check missing references, child failure, scoped activation after resume, no nested dispatch, no automatic document edits, and no second review gate. Retain existing review limits rather than importing EGM's larger loops.
- Sandbox installation/uninstallation tests; verify foreign-link preservation, existing skill overrides, both provider instruction renders, and unchanged settings/harness/manifest bytes. Run the project's documented suite before edits and after integration, plus a manual explicit document check before claiming success.

## Non-goals

No full EGM authoring mode, upstream plugin installation, documentation bootstrap, automatic drift scanning, comment-count rule, additional code-review layer, independent progress store, global opt-in, or guarantee that passing comprehension proves correctness. These can be separate proposals if the initial check demonstrates value.

## References and capability evidence

The reference method is Dave Rensin's [Elephant–Goldfish article](https://drensin.medium.com/elephants-goldfish-and-the-new-golden-age-of-software-engineering-c33641a48874), read from the user-supplied PDF, and the [upstream project](https://github.com/google/elephant-goldfish-model/tree/403d8881d62022490637d740657b33f01e321ea8). This proposal selects comprehension and artifact clarity, not the entire plugin.

Independent inspection of Prime Agent source at `d3fcf89acd1b9774fb957ed1a183451dab062e9b` confirms that the flag suppresses skill advertisement while explicit `/skill:name` expansion still reads the skill. Fresh children start new message histories and load global plus child-local harness guidance, not an automatic copy of parent-local harness state. They retain shared resources and potential family-observation access. These source facts do not certify the deployed runtime or permission enforcement; the release checks above remain required.

For a natural-language request, resolve the skill from the currently configured Prime skill root. Report a missing installation rather than searching arbitrary copies or hardcoding this development checkout. Explicit user requests, not the mere presence of an instruction or referenced document, authorize invocation.
