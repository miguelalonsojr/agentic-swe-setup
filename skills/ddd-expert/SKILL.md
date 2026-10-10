---
name: ddd-expert
description: Use when complex business rules or conflicting domain terms need clarification before choosing bounded contexts, entities, value objects, or aggregates.
---

## When to use

Use this guide when domain vocabulary is contested, rules differ across teams, or a proposed model must protect business invariants. Start with the problem the user is trying to solve. A simple data record, CRUD screen, or naming question alone does not justify a domain model. If the request is about storage, deployment, or framework boundaries without domain rules, answer that request directly rather than adding domain concepts.

## Procedure

1. Ask who uses each term, which actions matter, and what rules those actions must preserve. Request concrete examples of valid and invalid outcomes. If the rules are unknown, identify the missing decisions instead of inventing them.
2. Write a small glossary in the users' words. Mark terms with more than one meaning and ask whether the meanings belong to distinct workflows or teams. Treat a bounded context as a boundary around a consistent meaning and set of rules, not as a synonym for a service or a table.
3. Model only what the examples require. Use an entity when its continuing identity matters despite changing attributes. Use a value object when its value and constraints matter but independent identity does not. State the evidence for either choice; do not classify every noun.
4. Consider an aggregate only when a specific invariant must hold across changes. Identify the boundary, the allowed changes, and where the invariant is checked. Keep unrelated operations outside that boundary. If the consistency requirement is not known, leave the aggregate undecided and ask about the relevant failure case.
5. Compare the candidate model with the original examples and with a counterexample. Show which rule each choice serves, and give the smallest alternative when the domain is too simple for these distinctions.

## Verification

Check that stakeholders can recognize the terms and that each stated rule has at least one concrete example. Walk through a valid change and a rejected change without assuming an undocumented interface or persistence mechanism. Separate observed requirements from hypotheses, and ask for confirmation of hypotheses before treating them as design constraints.

## Limits

This guide helps clarify domain meaning; it does not prove transaction guarantees, choose a database, or prescribe a service layout. Do not claim a bounded context or aggregate is required merely because a team or data structure exists. Avoid attributing invented rules to stakeholders.

## References

- [Crunching knowledge](references/ch01_crunching_knowledge.md)
