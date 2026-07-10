# Copilot Instructions for macOS Dotfiles

This file guides Copilot sessions working in this repository. For comprehensive documentation, see [`CLAUDE.md`](../CLAUDE.md).

## Quick Reference

**Build, test, and lint** all from repository root:

```bash
make test                           # Run all tests (nvim + zsh)
make test-nvim                      # Neovim tests only (runs make prepare first)
make test-zsh                       # Zsh tests only
shellspec zsh/spec/ <name >_spec.sh # Single Zsh spec file
pre-commit run --all-files          # All linters
```

**Deployment:**

```bash
./start.sh          # Stow all packages to home directory
stow -Rv <package>  # Stow a single package (e.g., stow -Rv nvim)
```

## Repository Architecture

### Stow Package Structure

This is a macOS dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory (e.g., `nvim`, `zsh`, `git`, `ai`) is a "stow package" that gets symlinked to the home directory when deployed.

Internal file structure mirrors target paths:

- `nvim/.config/nvim/` → `~/.config/nvim/`
- `zsh/.zshrc` → `~/.zshrc`
- `git/.gitconfig` → `~/.gitconfig`

Files to exclude from stowing (listed in `.stowrc`): Brewfile, Makefile, README files, `.github`, specs, generated output.

### Where to Place New Files

| Location                                  | Purpose                                        |
| ----------------------------------------- | ---------------------------------------------- |
| Inside stow package (e.g., `zsh/`, `ai/`) | Config/code that syncs to home directory       |
| `.cursor/rules/*.mdc`                     | Cursor rules scoped to this repository only    |
| Repository root (`.`)                     | Repository-local tooling config; never stowed  |
| `.gitignored + .stowrc exclude`           | Generated/local output (e.g., `graphify-out/`) |

## Language-Specific Conventions

### Lua (Neovim Configuration)

**Files:** `nvim/.config/nvim/lua/user/` and `nvim/.config/nvim/lua/plugins/`

**Style:**

- 2 spaces indentation
- 160 character line width
- Single quotes preferred
- No call parentheses (stylua enforces this)
- Config: `stylua.toml` at repository root

**Linting:**

- `stylua`: Run from repository root with `--search-parent-directories` flag
- `selene` (`selene.toml` in `nvim/` directory): Run `cd nvim` first to avoid spurious errors
- `luacheck` (`.luacheckrc` in `nvim/`): Finds config from any cwd

**Testing:**

- Tests live in `nvim/.config/nvim/lua/tests/`
- Naming: `<module>_spec.lua` corresponds to `lua/user/<module>.lua`
- Framework: Plenary's busted test format
- Assertions: `assert.are.same()`, `assert.is_true()`, `assert.is_nil()`, `assert.is_not_nil()`
- Example: `describe()`, `it()`, `before_each()`, `after_each()`
- **Before changing Lua code:** Check if `lua/tests/<module>_spec.lua` exists and update/add tests

### Shell (Zsh)

**Files:** `zsh/` (entry point: `.zshrc`)

**Components:**

- Plugin manager: [antidote](https://antidote.sh/) (plugins in `.zsh_plugins.txt`)
- Modular config: `zsh/zsh.d/*.zsh` files
- Custom scripts: `zsh/.bin/`

**Testing:**

- Specs live in `zsh/spec/*_spec.sh` (excluded from stowing)
- Framework: [shellspec](https://shellspec.info/) DSL (configured in `.shellspec`)
- **Before changing functions:** Update or add matching spec in `zsh/spec/`
- Mock external commands (aws, ssh, etc.) as shell functions inside specs
- Interactive functions (fzf/gum prompts) are not unit-tested

**Linting:**

- shellcheck (pre-commit hook and CI)
- Config: `.shellcheckrc`

### Neovim Init Process

**Entry point:** `nvim/.config/nvim/init.lua`

**Load order:**

1. `user/init.lua` - Global functions and leader key setup
2. `user/options.lua` - Vim options
3. `user/keymaps.lua` - Key mappings
4. `user/lazy.lua` - Plugin manager (lazy.nvim) setup
5. `user/autocommands.lua` - Autocommands

**Plugin specs:** Auto-discovered from `lua/plugins/` directory

**Custom modules:** Utilities (utils.lua), Git helpers, LSP config, feature modules all in `lua/user/`

### YAML with Compound Filetypes

When adding `yaml.something` via `vim.filetype.add` in `options.lua`, follow the checklist in `.cursor/rules/yaml-compound-filetype.mdc`:

- Add yamlls filetype config
- Update run-buffer settings
- Add lint keys
- Update conform config
- Check hardcoded `yaml` references
- Write/update tests

## CI/CD & Linting

**Linters run via:**

- `pre-commit`: `pre-commit run --all-files` (includes shellspec)
- **CI:** GitHub Actions workflows in `.github/workflows/`
  - `ci.yml`: Runs zsh tests (Ubuntu) and Neovim tests (nightly)
  - `lint.yml`: Runs super-linter (luacheck for Lua, shellcheck for shell)

**Super-linter:** Disabled for: Biome, JSCpd, Editorconfig, Python Ruff, shfmt (zsh compatibility)

## Development Workflow

**When making changes:**

1. **Lua/Neovim changes:**
   - Check existing tests in `lua/tests/`
   - Update or add tests before changing functionality
   - Run `make test-nvim` to verify

2. **Zsh changes:**
   - Check existing specs in `zsh/spec/`
   - Update or add specs before changing functionality
   - Run `shellspec zsh/spec/<name>_spec.sh` or `make test-zsh`

3. **All changes:**
   - Run `pre-commit run --all-files` before committing
   - Format Lua: `stylua --search-parent-directories .`

**File editing guidelines:** Match existing code style. Only touch what's necessary. Keep changes focused on the user's request.

## MCP Servers

This repository includes MCP server configurations for enhanced Copilot capabilities:

- **Git** - Repository inspection: status, commits, diffs, branches
- **GitHub** - PR/issue management, workflows, repository operations
- **Filesystem** - File operations and directory exploration

These are configured in `ai/.config/mcphub/servers.json` and `ai/.cursor/mcp.json`. The GitHub server requires `$GITHUB_TOKEN` environment variable with appropriate scopes.

## Key Files

- `CLAUDE.md` - Full architectural documentation
- `README.md` - Setup and usage guide
- `Makefile` - Build, test, and prep commands
- `.stowrc` - Stow exclusion rules
- `.shellspec` - Zsh test configuration
- `.pre-commit-config.yaml` - Pre-commit hooks (shellspec + linters)
- `ai/.config/mcphub/servers.json` - MCP server configurations for Claude
- `ai/.cursor/mcp.json` - MCP server configurations for Cursor
