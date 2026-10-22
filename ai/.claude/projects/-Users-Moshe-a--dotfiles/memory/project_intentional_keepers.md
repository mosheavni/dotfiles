---
name: project-intentional-keepers
description: Dotfiles code that looks dead/unsafe but is intentionally kept — do not flag or delete
metadata:
  node_type: memory
  type: project
  originSessionId: 31583fab-540a-4029-aea5-c7a2ea787682
---

Confirmed by user on 2026-07-03 during repo audit (AUDIT.md, deleted 2026-10-22 after full execution — see git history):

- `automations/.local/bin/morning-routine.sh` — invoked by a macOS Shortcut, an external reference repo greps cannot see. Not orphaned.
- `zsh/zsh.d/functions.zsh` `zip-code` — embedded `ocp-apim-subscription-key` is a public website's key, deliberately kept (`#gitleaks:allow`). Not a secret.
- nvim lua: `_G.put_text` (used interactively at `:lua` prompt), `utils.get_visual_selection_stay_in_visual`, `git.get_toplevel` (async) — zero call sites but kept on purpose for future/interactive use.
- `zsh/.bin/git-branches.zsh` — invoked from `nvim/.config/nvim/lua/plugins/fzf.lua` (confirmed by user 2026-10-22). Cross-package reference: zsh/.bin scripts may be called from the nvim config, so an audit that scopes out nvim/ still can't call them dead.

**Why:** grep-based dead-code sweeps flag these every time; user already ruled keep.
**How to apply:** in future audits/cleanups of this repo, skip these items or mark "intentional keeper" — don't propose deletion again.
