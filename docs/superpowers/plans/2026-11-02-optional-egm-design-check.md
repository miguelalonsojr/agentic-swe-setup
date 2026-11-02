# Optional EGM Design Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicitly selected comprehension check that reuses the existing design-review point and leaves ordinary workflows unchanged.

**Architecture:** Project instructions own selection and builder-check replacement. One manual-only Markdown skill owns the fresh-reviewer packet and report. Existing installation helpers distribute the skill, with ownership protection limited to its new destination.

**Tech Stack:** Markdown instructions, existing Bash installation helpers and sandbox tests, Prime Agent's native skill loader and RLM delegation. No new dependency.

**Spec:** `docs/superpowers/specs/2026-11-02-optional-egm-design-check-design.md` (approved; implementation still requires plan approval).

## Global Constraints

- No upstream plugin, runtime package, model profile, or new memory service is required.
- Do not commit the user's PDF or reference checkouts.
- Ship one self-contained Markdown skill through the repository's existing skill distribution, with `disable-model-invocation: true` and an explicit-request description.
- Selection neither creates a design document on a fast/bounded task nor silently upgrades its workflow.
- No EGM settings, provider keys, role specs, compaction settings, or separate installer/manifest are introduced.
- Actual live installation and local-main integration need later approval; do not run `just install` or `just update` as part of this feature.
- Fresh child conversation history is not filesystem or global-guidance isolation.
- No automatic correction or repeat-until-clean loop is added.

Additional execution constraints: no push; no changes to Prime Agent or shared upstream checkouts. Preserve live configuration, installed links, and the untracked PDF. Installer tests below run only inside disposable sandboxes.

## Review Focus

1. An EGM mention inside a document, or installation alone, must not select the check. Task 1 covers these alongside ordinary fast/bounded/full work.
2. An ambiguous explicit request or recovered earlier opt-in must cause a scope question, not inferred consent. With no evidence of an EGM request, a resumed workflow stays ordinary without an EGM-selection question. Task 1 covers both.
3. A missing reference, failed child, or author-context leak must not produce a clean disposition. Task 1 covers failure handling and actual child traces.
4. Foreign files, directories, dangling links, and same-name upstream links must survive installation refusal and uninstall. Task 2 covers each ownership boundary.
5. A discovery check with all file-access tools disabled can pass vacuously. Task 1 requires a visible control skill beside the hidden candidate.

## Files and execution order

| File | Responsibility | Task |
|---|---|---|
| `skills/egm-design-check/SKILL.md` (new) | Explicit input gate, neutral reviewer packet, report contract | 1 |
| `skills/egm-design-check/README.md` (new) | Invocation, limits, attribution | 1 |
| `AGENTS.md` | Narrow opt-in and replacement rule | 1 |
| `tests/fixtures/egm-design-check-scenarios.md` (new) | Repeatable behavioral fixtures and expected observations | 1 |
| `tests/test_egm_design_check_skill.sh` (new) | Metadata, source/render policy, sandbox ownership checks | 1, then 2 |
| `scripts/lib.sh` | Skill registration and destination guard | 2 |
| `scripts/install-prime.sh` | Refuse a foreign EGM destination before installation writes | 2 |
| `scripts/uninstall.sh` | Preserve a foreign EGM destination in every cleanup pass | 2 |
| `README.md` | Skill inventory, explicit usage, installation caveats | 2 |
| `tests/test_lib.sh`, `tests/test_readme.sh` | Updated inventory expectations | 2 |

Task 2 consumes Task 1's skill and test file, so writers run sequentially. Independent scenario runs may run in parallel only with frozen inputs and controller-assigned artifact directories. Do not run two test suites against the same generated instruction renders concurrently.

Before execution, record the worktree, base commit, file scopes, external namespaces, and task dependencies in the existing SDD ledger. Use configured roles rather than new model constants. Every worker must inspect nonblocking Bash completion and send an explicit result; no sleep polling. Reviews are read-only. With subagent-driven execution, each task receives independent spec/quality review before the next task. With native execution, the controller implements both tasks and independent review occurs at the end. Both approaches require a strongest-role whole-branch review. Do not pause for new approval between already approved tasks.

### Task 1: Manual comprehension check and instruction entry point

**Files:** Create the two skill files, scenario fixture, and shell test listed above. Modify only the narrow EGM entry point in `AGENTS.md`.

