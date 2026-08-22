# Controller-managed subagent-driven development

This local skill overrides the upstream serial implementation dispatch. It retains task TDD, range-based review packages, the five-round fix loop, role escalation, sequential integration, rulings, and strongest whole-branch review.

`dispatching-parallel-agents` owns the complete collision inventory, controller-assigned namespace rulings, and largest safe wave. `using-git-worktrees` and `worker-worktree` own writer creation and cleanup. `routing-model-tiers` owns general per-dispatch model choice. SDD loads and consumes those policies. SDD owns orchestration, role routing, review and fix loops, integration, recovery, and final review.

The task ledger uses `planned`, `dispatched`, `committed`, `reviewed`, `integrating`, `integrated`, `abandoned`, and `cleaned` states. It records commit ranges and source-to-integration mappings so restart recovery does not repeat implementation or lose a commit when a worktree is missing.

Each plan workspace uses a readable basename and a stable hash of its canonical repository-relative path. Plans with the same basename do not share artifacts.
