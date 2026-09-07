# Agentic engineering patterns audit — design

Date: 2026-09-06
Status: draft, awaiting review
Source: Simon Willison, *Agentic Engineering Patterns*, all 17 chapters as of 2026-09-06
(https://simonwillison.net/guides/agentic-engineering-patterns/). Fetched text is in
`/tmp/aep/*.txt` for the duration of this work.

## Goal

Bring agentic-swe-setup into line with the guide's patterns, remove the conflicts the
audit found between installed skills, and cut token spend where a pattern is missing
or a rule is stale. The output is: three new repo-owned skills, two forked Superpowers
skills, edits to `AGENTS.md` and the SDD skill, a thinking-ladder change, and the
installer, tests, and docs that carry them.

## Audit summary

Present and adequate: red/green TDD; subagents for context preservation and parallel
work; model tiers; context hygiene (artifacts as files); the approval gate before
implementation; the "good code" definition in `AGENTS.md` coding discipline.

Partial: "first run the tests" (worktree baseline only); git recovery and history
authoring (no bisect, no tidy step, raw fix-round commits land); exploratory spikes
(brainstorming has a Spike path, `AGENTS.md` workflow scaling does not); naming the
validation mechanism in a dispatch (implementer prompt says "verify implementation
works" with no mechanism).

Missing: agentic manual testing; the compound engineering loop (retrospective that
updates instructions); the PR content contract from the anti-patterns chapter; pointing
agents at reference code; linear walkthroughs and interactive explanations.

Conflicts:

| # | Conflict | Resolution in this design |
|---|---|---|
| C1 | `AGENTS.md` surgical rule ("mention dead code; do not delete") vs the guide's zero tolerance for smells | Keep surgical. Capture smells as follow-ups; dispatch later as separate small tasks. |
| C2 | `test-driven-development` rationalization rows read as "do not manually test" | New `agentic-manual-testing` skill; one `AGENTS.md` line: tests are necessary, not sufficient. |
| C3 | Two taxonomies: `AGENTS.md` fast/bounded/full vs `brainstorming` spike/bounded/architectural | Add spike to `AGENTS.md`; state the mapping explicitly. |
| C4 | SDD lands raw fix-round commits on one branch per plan vs authored history and small PRs | History tidy and size report in the forked `finishing-a-development-branch`. |
| C5 | Seven references to SDD `## Model Selection`, a section that no longer exists | Repoint to `routing-model-tiers` and SDD `## Role routing and recovery`. |
| C6 | Controller reads full test output when integrating; the guide's test-runner pattern hides it | `test-summary` script in SDD; no new role. |

## Decisions already taken

1. Write all three new skills.
2. Fork `finishing-a-development-branch` and `systematic-debugging` into `skills/`.
3. Showboat is used only when the design or task calls for a demo or walkthrough
   document. Plain markdown with pasted output is the default evidence format.
4. Thinking ladder: light tier `medium`, default `high`, strong `xhigh`,
   `cross-checker` stays `high`.

## Changes

### 1. New skill: `agentic-manual-testing`

Description (trigger): use after the tests pass and before claiming a change works,
is fixed, or is done — run the code the way a user would and record what happened. Also
use when a task brief names a manual check, or when a change touches a CLI, an HTTP
API, a web UI, a startup path, or a migration.

Core principle: never assume generated code works until it has been executed. Passing
tests are necessary, not sufficient. Manual testing is not a substitute for tests; a bug
it finds is fixed with red/green TDD.

Content:

- Mechanism by surface. Library or function: `python -c` or the language equivalent,
  or a scratch file under `/tmp` (never inside the repo). CLI: run it with real
  arguments, including `--help`. HTTP API: start the dev server, `curl` it, explore
  several endpoints and edge cases. Web UI: Playwright, `agent-browser`, or
  `uvx rodney --help`; take screenshots and read them. Startup and migrations: boot
  the app; run the migration against a scratch database.
- Evidence rule. Record the command and its real output. Output is pasted from the
  run, never typed. Default format: fenced blocks in the task report (SDD) or the
  final message and PR body (non-SDD). Showboat (`uvx showboat --help`; `note`,
  `exec`, `image`) when the task asks for a demo document.
- Bug found: write the failing test that reproduces it, then fix. Never patch without
  a test.
- Scope: a few happy-path and edge cases; time-boxed. This is not a second test suite.
- Cannot run it here: say so and name the exact command you would run. Silence is not
  evidence.
- Rationalizations table: "tests pass, so it works"; "screenshots are overkill";
  "I will describe what it should do"; "I already know this code".
- Relationships: `test-driven-development` (complement, not substitute — this resolves
  C2); `verification-before-completion` (same evidence rule); the SDD implementer
  report (where evidence lives).

Size: under 200 lines.

### 2. New skill: `compound-step`

Description (trigger): use when a branch, plan, or multi-session task finishes — after
the final review and before the workspace is deleted — or when the human asks what was
learned. Turns rulings, review findings, surprises, and repeated fixes into small,
evidence-backed updates to instructions, skills, or memory.

Content:

- Harvest. Sources: the SDD ledger (`Ruling:` lines, parked findings, deferred minors,
  tasks with two or more fix rounds), review findings that recurred across tasks,
  verification failures, human corrections during the session, follow-ups recorded
  under C1.
- Threshold. Keep an item only if it recurred, cost a fix round, or came from a human
  correction. Drop one-offs.
- Classify. Project fact → the project's instruction file (`CLAUDE.md`/`AGENTS.md`).
  Reusable procedure → a skill, new or existing, via `writing-skills`. Durable
  preference or fact → memory (Prime Agent: `refine`; other harnesses: the instruction
  file). Follow-up work → an issue or the follow-ups list. Everything else → drop.
- Propose. Present a list to the human: what, where, the evidence line. The human
  approves each item. Apply approved items in a commit separate from the feature work.
- Report. A "Compound step" section in the final message: proposed, approved, applied.
- Rationalizations table: "the git history is the record" (it records what changed,
  not why the process failed); "I will remember next time"; "too small to capture".
- Relationships: `writing-skills`; Prime Agent `refine`; SDD Finish; the forked
  `finishing-a-development-branch`.

Size: under 150 lines.

### 3. New skill: `codebase-walkthrough`

Description (trigger): use when a human needs to understand code they did not write or
do not remember — onboarding to a codebase, reviewing an agent-built branch before
merge, or paying down cognitive debt on vibe-coded code. Produces a linear,
reading-order walkthrough with real snippets, and on request an interactive
explanation.

Content:

- Scope: whole codebase, one subsystem, or a branch (`git diff <base>..HEAD`). For a
  branch the order follows the change: entry point, data flow, tests.
- Read first, then plan the order: entry point → core flow → supporting modules →
  tests.
- Snippets are pulled by command (`sed -n 'a,bp' file`, `grep -n`, `git diff`), never
  hand-copied. Showboat `exec` when the task asks for a Showboat document; otherwise a
  fenced block with the command on the first line and the pasted output.
- Each section: what it does, why it exists, how it connects, then the snippet.
- Output path: the path the human names; default `docs/walkthroughs/<slug>.md`. Ask
  before committing.
- Large scope (more than a few thousand lines): dispatch light-tier read-only
  subagents for per-module notes; assemble in the root context.
- Interactive explanation: when a mechanism stays unclear after the walkthrough (an
  algorithm, a state machine, a scheduling loop), offer a single-file HTML animation
  with pause, step, and speed controls. Vanilla JS, no build step. Only on request.
- Rationalizations table: "I will paraphrase the code"; "the README covers it".
- Relationships: `generating-design-doc` (structured architecture document — a
  different artifact); `requesting-code-review` (a walkthrough helps the human do
  their own review, which the anti-patterns chapter requires; it does not replace the
  review dispatch).

Size: under 150 lines.

### 4. Fork: `finishing-a-development-branch`

Copy `~/.superpowers/skills/finishing-a-development-branch/SKILL.md` at upstream
commit `b36e082` into `skills/finishing-a-development-branch/`. Keep upstream text
except these additions:

- Step 1b, after tests pass: if the change has a runnable surface and no manual-testing
  evidence exists yet, run `agentic-manual-testing`; otherwise point at the existing
  evidence.
- Step 1c, history tidy: list `git log --oneline <base>..HEAD`; squash fix-round and
  WIP commits into the task commit they fix; rewrite messages to describe the change,
  not the process; keep task boundaries as commits. Never rewrite commits already on a
  shared branch. If the branch is already pushed, ask first.
- Step 1d, size report: files and lines changed against the base. Above 400 lines or 10
  files, offer a split into stacked PRs by task. The human decides.
- Option 2 (PR), description contract: goal and a link to the spec or issue; what
  changed, per task or commit; how it was tested — test command and result, manual
  testing evidence with commands, output, and screenshots for UI; rulings and deferred
  items; a line stating the author reviewed the diff and this description. Present the
  PR body in chat and wait for approval before posting.
- New step before cleanup: run `compound-step` if it has not already run for this
  branch.

`README.md` records the upstream path, the pinned commit, and the list of additions
so drift can be re-applied.

### 5. Fork: `systematic-debugging`

Copy the whole `~/.superpowers/skills/systematic-debugging/` directory at `b36e082`
(SKILL.md and its reference files). Additions to Phase 1 (root cause investigation):

- When did it break: for a regression, use `git bisect run` with a script that
  exercises the symptom (a failing test or a `python -c` check). Needs a known-good
  commit — ask, or use the last tag. The agent writes the boilerplate.
- What changed recently: `git log` over the relevant paths seeds the investigation.
- Lost code: `git reflog`, `git stash list`, and `git log --all -S'<snippet>'`.

`README.md` records provenance as in section 4.

### 6. `AGENTS.md` edits (shared body)

- Workflow scaling: add a Spike path — a feasibility question whose output is an
  answer, not code you keep; a two-to-three-sentence probe plan, a nod, throwaway code
  labeled as such. Add one mapping sentence: fast = no `brainstorming`; bounded =
  `brainstorming`'s bounded; full = `brainstorming`'s architectural; spike =
  `brainstorming`'s spike.
- Session start: on an existing project, run the test suite with the project's
  documented command before the first edit; report the count and result. Applies on
  every path.
- Surgical changes: list smells, dead code, and refactor opportunities you notice under
  "Follow-ups" in the final message; never fold them into the current diff; after the
  goal lands, offer to dispatch each as its own small task.
- Testing: passing tests are necessary, not sufficient. Before claiming a change works,
  exercise it as a user would (`agentic-manual-testing`) when it has a runnable
  surface.
- Reference code: when the user points at an example — a repo, a file, a URL — read the
  real thing. Clone repos to `/tmp`, fetch raw source with `curl`, never commit
  reference copies.
- Good code: if a change alters documented behavior, update the documentation that
  describes it.

### 7. SDD edits (`skills/subagent-driven-development/`)

- `implementer-prompt.md`: step 3 becomes "Verify: run the covering tests; then
  exercise the change per `agentic-manual-testing` when it has a runnable surface, and
  record commands and output in the report." Report format gains "Manual testing
  evidence" next to "TDD Evidence".
- `task-reviewer-prompt.md`: Part 1 gains "Docs: if the change alters documented
  behavior, was the documentation updated? Missing doc updates are a Missing finding."
- `scripts/test-summary CMD...`: runs the command, writes full output to
  `<workspace>/test-output/<timestamp>.log`, prints the exit code, pass/fail counts
  when the runner prints them, failing test names, and the last 30 lines on failure.
  SKILL.md integration steps ("focused tests after each integrated commit", "full
  suite after each wave") name the script.
- Finish: run `compound-step` with the ledger path before `rm -rf <workspace>`.
- C5: replace every "choose per SKILL.md Model Selection" with "choose per
  `routing-model-tiers`; roles per SDD `## Role routing and recovery`". Same repoint
  in `routing-model-tiers` and `cross-checking-claims`.
- Forked-skill references: SDD names `superpowers:using-git-worktrees` and
  `superpowers:finishing-a-development-branch`. On Claude Code that prefix loads the
  plugin copy, not this repo's fork. Drop the prefix for every skill this repo forks;
  keep it for skills it does not (`superpowers:requesting-code-review`).

### 8. Thinking ladder

| Tier | Roles | Prime `thinking` / OpenCode `variant` | Claude Code `effort` |
|---|---|---|---|
| light | `explore`, `implementer-light`, `reviewer-lite` | `medium` | `medium` |
| default | `general`, `implementer`, `reviewer` | `high` | `high` |
| strong | `implementer-strong`, `reviewer-final` | `xhigh` | `xhigh` if accepted, else `high` |
| strong | `cross-checker` | `high` | `high` |

Files: `prime/anthropic.json`, `opencode/anthropic.json`, `agents/*.md` frontmatter,
`README.md` ladder tables and the "every tier reasons at high" paragraph,
`tests/test_prime_configs.sh` (currently asserts all Anthropic roles are `high`),
`tests/test_provider_configs.sh`, `tests/test_agents.sh`. The OpenAI ladder is
unchanged.

Open verification: whether Claude Code agent frontmatter accepts `effort: xhigh`.
Check the Claude Code documentation or schema before editing `agents/*.md`. If it does
not, the strong tier stays `high` on Claude Code and the README says so.

### 9. Installer, tests, docs

- `scripts/lib.sh` `LOCAL_SKILLS` gains `agentic-manual-testing compound-step
  codebase-walkthrough finishing-a-development-branch systematic-debugging`.
- Each new directory has `SKILL.md` and `README.md` (`tests/test_local_skills.sh`
  requires both).
- One content test per new or forked skill, in the style of
  `tests/test_using_git_worktrees_skill.sh`: needles anchored on the sentences that
  make the skill correct.
- `tests/test_subagent_driven_development_skill.sh` gains needles for the test-summary
  script, the compound-step hook, and the absence of "Model Selection".
- Baseline fix: `tests/test_local_skills.sh` expects the routing skill to say
  "accepts `name` and `model` and nothing else"; the skill now says it accepts
  `thinking` too. `just test` is red on `main` before this work. Update the needle to
  the current sentence.
- `README.md`: skill table rows; ladder tables; the fork list.

## Fork policy

A fork copies the upstream directory verbatim at a pinned commit, then applies the
listed additions. `README.md` in the skill records upstream path, commit, and the
additions. `just update` refreshes `~/.superpowers` but never touches `skills/`; drift is
re-applied by hand when upstream changes matter.

Claude Code loads Superpowers as a plugin, so a forked skill coexists with
`superpowers:<name>` rather than replacing it. The rendered Claude Code `AGENTS.md`
names the forked skill without the `superpowers:` prefix so the fork is the one
loaded. OpenCode and Prime Agent replace by symlink.

## Non-goals

- No new subagent roles. The guide warns against going overboard; the test-runner
  pattern is a script, not a role.
- No changes to the OpenAI ladder or to model choices.
- No fork of `test-driven-development` or `brainstorming`.
- No project-level scaffolding (Showboat notes directories, walkthrough directories)
  installed by this repo.

## Risks

- `xhigh` on Claude Code frontmatter may not exist. Mitigation in section 8.
- The `medium` light tier may raise turn counts on some tasks. Mitigation: reversible
  config; revisit after a few plans using Prime session token logs.
- Fork drift from Superpowers. Mitigation: pinned commit and additions list per fork.
- Manual testing adds tokens per task. Mitigation: time-boxed, surface-gated, and
  skipped when the change has no runnable surface.

## Verification

`just test` green, including the new content tests. `just install-skills` links the
five new directories. `just doctor` reports them. The rendered `build/*/AGENTS.md`
carry the new sections and the correct routing table.