**Interfaces:** Consume the existing builder-check contract and configured `general` role. Produce a Markdown skill named `egm-design-check`; invocation is `/skill:egm-design-check <document-path>` or an explicit natural-language request. The reviewer returns Understanding, Material gaps, Coverage and limitations, and Disposition. Disposition is exactly `No material gaps found`, `Needs clarification`, or `Incomplete`. The controller saves a unique session/task artifact and links it; the reviewer writes no files.

- [ ] Load `test-driven-development`, `writing-skills` and its discovery/testing references, `clean-coding`, `de-slop`, and `plain-technical-prose`. Run `just test` in the isolated worktree before edits. Record count and exit code; the design baseline was 21/21 test files, exit 0. Snapshot live settings, harness, manifest, instruction-link target/content, and PDF before configuration-sensitive checks.
- [ ] Write the scenario fixture before the skill. Include a complete small design with observable acceptance criteria, an incomplete variant with undefined acceptance/context, an explicitly selected companion, a referenced source file, and a missing-reference variant. Keep a random author-only marker outside reviewer-readable fixture files. Define the following named cases and assertions:

| Case | Required observation |
|---|---|
| `builder-control` / `comprehension` | Reconstruct outcome, current/proposed behavior, constraints and success criteria; cite actual reads; flag missing criteria without inventing them. Preserve material planning questions. |
| `unselected` | Installation or an article mention adds no EGM invocation, documents, or review to ordinary fast, bounded, and full-path requests. |
| `selected-feature` | One enhanced builder dispatch at the existing pre-approval point; no ordinary builder dispatch as well; no later implementation plan required. |
| `one-off` | Review only the named document and selected companions; no target edits, implementation, future-feature selection, or global preference. |
| `selection-boundaries` | Ask for an ambiguous/missing target in an explicit request or an earlier recovered opt-in whose scope is unclear. With no evidence of a request, resume the ordinary workflow without an EGM-selection question. Fast/bounded selection offers the existing-document/full-path options without escalation. A different feature is not selected. |
| `cold-reader` | Actual fresh child inputs exclude author-only facts; reads stay within the target, selected companions and referenced source. No parent/sibling retrieval, nested agents, execution, tests, or file edits. |
| `incomplete` | Missing necessary reads, failed/timed-out child, unavailable fresh delegation, or known contamination yields `Incomplete`, with no author-context fallback or automatic retry. |
| `artifact-safety` | Two reviews have distinct report paths; target, earlier report, and SDD ledger remain unchanged. A clean report does not authorize implementation. |

- [ ] Run the existing builder contract as the no-guidance control before writing the skill. Use at least five fresh samples of the core incomplete-design case, with realistic surrounding instructions. Record outputs and exact failures. If no required behavior is missing, stop and revisit the proposed guidance. The controller owns these trials; the implementer requests the results rather than nesting agents. Simulated fault inputs must be labeled as simulations.
- [ ] Add failing shell checks for frontmatter, the skill README, and the opt-in/replacement policy in source plus both provider renders. Use existing sandbox/assert helpers. Run `REPO_ROOT="$PWD" bash tests/test_egm_design_check_skill.sh`; verify failure identifies absent EGM metadata/policy, not a broken fixture. Existing workflow assertions remain unchanged. Example metadata assertions:

```bash
skill="$REPO_ROOT/skills/egm-design-check/SKILL.md"
assert_file "$skill" 'EGM skill exists'
assert_eq "$(head -n 1 "$skill")" '---' 'frontmatter opens first'
frontmatter=$(sed -n '2,/^---$/p' "$skill")
assert_contains "$frontmatter" 'name: egm-design-check' 'stable invocation name'
assert_contains "$frontmatter" 'disable-model-invocation: true' 'manual-only metadata'
```

