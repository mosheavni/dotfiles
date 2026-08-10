# Neovim configuration architecture

A map of how this config is put together: what loads when, what lives where, and
which conventions hold the pieces together.

## 1. Overview

This config uses Neovim's **native `vim.pack`** plugin manager (`:h vim.pack`).
There is no `lazy.nvim`, no `packer`, and no plugin-spec auto-discovery — every
plugin spec file under `lua/plugins/` is `require`d explicitly, by hand, in a
deliberate order from `lua/user/pack/init.lua`.

Startup cost is managed by hand rather than by a lazy-loading framework:

- A small **eager** set of plugins is installed and set up during `init.lua`.
- Everything else is set up inside a single `vim.schedule(...)` callback, so it
  runs after the first screen is drawn.
- A second wave of *non-plugin* `user.*` modules is deferred even further,
  behind a `User DeferredPluginsLoaded` autocmd (see section 3).

Installed plugin versions are pinned in `nvim-pack-lock.json` (managed by
`vim.pack`). `<leader>z` opens `:PackFloat`, a custom update UI implemented in
`lua/user/pack/float.lua`.

## 2. Bootstrap / load order

`init.lua` is six lines and is the whole story:

```lua
vim.loader.enable()
require 'user.options'
require 'user'
require 'user.keymaps'
require 'user.pack'
require 'user.autocommands'
```

In order:

1. **`vim.loader.enable()`** — turn on the Lua module bytecode cache first, so
   every subsequent `require` benefits.
2. **`lua/user/options.lua`** — `vim.o`/`vim.g` settings, disables unused
   bundled runtime plugins and providers, and registers all custom filetypes via
   `vim.filetype.add` (including the compound `yaml.*` filetypes and the
   `is_kubernetes` buffer-detection hook).
3. **`lua/user/init.lua`** (`require 'user'`) — sets `mapleader`, applies the
   colorscheme, defines global helpers (`_G.put_text`, `_G.tmp_write`) and
   standalone user commands (`:Yaml2Json`, `:JsonPath`, `:DiffWithSaved`,
   `:DirDiff`, `:Titleize`, `:Say`, `:ParseCert`, `:Whereami`, ...), and
   registers their menu actions.
4. **`lua/user/keymaps.lua`** — global (non-buffer-local, non-plugin) mappings.
5. **`lua/user/pack/init.lua`** (`require 'user.pack'`) — the plugin loader; see
   below.
6. **`lua/user/autocommands.lua`** — all global autocommands, including the
   `DeferredPluginsLoaded` consumer described in section 3.

### Inside `lua/user/pack/init.lua`

The file does four things, in this order:

1. Registers a **`PackChanged` autocmd** *before* the first `vim.pack.add()`
   call. This is what runs post-install/update hooks: `:TSUpdate` for
   `nvim-treesitter`, `make install_jsregexp` for `LuaSnip`, and
   `require('go.install').update_all_sync()` for `go.nvim`.
2. Runs the **eager batch** synchronously:

   ```lua
   require 'plugins.treesitter'()
   require('plugins.mini').eager()
   require 'plugins.gitsigns'()
   require('plugins.functionality').eager()
   require 'plugins.kubectl'()
   ```

3. Queues the **deferred batch** in a single `vim.schedule(function() ... end)`:
   `look-and-feel`, `mini.deferred()`, `functionality.deferred()`, `git`, `lsp`,
   `fzf`, `conform`, `lint`, `blink`, `ai`, `tree`, `mini-statusline` — then
   fires `User DeferredPluginsLoaded`.
4. Requires `user.pack.float` and maps `<leader>z` to `:PackFloat`.

### Eager vs. deferred, precisely

`vim.pack.add` is called at **require time**, at the top level of each
`lua/plugins/*.lua` file — not inside the returned setup function. So requiring a
spec file *installs and adds the plugin to the runtimepath*; calling the returned
function *configures* it.

The practical consequence: `plugins/mini.lua` and `plugins/functionality.lua` are
required during the eager phase, so **all** of their plugins are installed
eagerly. Only part of their *setup* is deferred, via the separate `.eager()` /
`.deferred()` entry points. Spec files that appear only in the `vim.schedule`
block (`plugins/lsp.lua`, `plugins/fzf.lua`, ...) are both installed and
configured on the scheduled tick.

