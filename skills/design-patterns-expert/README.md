# design-patterns-expert

Use this skill to evaluate a design pattern against a specific code change. It begins with the current behavior and the pressure to change it, then compares a candidate pattern with the simplest workable code. The answer should name the added indirection as well as the benefit, and reject a pattern when the benefit is speculative.

Give the agent the relevant code, call sites, tests, and the change you expect. If you only have a design question, describe the constraints and what must remain stable. The skill can suggest a small implementation sketch and a behavior-focused check. It does not assume an external API, claim that an unrun test passed, or replace a general code-style review.
