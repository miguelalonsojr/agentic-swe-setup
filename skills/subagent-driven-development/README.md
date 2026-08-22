# Controller-managed subagent-driven development

This local skill overrides the upstream serial implementation dispatch. It keeps the upstream briefs, reports, range-based review packages, five-round fix loop, rulings, final review, and escalation rules.

The controller maps dependencies and collision edges before dispatch. It dispatches the largest safe wave. A safe wave contains tasks with satisfied dependencies and resolved collision edges.

The controller creates each writer worktree sequentially from the wave integration HEAD. Read-only tasks use stable inputs. Workers only change and commit their assigned task in the supplied worktree.

The task reviewer reads the worker commit range before integration. The controller compares the actual change scope, then cherry-picks approved commits one at a time in dependency order. It runs focused tests after each integrated commit and the full suite after each wave.

The controller records worker state in the plan ledger. It records worktree cleanup only after integration or an explicit abandonment ruling. The final whole-branch review runs after all waves complete.