## 3. Two-phase deferred startup

The `User DeferredPluginsLoaded` autocmd is the seam between "plugins are ready"
and "everything else."

**Fired from** the end of the `vim.schedule` callback in
`lua/user/pack/init.lua`:

```lua
vim.api.nvim_exec_autocmds('User', { pattern = 'DeferredPluginsLoaded' })
```

**Consumed in** `lua/user/autocommands.lua` (augroup `FirstLoad`), whose callback
calls `.setup()` on 17 `user.*` modules:

`user.menu`, `user.projects`, `user.navic`, `user.input`, `user.search-count`,
`user.tabular-v2`, `user.number-separators`, `user.terminal`, `user.yank-ring`,
`user.run-buffer`, `user.grep`, `user.lister`, `user.figlet`, `user.open-url`,
`user.gitbrowse`, `user.easymotion`, `user.conflicts`.

### Why the ordering is safe

`require 'user.pack'` does not *run* the deferred batch — `vim.schedule` only
queues it onto the next event-loop tick. `require 'user.autocommands'` then runs
**synchronously**, on the very next line of `init.lua`, registering the
`DeferredPluginsLoaded` listener. Only once all of `init.lua` has finished does
Neovim return to the event loop and run the scheduled callback, which fires the
autocmd. So the consumer is registered *after* the producer in source order but
comfortably *before* the event is ever emitted.

### Why it exists

Purely startup performance. These 17 modules are not needed to display the first
buffer: they register commands, keymaps and autocommands for features the user
reaches for later (pickers, terminals, the action menu, conflict navigation).
Deferring their `require` keeps them — and the Lua files they pull in — off the
critical path.

The `UIEnter` autocmd in the same `FirstLoad` group prints the tail of
`startuptime.txt` when Neovim was launched with `--startuptime`, which is how
this budget gets measured.

## 4. `lua/user/*` module map

### Entry points and core

| Module | Purpose |
| --- | --- |
| `init.lua` | Leader keys, colorscheme call, `_G` helpers, standalone user commands, their menu registrations. |
| `options.lua` | `vim.o`/`vim.g` settings, provider/runtime-plugin disabling, all `vim.filetype.add` rules. |
| `keymaps.lua` | Global key mappings. |
| `autocommands.lua` | All global autocommands, including the `DeferredPluginsLoaded` consumer. |
| `utils.lua` | Shared helpers: visual-selection capture, filetype→extension/command tables, `throttle`, `read_json_file`, `load_plugin` (local `~/Repos` checkout override for `vim.pack.add`), and `for_each_client(bufnr, method, fn)` — the single place LSP clients are iterated and support-checked. |

### Plugin loading

| Module | Purpose |
| --- | --- |
| `pack/init.lua` | `PackChanged` install/update hooks, eager plugin batch, `vim.schedule` deferred batch, fires `DeferredPluginsLoaded`. |
| `pack/float.lua` | `:PackFloat` — a floating UI over `vim.pack` for reviewing and applying plugin updates, with commit-log previews. |

### Git tooling

| Module | Purpose |
| --- | --- |
| `git.lua` | Git primitives: async + sync branch/remote/tag/toplevel/default-branch queries, `owner/repo` extraction, fugitive index reloading, checkout and PR-creation helpers. |
| `gitbrowse.lua` | Build and open the web URL for the current file/line/branch/commit across GitHub, GitLab, Bitbucket, etc. |
| `conflicts.lua` | Merge-conflict tooling: marker parsing, highlighting, take-head/base/origin resolution, quickfix population, next/prev navigation. |
| `gh-actions.lua` | Build the `act` command for a GitHub Actions workflow file, writing a minimal push event so linter actions work. |

### LSP

