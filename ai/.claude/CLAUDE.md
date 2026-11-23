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

# shell

- `sed` is aliased to GNU sed. Use `sed -i 's/a/b/' file`, never the BSD form `sed -i '' ...` (it treats `''` as the script and breaks the command).

# argocd cli

- Always run the `argocd` CLI in core mode with an explicit context: `argocd --core --kube-context <context> ...`. No `argocd login`, no API server/port-forward. Core mode requires the kube context's namespace to be `argocd` (it looks for Argo CD's resources in the context's namespace); all my contexts are already set that way, so don't change it.
- Also point `KUBECONFIG` at that context's own file: `KUBECONFIG=~/.kube/clusters/<context>.yaml argocd --core --kube-context <context> ...`. Core mode resolves `https://kubernetes.default.svc` from `$KUBECONFIG`'s current-context and ignores `--kube-context`, so server-side diffs otherwise run against whatever cluster is current. The files are machine-local (credentials, not in dotfiles); after `az aks get-credentials` regenerate one with `kubectl config view --minify --raw --context <context> > ~/.kube/clusters/<context>.yaml`.

# kubectl / argocd diff

- Before every `kubectl diff` or `argocd ... diff` (e.g. `argocd app diff`), run `unset KUBECTL_EXTERNAL_DIFF` in the same command (`unset KUBECTL_EXTERNAL_DIFF; kubectl diff ...`). My `KUBECTL_EXTERNAL_DIFF` is interactive neovim, which hangs/breaks Claude's non-interactive terminal. Shell state doesn't persist between calls, so repeat it every time.

# commands for me to run (one at a time)

- When I run commands myself (cluster syncs, applies, logins, rollouts, anything stateful or sequential), give exactly ONE command per message, in its own fenced `bash` block, then stop and wait for me to run it and paste the output. Never a list, a script, or "next, run...". Analyze the output, then give the next single command.
- Say in one short line what the expected output is, so I can see whether it matched. Wrap noisy output in a filter (`grep`/`awk`) instead of making me read all of it.
- Applies in every repo and every session. I'm the one clicking Run in the terminal pane; several commands in one message hide failures and break the check-after-each-step flow.

# response style

- Keep responses short and direct. Lead with the result or answer; no preamble ("Let me...", "Now I'll...") and no closing recap.
- Don't narrate steps or restate the request. Report outcomes, decisions, and anything I must act on.
- Default to 1-3 sentences of plain prose. Use headers/tables/bullets only when they carry real structure.
- Give full detail only when I ask for it. Never cut error output, test failures, or security/destructive-action warnings for brevity.
- This also applies to everything written for other people (Confluence, Jira, PR descriptions, runbooks, Slack drafts): must-haves only. No background, no explanations of obvious things, no extra sections. When unsure whether a line is needed, cut it. People don't read long text.
