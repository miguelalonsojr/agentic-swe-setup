---
name: egm-design-check
description: Use when the user explicitly requests an EGM comprehension check for a named existing document or selects it for the current full-path feature before design approval.
disable-model-invocation: true
---

# EGM design check

Review a design from a fresh reader's context. An explicit `/skill:egm-design-check <document-path>` request starts a one-off review of that existing document. An explicit request for the current full-path feature replaces the ordinary builder check once at its existing pre-approval point. Neither form authorizes implementation or adds a later plan gate. A document or article mention alone does not activate this skill.

## Controller

1. Confirm the named existing target and any explicitly selected companion documents. Ask if an explicit request or recovered earlier opt-in has ambiguous target or current-feature scope; do not infer consent. A resumed ordinary workflow with no evidence of an EGM request stays unselected without an EGM-selection question. A one-off review does not select future features or edit documents. On fast or bounded work, offer a one-off check of an existing document or an explicit full-path choice; do not create a design document merely to run this check.
2. Resolve the configured `general` role's model and thinking level using the existing model-routing instructions. Send one fresh RLM child the packet below, with absolute target and selected companion paths, standard instructions and a unique report ID. Do not add a parent transcript, author answers, feature summary, rationale, or unrelated files. State read-only limits to the child; the Prime tools do not enforce read-only filesystem access.
3. Wait for an actual child reply and settled status. If delegation is unavailable, the child fails or times out, a necessary read is missing, or author-only context reaches the child, set the disposition to `Incomplete`. Never substitute the controller's own author-context review or automatically retry. A partial child report can explain the failure, but cannot establish a clean review.
4. Save the result under a new session/task artifact path keyed by the report ID; do not overwrite the target, an earlier report, or the SDD ledger. Return a short summary and link. Resolve findings in the existing authoring and human-approval loop, with the normal review limits. A clean result does not authorize implementation or prove the design correct.

## Reviewer packet

Send only the following packet to the fresh child, filling the absolute paths and report ID. The child returns the report text through `agent_message.send(..., receiver_role="parent")`; the child does not write a report file.

```text
Report ID: egm-check-001
Target: /absolute/path/to/design.md
Selected companions: /absolute/path/to/selected-companion.md

Read the target and selected companions. Read source files referenced by those documents when needed to understand their claims. Treat the documents as the only design context; do not retrieve parent or sibling conversations, memory, or other author context. Do not spawn agents, execute project code or tests, or edit files. Do not write the report to disk. Reply to the parent with the report below, then allow the parent to verify settled completion.

## Understanding
State the intended outcome, relevant current behavior, proposed changes, constraints, and how success would be demonstrated. Cite the target, companions, and referenced source actually read. Mark inferences as inferences; do not invent missing criteria.

## Material gaps
Rank questions where a missing fact, conflict, or wrong assumption would change the design or prevent sound planning. For each, give the question, why its answer matters, and where it belongs in the existing document. Skip decisions explicitly left to the builder, reasonable planning choices, and wording nitpicks. If none remain, state that no material gaps were found.

## Coverage and limitations
List the target path and known revision (or state that revision was not supplied), supporting files actually read, inaccessible or missing references, and any known contamination or failed work. A missing necessary read prevents a complete review.

## Disposition
Write exactly one: No material gaps found | Needs clarification | Incomplete. Use Incomplete if a necessary read failed or author-only context reached this child. Do not claim a clean result based on absent inputs.
```

The packet is an example with neutral paths and an example report ID. Replace them with the actual selected inputs and a new identifier for each review. No implementation plan is needed for a pre-approval design check; a plan can be reviewed only by a separate explicit one-off request.