| Module | Purpose |
| --- | --- |
| `lsp/config.lua` | Diagnostic signs/config, client capabilities, `on_attach` keymaps, `vim.lsp.enable` wiring — the real body of `plugins/lsp.lua`. |
| `lsp/actions.lua` | LSP entries for the action menu (code actions, definition, references, rename, ...). |
| `lsp/server/init.lua` | The hand-rolled **in-process LSP server** (`create_server()`, commands, config) surfaced through `lsp/user_lsp.lua`. |
| `lsp/server/actions.lua` | Custom code actions served by that server (ported from the old null-ls setup). |
| `lsp/server/hover.lua` | Custom hover providers for that server. |
| `lsp/server/shellcheck.lua` | ShellCheck `# shellcheck disable=` code actions (adapted from none-ls-shellcheck). |
| `navic.lua` | Breadcrumb context tracking driven by LSP `documentSymbol`; caches per buffer and renders into `vim.o.winbar` (not the statusline). |
| `navic_core.lua` | Pure symbol-tree parsing, context diffing and rendering used by `navic.lua` (kept separate so it is unit-testable). |

### Linting and formatting

| Module | Purpose |
| --- | --- |
| `lint/init.lua` | The whole nvim-lint framework: a single declarative linter table (filetype linters vs. global event-driven linters, root markers, enable flags), `linters_by_ft` derivation, commands, and lint autocommands. |
| `lint/brew_bundle.lua` | Custom nvim-lint linter that turns `brew bundle check --verbose` output into buffer diagnostics. |
| `jenkins-validate.lua` | Validate the current Jenkinsfile against a Jenkins server's converter endpoint and publish diagnostics. |

### Running buffers and terminals

| Module | Purpose |
| --- | --- |
| `run-buffer/init.lua` | `<F3>` orchestration: resolve a command, send it to the per-file terminal (or Wezterm tab), interrupting a previous run. |
| `run-buffer/buffer.lua` | Resolve the current buffer's path and filetype, prompting to save / starting an LS for unnamed buffers. |
| `run-buffer/command.lua` | Build a `RunResult` by looking up a filetype handler, falling back to a shebang/default command. |
| `run-buffer/handlers/init.lua` | Handler registry (`register`/`get`) keyed by filetype. |
| `run-buffer/handlers/*.lua` | One handler per filetype: `brewfile`, `groovy` (Jenkinsfile validate), `helm`, `html`, `lua` (hot reload), `make`, `markdown` (mdserve preview), `package_json`, `requirements`, `terraform`/terragrunt, `yaml`, `yaml_ghaction`, `yaml_precommit`. |
| `run-buffer/types.lua` | `---@meta` type definitions for `RunContext`, `RunResult`, `RunHandler`. |
| `terminal.lua` | Managed terminal buffers: one registry for `:Terminal` shells and per-file run terminals, reusing a single bottom split. |
| `wezterm.lua` | Thin synchronous wrapper around `wezterm cli` (list/spawn/activate/kill panes, send text), no-op when Wezterm isn't on `PATH`. |

### Editing utilities

| Module | Purpose |
| --- | --- |
| `tabular-v2.lua` | Live tabular buffers for command output: column alignment, sorting, filtering, timed refresh. |
| `number-separators.lua` | Virtual-text comma separators on long numbers. |
| `yank-ring.lua` | Minimal yank ring over registers 1-9; `<C-n>`/`<C-m>` cycle the last put. |
| `easymotion.lua` | Two-character jump-to-location with overlay labels. |
| `search-count.lua` | End-of-line virtual text showing `current/total` search matches while `hlsearch` is on. |
| `open-url.lua` | Open the URL (or `user/repo` shorthand) under the cursor, with GitHub URL construction. |
| `figlet.lua` | Turn the current line into figlet ASCII art, with a font picker. |
| `ftplugin.lua` | Shared `ftplugin` logic — currently `shell.setup()` (shebang insertion, `is_bash` flag, `J`-joins-continuations), used by `ftplugin/{sh,bash,zsh}.lua`. |
| `terraform-docs.lua` | `:OpenDoc` — resolve the Terraform resource/data block under the cursor and open its registry documentation. |

### UI, pickers, and navigation

