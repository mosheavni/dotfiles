# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
  When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# git worktree cleanup

- When work done in a git worktree (native `EnterWorktree` or manual `git worktree add`) ends with its PR merged, delete the worktree locally right after confirming the merge — don't wait to be asked.
  - Native tool: use `ExitWorktree` with removal, or answer "remove" if prompted at session end.
  - Manual worktree: `git worktree remove <path>` (add `--force` only if it refuses due to untracked files you've verified are safe to drop), then `git branch -d <branch>` if not already deleted.
  - Skip cleanup only if the user says they want to keep working in it, or other uncommitted/unpushed work remains in it.
