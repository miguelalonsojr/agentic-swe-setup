# Using Git Worktrees

Upstream source: `$HOME/.superpowers/skills/using-git-worktrees`.

The controller worktree is the integration workspace. It records the integration commit for each wave. Each writer uses a separate controller-created worktree and branch based on that commit. The controller creates and removes those writer worktrees. A writer only changes and commits its assigned task in the supplied path.

Local links override the upstream skill. The local skill keeps the upstream isolation, setup, and baseline rules. It adds the controller-managed lifecycle for concurrent writers.
