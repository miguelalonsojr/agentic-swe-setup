# jira-fu

Create a Jira epic, stories and sub-tasks from a markdown backlog, and verify
the hierarchy landed.

`SKILL.md` is the agent-facing guide. This file is for humans running it by hand.

## Install

Drop the directory where your agent looks for skills, or symlink it so edits
take effect without copying again:

```bash
# Claude Code
ln -sfn "$PWD/jira-fu" ~/.claude/skills/jira-fu

# OpenCode
ln -sfn "$PWD/jira-fu" ~/.config/opencode/skills/jira-fu
```

`~/.agents/skills/` also works as a cross-runtime location on Codex, Copilot CLI
and Gemini CLI.

The script stands on its own. If you only want the tooling and not the skill,
run `jira_backlog.py` directly from wherever you cloned it.

## Set up credentials once

```bash
printf '%s' 'YOUR_API_TOKEN' > ~/.jira-token
chmod 600 ~/.jira-token
```

Create the token at https://id.atlassian.com/manage-profile/security/api-tokens.

Then, per shell:

```bash
export JIRA_SITE=https://yourcompany.atlassian.net
export JIRA_PROJECT=ABC
export JIRA_EMAIL=you@yourcompany.com
export JIRA_TOKEN="$(cat ~/.jira-token)"
```

Nothing is defaulted. The script refuses to run rather than guess a site or a
project, because guessing wrong writes issues into someone else's board.

## Write the backlog

```markdown
## EPIC: Ship the thing

Why this exists, in a paragraph or two.

---

## Ticket 1: First area of work

What this groups together.

*Acceptance criteria*

- [ ] Outcome someone can check

### Task 1.1: First unit of work

One or two sentences.

*Acceptance criteria*

- [ ] Something testable
```

`## Ticket N:` becomes a Story. `### Task N.M:` becomes a Sub-task of it. A `---`
or any later `## Heading` ends the current description, so a trailing summary
section is not absorbed into the last issue.

## Run it

```bash
S=path/to/jira-fu/jira_backlog.py   # wherever you put it

python3 $S parse docs/BACKLOG.md # tree + warnings, no network
python3 $S wiki docs/BACKLOG.md 1.1 # preview one converted description
python3 $S probe # issue types, project style
python3 $S fields # required fields per type

python3 $S create docs/BACKLOG.md --epic-only
# look at the epic in the browser, then:
JIRA_EPIC_KEY=ABC-123 python3 $S create docs/BACKLOG.md

python3 $S verify # exits non-zero if anything is off
```

`create` writes `jira-created.json` (override with `JIRA_CREATED_JSON`) mapping
every task number to its issue key. That file is what `verify` reads, and what
you use to name branches after real keys.

## Why the epic goes first

A create call returning 201 means a row was written. It does not mean the issue
is parented where you asked, that the description rendered, or that a required
field was not silently defaulted. Creating one issue and looking at it costs a
minute; discovering the problem after 39 issues costs an afternoon of deletion.

## If a run dies part way

`create` rewrites `jira-created.json` after every story, so the file lists what
exists. Do not re-run `create` from the top - it will duplicate everything
already made, and Jira has no bulk undo. Pass `JIRA_EPIC_KEY` and cut the
finished stories out of the backlog first.

## Requirements

Python 3.9+, standard library only. No `pip install`.
