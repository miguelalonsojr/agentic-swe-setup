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

## Workflow Scaling

Classify implementation work before selecting workflow skills. Use the fast path only when every eligibility condition holds. Use the bounded or full path when any required condition does not hold.

### Fast path

A task uses the fast path only when all of these conditions hold:

- The change affects at most two files.
- The change is localized and easy to reverse.
- The expected result is clear.
- The change requires no cross-component coordination.
- One focused command can verify the result.
- The change does not affect a public API, schema, migration, dependency, security control, authentication flow, concurrent behavior, or destructive operation.

Fast-path work follows these rules:

- Make the change directly and keep the edit surgical.
- Do not invoke `brainstorming`, `writing-plans`, worktree management, subagents, or formal review.
- Do not require a new test for documentation, formatting, or mechanical configuration changes.
- Add or update a focused test for a behavior change when practical.
- Inspect the diff and run focused verification before reporting completion.
- Load a craft skill only when the task needs its specific guidance.

A failure whose root cause is unknown does not qualify for the fast path. Use the bounded path with `systematic-debugging` unless the risk or scope requires the full path.

### Bounded path

Use the bounded path for a localized change to an existing flow when the task fails a fast-path condition but has no architectural or listed high-risk effect.

- Use the short in-chat `brainstorming` flow and obtain approval before implementation.
- Do not write a design document or implementation-plan document.
- Work directly unless isolation or delegation has a concrete benefit.
- Use tests and review in proportion to the change risk.
- Apply the coding discipline and verification rules below.

### Full path

Use the full path for architectural, unclear, cross-component, or high-risk work. Public APIs, schemas, migrations, dependencies, security, authentication, concurrency, and destructive operations are high-risk even when their diffs are small.

The full path retains the Superpowers design, planning, TDD, worktree, delegation, review, and verification workflows.

### Reclassification

Classification can become heavier after work starts. It cannot become lighter during the same task.

If fast-path work expands beyond two files or exposes new risk, stop direct implementation. Explain the new classification and obtain the approval required by the bounded or full path. Preserve existing edits, but do not extend them until approval.

An explicit user request for more process selects the heavier requested path. A request for less process can reduce optional ceremony but cannot remove a safety check required by a high-risk change.

## Coding Discipline

These checks apply before and during code changes in every supported harness.
They bias toward caution over speed; use judgment for trivial tasks.

### Think before coding

- State assumptions explicitly. If uncertain, ask.
- If a request has multiple plausible interpretations, present them instead of
  choosing silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop, name the confusion, and ask.

### Simplicity first

- Write the minimum code that solves the problem.
- Do not add features, abstractions, flexibility, configurability, or error
  handling that the task does not require.
- If the solution is much larger than the problem, simplify before proceeding.

### Surgical changes

- Touch only the files and lines needed for the request.
- Do not refactor, reformat, or clean up adjacent code unless the task requires
  it.
- Match existing style, even when you would choose differently.
- Remove imports, variables, functions, or files that your own change makes
  unused. Mention unrelated dead code; do not delete it unless asked.
- Every changed line should trace back to the user's request.

### Goal-driven execution

- Turn work into verifiable goals: reproduce bugs with tests, make new behavior
  observable, and define what proves a refactor is safe.
- For multi-step tasks, state a brief plan with a verification check for each
  step.
- If success criteria are weak or ambiguous, clarify them before implementation.

### Test design

Test intent, not implementation. Some contracts require implementation
awareness, including performance characteristics, concurrency guarantees, and
safety invariants. Test an implementation detail only when it is part of the
contract, such as “this function is O(log n)” or “this operation is atomic
under contention.” Otherwise, treat it as internal and avoid locking tests to
it.

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
are missing from it. This table is authoritative. Its model strings are Prime
Agent `rlm(model=...)` selectors and are not valid anywhere else. Installed roles must use the
configured thinking level shown in the table. A direct `rlm()` call that omits
`thinking` inherits the parent session's thinking level.

<!-- PRIME_AGENT_ROLE_ROUTING_TABLE -->

- Dispatch with the model and thinking level from the table, never the ones
  you are running on:

  ```python
  handle = await rlm(task, name="reviewer", model="<!-- PRIME_AGENT_REVIEWER_MODEL -->", thinking="<!-- PRIME_AGENT_REVIEWER_THINKING -->")
  ```

- `rlm()` accepts `name`, `model`, and optional `thinking`. Thinking is clamped
  to the selected child's model.
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

1. Direct user instructions, subject to necessary safety checks.
2. Workflow classification and the rules for the selected path.
3. Applicable Superpowers workflow skills.
4. This file's phase mapping.
5. Advisory craft-skill guidance.

Superpowers workflows remain mandatory when the bounded or full path names them. They are not mandatory when the fast path explicitly excludes them. YAGNI overrides optional abstractions and unrelated work.
