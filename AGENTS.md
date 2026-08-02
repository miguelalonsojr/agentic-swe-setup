# Agent Instructions

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

Five role agents are defined in both harnesses under the same names:
implementer-light, implementer, implementer-strong, reviewer,
reviewer-lite. When executing superpowers subagent-driven-development:

- Implementation dispatches go to `implementer` (or `implementer-light`
  for mechanical 1-2 file tasks with complete specs).
- Spec-compliance and code-quality review dispatches go to `reviewer`.
  The final whole-branch review also goes to `reviewer`.
- Scoped re-reviews of small fix diffs go to `reviewer-lite`.
- Never retry the same agent unchanged after BLOCKED.

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
  `reviewer-lite` agents regardless of model choice, so the
  read-only tool restriction applies.

### Precedence

1. Superpowers workflow skills (process, TDD, verification) — mandatory.
2. This file's phase mapping — load the named craft skill at the named phase.
3. Craft skill advice — apply where it fits the task; drop it where it conflicts
   with YAGNI or the approved plan.