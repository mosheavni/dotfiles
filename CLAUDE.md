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

### Neovim Tests

```bash
cd nvim/.config/nvim
make prepare # Clone plenary.nvim (required once)
make test    # Run all tests
```

Tests are in `nvim/.config/nvim/lua/tests/` and use Plenary's busted test framework.

## Lua Testing Infrastructure

**When making any changes to Lua code in `lua/user/`, always:**

1. Check if there's an existing test file (`lua/tests/<module>_spec.lua`) that needs updating
2. Add tests for new functionality
3. Run `make test` to verify nothing breaks

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

- Lua: `luacheck` with `.luacheckrc` config, `selene` with `nvim/selene.toml`
- Lua formatting: `stylua` with `stylua.toml` config
- Shell: `shellcheck`
- Pre-commit: `pre-commit run --all-files`
- CI uses [super-linter](https://github.com/super-linter/super-linter)

## Architecture

### Stow Package Structure

Each directory at the root is a stow package. The internal structure mirrors where files should land relative to `~`:

- `nvim/.config/nvim/` → `~/.config/nvim/`
- `zsh/.zshrc` → `~/.zshrc`
- `git/.gitconfig` → `~/.gitconfig`

The `.stowrc` file excludes non-stowable files (Brewfile, readme, etc.) from deployment.

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

### Zsh Configuration

- Main config: `zsh/.zshrc`
- Plugin manager: [antidote](https://antidote.sh/) with plugins defined in `.zsh_plugins.txt`
- Modular configs: `zsh/zsh.d/*.zsh` (aliases, functions, kubectl, fzf, etc.)
- Custom scripts: `zsh/.bin/`

### Code Style

- Lua: 2 spaces, 160 char line width, single quotes preferred, no call parentheses (see `stylua.toml`)
- Groovy/Python: 4 spaces
- Unix line endings throughout
