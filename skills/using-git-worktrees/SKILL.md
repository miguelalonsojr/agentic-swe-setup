---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Mode selection

Use one mode for one purpose:

- Feature/controller workspace mode prepares the workspace that owns a feature or plan. It uses the detect, create, setup, and baseline flow below.
- SDD writer provisioning mode creates and cleans controller-owned child worktrees. It uses `scripts/worker-worktree` and does not run the feature/controller detection flow.

A linked worktree stops creation only in feature/controller workspace mode. SDD writer provisioning may create child writer worktrees from a linked controller worktree.

## Feature/controller workspace mode

### Step 0: Detect existing isolation

**Before creating anything, check if the feature or controller workspace is already isolated.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.

### Step 1: Create isolated workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

### Step 2: Project setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### Step 3: Verify clean baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```


## SDD writer provisioning mode

The controller creates and removes worker worktrees. It owns each writer worktree and branch. Workers only use the path in their dispatch brief. Workers must not create, remove, merge, rebase, or cherry-pick worktrees or branches. Workers must not dispatch nested agents. A worker commits only its assigned task changes.

The controller records the integration `HEAD` as the explicit `base` before each wave. Create writer worktrees sequentially before dispatching the wave. The skill owns this sequencing because concurrent Git metadata changes can collide.

A native writer-worktree tool is valid only when it accepts the recorded base and returns the path, branch, and base needed by the ledger. It must also verify those values, use the canonical root, and satisfy the same cleanup contract. A general native workspace tool that chooses its own base does not meet this contract.

Without such a native tool, use the helper from the controller worktree:

```bash
skills/using-git-worktrees/scripts/worker-worktree create \
  --plan-slug "$plan_slug" \
  --task-id "$task_id" \
  --task-slug "$task_slug" \
  --base "$base"
```

The helper derives the primary worktree from porcelain output without field splitting. It restricts each slug component. It places writers under the canonical primary-worktree `.worktrees/<plan>/...` root. It verifies that `.worktrees/` is ignored relative to the primary worktree before creation. It refuses an unignored root. It creates from the explicit base, then verifies and prints `path`, `branch`, and `base`.

Record the printed values and task ownership in the ledger before dispatch. Do not reconstruct them later.

### Cleanup after integration or abandonment

Cleanup requires an exact terminal ledger record. The accepted records are:

```text
Task $task_id | state=integrated | worktree=$path | branch=$branch
Task $task_id | state=abandoned | worktree=$path | branch=$branch
```

A cherry-picked worker commit is not an ancestor of the integration branch. Do not infer integration from ancestry. After recording one accepted line, run:

```bash
skills/using-git-worktrees/scripts/worker-worktree cleanup \
  --ledger "$ledger" \
  --task-id "$task_id" \
  --path "$path" \
  --branch "$branch"
```

The helper derives authorization from the ledger. It does not accept a caller-supplied state. It verifies the canonical path, Git registration, checked-out branch, and clean status. A dirty writer is never force-removed. Remove the worktree before deleting its branch. Record `cleaned` only after the helper succeeds.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Feature/controller mode in a linked worktree | Skip controller creation and continue setup |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native feature-workspace tool available | Use it in feature/controller mode |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call. |
