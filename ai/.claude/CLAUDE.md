# git worktrees

- After a worktree's PR is merged, remove the worktree right away without asking: `ExitWorktree` with removal for native ones; otherwise `git worktree remove <path>` (`--force` only for untracked files verified safe to drop), then `git branch -d <branch>`. Skip only if I want to keep working there or it holds uncommitted/unpushed work.

# dotfiles

- `~/.dotfiles` (public git repo, GNU Stow) holds config that should persist across machines. Each top-level dir is a stow package mirroring `~` (`ai/.claude/` → `~/.claude/`, so this file lives there). Read `~/.dotfiles/CLAUDE.md` before adding files there.
- When changing any config (shell, nvim, Claude settings/skills/MCP, Brewfile, launchd, tools), decide whether it should persist. If yes, change it in the dotfiles repo (`stow -Rv <package>` for new files). Machine-local, company-specific, secret or generated → keep it out (gitignore) and say so. Don't commit or push unless asked; mention persistent changes left uncommitted.

# shell

- `sed` is GNU sed: `sed -i 's/a/b/' file`, never BSD `sed -i '' ...`.

# argocd / kubectl

- Run argocd only in core mode with an explicit context and that context's own kubeconfig: `KUBECONFIG=~/.kube/clusters/<ctx>.yaml argocd --core --kube-context <ctx> ...` (core mode takes the cluster from `$KUBECONFIG`'s current-context, not `--kube-context`). No `argocd login` or port-forward. Contexts already use namespace `argocd`; don't change it. After `az aks get-credentials`, regenerate the file: `kubectl config view --minify --raw --context <ctx> > ~/.kube/clusters/<ctx>.yaml` (machine-local, never in dotfiles).
- Prefix every `kubectl diff` / `argocd ... diff` with `unset KUBECTL_EXTERNAL_DIFF;` in the same command (it's interactive nvim and hangs).
- ALWAYS diff right before every Argo CD sync, even a single resource, and check the diff is exactly what you expect before giving the sync command. Never rely on an earlier diff or render. If `argocd app diff` fails (e.g. kubelogin workload identity only works in the Argo pod), run `kubectl --context <target> diff --server-side --force-conflicts -f <manifests from origin/main>` instead. Argo's OutOfSync list (`.status.resources`) is not a diff.

# commands I run myself

- For commands I run (syncs, applies, logins, rollouts, anything stateful), give exactly ONE per message in its own `bash` block plus one line on the expected output, then wait for my pasted output. Never a list, script or "next, run...". Filter noisy output with grep/awk.

# writing

- Replies follow the Concise output style. Text for others (Confluence, Jira, PRs, runbooks, Slack drafts): must-haves only, no background or extra sections; when unsure a line is needed, cut it. Never cut errors, test failures or security/destructive warnings.
