---
name: codebase-walkthrough
description: Use when a human needs to understand code they did not write or do not remember - onboarding to a codebase, reviewing an agent-built branch before merge, or paying down cognitive debt on vibe-coded code. Produces a linear, reading-order walkthrough with real snippets, and on request an interactive explanation.
---

# Codebase Walkthrough

A walkthrough is a reading order plus the real code at each stop. Each stop states what
the code does, why it exists, and how it connects to the stop before it.

It does not replace the review dispatch. `requesting-code-review` still runs against the
branch. The walkthrough serves the other reader: the human who has to understand code an
agent wrote before merging it, or code that has gone unread long enough to become
cognitive debt.

## Scope

Settle the scope before reading anything. Three scopes cover the usual requests.

| Scope | Reading order |
|---|---|
| Whole codebase | The public entry point, then the flow it starts. |
| One subsystem | The subsystem boundary, then inward. |
| A branch | `git diff <base>..HEAD`, then follow the change. |

For a branch the order follows the change rather than the repository layout: the entry
point the change touches, the data flow through it, then the tests that cover it.

## Order

Read first, then plan the order. A walkthrough written in the order the files happened
to be opened reads as a tour of the file tree.

The default order is: entry point, core flow, supporting modules, tests. Supporting
modules appear where the core flow first calls them, not in a block at the end.

## Snippets

Snippets are pulled by command, never hand-copied. A retyped or summarised snippet drifts
from the code, and the drift is invisible to the reader.

The commands that pull them:

```
sed -n '12,40p' path/file.py
grep -n 'def ' path/file.py
git diff <base>..HEAD -- path
```

Default format: a fenced block whose first line is the command, followed by the pasted
output. The command is part of the artifact, so a later reader can re-run it and see
whether the code still matches.

When the task asks for a Showboat document, run `uvx showboat --help` and use `exec` for
every snippet. Showboat is the format for a demo or walkthrough document, not the default
for evidence.

## Sections

Each section covers one unit: a module, a class, a function, or one hunk of a diff.
Write four parts in this order.

1. What it does. One or two sentences, in the domain's terms.
2. Why it exists. The problem it solves, or the constraint that forced it.
3. How it connects. Its caller, its callee, the data that crosses the boundary.
4. The snippet. Pulled by command, as above.

Prose before code. A reader who meets the code first has to reverse-engineer the point of
the section before reading it.

## Output

The output path is the one the human names. The default is `docs/walkthroughs/<slug>.md`,
where the slug names the scope: `auth-flow`, `pr-412-review`, `whole-repo`.

Ask before committing. A walkthrough is a document about the branch, and whether it
belongs in the branch is the human's call.

## Large scope

Above a few thousand lines, reading everything in the root context spends the context
budget on file contents rather than on the walkthrough.

Dispatch light-tier read-only subagents for per-module notes: one module per child, each
returning what the module does, its entry points, and the line ranges worth quoting.
Assemble the notes in the root context, where the reading order is decided. Children
report; they do not write sections of the document.

## Interactive explanation

When a mechanism stays unclear after the walkthrough, offer a single-file HTML animation
of it. The candidates are mechanisms that change state over time: an algorithm, a state
machine, a scheduling loop, a retry ladder.

Requirements: one HTML file, vanilla JS, no build step, and pause, step, and speed
controls so the reader sets the pace.

Only on request. The animation costs a second artifact and it explains one mechanism, so
it follows the walkthrough rather than replacing a section of it.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I will paraphrase the code, it is shorter" | A paraphrase drifts from the code and the reader cannot see the drift. Pull the lines. |
| "The README covers it" | The README says what the code was meant to do. The walkthrough shows what it does. |
| "A diff is a walkthrough" | A diff has no reading order and no why. It shows what changed, in path order. |
| "The tests document it" | Tests state the contract at one call site each. They do not give the flow between them. |

## Related skills

- `generating-design-doc`: a structured architecture document with diagrams. A different
  artifact for a different question, and a heavier one.
- `requesting-code-review`: the review dispatch this skill supports and does not replace.
