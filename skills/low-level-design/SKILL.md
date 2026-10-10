---
name: low-level-design
description: Use when a task asks for object-level design of a bounded system, class responsibilities and interactions, or an interactive low-level design interview drill.
---

# Low-level design

## When to use

Use this guide for objects and behavior inside one bounded system, such as a vending machine. It applies to class models, interaction walkthroughs, and live design drills. For cross-service topology, storage, replication, and scale, use a system-design guide. For a named pattern or architectural principle, use its specialist guide.

## Procedure

1. Establish the mode. For a worked design, ask for missing rules that could change object ownership. For a drill, give one requirement at a time and let the participant propose a model before giving feedback. Do not present later requirements as agreed facts.
2. List actors, operations, constraints, and exclusions. Separate supplied facts from assumptions. Confirm consequential assumptions. Select one representative operation for the first pass.
3. State invariants in observable terms. For a vending machine, an item cannot be dispensed if payment is insufficient. Assign each invariant to an object that can enforce it using its owned state. Introduce an object for a distinct responsibility or state boundary, not for every noun.
4. Draw a small object diagram with relationships and ownership. Use text if rendering support is unknown. Label multiplicity or lifetime only when it changes behavior. Trace the operation through calls and state changes. Check ordinary, failure, and cancellation paths against the invariants that apply.
5. Define a runnable seam: a small entry point or test that constructs the minimum objects, performs the operation, and checks its result and state. If the task is design-only, provide a test sketch and say it was not run. Add another scenario only when it exposes a different rule. Refine responsibilities after tracing the interaction; add a pattern only for a concrete constraint.
6. In drill mode, identify one gap in the current answer and ask a follow-up that reveals its consequence. Allow revision before adding a requirement. Record accepted decisions and open assumptions.

## Verification

Check that each operation has an initiator, each invariant has an owner, and the diagram agrees with the interaction trace. If code was requested, run the seam and report the command and result. Otherwise distinguish proposed behavior from observed behavior. Check a boundary or invalid case when the model claims to handle it.

## Limits

Do not infer framework APIs, persistence, concurrency guarantees, or product rules without evidence. A diagram does not prove that a model runs. Do not claim unexecuted sketches pass tests. Stop at the smallest model that satisfies the agreed requirements.

## References

- [Deriving the model](references/deriving-the-model.md)
