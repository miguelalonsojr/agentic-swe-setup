# Dispatching Parallel Agents

Upstream source: `$HOME/.superpowers/skills/dispatching-parallel-agents`.

The local override owns task inventory, dependency and collision edges, controller-assigned namespace decisions, and selection of the largest safe wave. The inventory includes expected files, interfaces, generated artifacts, lockfiles, migrations, configuration, and external resources.

`using-git-worktrees` owns writer lifecycle. `subagent-driven-development` consumes this skill's inventory and safe-wave decision, then orchestrates dispatch, review, integration, and recovery.
