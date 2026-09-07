# Finishing a Development Branch

Fork of `~/.superpowers/skills/finishing-a-development-branch` at upstream commit `b36e082`.

## Additions

- Step 1b: Manual check. A green suite does not prove the change works for a user, so a runnable surface is exercised before the integration menu.
- Step 1c: Tidy history. Fix rounds and WIP commits are squashed into the task commit they fix, so the branch history reads as the change rather than as the process.
- Step 1d: Size report. The size of the diff decides whether one PR is reviewable, so the number is reported before the menu.
- PR description contract, at the end of Option 2. The PR body lists the goal, the changes, the test and manual-testing evidence, the rulings, and an author-review line, so the reviewer does not reconstruct them from the diff.
- Step 5b: Compound step. Lessons from the branch are captured while the workspace still exists.

## Re-applying drift

Diff the upstream file against this one; the additions are the only intended differences.
