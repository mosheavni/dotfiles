<!-- markdownlint-disable MD013 -->

# Dotfiles Repository Audit

**Date:** 2026-07-03
**Scope:** Full repository — dead code, duplication, unnecessary abstractions, performance, stale references.
**Method:** Three exploration passes (nvim lua, zsh/shell, remaining packages) with grep-based cross-referencing. Every finding below carries its evidence; critical claims were re-verified by hand. No changes have been applied — this is a proposal document.

**Decisions:** Findings 1–10 were reviewed on 2026-07-03, findings 8 and 11–15 on 2026-07-05; each carries a **Decision** line (✅ approved / ❌ won't fix / ⏸ pending). Findings 16+ await review. Nothing has been executed yet.

Severity legend:

- 🔴 **Critical** — actively hazardous or broken behavior
- 🟠 **High** — dead code / stale wiring, safe wins
- 🟡 **Medium** — duplication worth consolidating
- 🟢 **Low** — polish, perf, thin abstractions

---

## 🔴 Critical

### 1. `start.sh` stows _every_ root directory — `examples/` nearly landed in `$HOME`

- **Where:** `start.sh:4` — `for dir in */; do stow -Rv "$dir"; done`
- **Evidence:** During this audit an untracked `examples/` dir (79 zero-byte files: `app.py`, `App.tsx`, `Dockerfile`, …) sat at repo root, absent from both `.stowrc` and `.gitignore`. A `./start.sh` run would have symlinked `~/App.tsx`, `~/app.py`, etc. into home. The directory has since been deleted, but the structural hazard remains: **any** stray root directory becomes a stow package.
- **Suggested change:** Make `start.sh` stow an explicit allowlist of packages, or at minimum add a guard (skip dirs not containing a dotfile/`.config` layout). Alternatively adopt a convention: scratch dirs at root must be dot-prefixed or added to `.stowrc` + `.gitignore` immediately.
- **How to test:**

  ```bash
  mkdir -p testjunk && touch testjunk/canary.txt
  ./start.sh                   # AFTER fix: no ~/canary.txt symlink appears
  rm -rf testjunk ~/canary.txt # cleanup
  ```

- **Risk:** Allowlist must include every real package or one silently stops deploying — compare `ls -d */` against the list when adding it.
- **Decision:** ❌ Won't fix — `examples/` was a test directory, already removed by hand. No `start.sh` guard wanted.

### 2. `fzf-rm` broken argument check (`"$"` instead of `"$#"`)

- **Where:** `zsh/zsh.d/fzf.zsh:9`
- **Evidence:**

  ```zsh
  if [[ "$" -eq 0 ]]; then
  ```

  `"$"` is a literal string, not the arg count. In zsh arithmetic context a non-numeric string evaluates to 0, so the interactive fzf branch _always_ runs, even when arguments are passed — `fzf-rm somefile` never reaches `command rm "$@"`. Note this function is also unwired (see finding 4), so nothing currently hits the bug.

- **Suggested change:** `[[ "$#" -eq 0 ]]` — or delete the function altogether per finding 4.
- **How to test:**

  ```bash
  zsh -n zsh/zsh.d/fzf.zsh # syntax still valid
  zsh -ic 'touch /tmp/x; fzf-rm /tmp/x; [ ! -f /tmp/x ] && echo PASS'
  ```

- **Risk:** None — currently unreachable dead-ish code.
- **Decision:** ✅ Approved — remove `fzf-rm` (subsumed by finding 4: the whole file goes).

### 3. Hardcoded API subscription key in `zip-code`

- **Where:** `zsh/zsh.d/functions.zsh:204-221`
- **Evidence:** Function embeds an `ocp-apim-subscription-key` for the Israel-Post API (marked `#gitleaks:allow`) plus a fixed street/house payload. Secret material committed to a dotfiles repo, loaded into every shell.
- **Suggested change:** Delete the function (one-off personal utility), or move key to an untracked env file (`~/.secrets.zsh` style) if still used.
- **How to test:**

  ```bash
  grep -rn 'ocp-apim' zsh/    # should return nothing after fix
  gitleaks detect --no-banner # no allow-listed secret needed anymore
  ```

- **Risk:** Losing the function; recreate on demand — the payload is hardcoded to one address anyway.
- **Decision:** ❌ Won't fix — key belongs to a public website's zipcode-lookup API, not personal or sensitive. Keep as-is.

---

## 🟠 High — dead code / stale wiring

### 4. Five fzf helper functions defined but never wired

- **Where:** `zsh/zsh.d/fzf.zsh` — `fzf-rm` (line 8), `fzf-man` (19), `fzf-eval` (30), `fzf-aliases-functions` (34), `fzf-git-status` (45)
- **Evidence:** Zero hits for any of them in `zle -N`, `bindkey`, or `alias` across the repo. `fzf-rm`/`fzf-man` were clearly written to shadow `rm`/`man` but nothing aliases them, so they're reachable only by typing the full function name.
- **Suggested change:** Delete, or wire up the ones you actually want (`alias rm=fzf-rm` etc. / bindkey).
- **How to test:**

  ```bash
  zsh -n zsh/zsh.d/fzf.zsh
  zsh -ic 'which fzf-man' # "not found" after deletion
  time zsh -ic exit       # startup unchanged or marginally faster
  ```

- **Risk:** None if genuinely unused; if muscle memory exists for typing them, keep + wire instead.
- **Decision:** ✅ Approved, expanded — delete `zsh/zsh.d/fzf.zsh` entirely (all five functions). Move the fzf loading it carries — `[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh` plus the `FZF_DEFAULT_OPTS` / `FZF_CTRL_T_*` / `FZF_CTRL_R_OPTS` exports — into `.zshrc`.
- **Status:** ✔ Executed 2026-07-05 — file deleted, fzf block added to `.zshrc` (own section before the zsh.d loop). Verified: `fzf-man`/`fzf-rm` unresolvable, `FZF_CTRL_R_OPTS` still set, no bindkey conflicts in `zsh.d`, `~/zsh.d` is a folded stow symlink so no dangling link.

### 5. Dead nvim lua functions

- **Where:**
  - `nvim/.config/nvim/lua/user/utils.lua:36` — `M.get_visual_selection_stay_in_visual`
  - `nvim/.config/nvim/lua/user/git.lua:239` — `M.get_toplevel` (async variant)
  - `nvim/.config/nvim/lua/user/init.lua:12` — `_G.put_text`
- **Evidence:** Full-tree grep for each name returns only the definition line. All callers of the git helper use `M.get_toplevel_sync` (6 call sites: fzf.lua, actions.lua, gh-actions.lua, conflicts.lua, two run-buffer handlers). `put_text` is a `:lua`-prompt debug helper — keep only if you use it interactively.
- **Suggested change:** Delete all three (keep `put_text` if used at the `:lua` prompt).
- **How to test:**

  ```bash
  grep -rn 'get_visual_selection_stay_in_visual\|get_toplevel\b\|put_text' nvim/.config/nvim
  cd nvim/.config/nvim && make test # utils and git both have specs
  ```

- **Risk:** Low. `utils` and `git` have spec coverage; test suite catches accidental breakage.
- **Decision:** ❌ Won't fix — keep all three. `put_text` is used interactively at the `:lua` prompt; the other two are kept for possible future use.

### 6. Old `kubedebug` superseded by `kubedebug-ng`

- **Where:** `zsh/zsh.d/kubectl.zsh:274-338` (old, ~65 lines) vs `zsh/zsh.d/kubedebug-ng.zsh` (414 lines, gum-based)
- **Evidence:** Two debug-pod launchers coexist. `completions.zsh:19` still generates completion for the **old** `kubedebug`, not `kubedebug-ng`.
- **Suggested change:** Delete the old function; update `completions.zsh:19` to reference `kubedebug-ng` (or alias `kubedebug=kubedebug-ng` for muscle memory).
- **How to test:**

  ```bash
  zsh -ic 'which kubedebug kubedebug-ng'
  # then in a live shell: kubedebug-ng against a test cluster/namespace
  ```

- **Risk:** If the old one has flags/behavior the ng version lacks, diff them before deleting.
- **Decision:** ✅ Approved — delete old `kubedebug` from `kubectl.zsh`, rename `kubedebug-ng` → `kubedebug` (function and, if desired, the `kubedebug-ng.zsh` filename). `completions.zsh:19` then points at the right name automatically; verify it generates completion for the gum-based function.

### 7. `morning-routine.sh` orphaned

- **Where:** `automations/.local/bin/morning-routine.sh` (95 lines, tracked)
- **Evidence:** `grep -rn morning-routine` across the repo returns only its own shebang-adjacent line. Only launchd plist in `automations/` is `com.mosheavni.ghnotify.plist` (drives `gh-notify.sh`). No cron, no alias, no launchd job. README documents `gh-notify`, never `morning-routine`.
- **Suggested change:** Delete, or add a plist if you meant to schedule it.
- **How to test:**

  ```bash
  launchctl list | grep -i morning                        # confirms nothing loaded
  stow -Rv automations && ls ~/.local/bin/ | grep morning # gone after fix
  ```

- **Risk:** None visible — it was never scheduled.
- **Decision:** ❌ Won't fix — false positive. Invoked by a macOS Shortcut, an external reference repo greps cannot see. Keep.

### 8. gsd-era leftovers in `ai/.claude/`

- **Where:** `ai/.claude/hooks/gsd-check-update-worker.js` and `ai/.claude/settings.json.bak` (both untracked — `ai/.claude/hooks/` is entirely gitignored; only `settings.json`, `CLAUDE.md`, `.gitignore` are tracked there)
- **Evidence:** Live `settings.json` references only `caveman-*` hooks. The `.bak` (dated May 4) references a `gsd-*` hook suite that no longer exists except this one orphaned worker file, which nothing invokes. Local-machine cruft rather than repo dead code, but it lives inside the stowed `~/.claude` tree.
- **Suggested change:** Delete both (local `rm` — no commit involved).
- **How to test:**

  ```bash
  grep -rn 'gsd-' ai/.claude/settings.json # empty — nothing references it
  # start a new claude session; hooks still function (caveman statusline etc.)
  ```

- **Risk:** None — worker is invoked by nothing in current settings.
- **Decision:** ✅ Approved — delete all gsd relics (`gsd-check-update-worker.js`, `settings.json.bak`, and anything else `gsd-*` found under `ai/.claude/`). Local `rm`, no commit involved.
- **Status:** ✔ Resolved 2026-07-05 — files already gone; `find`/`grep` for `gsd`/`*.bak` under `ai/` and `~/.claude` (symlink to it) return nothing.

### 9. Docs reference a nonexistent `cursor/` stow package

- **Where:** root `CLAUDE.md` (AI config packages section + scope table line 94) and `.cursor/rules/dotfiles-conventions.mdc:16`
- **Evidence:** Both claim `cursor/` → stows `~/AGENTS.md` and `~/.cursor/rules/agents.mdc`. No `cursor/` directory exists; those symlinks are produced by the **`ai/`** package (`ai/AGENTS.md`, `ai/.cursor/rules/agents.mdc`).
- **Suggested change:** Update both docs to attribute the symlinks to `ai/`.
- **How to test:**

  ```bash
  grep -rn 'cursor/' CLAUDE.md .cursor/rules/dotfiles-conventions.mdc | grep -v '\.cursor'
  ls -la ~/AGENTS.md # symlink target proves it comes from ai/
  ```

- **Risk:** None — documentation-only. Stale docs actively mislead Claude/Cursor sessions, so this is high despite zero runtime impact.
- **Decision:** ✅ Approved — fix both docs to attribute the symlinks to `ai/`.
- **Status:** ✔ Executed 2026-07-05 — both docs updated (merged the `cursor/` bullet into `ai/`, swapped the scope-table example to `zsh/`); verified `~/AGENTS.md → .dotfiles/ai/AGENTS.md`.

### 10. Commented-out reference to deleted `user.winbar` module

- **Where:** `nvim/.config/nvim/lua/user/options.lua:138-139` (plus minor commented options at lines 23-24, 68, 123, 140)
- **Evidence:** `lua/user/winbar.lua` does not exist; the only two `user.winbar` mentions in the tree are these comment lines. Live winbar is set by `user.navic` (navic.lua:113).
- **Suggested change:** Delete the two winbar comment lines; sweep the other commented options while there.
- **How to test:** `nvim --headless '+quitall'` starts clean; winbar still rendered by navic in a normal session.
- **Risk:** None — comments.
- **Decision:** ✅ Approved — delete the winbar comment lines.
- **Status:** ✔ Executed 2026-07-05 — `options.lua:138-139` removed; `nvim --headless '+quitall'` exits 0.

### 11. Intel-Homebrew PATH entries on Apple-Silicon machine

- **Where:** `zsh/.zshrc:25` (`/usr/local/opt/curl/bin`), `:26` (`/usr/local/opt/ruby/bin`), `:34` (`/usr/local/opt/postgresql@15/bin`)
- **Evidence:** Rest of config uses `/opt/homebrew`. On this machine the `/usr/local/opt` dirs likely don't exist — dead PATH entries scanned on every command lookup miss.
- **Suggested change:** Delete the three lines (or swap to `/opt/homebrew/opt/...` if those kegs are installed).
- **How to test:**

  ```bash
  ls /usr/local/opt/curl/bin /usr/local/opt/ruby/bin /usr/local/opt/postgresql@15/bin # confirm missing first
  zsh -ic 'which curl ruby psql'                                                      # still resolve after removal
  ```

- **Risk:** Only if any keg genuinely lives in Intel prefix — the `ls` check settles it.
- **Decision:** ✅ Approved — per PATH entry: if the keg exists under `/opt/homebrew/opt/...`, switch the line to that path; if it doesn't exist there either, delete the line.
- **Status:** ✔ Executed 2026-07-05 — curl switched to `/opt/homebrew/opt/curl/bin` (keg exists, `which curl` resolves there); ruby and postgresql@15 lines deleted (kegs absent from both prefixes; `ruby` falls back to `/usr/bin/ruby`, `psql` was already unresolvable before the change).

### 12. `set-tab-title` calls a tool that doesn't match dialog(1)

- **Where:** `zsh/zsh.d/functions.zsh:37-40`
- **Evidence:** Calls `dialog -t ... -m ... --bannertext ... --textfield ...` — flags not in standard `dialog(1)`; looks like a removed third-party tool. No other `dialog` references in the repo.
- **Suggested change:** Delete, or rewrite with the actual escape sequence (`printf '\e]0;%s\a'`) / wezterm CLI.
- **How to test:** `zsh -ic 'set-tab-title test'` — currently errors; after rewrite, tab title changes.
- **Risk:** None — currently broken anyway.
- **Decision:** ✅ Approved (revised) — initially rewritten with `printf '\e]0;%s\a'`, but `term-support.zsh` re-sets the title via a `precmd` hook before every prompt, so any manual title is overwritten immediately (the old `dialog` version had the same flaw). Function unused → deleted instead.
- **Status:** ✔ Executed 2026-07-05 — `set-tab-title` removed from `functions.zsh`; tab titles remain owned by `term-support.zsh` hooks.

---

## 🟡 Medium — duplication

### 13. `updates.sh` / `cleanup.sh` shared-logic duplication

- **Where:** `updates.sh` (218 lines) and `cleanup.sh` (267 lines)
- **Evidence:** Both define `brew_bundle_files()`, `log()`, and near-identical tap-trust `awk` blocks (`updates.sh:44-46` / `cleanup.sh:48-51`). Divergence risk: fix a bug in one, forget the other.
- **Suggested change:** Extract a small sourced lib (e.g. `scripts/lib.sh`, dot-prefixed or `.stowrc`-ignored) with `log`, `brew_bundle_files`, tap parsing; source from both.
- **How to test:**

  ```bash
  shellcheck updates.sh cleanup.sh scripts/lib.sh
  ./updates.sh # dry-run friendly sections first; same output as before extraction
  ./cleanup.sh # same list of removal candidates as before
  ```

- **Risk:** Medium — these scripts mutate installed packages. Diff their _output_ (list phases) before/after, don't just eyeball the code.
- **Decision:** ✅ Approved — extract the shared lib and source it from both scripts.

### 14. Alias duplicates and ohmyzsh shadowing

- **Where:** `zsh/zsh.d/aliases.zsh`
- **Evidence:**
  - `:45` `gst='git status'` — identical to ohmyzsh git plugin's `gst` (plugins load first, zsh.d re-defines same thing).
  - `:46` `git_current_branch=...` — shadows ohmyzsh's _function_ of the same name with an alias.
  - `:47` `gb=...` — silently replaces ohmyzsh's `gb='git branch'` with an fzf-checkout pipeline (behavior change hiding behind a plugin name).
  - `:18-19` `dotfiles`/`dot` both `cd ~/.dotfiles`; `:31-32` `lv`/`lvim` identical; `:84-85` global `Sa`/`Srt` byte-identical.
- **Suggested change:** Drop `gst`; rename the fzf checkout to something non-colliding (e.g. `gbf`) or keep the override but comment it as deliberate; keep one of each identical pair.
- **How to test:**

  ```bash
  zsh -ic 'type gst; type gb; type git_current_branch' # shows final winner + origin
  ```

- **Risk:** Muscle-memory only. The `gb` decision is preference — flag, not mandate.
- **Decision:** ✅ Approved, expanded — remove the ohmyzsh git plugin entirely (`.zsh_plugins.txt:11` `ohmyzsh/ohmyzsh path:plugins/git`) and port only the essential aliases into `aliases.zsh`: `gpom`, `gmom`, `gl`, `gp`, `gcam`, `gcmsg`, `gpsup`, plus suggested extras — `gco` (checkout), `gcb` (checkout -b), `gd` (diff), `gaa` (add --all), `gpf` (push --force-with-lease). Note: `gpsup`, `gpom`, `gmom` depend on ohmyzsh's `git_current_branch`/`git_main_branch` helper functions — port those two functions too (which also resolves the `git_current_branch` alias-shadowing item above). Then dedupe: drop the redundant `gst` question (it becomes the only definition), keep the fzf `gb` (no longer collides), keep one of each identical alias pair (`dotfiles`/`dot`, `lv`/`lvim`, `Sa`/`Srt`).

### 15. Repeated constants/lookups in zsh functions

- **Where:** `GIT_DEFAULT_ORG` default `mosheavni` in `zsh/zsh.d/functions.zsh:73` **and** `zsh/zsh.d/ghc.zsh:8`; AWS account-id lookup (`aws sts get-caller-identity | jq -r .Account`) in `functions.zsh:64` (`ecr-login`) **and** `:168` (`docker_copy_between_regions`)
- **Suggested change:** Export `GIT_DEFAULT_ORG` once (e.g. in `.zshrc` or an `env.zsh`); extract `aws_account_id()` helper.
- **How to test:** `zsh -ic 'ghc <repo>'` and `zsh -ic 'ecr-login'` behave as before.
- **Risk:** Low.
- **Decision:** ✅ Approved — export `GIT_DEFAULT_ORG` once in `.zshrc`; extract the `aws_account_id()` helper.
- **Status:** ✔ Executed 2026-07-05 — `export GIT_DEFAULT_ORG=mosheavni` added to `.zshrc`; inline defaults removed from `clone()` and `ghc()`. `aws_account_id()` added to `functions.zsh` (uses `--query Account --output text`, dropping the jq dependency) and used by both `ecr-login` and `docker_copy_between_regions`.

### 16. nvim repeated patterns

- **Where:**
  - q-to-close mapping implemented inline 4×: `lua/user/autocommands.lua:91`, `lua/user/init.lua:183`, `lua/user/input.lua:515`, `ftplugin/qf.lua`
  - `lua/user/keymaps.lua:199-218`: four near-identical copy-path closures (`<leader>cfp/cfa/cfd/cfn`) differing only in `expand()` flag + message
- **Suggested change:** Small `utils.map_q_close(buf)` helper for the first; table-driven loop for the second (same file already uses this pattern at lines 127-136 and 314-323).
- **How to test:**

  ```bash
  cd nvim/.config/nvim && make test
  # manual: open qf window / parse_cert float / input list → q closes each
  # manual: <leader>cfp/cfa/cfd/cfn each yank correct path variant (:echo @+)
  ```

- **Risk:** Low; keymaps has behavioral surface but the transforms are mechanical.

### 17. Stow-layout documentation triplicated

- **Where:** root `CLAUDE.md` (§Architecture), `.cursor/rules/dotfiles-conventions.mdc`, `README.md` — same stow-package table restated in all three.
- **Suggested change:** Pick one canonical home (CLAUDE.md, since both AI tools read it); others link to it. Note: `ai/AGENTS.md` vs `ai/.cursor/rules/agents.mdc` duplication is **by design** (both written from one remote by `sync-ai-config.sh`) — leave it.
- **How to test:** Docs-only; verify each file still parses/renders and cross-links resolve.
- **Risk:** None.

---

## 🟢 Low — perf, thin abstractions, hygiene

### 18. kubectl.nvim setup runs eagerly at startup

- **Where:** `nvim/.config/nvim/lua/user/pack/init.lua:31` — `require 'plugins.kubectl'()` sits in the eager block, before the `vim.schedule` deferred block (line 33). Enables `auto_refresh` + FileType autocmds in every session.
- **Suggested change:** Move into the deferred block, or lazy-init on first `:Kubectl` invocation — it's the only feature plugin not deferred, so eagerness may be deliberate; verify before moving.
- **How to test:**

  ```bash
  nvim --startuptime /tmp/st.log +q && grep -i kubectl /tmp/st.log # before/after delta
  # manual: :Kubectl still works after the move
  ```

- **Risk:** Low; if a keymap fires before deferred load, add a stub.

### 19. Eager terraform/aws completion registration

- **Where:** `zsh/zsh.d/completions.zsh:22` (`bashcompinit`), `:35-37` (three `complete -C terraform/terragrunt/aws_completer`)
- **Evidence:** Runs every shell start; the same file already implements a lazy `unfunction` pattern for kubectl/helm/etc. (lines 41-94).
- **Suggested change:** Convert the three to the existing lazy pattern; drop `bashcompinit` if nothing else needs it. Also `:19` lists `ab` (apachebench) in completion-generator targets — not installed/used anywhere; remove alongside the `kubedebug` fix (finding 6).
- **How to test:**

  ```bash
  time zsh -ic exit                          # startup delta
  zsh -i  →  terraform <TAB>, aws <TAB>      # completion still works on first use
  ```

- **Risk:** First-tab-press latency instead of startup cost. Fair trade.

### 20. Thin wrappers and semantic hazards

- **Where / what:**
  - `zsh/zsh.d/functions.zsh:121-123` `docker_build_push` = `docker_build --push $*`; `:108-110` `grl` = `grep -rl $* .`; `:98-100` `gitcd` = `cd $(git rev-parse --show-toplevel)`; `aliases.zsh:17` `dc='cd '`
  - `zsh/.bin/vdiff` — one-line nvim wrapper, **zero references** (`kdiff` by contrast is load-bearing: `.zshrc:88` `KUBECTL_EXTERNAL_DIFF`)
  - `aliases.zsh:26-29` — `vim`/`vi`/`v`/`sudoedit` all → `nvim`; **`sudoedit=nvim` silently drops the privileged-edit semantics** (real `sudoedit` copies to temp, edits unprivileged, writes back as root)
  - `zsh/zsh.d/functions.zsh:223-260` `matrix` — screensaver toy in startup path
- **Suggested change:** Keep wrappers you actually type (they're muscle memory, cost ≈ 0); delete `vdiff` and `matrix`; **remove the `sudoedit` alias** — that one changes behavior, not just spelling.
- **How to test:** `zsh -ic 'which vdiff'` not found; `sudoedit /etc/hosts` uses real sudoedit flow again.
- **Risk:** `sudoedit` alias removal is the only behavior change, and it restores _correct_ behavior.

### 21. diffput/diffget operatorfunc indirection

- **Where:** `nvim/.config/nvim/lua/user/keymaps.lua:164-177` — `_G.op.diffput`/`diffget` route a single ex-command through `operatorfunc` + `g@l`
- **Evidence:** Callbacks take no motion and ignore the region — the operator machinery adds nothing unless it's there to make the mapping dot-repeatable.
- **Suggested change:** If dot-repeat is the point, add a comment saying so; otherwise flatten to plain `<cmd>diffput<cr>` mappings.
- **How to test:** In a diff (`nvim -d a b`): mapping still puts/gets hunk; press `.` — if repeat worked before and matters, keep the indirection.
- **Risk:** Losing dot-repeat if that was intentional. Check before flattening.

### 22. Misc hygiene

| Item                                     | Where                                                                                            | Note                                                                                                                                                                                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Redundant `.stowrc` ignores              | `.stowrc` — `Brewfile`, `Brewfile.lock.json`, `BACKUP.md`, `snippets.xml`, `start.sh`, `.github` | Root _files_ are never stowed (start.sh stows dirs only). Harmless noise; the load-bearing ignores are `requirements.txt`, `install-skills.sh`, `sync-ai-config.sh`, `graphify-out`. Verify with `stow -nv <pkg>` before pruning. |
| Version-pinned plugin path in statusline | `ai/.claude/settings.json`                                                                       | Hard-codes `plugins/cache/caveman/caveman/ef6050c5e184/...` — hash changes on plugin update, silently breaking statusline. Point at a stable path or resolve dynamically.                                                         |
| `gg-shield-action@master`                | `.github/workflows/gitguardian.yml`                                                              | Moving ref; pin to a tag/SHA.                                                                                                                                                                                                     |
| `teams-call` stale                       | `zsh/.bin/teams-call:5-6,35`                                                                     | Hardcodes one user + `@company.com` placeholder; bound to Alt-t via `teams.zsh:12`. Fix or delete both.                                                                                                                           |
| Former-employer ECR path                 | `zsh/zsh.d/functions.zsh:171-172`                                                                | `docker_copy_between_regions` hardcodes `spotinst-production/`. Parameterize or delete.                                                                                                                                           |
| Plugin review                            | `.zsh_plugins.txt` — `agkozak/zhooks`, `peterhurford/git-it-on.zsh`                              | `zhooks` is a debugging tool loaded permanently; confirm still wanted.                                                                                                                                                            |
| Empty dir                                | `ai/.claude/agents/`                                                                             | Empty, gitignored, runtime-managed — safe to leave or remove.                                                                                                                                                                     |
| `mwatch` leftovers                       | `zsh/zsh.d/functions.zsh:48-49`                                                                  | Commented-out log lines.                                                                                                                                                                                                          |
| `kns`/`ctx` alias deps                   | `zsh/zsh.d/kubectl.zsh:176-177`                                                                  | Depend on `kubens`/`kubectx` binaries — confirm they're in Brewfile.                                                                                                                                                              |
| Personal PATH                            | `zsh/.zshrc:40-44`                                                                               | `~/Repos/moshe/devops-scripts/*` loop — existence-guarded, but confirm still relevant.                                                                                                                                            |

---

## ✅ Verified clean (skip in future audits)

- **nvim lock vs specs:** all 45 plugins in `nvim-pack-lock.json` map to live specs (SchemaStore added via `after/lsp/*.lua`; kubectl.nvim is a dev-path plugin). No orphaned plugin references.
- **Tests ↔ modules:** every `lua/tests/*_spec.lua` maps to a real module; no orphan specs.
- **run-buffer handlers:** all 12 registered in `handlers/init.lua`.
- **`github-releases.txt` vs Brewfile:** no overlap (`nektos/act` intentionally GH-release-installed via `updates.sh:128`).
- **CI workflows:** `lint.yml`, `ci.yml`, `gitguardian.yml` all wired; README badges resolve. (Only nit: the `@master` pin above, and `lint.yml` copies lint configs out of `nvim/` — coupling worth knowing, not worth changing.)

## Suggested execution order

1. **Critical trio** (1-3): examples/ + fzf typo-or-delete + zip-code key. Five minutes, real hazards.
2. **High deletions** (4-12): each independent, each testable with the commands above. One commit per finding keeps reverts trivial.
3. **Medium consolidation** (13-17): `updates.sh`/`cleanup.sh` lib extraction is the only one needing care — diff script _output_ before/after.
4. **Low** (18-22): opportunistic, alongside other edits per the surgical-changes guideline in `ai/AGENTS.md` — don't batch-refactor.

Global regression check after any zsh batch: `zsh -n` each touched file, `time zsh -ic exit` vs baseline, `pre-commit run --all-files`. After any nvim batch: `cd nvim/.config/nvim && make test` plus `nvim --headless '+quitall'`.
