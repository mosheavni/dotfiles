# CLAUDE.md

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package that mirrors `~` (`nvim/.config/nvim/` → `~/.config/nvim/`, `zsh/.zshrc` → `~/.zshrc`). `.stowrc` excludes non-stowable files.

## Commands

```bash
./start.sh          # Stow all packages
stow -Rv <package>  # Stow one package
make test-nvim      # Neovim tests (Plenary busted, from the repository root)
pre-commit run --all-files
```

## Lua tests

When changing Lua in `lua/user/`, update or add `nvim/.config/nvim/lua/tests/<module>_spec.lua` and run `make test-nvim`.

## Linting gotchas

- `stylua` doesn't search parent directories: run it from the repository root or pass `--search-parent-directories`.
- `selene` reads `selene.toml` from the cwd only: `cd nvim` first.
- CI uses super-linter (luacheck only for Lua). Shell: `shellcheck`.

## Where new files go

| Where to put it                            | When                                          |
| ------------------------------------------ | --------------------------------------------- |
| Inside a stow package (e.g. `zsh/`, `ai/`) | Config you want on every machine (global)     |
| Repository root with a leading dot         | Repository-local tooling config, never stowed |
| Gitignored + excluded in `.stowrc`         | Generated/local output                        |

## AI config (`ai/` → `~/.claude/`, `~/AGENTS.md`)

- This repo is public: company-specific detail never goes in a tracked file (use gitignored `ai/.claude/rules/*.local.md`, `servers.local.json`, or the live `settings.json`).
- `ai/sync-ai-config.sh` merges tracked shared files into untracked local ones:
  - `ai/.claude/settings.shared.json` → `~/.claude/settings.json` (gitignored, holds company entries). Objects merge recursively, shared scalars win, arrays are unioned. Entries removed from the shared file must also be removed from the live file by hand.
  - `ai/.config/mcphub/servers.json` + gitignored `servers.local.json` → MCP servers in `~/.claude.json` and Copilot.
  - Fresh machine: run it, then re-add the company entries.
- Skills from external repos are installed by `ai/install-skills.sh` (`npx skills`); add new ones there.

## Neovim

- No `lazy.nvim`. Plugins are declared with `vim.pack.add` in `lua/plugins/*.lua` and `require`d **explicitly** from `lua/user/pack/init.lua`; a new plugin file does nothing until added there. Versions are pinned in `nvim-pack-lock.json`.
- `lua/.../ARCHITECTURE.md` is the per-module reference.
- Adding a `yaml.*` filetype: follow `nvim/.config/nvim/YAML_FILETYPES.md`.

## Zsh

antidote plugins in `.zsh_plugins.txt`; modular configs in `zsh/zsh.d/*.zsh`; scripts in `zsh/.bin/`.