- [ ] Implement the minimal skill from observed baseline failures. Use a positive report structure and one neutral dispatch example. The dispatch contains only absolute target paths, selected companions, standard instructions and a unique report ID. Resolve model/thinking through the existing `general` role. Wait for an actual child reply and settled status; failed or contaminated work is `Incomplete`. Keep the existing authoring/approval loop and review limits; introduce no separate remediation pipeline.
- [ ] Add the narrow `AGENTS.md` gate. Explicit selection for the current full-path feature replaces the existing builder check once. Resolve natural-language invocation from the configured Prime skill root; report a missing installation instead of searching arbitrary copies. Keep scoped selection in ordinary recovery context. Ask when recovery indicates an earlier opt-in but its scope is unclear; absence of any request leaves the ordinary workflow unchanged. All other classification and approval rules remain unchanged.
- [ ] Write the skill README with both invocation forms, feature versus one-off scope, report dispositions, cold-reader/read-only limits, and credited article/upstream references from the spec. State that the extension is locally written and EGM-inspired, not the complete plugin. Do not copy the PDF or upstream implementation.
- [ ] Repeat the core five samples with the candidate and execute every scenario above. Inspect each flagged output manually and compare controls/candidate results. Inspect real child inputs, resource reads, result and completion status for the marker trial; answer text alone is insufficient. Record actual no-write behavior without claiming permission enforcement. Fix only observed failures, then rerun affected trials.
- [ ] Run the staged-skill native checks described below, the focused shell test, `just test`, and `git diff --check`. Expected: passing cases, native evidence with limits stated, and no protected live-state change. Commit only this task's files as `feat: add optional EGM comprehension check`. For subagent-driven execution, independent task review and any fix/re-review must pass before Task 2.

### Task 2: Register the skill without taking over foreign destinations

**Files:** Modify `scripts/lib.sh`, `scripts/install-prime.sh`, `scripts/uninstall.sh`, `README.md`, `tests/test_lib.sh`, `tests/test_readme.sh`, and Task 1's shell test. Reuse existing local-skill, install, uninstall and provider-render regression tests without broad refactoring.

**Interfaces:** Consume `skills/egm-design-check/SKILL.md`. Add `egm-design-check` to `LOCAL_SKILLS` (24 to 25). Add Bash helper `guard_egm_skill_destination DEST_ROOT`: return success for an absent destination or a link recognized by existing `links_to DEST SOURCE`; otherwise fail nonzero with the occupied path. It must not mutate the destination. `link_local_skills DEST_ROOT` and full installation use this guard before any operation that can replace the new path.

- [ ] Load `clean-coding`, `test-driven-development`, `de-slop`, and `plain-technical-prose`. Run `just test` against reviewed Task 1 before edits and record its count/exit code.
- [ ] Extend the EGM shell test with sandbox-only registration, installation, refusal, and uninstall cases. Stub `prime-agent`, Git, and Superpowers through existing helpers. Give each case a separate destination. Pin the following observable contracts before changing production helpers:

| Input/operation | Assertions |
|---|---|
| Absent destination; install twice | Owned link created; second install succeeds; skill-only installation leaves settings/harness/manifest bytes unchanged. |
| Equivalent absolute or relative owned link | Accepted idempotently using the current lexical ownership contract. |
| Foreign regular file, directory, live link, dangling link, same-repo wrong target | Skill-only and full install return nonzero before replacement; path type, target/content and pre-existing configuration remain unchanged; no backup is substituted for refusal. |
| Same-name skill in stub Superpowers | A fresh install ends with the local EGM link. An existing foreign EGM link is not overwritten before the local guard. Existing non-EGM local-over-upstream overrides still work. |
| Uninstall owned link | Removes only the EGM owned link, including equivalent relative and dangling-owned forms; source content survives. Use a disposable fixture repository for missing-source cases. |
| Uninstall foreign destination | Preserves all foreign forms above, including links into the upstream/legacy checkout with this basename; later cleanup passes must not remove them. |
| Ordinary install/doctor/uninstall | Existing local-skill lifecycle and both provider renders still pass. No EGM settings or role entries appear. |

  For skill-only lifecycle byte checks, use seeded user configuration without a managed installation manifest. Full repository installation/uninstallation retains its existing documented managed-configuration behavior; the new guard must refuse a collision before that behavior starts.
