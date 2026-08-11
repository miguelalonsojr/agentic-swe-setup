# Agent Instructions

## Disagreement

Say the disagreement first. If the user is wrong, a plan has a flaw, or a task
spec is broken, that comes before agreement and before starting work.

## Responding

- Lead with the answer. The first sentence carries information, not an
  assessment of the message and not a preview of the reply.
- Let the reply end when the content ends. No restating what the message
  already covered, no unrequested next steps. Summarizing work you did is not
  a recap — a review report is a summary and stays one.
- State the point, don't announce that it matters. No "the real question is",
  "what's notable", "worth flagging".
- Structure earns its place: bullets for discrete items, prose for reasoning.
  A report format required by a skill outranks this.

## Craft skills (swe-agent-skills)

In addition to the Superpowers workflow skills, this environment has book-grounded
craft skills installed: `ddd-expert`, `clean-architecture`, `design-patterns-expert`,
`clean-coding`, `pragmatic-engineer`, `system-designing`, `de-slop`,
`generating-design-doc`. Load them with the `skill` tool at the phases below.
They are advisory references, not workflows — the Superpowers process always
governs sequencing, and YAGNI wins any conflict: never add layers, patterns, or
abstractions a craft skill suggests unless the current task requires them.

### Phase mapping

**During `brainstorming`:**
- If the design involves domain modeling, entities, or business rules, load
  `ddd-expert` before proposing a model. Use its bounded-context and aggregate
  guidance to shape the design doc.
- If the design involves distributed systems, storage, replication, queues, or
  streaming, load `system-designing` before discussing trade-offs.
- If the design involves decisions that are costly to reverse (schema,
  wire formats, public APIs) or requirements are still fuzzy, load
  `pragmatic-engineer` for its reversibility and tracer-bullet guidance.
- For module/layer structure and dependency direction, load `clean-architecture`.

**During `writing-plans`:**
- Load `clean-architecture` once to sanity-check the planned file/module layout
  before writing tasks.
- IMPORTANT: for each implementation task in the plan, add an explicit step
  telling the executing agent which craft skill to load, e.g.
  "Load the `clean-coding` skill, then implement...". Subagents only do what the
  plan says — a skill not named in the task text will not be used.
- Default per-task skill: `clean-coding`. Add `design-patterns-expert` only for
  tasks where the design doc already calls for a specific pattern.

**During `subagent-driven-development` / `executing-plans`:**
- Follow the skill-load steps written into each task. Do not skip them.
- Apply `clean-coding` naming/function/error-handling guidance within the
  RED-GREEN-REFACTOR cycle — craft applies at the REFACTOR step, never as an
  excuse to write code before a failing test.

**During `requesting-code-review` / when reviewing code:**
- Load `clean-coding`, `clean-architecture`, and `pragmatic-engineer`.
  Review against all three: naming, function size, error handling,
  comments (clean-coding); dependency rule and layer violations
  (clean-architecture); duplication and needless coupling between
  components (pragmatic-engineer).
- Report craft violations using the normal severity levels. A dependency
  pointing the wrong direction across a layer boundary is at least Major.
  Duplicated knowledge (not just duplicated text) is at least Minor.

**When writing prose** (READMEs, design docs, PR descriptions, comments meant
for humans):
- Load `de-slop` and apply it before presenting the text.

**When asked to document an existing codebase:**
- Load `generating-design-doc` and follow it instead of improvising a format.

### Subagent-driven development routing

The same role agents are defined in all three harnesses:
implementer-light, implementer, implementer-strong, reviewer,
reviewer-final, reviewer-lite, cross-checker. When executing superpowers
subagent-driven-development:

- Implementation dispatches go to `implementer` (or `implementer-light`
  for mechanical 1-2 file tasks with complete specs).
- Per-task spec-compliance and code-quality review dispatches go to
  `reviewer`.
- The final whole-branch review goes to `reviewer-final` (the strong
  model - reserved for this one merge-gating pass).
- Scoped re-reviews of small fix diffs go to `reviewer-lite`.
- A load-bearing claim that needs an independent check goes to
  `cross-checker`, which runs on a different model from the tier that
  produced the claim. Both installed ladders stay inside one vendor;
  `cross-checking-claims` covers what that decorrelation is worth.
- Never retry the same agent unchanged after BLOCKED.
- Before dispatching a subagent, and especially before a batch, load the
  `routing-model-tiers` skill and pick a tier per task. Enumeration and
  lookup go to the light tier; synthesis and judgement go to the default
  or strong tier.
- Before a subagent's finding goes into a design doc, plan, or decision
  log, load the `cross-checking-claims` skill. It applies only to claims
  that would change the work if they were wrong.

#### When running under OpenCode

- Ignore the skill's instructions to pass a `model:` parameter when
  dispatching - model and reasoning effort are fixed by the agent
  definitions in opencode.json.
- Escalation ladder: DONE_WITH_CONCERNS or NEEDS_CONTEXT ->
  re-dispatch `implementer` with better scoping; BLOCKED or fix
  round 4 -> `implementer-strong`; if implementer-strong reports
  BLOCKED -> re-dispatch it on its `max` variant; still BLOCKED ->
  escalate to the human.

#### When running under Claude Code

- Follow the skill's native model-selection guidance: pass a model
  per dispatch and escalate per the skill's status protocol. The
  agent frontmatter models are fallbacks, not mandates.
- Exception: all review dispatches MUST go to the `reviewer` /
  `reviewer-final` / `reviewer-lite` agents regardless of model
  choice, so the read-only tool restriction applies.

#### When running under Prime Agent

Prime Agent has no agent-definition files. The same roles are
installed as continual-harness subagent specs, and every dispatch is
an `rlm(...)` call that names its model explicitly.

The harness roster is a hint, not a lookup. Prime Agent summarises each
subagent spec to 180 characters and shows only six of them, so some roles
are missing from it. This table is authoritative. The model strings are
Prime Agent `rlm(model=...)` selectors and are not valid anywhere else.

<!-- PRIME_AGENT_MODEL_TABLE -->

- Dispatch with the model from the table, never the one you are running on:

  ```python
  handle = await rlm(task, name="reviewer", model="<!-- PRIME_AGENT_REVIEWER_MODEL -->")
  ```

- `rlm()` accepts `name` and `model` and nothing else. A child's thinking
  level is inherited from this session and clamped to the child's model, so
  there is no per-dispatch thinking argument to pass.
- Children reply with `await agent_message.send(msg, receiver_role='parent')`.
  Ask for an explicit reply in the task text whenever you need the
  DONE / DONE_WITH_CONCERNS / BLOCKED status back.
- Prime Agent cannot enforce read-only tools per child. A spec marked
  read-only must say so in the dispatch text: tell the reviewer to
  report findings only and to make no edits.
- Escalation ladder matches OpenCode: DONE_WITH_CONCERNS or
  NEEDS_CONTEXT -> re-dispatch `implementer` with better scoping;
  BLOCKED or fix round 4 -> `implementer-strong`; still BLOCKED ->
  escalate to the human.
- Delete a child with `await rlm.delete_subagent(handle)` once its
  context is no longer needed.

### Precedence

1. Superpowers workflow skills (process, TDD, verification) — mandatory.
2. This file's phase mapping — load the named craft skill at the named phase.
3. Craft skill advice — apply where it fits the task; drop it where it conflicts
   with YAGNI or the approved plan.