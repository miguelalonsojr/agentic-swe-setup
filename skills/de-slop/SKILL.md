---
name: de-slop
description: Use when an existing draft sounds formulaic or conspicuously AI-written and the user wants it revised without losing their voice, facts, terminology, or requested register.
---

# De-slop

Remove formulaic wording from an existing draft. Preserve what the writer means and how the writer wants to sound. The default is not a technical register.

## When to use

Use this skill when the user asks to “de-slop,” “make this sound human,” remove an “AI footprint,” or revise a draft that relies on canned transitions, inflated claims, repetitive framing, or uniform sentence rhythms.

If the task is to draft or edit a technical specification in a deliberately dry, consistent register, use `plain-technical-prose` instead. If the user requests both, use that register as a constraint while removing formulaic wording. Do not treat an unfamiliar voice as an error merely because it is expressive or informal.

## Procedure

1. Identify the draft's purpose, audience, voice, facts, technical terms, and any wording the user says to keep. If the intended voice is unclear and different choices would change the result, ask a short question. Otherwise infer only what the text supports.
2. Find repeated structures and phrases that do no work. Look for generic praise, unsupported superlatives, long lead-ins, predictable three-part lists, and conclusions that repeat the opening. Do not use a blacklist as an automatic deletion rule: a phrase can be apt in context.
3. Rewrite at the level needed. Replace vague statements with the draft's actual point, vary syntax where repetition sounds mechanical, and remove filler. Keep purposeful repetition, quoted text, names, numbers, caveats, and the writer's level of formality. If a claim needs support, preserve its uncertainty rather than inventing support.
4. Return the revised text in the format requested. Add a brief note only when a material meaning change, missing context, or unresolved factual claim needs the user's attention.

## Verification

Compare the revision against the draft. Check that every factual claim, qualification, attribution, technical term, and requested constraint survives. Read the revision as the intended audience would: does it sound like this writer, not like a standardized editor? Check that the edit did not introduce new facts, flatten deliberate humor or emphasis, or switch registers. If a passage cannot be improved without guessing at its meaning, flag it instead of silently replacing it.

## Limits

This is prose editing, not fact-checking or a promise that text will evade AI detectors. Do not claim to identify an author's identity or prove how a draft was made. Do not invent product behavior, citations, APIs, research findings, or quotations to make a paragraph feel specific.

## References

- [Common formulaic patterns](references/tropes.md) — optional examples to inspect, not a list of forbidden words.