| Module | Purpose |
| --- | --- |
| `float.lua` | Generic reusable floating-window primitive (buffer/window caching, refresh/close/toggle, sizing helpers). Used by `hints`, `pack/float`, `:ParseCert`, and others. |
| `hints.lua` | Build a keymap-hints float from a `{key, desc}` list. |
| `input.lua` | A `vim.ui.input` replacement: floating prompt with history and completion. |
| `menu.lua` | The central action menu — collects action tables (from `user.actions` plus `add_actions()` registrations) and presents them. |
| `actions.lua` | The large static table of general-purpose menu actions (search/replace, folds, macros, clipboard, terraform, view, ...). |
| `lister.lua` | Quickfix filtering: `:Qgrep` / `:Qfilter` (replaces vim-lister). |
| `grep.lua` | `<C-f>` project search into the quickfix list (ripgrep, literal/regex). |
| `projects.lua` | Project picker (via `user.wezterm`): activates the project's existing Wezterm tab, or spawns a new one running `nvim` in that directory. |
| `colorscheme.lua` | Colorscheme setup plus a shared `palette` table of resolved Nvim default-theme colors, reused by the statusline. |
| `kubectl.lua` | Extra kubectl.nvim resource views and actions (ALB console links, ServiceAccount secrets, StorageClass PVs, ArgoCD, ExternalSecrets, cert-manager), with AWS SSO prompting. |

### Present but disabled

| Module | Status |
| --- | --- |
| `user-dir.lua` | Present in the tree but **not active**. Both of its call sites are commented out: `require('user.user-dir').setup()` in `lua/user/init.lua` (line 12) and `require('user.user-dir').setup_icons()` in `lua/user/autocommands.lua` (line 65). It implements icons and ex-command prefill mappings for Neovim's native `nvim.dir` listing. |

## 5. `lua/plugins/*` inventory

Each file installs its plugins with `vim.pack.add` (or `user.utils.load_plugin`)
at the top level, and **returns a function** that performs setup. The loader
calls it as `require 'plugins.X'()`. The two exceptions are `mini.lua` and
`functionality.lua`, which return a table `M` with `.eager()` and `.deferred()`
so their setup can straddle both phases.

| File | Plugins installed | Setup responsibility |
| --- | --- | --- |
| `treesitter.lua` | `nvim-treesitter`, `nvim-treesitter-textobjects`, `nvim-treesitter-context`, `ts-comments.nvim` | Parser install, highlight/textobject setup, sticky context. Eager. |
| `mini.lua` | `mini.notify`, `mini.indentscope`, `mini.cursorword`, `mini.hipatterns`, `mini.splitjoin`, `mini.surround`, `mini.ai`, `mini.operators` | `.eager()` sets up `mini.notify` (+ dismiss/history keymaps); `.deferred()` sets up the rest. |
| `gitsigns.lua` | `gitsigns.nvim` | `on_attach` hunk keymaps (stage/reset/preview/blame, `]c`/`[c`), Git menu actions. Eager. |
| `functionality.lua` | `smart-splits.nvim`, `nvim-pqf`, `vim-easy-align`, `switch.vim`, `vim-swap`, `vim-matchup`, `nvim-autopairs`, `linediff.vim`, plus `search-replace.nvim` via `load_plugin` | `.eager()` wires smart-splits resize/move keymaps; `.deferred()` sets up the rest and the LSP file-rename notifications (via `utils.for_each_client`). |
| `kubectl.lua` | `kubectl.nvim` (2.x, via `load_plugin`, with `blink.download`) | kubectl.nvim setup; hooks in the extra views from `user.kubectl`; Kubernetes menu actions. Eager. |
| `look-and-feel.lua` | `nvim-web-devicons`, `render-markdown.nvim`, `nvim-bqf` | Icon, markdown-rendering and better-quickfix setup. Deferred. |
| `git.lua` | `plenary.nvim`, `vim-fugitive`, `diffview.nvim` | Fugitive/diffview keymaps and commands; registers the Git action menu from `user.git`. Deferred. |
| `lsp.lua` | `guihua.lua`, `nvim-lspconfig`, `fidget.nvim`, `lazydev.nvim`, `wezterm-types`, `go.nvim` | Delegates the LSP setup to `user.lsp.config.setup()`; adds YAML menu actions. Deferred. |
| `fzf.lua` | `fzf-lua` | fzf-lua setup and all picker keymaps, including the `<F4>` git-branch flow that calls into `user.git`. Deferred. |
| `conform.lua` | `conform.nvim` | Formatter table, format-on-save, and a `<leader>lp` info mapping that lists the buffer's formatters — LSP ones resolved via `utils.for_each_client`. Deferred. |
| `lint.lua` | `nvim-lint` | Five lines: installs the plugin and calls `require('user.lint').setup()`. Deferred. |
| `blink.lua` | `blink.download`, `blink.cmp` (1.x), `LuaSnip`, `friendly-snippets` | Completion sources, keymaps, snippet integration. Deferred. |
| `ai.lua` | `copilot.lua` | Copilot setup (pinned node binary) and suggestion keymaps. Deferred. |
| `tree.lua` | `nvim-tree.lua` | nvim-tree setup, `on_attach` keymaps (including sort cycling and the `Z` extract mapping), and a `user.hints` help float. Deferred. |
| `mini-statusline.lua` | `mini.statusline` | Custom statusline sections (mode, git + diff, diagnostics, filename, quickfix search label, YAML schema, run terminals, LSP client names, filetype, progress, location), colored from `user.colorscheme.palette`. Deferred. |

