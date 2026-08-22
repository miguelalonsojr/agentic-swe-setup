# Using Git Worktrees

Upstream source: `$HOME/.superpowers/skills/using-git-worktrees`.

The local skill has two modes. Feature/controller workspace mode retains the upstream isolation, setup, and baseline flow. SDD writer provisioning mode permits a linked controller to create child writer worktrees.

The controller runs `scripts/worker-worktree` sequentially for writer creation and cleanup. The helper uses the canonical primary-worktree `.worktrees/<plan>/...` root. It verifies ignore status, the explicit base, the branch, the path, exact terminal ledger authorization, and clean status. A conforming native writer tool must accept the recorded base and return verified path, branch, and base values.

Local links override the upstream skill.
