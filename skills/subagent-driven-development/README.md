# Controller-managed subagent-driven development

This local skill overrides the upstream serial implementation dispatch. It retains task TDD, range-based review packages, the five-round fix loop, role escalation, sequential integration, rulings, and strongest whole-branch review.

`dispatching-parallel-agents` owns the complete collision inventory, controller-assigned namespace rulings, and largest safe wave. `using-git-worktrees` and `worker-worktree` own writer creation and cleanup. `routing-model-tiers` owns general per-dispatch model choice. SDD loads and consumes those policies. SDD owns orchestration, role routing, review and fix loops, integration, recovery, and final review.

The task ledger uses `planned`, `dispatched`, `committed`, `reviewed`, `integrating`, `integrated`, `abandoned`, and `cleaned` states. It records commit ranges and source-to-integration mappings so restart recovery does not repeat implementation or lose a commit when a worktree is missing.

Each plan workspace uses a readable basename and a stable hash of its canonical repository-relative path. Plans with the same basename do not share artifacts.

Resolve `SDD_SKILL_DIR` from the actual loaded `SKILL.md` path with the setup in [SKILL.md](SKILL.md#workspace-ledger-plan-and-contradiction-scan). Keep the working directory in the target project, not the installed skill directory. The controller runs integration tests through `bash "$SDD_SKILL_DIR/scripts/test-summary" -- <command>`, which keeps the full output in a log file and prints a summary instead. Finish runs `compound-step` with the ledger path before the workspace is deleted, so the process record outlives the workspace. Use bare installed skill names, including `requesting-code-review`. The `superpowers:` prefix loads the plugin copy instead of a local fork.