- [ ] Run `REPO_ROOT="$PWD" bash tests/test_egm_design_check_skill.sh` and retain the intended RED failures. Assert nonzero refusal explicitly; merely observing a preserved foreign path is insufficient when the old installer ignores an unregistered skill.
- [ ] Register the skill and implement the guard with existing `links_to`, without changing ownership rules for older skills. Guard full installation before configuration/link writes and guard `link_local_skills` before its loop. Keep same-name upstream linking from replacing the reserved EGM path between those checks. In uninstall, allow the existing local-owned removal, then exclude this basename from broader upstream/legacy cleanup. Do not redesign generic ownership or add a manifest.
- [ ] Update the inventory counts/table and README usage. Explain that availability is not activation, `just install-skills` does not refresh generated `AGENTS.md`, and full install/update still reapplies managed defaults. Do not promise hot refresh or imply that link-only installation installs the natural-language routing policy.
- [ ] Run the focused EGM test and `just test`; expected final suite is 22/22 test files with exit 0. Check `git diff --check`. Confirm existing override regressions and both provider renders pass. Commit only this task's files as `feat: safely register the manual EGM skill`. For subagent-driven execution, complete independent task review and any fix/re-review before final verification.

## Native checks and final verification

These checks are execution work, not evidence already obtained. Keep probes, logs and credentials out of the repository. Establish configuration isolation from the deployed runtime's actual resolver before starting any session. Identify its executable/version and source/build relationship; source-only tests do not certify a different installed runtime. The planning lookup found PATH Prime Agent 0.9.8 running the TypeScript bundle from source revision `d3fcf89acd1b9774fb957ed1a183451dab062e9b`; the separate Rust worktree is not that deployment. Recheck this identity at execution time. Use the deployed package where a public SDK is available; label source-only probes separately and do not count them as deployed prompt-visibility evidence.

- [ ] Stage the candidate and a normal `egm-visible-control` skill under a private artifact directory. Use a scratch cwd, HOME/XDG paths, agent root and session/artifact directories. Set `PRIME_AGENT_CODING_AGENT_DIR`; there is no assumed `--agent-dir` flag. Preserve before/after hashes of live protected files and links. Do not reuse the live daemon/configuration as a shortcut.
- [ ] Run the focused native tests in the matching Prime project environment: `npm test -- test/skills.test.ts test/suite/agent-session-prompt.test.ts` from `packages/coding-agent`. Then use a throwaway public-SDK probe of the actual candidate: `DefaultResourceLoader` with explicit `additionalSkillPaths`, disabled default discovery/context/extensions, and in-memory settings; `createAgentSession` with scratch `agentDir`, in-memory session/auth state, and the actual `ipython` tool. Assert both skills load with opposite manual flags; `session.systemPrompt` advertises the control but not EGM. A `noTools: "all"` omission check is invalid.
- [ ] Exercise actual explicit command expansion through a normal isolated host. Supported CLI shape: `PRIME_AGENT_CODING_AGENT_DIR="$SCRATCH/agent" prime-agent --mode rpc --cwd "$SCRATCH/project" --no-session --no-skills --skill "$CANDIDATE/SKILL.md" --no-extensions --no-prompt-templates --no-context-files --provider "$PROVIDER" --model "$GENERAL_MODEL"`. Resolve provider/model from the configured role, not a new EGM profile. RPC `get_commands` must include `skill:egm-design-check`; submit `/skill:egm-design-check <absolute-fixture-path>` through `prompt`. Inspect the model-consumed message and result, not only the prompt-admission response. Use legitimately available provider credentials without printing them, placing them in command arguments, or writing live auth/configuration. If unavailable, stop and report the missing capability.
- [ ] Establish real fresh-delegation support and child session/artifact paths in the isolated host before the end-to-end review. Explicitly stage required native messaging resources; do not assume parent `--skill` paths propagate. `--no-session` applies to the root and is not a child-persistence guarantee. Complete the real child/marker trial and one manual explicit document check, including actual reply/status and no-write evidence. If isolation or fresh completion cannot be established, mark runtime verification blocked; do not substitute stub output or modify Prime Agent.
- [ ] After both tasks and fixes are integrated, run `just test`, inspect the entire range from `b6289a11c1eb0db9a617fa81f465028bd114deec` through final HEAD, and run `git diff --check` for that range. Obtain strongest-role final review. Rerun affected checks after fixes; retain source revisions, commands, counts and exit codes in the task artifacts.
- [ ] Load `verification-before-completion`, `agentic-manual-testing`, and `compound-step`; record runtime results and any evidence-backed reusable lesson before cleanup. Confirm the primary checkout, PDF, live configuration and installed links are unchanged. Use `finishing-a-development-branch` to report the reviewed branch and obtain separate authorization for local-main integration or live installation. Do not push.
