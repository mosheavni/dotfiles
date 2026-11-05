# graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
  When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.

# git worktree cleanup

- When work done in a git worktree (native `EnterWorktree` or manual `git worktree add`) ends with its PR merged, delete the worktree locally right after confirming the merge — don't wait to be asked.
  - Native tool: use `ExitWorktree` with removal, or answer "remove" if prompted at session end.
  - Manual worktree: `git worktree remove <path>` (add `--force` only if it refuses due to untracked files you've verified are safe to drop), then `git branch -d <branch>` if not already deleted.
  - Skip cleanup only if the user says they want to keep working in it, or other uncommitted/unpushed work remains in it.

# dotfiles

- `~/.dotfiles` (git repo, GNU Stow) holds every config that should persist across machines. Each top-level dir is a stow package whose inner layout mirrors `~` (e.g. `zsh/.zshrc` → `~/.zshrc`, `ai/.claude/` → `~/.claude/`, `nvim/.config/nvim/` → `~/.config/nvim/`). This file itself lives there (`~/.claude` is a symlink into `ai/`).
- Whenever you change configuration (shell, git, nvim, wezterm, starship, Claude settings/skills/commands/MCP servers, Brewfile, launchd agents, tool configs, etc.), ask yourself: should this persist? If yes, make the change inside the dotfiles repo (right stow package, then `stow -Rv <package>` if it's a new file) rather than only in `~`; if it's machine-local, secret, or generated, leave it out (gitignore it) and say so. Never put tokens/credentials in the repo.
- Read `~/.dotfiles/CLAUDE.md` (Architecture ▸ Stow Package Structure) before adding new files there. Don't commit or push the repo unless asked; do mention when a persistent change is left uncommitted.
