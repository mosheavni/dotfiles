<!-- markdownlint-disable MD013 -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory (nvim, Zsh, Git, etc.) is a "stow package" that gets symlinked to the home directory when deployed.

## Commands

### Deployment

```bash
./start.sh          # Stow all packages to home directory
stow -Rv <package>  # Stow a single package (e.g., stow -Rv nvim)
```

### Tests

All test commands run from the repository root via the root `Makefile`
(stow-ignored in `.stowrc`):

```bash
make test      # Run Neovim tests (runs `make prepare` first — clones plenary.nvim)
make test-nvim # Same as make test
```

#### Neovim

Tests are in `nvim/.config/nvim/lua/tests/` and use Plenary's busted test framework.

## Lua Testing Infrastructure

**When making any changes to Lua code in `lua/user/`, always:**

1. Check if there's an existing test file (`lua/tests/<module>_spec.lua`) that needs updating
2. Add tests for new functionality
3. Run `make test-nvim` (from the repository root) to verify nothing breaks

### Test File Conventions

- Test files live in `nvim/.config/nvim/lua/tests/`
- Naming: `<module>_spec.lua` corresponds to `lua/user/<module>.lua`
- Uses Plenary busted syntax: `describe()`, `it()`, `before_each()`, `after_each()`
- Common assertions: `assert.are.same()`, `assert.is_true()`, `assert.is_nil()`, `assert.is_not_nil()`

### Example Test Structure

```lua
local module = require 'user.module'
local eq = assert.are.same

describe('user.module', function()
  describe('function_name', function()
    it('does something expected', function()
      eq(module.function_name 'input', 'expected_output')
    end)
  end)
end)
```

### Existing Test Coverage

Tests exist for: `utils`, `gitbrowse`, `git`, `hints`, `number-separators`, `open-url`, `present`, `tabular-v2`

### Linting

- Lua formatting: `stylua` with root `stylua.toml`. stylua does NOT search parent
  directories, so run it from the repository root or pass `--search-parent-directories`;
  otherwise it falls back to defaults and reports bogus diffs.
- Lua lint (`selene`): config is `nvim/selene.toml` with std `nvim/vim.toml`. selene
  reads `selene.toml` from the cwd only, so `cd nvim` first or you get spurious
  `'vim' is not defined` errors.
- Lua lint (`luacheck`): resolves `.luacheckrc` relative to each file, so `nvim/.luacheckrc`
  is found from any cwd — no special handling.
- Shell: `shellcheck`
- Pre-commit: `pre-commit run --all-files`
- CI uses [super-linter](https://github.com/super-linter/super-linter) (luacheck only for Lua)

## Architecture

### Stow Package Structure

Each directory at the root is a stow package. The internal structure mirrors where files should land relative to `~`:

- `nvim/.config/nvim/` → `~/.config/nvim/`
- `zsh/.zshrc` → `~/.zshrc`
- `git/.gitconfig` → `~/.gitconfig`

The `.stowrc` file excludes non-stowable files (Brewfile, readme, etc.) from deployment.

**When creating new files, decide scope first:**

| Where to put it                                      | When                                          |
| ---------------------------------------------------- | --------------------------------------------- |
| Inside a stow package (e.g. `zsh/`, `ai/`)           | Config you want on every machine (global)     |
| `.cursor/rules/*.mdc` at repository root             | Cursor rules scoped to this repository only   |
| Repository root with a leading dot (e.g. `.cursor/`) | Repository-local tooling config, never stowed |
| Gitignored + excluded in `.stowrc`                   | Generated/local output (e.g. `graphify-out/`) |

**AI config packages:**

- `ai/` → stows `~/.claude/` (Claude config, skills, MCP servers), `~/AGENTS.md` (Claude + agents), and `~/.cursor/rules/agents.mdc` (Cursor global rules)
- `.cursor/rules/` (repository root, NOT a stow package) → Cursor rules that only apply when working in this repository

### Neovim Configuration

Entry point: `nvim/.config/nvim/init.lua`

Load order:

1. `user/init.lua` - Global functions and leader key setup
2. `user/options.lua` - Vim options
3. `user/keymaps.lua` - Key mappings
4. `user/lazy.lua` - Plugin manager (lazy.nvim) setup
5. `user/autocommands.lua` - Autocommands

Plugin specs are in `lua/plugins/` - lazy.nvim auto-discovers all files in this directory.

Custom modules in `lua/user/` include utilities (utils.lua), Git helpers, LSP configuration, and various feature modules.

### Compound YAML filetypes (`yaml.*`)

When adding `yaml.something` via `vim.filetype.add` in `options.lua`, follow the full checklist in `.cursor/rules/yaml-compound-filetype.mdc` (yamlls filetypes, run-buffer, lint keys, conform, hardcoded `yaml` checks, tests).

### Zsh Configuration

- Main config: `zsh/.zshrc`
- Plugin manager: [antidote](https://antidote.sh/) with plugins defined in `.zsh_plugins.txt`
- Modular configs: `zsh/zsh.d/*.zsh` (aliases, functions, kubectl, fzf, etc.)
- Custom scripts: `zsh/.bin/`

### Code Style

- Lua: 2 spaces, 160 char line width, single quotes preferred, no call parentheses (see `stylua.toml`)
- Groovy/Python: 4 spaces
- Unix line endings throughout
