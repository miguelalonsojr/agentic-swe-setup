---
name: compound-step
description: Use when a branch, plan, or multi-session task finishes - after the final review and before the workspace is deleted - or when the human asks what was learned. Turns rulings, review findings, surprises, and repeated fixes into small, evidence-backed updates to instructions, skills, or memory.
---

# Compound Step

An agent follows the instructions it is given. Instructions improve only when someone writes the lesson down. A session that corrects the same mistake three times ends with the correction in the code and nothing in the instructions, so the next session makes the mistake again. Run this step once per branch, after the final review and before the workspace is deleted.

## Harvest

Collect candidate lessons from the sources below. If the dispatch names a ledger path (`Ledger: <path>`), read that file first.

- The SDD ledger: lines that contain `Ruling:`, parked findings, deferred minors, and any task that took two or more fix rounds.
- Review findings that recurred across tasks. One naming complaint in one task is noise. The same complaint in four tasks is a missing rule.
- Verification failures: a test, lint, build, or install step that broke for a reason the instructions did not cover.
- Human corrections made during the session. A correction is evidence that the instructions did not say what the human wanted.
- Items listed under "Follow-ups" in task reports and in the final message.

Each candidate carries one evidence line: the ledger line, the review finding, or the human's words, quoted.

## Keep or drop

Keep an item only if it recurred, cost a fix round, or came from a human correction. Drop one-offs. A surprise that happened once and cost nothing is a fact about one task, not a lesson.

## Classify

Each kept item has one destination.

| Item | Destination |
|---|---|
| A fact about this project: a path, a command, a convention, a constraint | The project's instruction file (`CLAUDE.md` or `AGENTS.md`) |
| A procedure that another project would also need | A skill, new or existing, through `writing-skills` |
| A durable preference or fact about the human or the environment | Memory. Prime Agent: `refine`. Other harnesses: the instruction file. |
| Work this branch will not do | An issue, or the follow-ups list |
| Anything else | Drop |

A project fact written into a skill leaks project detail into every other project. A reusable procedure written into an instruction file is unavailable everywhere else. Classify before drafting the text.

## Propose and apply

Present the kept items to the human as one list. One line per item: what changes, where it lands, and the evidence.

```
<what changes> -> <file or mechanism> (evidence: <line>)
```

The human approves each item. Approval is per item, not for the list. Apply approved items in a commit separate from the feature work, so a revert of one leaves the other standing. Route a new or edited skill through `writing-skills`; do not hand-write a `SKILL.md` around this skill.

Keep each edit small. One sentence in an instruction file, one row in a table, or one memory entry is the normal size.

## Compound step

The final message carries a section with this heading. Three lines, or one line per applied item.

```
## Compound step
Proposed: <n items>
Approved: <n items, or the ones the human declined>
Applied: <what, where, commit sha>
```

An empty harvest is a valid result. Report "Proposed: 0" rather than inventing an item.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "The git history is the record" | It records what changed, not why the process failed. A rework loop leaves no commit. |
| "I will remember next time" | The next session starts in a fresh context. Models do not carry the lesson; instructions do. |
| "Too small to capture" | Small items are what compound. One line costs nothing per session and applies to every session. |

## Related skills

- `writing-skills`: structure and verification for any skill this step creates or edits.
- `finishing-a-development-branch`: runs at the same moment. The compound step comes first, because it needs the workspace.
- `subagent-driven-development` Finish: source of the rulings list, the parked findings, and the deferred minors.