## 6. Cross-module convention

**`lua/plugins/*` files are thin wrappers. Real logic lives in `lua/user/*`.**

A plugin spec file should only: install the plugin, translate the plugin's
configuration surface, and wire keymaps. Anything with behaviour worth reading,
reusing, or unit-testing gets its own `lua/user/` module and is called from the
spec. The most explicit examples:

- `plugins/lsp.lua` → `user.lsp.config.setup()`
- `plugins/lint.lua` → `user.lint.setup()` (the file is five lines)
- `plugins/git.lua`, `plugins/fzf.lua` → `user.git`
- `plugins/kubectl.lua` → `user.kubectl`

The payoff is that `lua/user/*` is plugin-agnostic and directly testable: the
Plenary specs in `lua/tests/*_spec.lua` require `user.*` modules without loading
the plugins those modules wrap (a few stub what they must — see
`lua/tests/notify_stub.lua`).

Three narrower conventions fall out of the same idea:

- **Shared helpers over local copies.** `user.utils.for_each_client(bufnr,
  method, fn)` is the one place LSP clients are enumerated and support-checked
  (`plugins/conform.lua`, and both file-rename notifications in
  `plugins/functionality.lua`).
  `user.utils.load_plugin` is the one place a local `~/Repos/<name>` checkout may
  shadow a remote `vim.pack` install (`plugins/functionality.lua`,
  `plugins/kubectl.lua`).
- **Menu registration is decentralized.** Any module can contribute to the action
  menu with `require('user.menu').add_actions('<Prefix>', { ... })` — done by
  `plugins/git.lua`, `plugins/gitsigns.lua`, `plugins/kubectl.lua`,
  `plugins/lsp.lua`, `plugins/functionality.lua`, and `lua/user/init.lua`.
- **Shared UI primitives.** Floats go through `user.float`; keymap help screens
  go through `user.hints`; statusline colors come from
  `user.colorscheme.palette`.

## Appendix: other runtime directories

| Path | Role |
| --- | --- |
| `ftplugin/*.lua` | Per-filetype buffer-local settings, loaded by Neovim's normal `ftplugin` mechanism. Shell filetypes delegate to `user.ftplugin`. |
| `after/ftplugin/*.lua` | Filetype overrides that must win over plugin `ftplugin` files. |
| `after/lsp/*.lua` | Per-server LSP overrides in the Neovim 0.11+ `vim.lsp.config` convention (`lua_ls`, `yamlls`, `jsonls`, `pyright`, `helm_ls`, `terraformls`, `terragrunt_ls`). |
| `lsp/user_lsp.lua` | Config entry for the hand-rolled in-process LSP server implemented in `lua/user/lsp/server/`. |
| `snippets/*.json` | VSCode-format snippets, loaded explicitly by `plugins/blink.lua` via `require('luasnip.loaders.from_vscode').lazy_load { paths = '~/.config/nvim/snippets' }` (alongside a bare `lazy_load()` that picks up `friendly-snippets`). |
| `lua/dotfiles/health.lua` | `:checkhealth dotfiles` — verifies external tools (linters, formatters, language servers) are on `PATH`. |
| `lua/tests/*_spec.lua` | Plenary busted specs for `lua/user/*` modules. Run with `make test-nvim` from the repository root. |
| `scripts/minimal_init.vim` | Minimal init used by the test harness. |
| `nvim-pack-lock.json` | `vim.pack` lockfile pinning installed plugin revisions. |
