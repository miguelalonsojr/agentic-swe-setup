# Dispatching Parallel Agents

Upstream source: `$HOME/.superpowers/skills/dispatching-parallel-agents`.

This repository provides a local override for the upstream skill. The override classifies each task as `read-only` or `write-capable`, maps collision edges, and schedules the largest safe wave.

`using-git-worktrees` defines worktree setup. This skill requires a controller-created worktree for every concurrent writer. `subagent-driven-development` consumes the safe-wave decision when it dispatches and integrates tasks.
