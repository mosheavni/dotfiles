# Neovim Config Review — Findings & Fix Plan

> Generated 2026-06-10 by Claude Code (model: claude-fable-5) after full review of `nvim/.config/nvim`.
> Verified against Neovim **nightly** runtime docs at
> `~/.asdf/installs/neovim/nightly/share/nvim/runtime/doc/` and runtime plugin sources.
>
> **For AI agents:** read this file before touching the nvim config. Each finding has
> a status checkbox — mark `[x]` when fixed (with commit ref if possible). When fixing
> Lua under `lua/user/`, follow CLAUDE.md: update/add tests in `lua/tests/`, run
> `cd nvim/.config/nvim && make test` — but ONLY when the change touches a spec-covered
> module; otherwise verify with targeted headless nvim runs.
> Style: stylua (2 spaces, single quotes, no call parens).
>
> **Fix documentation convention (user requirement):** every fixed section MUST include
> a **Manual test** block the user can run interactively to see the change with their
> own eyes, formatted as:
> - shell commands to set up + open nvim (not headless)
> - what to check inside nvim (e.g. `:set ft?`)
> - `Status before:` one line describing old broken behavior
> - `Status after:` one line describing new correct behavior

## Architecture summary (context for later sessions)

- Plugin manager: **native `vim.pack`** (nightly). Entry: `init.lua` → `user/init.lua`,
  `user/options.lua`, `user/keymaps.lua`, `user/pack/init.lua`, `user/autocommands.lua`.
- `user/pack/init.lua` loads plugin spec files from `lua/plugins/`. Each spec calls
  `vim.pack.add` at module top-level, returns either a function (deferred setup) or a
  table with `.eager()` / `.deferred()`.
- Eager (startup): look-and-feel (colorscheme), mini (notify), gitsigns, functionality
  (smart-splits), kubectl.
- Deferred (`vim.schedule`): everything else — git, treesitter, lsp, fzf, conform, lint,
  blink, ai, tree, mini-statusline. Fires `User DeferredPluginsLoaded` when done.
- Custom modules in `lua/user/` (~9.6k lines). Largest: tabular-v2 (1130), pack/float (880),
  lsp/server/actions (660), keymaps (628), input (574).
- Tests: Plenary busted, `lua/tests/*_spec.lua`, `make test`.
- LSP: native `vim.lsp.config`/`vim.lsp.enable` + nvim-lspconfig for definitions.
- PackChanged autocmd in `user/pack/init.lua:2` runs build hooks (TSUpdate, LuaSnip
  jsregexp, markdown-preview yarn, mcp-hub npm, go.nvim update).

---

## CRITICAL / CORRECTNESS BUGS

### B1. Helm filetype detection always matches `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/options.lua:205-212`
- **Code:**
  ```lua
  ['.*/templates/.*%.yaml'] = {
    function()
      if vim.fn.search('{{.+}}', 'nw') then
        return 'helm'
      end
    end,
  ```
- **Problem:** `vim.fn.search()` returns `0` (a number) when no match. In Lua, `0` is
  truthy → the condition is **always true**. Every `*/templates/*.yaml` file is detected
  as `helm` even with zero Go-template syntax (breaks yamlls/schema validation for plain
  k8s manifests in `templates/` dirs).
- **Fix applied:** `if vim.fn.search([[{{.\+}}]], 'nw') ~= 0 then`.
- **Second bug found during fix:** original regex `{{.+}}` never matched anything — in
  vim magic mode `+` is a LITERAL plus sign (quantifier is `\+`). Old code only "worked"
  because the truthy-`0` bug forced helm for everything. Fixed pattern: `{{.\+}}`.
- **Verified:** headless nvim — `templates/plain.yaml` (kind/apiVersion only) → `yaml`;
  `templates/tpl.yaml` (with `{{ .Release.Name }}`) → `helm`. `make test` 39/39 pass.
- **Manual test:**
  ```sh
  mkdir -p /tmp/ftest/templates
  printf 'kind: Deployment\napiVersion: apps/v1\n' > /tmp/ftest/templates/plain.yaml
  printf 'kind: Deployment\nname: {{ .Release.Name }}\n' > /tmp/ftest/templates/tpl.yaml
  nvim /tmp/ftest/templates/plain.yaml   # then :set ft?  → expect filetype=yaml
  nvim /tmp/ftest/templates/tpl.yaml     # then :set ft?  → expect filetype=helm
  ```
  - **Status before:** both files showed `filetype=helm` — anything under a `templates/`
    dir ending in `.yaml` became helm, even plain k8s manifests (broke yamlls schemas).
  - **Status after:** `plain.yaml` → `filetype=yaml`; `tpl.yaml` (contains `{{ ... }}`)
    → `filetype=helm`.
- **Bonus (still open, fold into B2):** callback receives `(path, bufnr)` — prefer
  `vim.filetype.getlines(bufnr, ...)` scan over `vim.fn.search` (operates on "current"
  buffer; see B2 rationale).

### B2. Catch-all `['.*']` filetype pattern — no priority, wrong buffer access `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/options.lua:216-225`
- **Code:** pattern `['.*']` loops `vim.fn.getline(i)` for i=1..20 looking for `^kind:` /
  `^apiVersion:` → yaml.
- **Problems:**
  1. Catch-all patterns must carry negative priority per `:h vim.filetype.add()` docs
     example (`{ priority = -math.huge }`), otherwise it competes with specific patterns
     and runs for *every* opened file.
  2. `vim.fn.getline` reads the **current** buffer. Filetype detection can run for a
     non-current buffer (`vim.filetype.match { buf = ... }`, `:edit` from scripts,
     bufadd flows). Callback signature is `function(path, bufnr)` — use
     `vim.filetype.getlines(bufnr, i)` or `nvim_buf_get_lines`.
- **Fix applied:**
  - catch-all now `{ function(_, bufnr) ... nvim_buf_get_lines(bufnr, 0, 20, false) ... end, { priority = -math.huge } }`
  - helm callback (B1 bonus) also converted to `(path, bufnr)` form with
    `nvim_buf_get_lines(bufnr, 0, -1, false)` + Lua pattern `line:find '{{.+}}'`
    (in Lua patterns `+` IS a quantifier — unlike vim magic; `.-` was rejected since it
    matches empty `{{}}`). No more current-buffer dependency.
  - Note: `vim.filetype.getlines` is NOT public API (checked nightly lua.txt) — use
    `nvim_buf_get_lines`.
- **Verified headless:** `templates/plain.yaml`→yaml, `templates/tpl.yaml`→helm,
  extensionless k8s manifest→yaml, `x.lua`→lua (catch-all loses), `.kube/config`→yaml.
- **Gotcha (test infra):** nvim caps `+cmd`/`-c` args at 10 — verification matrix must
  use a single `+luafile` script, not per-file `+e`/`+lua` pairs.
- **Manual test:**
  ```sh
  # 1. catch-all still detects extensionless k8s manifests (now from the right buffer):
  printf 'kind: Deployment\napiVersion: apps/v1\n' > /tmp/ftest/manifest-noext
  nvim /tmp/ftest/manifest-noext         # :set ft?  → expect filetype=yaml

  # 2. works via stdin too (StdinReadPost runs detection; buffer has no filename,
  #    only the catch-all matches):
  echo 'kind: Deployment' | nvim -       # :set ft?  → expect filetype=yaml

  # 3. catch-all loses to every specific pattern (negative priority):
  printf 'print("hi")\n' > /tmp/ftest/x.lua
  nvim /tmp/ftest/x.lua                  # :set ft?  → expect filetype=lua

  # 4. helm callback no longer depends on the *current* buffer — detection from a
  #    different active buffer still correct:
  nvim /tmp/ftest/x.lua
  #    inside nvim:
  #    :lua local b = vim.fn.bufadd('/tmp/ftest/templates/tpl.yaml'); vim.fn.bufload(b); print(vim.filetype.match { buf = b })
  #    → expect: helm   (before the fix this inspected x.lua, the current buffer)
  ```
  - **Status before:** catch-all ran for every file with default priority and read lines
    from whatever buffer was *current* (`vim.fn.getline`) — `vim.filetype.match { buf }`
    from another buffer gave wrong answers; helm check had the same wrong-buffer flaw.
  - **Status after:** both callbacks read the buffer being detected (`bufnr` arg);
    catch-all demoted with `priority = -math.huge`; detection correct regardless of
    which buffer is current (case 4 returns `helm`).

### B3. Deferred-setup race: initial buffer misses FileType-driven features `[x]` FIXED 2026-06-10

- **Files:** `nvim/.config/nvim/lua/user/pack/init.lua:37-53` (the `vim.schedule` block),
  `lua/plugins/treesitter.lua:10-44`, `lua/plugins/lint.lua` (autocmd on
  BufReadPost/BufWritePost/InsertLeave/TextChanged), `lua/plugins/functionality.lua:104-129`
  (switch.vim FileType autocmds), `lua/plugins/mini.lua` (miniindentscope_disable FileType/TermOpen).
- **Problem:** Startup order (`:h startup`): init.lua sourced → first file(s) edited
  (**BufReadPost + FileType fire here**) → VimEnter → main loop → `vim.schedule` callbacks.
  So all autocmds registered inside the deferred block are created *after* the initial
  buffer's FileType/BufReadPost already fired. Consequences for `nvim somefile.lua`:
  - no treesitter highlight/folds/indentexpr on the first buffer
  - nvim-lint doesn't lint it until next write/InsertLeave
  - switch.vim buffer definitions, miniindentscope disables missed
  - **LSP is NOT affected**: `vim.lsp.enable()` "Activates LSP for current and future
    buffers" (verified in nightly `lsp.txt`).
- **Fix applied** (`user/pack/init.lua`): moved `require 'plugins.treesitter'()` from
  the deferred `vim.schedule` block to the **eager** section. The FileType autocmd now
  exists before the first buffer loads.
- **History / rejected alternative:** first attempt replayed
  `nvim_exec_autocmds('FileType', { buffer = buf, modeline = false })` for loaded
  buffers at the end of the deferred block. Worked (and `event.match` was verified to
  be the *filetype*, not the buffer name), but user rejected as ugly hack → replaced
  with eager load. Keep in mind if eager cost ever matters again.
- **Why eager-autocmd-only wasn't enough:** `vim.treesitter.start` needs parser +
  queries on the rtp; nvim-treesitter's `setup { install_dir = ... }` is what puts the
  install dir on the rtp. Autocmd eager + plugin deferred = pcall fails silently for
  the first buffer, same symptom. So the whole spec (pack.add + setup + context/
  ts-comments/autotag) went eager.
- **Measured cost:** `--- NVIM STARTED ---` 37ms → ~49ms. Breakdown: ~2ms actual
  treesitter module requires; remainder is first-buffer parse/highlight/ftplugin work
  that previously ran *after* the startuptime clock stopped — moved earlier, not added.
- **Residual gaps (minor, still open):** other FileType-driven setup still deferred —
  switch.vim gitrebase/markdown `b:switch_custom_definitions` and mini.indentscope
  disables miss the startup buffer (matters for `git rebase -i` flows). nvim-lint never
  lints the startup buffer until first write/InsertLeave (its trigger is BufReadPost,
  also deferred) — fold into P1 lint redesign. These autocmds are plugin-independent
  one-liners; can be registered eagerly if it ever annoys.
- **Verified headless:** open `templates/plain.yaml`, wait 1s →
  `ft=yaml ts_highlight=true foldexpr=v:lua.vim.lsp.foldexpr()` — treesitter active on
  the startup buffer without `:e`; LSP fold upgrade also confirmed working.
- **Manual test:**
  ```sh
  printf 'kind: Deployment\napiVersion: apps/v1\nmetadata:\n  name: x\n' > /tmp/ftest/plain.yaml
  nvim /tmp/ftest/plain.yaml
  # look at the buffer immediately — no :e needed
  # optional hard proof inside nvim:
  #   :lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)
  #   → true
  ```
  - **Status before:** file opened with plain (regex/no) highlighting; treesitter
    highlight only appeared after `:e` re-fired FileType. Same gap: no lint on open,
    no switch.vim/mini.indentscope ft setup for the first buffer.
  - **Status after:** treesitter highlight active the moment the file opens (within the
    deferred-load tick, ~a few ms); `:e` no longer needed.

### B4. Two competing yank-rings `[ ]`

- **Files:** `nvim/.config/nvim/lua/user/autocommands.lua:121-133` (custom register
  shifter on TextYankPost/TextPutPost) **and** `lua/plugins/functionality.lua:58-65`
  (yanky.nvim with `sync_with_numbered_registers = true`).
- **Problem:** Both manipulate numbered registers. Custom autocmd shifts 0→9 on every
  yank *and put*; yanky also syncs its ring to numbered registers. Result: double
  shifting, ring corruption, puts polluting registers. Also the custom shifter runs even
  for yanks yanky already recorded.
- **Fix:** delete the custom autocmd block (yanky's ring + sqlite storage supersedes it).
  If keeping the custom one instead, set `sync_with_numbered_registers = false` — but
  pick ONE.

### B5. LSP document-highlight detach handler race `[ ]`

- **File:** `nvim/.config/nvim/lua/user/lsp/config.lua:139-158`
- **Problems:**
  1. `nvim_create_augroup('lsp-document-highlight-detach', { clear = true })` runs inside
     **every** LspAttach → wipes detach handlers registered for previously attached
     buffers. With >1 buffer attached, only the last buffer has a working detach handler.
  2. The LspDetach autocmd has no `buffer =` scope → fires for ANY client detach in any
     buffer, and calls `vim.lsp.buf.clear_references()` which operates on the *current*
     buffer — clears highlights in an unrelated buffer.
  3. CursorHold/CursorMoved highlight autocmds (line 141) are registered once per
     *attaching client*; with 2+ clients supporting documentHighlight on one buffer,
     duplicate handlers accumulate (group has `clear = false`, buffer-scoped but
     re-entered per client).
- **Fix:** mirror the keymap guard:
  ```lua
  if client:supports_method('textDocument/documentHighlight', bufnr)
      and not vim.b[bufnr].lsp_dochl_configured then
    vim.b[bufnr].lsp_dochl_configured = true
    local hl_group = vim.api.nvim_create_augroup('lsp-document-highlight', { clear = false })
    -- CursorHold/CursorMoved autocmds as today (buffer = bufnr, group = hl_group)
    vim.api.nvim_create_autocmd('LspDetach', {
      group = hl_group,
      buffer = bufnr,
      callback = function(ev)
        if #vim.lsp.get_clients({ bufnr = ev.buf, method = 'textDocument/documentHighlight' }) <= 1 then
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = hl_group, buffer = ev.buf }
          vim.b[ev.buf].lsp_dochl_configured = nil
        end
      end,
    })
  end
  ```

### B6. Broken / dead `vim.g.loaded_*` disable guards `[ ]`

- **File:** `nvim/.config/nvim/lua/user/options.lua:6-28`
- Verified against nightly `runtime/plugin/` contents
  (`editorconfig.lua gzip.vim man.lua matchit.vim matchparen.lua net.lua netrwPlugin.vim
  osc52.lua rplugin.vim shada.lua spellfile.lua tarPlugin.vim tutor.vim zipPlugin.vim`):

| Flag set in options.lua | Verdict |
|---|---|
| `loaded_rplugin` | **WRONG NAME** — real guard `g:loaded_remote_plugins`. rplugin.vim currently still loads. |
| `loaded_tutor` | **WRONG NAME** — real guard `g:loaded_tutor_mode_plugin`. |
| `loaded_shada` | **NO-OP** — guard is `g:loaded_shada_plugin`, and that plugin only handles *editing* `.shada` files (BufReadCmd etc.), not shada persistence. Safe to delete flag. |
| `loaded_2html_plugin` | dead — tohtml plugin no longer ships |
| `loaded_getscript`, `loaded_getscriptPlugin` | dead |
| `loaded_logipat` | dead |
| `loaded_rrhelper` | dead |
| `loaded_vimball`, `loaded_vimballPlugin` | dead |
| `loaded_netrwFileHandlers`, `loaded_netrwSettings` | dead — only `loaded_netrw` + `loaded_netrwPlugin` checked (both already set) |
| `loaded_tar` | dead — guard is `loaded_tarPlugin` (already set) |
| `loaded_zip` | dead — guard is `loaded_zipPlugin` (already set) |
| `loaded_gzip`, `loaded_matchit`, `loaded_matchparen`, `loaded_netrw`, `loaded_netrwPlugin`, `loaded_spellfile_plugin`, `loaded_tarPlugin`, `loaded_zipPlugin` | correct, keep |

- **Fix:** replace block with only the working set; add `loaded_remote_plugins = 1`,
  `loaded_tutor_mode_plugin = 1` if those disables are desired. Candidates to also
  consider: `loaded_man`, `loaded_nvim_net_plugin`, `editorconfig` (`vim.g.editorconfig = false`)
  — only if genuinely unused (`vim.net` IS used by `:Whereami`, so do NOT disable net.lua... actually net.lua only defines `:Network`-style cmds; `vim.net` lua module works regardless. Still, leave it).
- **Note:** `loaded_matchparen` set twice — options.lua:12 and functionality.lua:45
  (deferred — too late there, harmless duplicate; remove the deferred one).

### B7. Operator-func helpers broken for visual / multiline `[ ]`

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua`
  - `_G.op.surround_with_interpolation` (line 41), `_G.op.base64_encode/decode` (lines 317-330), visual maps at 331-334.
- **Problems:**
  1. Guard `if motion == nil or motion == 'line' then` re-arms opfunc. But when invoked
     as operatorfunc from a **linewise** context (`V` selection → `g@`, or `g@g@`),
     callback legitimately receives `'line'` → instead of transforming, it re-arms and
     feedkeys `g@`, leaving Neovim waiting for a motion. Linewise usage broken.
  2. Charwise path reads only the first line: `nvim_buf_get_text(...)[1]` — multiline
     charwise selections silently truncated; `finish[2] + 1` can also be out of range
     on multibyte tail.
  3. `vim.fn.feedkeys 'g@'` → should be `vim.api.nvim_feedkeys('g@', 'n', false)` (or
     `vim.fn.feedkeys('g@', 'n')`) to bypass mappings; and for dot-repeat correctness
     prefer `expr = true` maps returning `'g@'` / `'g@_'`.
- **Fix:** distinguish "arming call" from "execution call" by argument: operatorfunc is
  always called with `'char'|'line'|'block'`; arming call from the keymap should pass
  nothing. Use the standard pattern:
  ```lua
  map('n', '<leader>64', function()
    vim.o.operatorfunc = 'v:lua.op.base64_encode'
    return 'g@'
  end, { expr = true })
  map('x', '<leader>64', function()
    vim.o.operatorfunc = 'v:lua.op.base64_encode'
    return 'g@'
  end, { expr = true })  -- g@ in visual applies operator to selection directly
  ```
  and make `b64()` join all lines from `nvim_buf_get_text` instead of `[1]`.

### B8. `filter_yank` appends to register e forever `[ ]`

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:282`
- `vim.fn.setreg('E', ...)` — uppercase register name **appends** (`:h setreg()`).
  Every "Yank all..." invocation grows register `e` with stale content.
- **Fix:** `vim.fn.setreg('e', ..., 'l')` (lowercase) unless append genuinely intended.

### B9. `<leader>bh` (delete hidden buffers) aborts on modified buffer `[ ]`

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:339-348`
- `nvim_buf_delete(buf, {})` throws on modified buffers / some special buffers → loop
  dies mid-iteration, count misleading.
- **Fix:** skip `vim.bo[buf].modified`, wrap `pcall(vim.api.nvim_buf_delete, buf, {})`,
  count only successes.

### B10. `cii` (change indentation) crashes/nils options on cancel `[ ]`

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:409-416`
- Cancel (`<Esc>`) → `indent_size = nil` → `tonumber(nil)` → nil → assigns nil to
  `shiftwidth/softtabstop/tabstop` (resets local values unexpectedly). Non-numeric input
  same path.
- **Fix:** `local n = tonumber(indent_size); if not n then return end`.

### B11. `:Rename` sends `workspace/willRenameFiles` AFTER the rename `[ ]`

- **File:** `nvim/.config/nvim/lua/plugins/functionality.lua:137-165`
- LSP spec: `willRenameFiles` is a request sent **before** the file operation so the
  server can compute edits against the old URI; `didRenameFiles` after. Current code:
  `vim.fn.rename` → `saveas` → `notify_lsp_rename` (which does will+did together).
  Servers that resolve the old file (import updates) may return empty/wrong edits.
- **Fix:** split `notify_lsp_rename` into `will` (request_sync + apply edits) called
  before `vim.fn.rename`, and `did` (notify) after `saveas`. Also `request_sync` second
  param: pass bufnr where required (current signature
  `client:request_sync(method, params, timeout_ms, bufnr)` — they pass 1000 as timeout, fine).

### B12. `tmp_write` temp-file cleanup usually skipped `[ ]`

- **File:** `nvim/.config/nvim/lua/user/init.lua:41-48`
- `nvim_create_autocmd('VimLeavePre', { buffer = 0, ... })` — buffer-local autocmd for a
  global event only fires when that buffer is **current** at exit. Temp files leak in
  most sessions (mitigated only by OS tempdir cleanup).
- **Fix:** global autocmd capturing `tmp` in closure (no `buffer` key); or collect paths
  in a module-level list with a single VimLeavePre handler.

### B13. Duplicate `<C-h/j/k/l>` window maps `[ ]`

- **Files:** `nvim/.config/nvim/lua/user/keymaps.lua:98-101` (plain `<C-w>h` style) then
  `lua/plugins/functionality.lua:33-36` overwrites with smart-splits versions (eager, runs after).
- **Fix:** remove keymaps.lua versions; smart-splits is the intended behavior (works
  across wezterm panes).

### B14. `:Whereami` passes unsupported `verbose` opt `[ ]`

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:386-404`
- Nightly `vim.net.request` opts (lua.txt:4393): `body`, `headers`, `outbuf`, `outpath`,
  `retry`. No `verbose`. Signature is `request({method}, {url}, {opts}, {on_response})`
  with method optional — current 3-arg call form is fine.
- **Fix:** drop `verbose = true`. Also guard `vim.json.decode` with pcall (network body
  may be error HTML).

### B15. Dead plugin spec file `[ ]`

- **File:** `nvim/.config/nvim/lua/plugins/databases.lua`
- Old **lazy.nvim** spec format (`{ 'tpope/vim-dadbod', enabled = false, cmd = ..., init = ... }`),
  never `require`d by `user/pack/init.lua`. Pure dead code since the vim.pack migration.
- **Fix:** delete, or port to vim.pack + deferred function if dadbod still wanted
  (note `enabled = false` — it was already off under lazy.nvim).

---

## RACE CONDITIONS (summary index)

- B3 — deferred FileType/BufReadPost autocmds vs initial buffer (treesitter, lint, switch, mini).
- B5 — LspAttach/LspDetach augroup clearing + non-buffer-scoped detach.
- B12 — buffer-local VimLeavePre.
- Minor: `lua/plugins/lint.lua` autocmd callback reads `vim.bo` / buffer 0 / `nvim_buf_get_name(0)`
  instead of `args.buf` — wrong buffer if an async event lands while another buffer has
  focus. Use `vim.bo[args.buf]`, `nvim_buf_get_name(args.buf)`, and pass bufnr to try_lint where possible. `[ ]`
- Minor: `user/lsp/config.lua:185` statusline `vim.b[bufnr].attached_lsp` set on attach,
  never updated on LspDetach → stale statusline after `:lsp stop`. `[ ]`

---

## PERFORMANCE

### P1. nvim-lint runs on every `TextChanged`, no debounce `[ ]`

- **File:** `nvim/.config/nvim/lua/plugins/lint.lua`
- Each normal-mode text change spawns all ft linters **plus codespell** (every buffer).
  npm-groovy-lint / selene / ruff are not cheap. Recommendations:
  - drop `TextChanged` from the event list, or add a per-buffer debounce
    (`vim.uv.new_timer`, 300–500ms, `timer:stop(); timer:start(...)` pattern);
  - run codespell only on BufReadPost/BufWritePost;
  - `lint._global_linter_names` (line set near top) is written but never read — delete;
  - writing to `lint._disabled_linters` pokes a private-looking field on the plugin
    module — works, but keep own local table instead.

### P2. `lazyredraw` left permanently on `[ ]`

- **File:** `nvim/.config/nvim/lua/user/options.lua:118`
- `:h 'lazyredraw'`: intended for temporary use inside scripts; known to cause stale/
  flickery UI with notify/statusline/extui plugins. Remove.

### P3. Redundant option noise (defaults in Neovim) `[ ]`

- **File:** `nvim/.config/nvim/lua/user/options.lua`
- Already defaults, deletable: `hlsearch`, `incsearch`, `autoread`, `hidden`, `wildmenu`,
  `smarttab`, `autoindent`, `encoding` (utf-8 always; option is a no-op stub),
  `termguicolors` (auto-detected since 0.10), `showcmd`, `equalalways`, `visualbell`
  (preference, but consider `belloff=all` default already silences). `mouse` default is
  `nvi`; keep `a` only if cmdline-mode mouse wanted.
- `vim.o.numberwidth = 4` comment says "set to 2" — default is already 4; line + comment
  both pointless.

### P4. `backupdir` missing trailing `//` `[ ]`

- **File:** `nvim/.config/nvim/lua/user/options.lua:122`
- Without `//`, backup filenames don't encode full path → same-named files from
  different dirs overwrite each other's backups.
- **Fix:** `vim.o.backupdir = vim.fn.stdpath 'state' .. '/backup//'` and ensure dir
  exists: `vim.fn.mkdir(vim.fn.stdpath 'state' .. '/backup', 'p')`.

### P5. Conform markdown chain `[ ]`

- **File:** `nvim/.config/nvim/lua/plugins/conform.lua`
- `markdown = { 'prettier', 'cbfmt', 'injected', 'markdownlint' }` — four sequential
  formatters on every save (note: plain `prettier`, not `prettierd` like everything
  else — intentional? prettierd would be faster). Consider trimming or making some
  on-demand only.

---

## POLISH / MODERNIZATION

### M1. `CleanTitle()` vimscript → Lua `[ ]`

- `options.lua:35-40`. Replace `vim.cmd[[function! CleanTitle()...]]` with:
  ```lua
  function _G.clean_title()
    return '💻 nvim: ' .. (vim.fn.getcwd():gsub(vim.env.HOME .. '/Repos/', ''):gsub(vim.env.HOME .. '/', ''))
  end
  vim.o.titlestring = '%{%v:lua.clean_title()%}'
  ```

### M2. `country_os_to_emoji` manual UTF-8 encoder `[ ]`

- `user/utils.lua:60-85`. 25 lines of manual encoding → `vim.fn.nr2char(code_point, 1)`
  per char, concat. Has test (`utils_spec.lua`) — update expectations stay identical.

### M3. gitsigns deprecated API `[ ]`

- `plugins/gitsigns.lua`: `gs.next_hunk()`/`gs.prev_hunk()` deprecated → `gs.nav_hunk('next'|'prev')`.
  `toggle_deleted` still exists but check current README on next update.

### M4. bigfile.nvim archived `[ ]`

- `plugins/functionality.lua:14`. LunarVim org archived the repo. Options: keep (frozen,
  works), or replace with `snacks.nvim` bigfile module, or ~20-line hand-rolled
  BufReadPre file-size check that disables TS/LSP/inline features.

### M5. Diagnostics config gated behind first LspAttach `[ ]`

- `user/lsp/config.lua:161-182`. nvim-lint publishes diagnostics independent of LSP —
  before the first LspAttach, signs/virtual-text/float styling is default-ugly.
  Move `vim.diagnostic.config { ... }` straight into `M.setup()`; delete
  `vim.g.diagnostics_configured` gate.

### M6. `vim.lsp.semantic_tokens.enable(true)` per attach `[ ]`

- `user/lsp/config.lua:118-120`. Semantic tokens are on by default when server supports;
  this call is global (not per-buffer) and redundant. Delete the block.

### M7. `<c-m>` ≡ `<CR>` without extended-keys terminal `[ ]`

- `plugins/functionality.lua:69` maps `<c-m>` (YankyCycleBackward). Works in wezterm
  (kitty keyboard protocol); over bare ssh/tmux without extended-keys, `<c-m>` IS Enter
  → collides with `<CR>` nohlsearch map (`keymaps.lua:164`). Conscious tradeoff —
  documented here so nobody "fixes" the wrong one. Consider `<c-S-n>` or leader-based alt.

### M8. Shell-executable autocmd bit math `[ ]`

- `autocommands.lua:194-218`. `fileinfo.mode - 32768` assumes regular-file bit; use
  `bit.band(fileinfo.mode, 0x49)` (any exec bit) check instead, or
  `vim.uv.fs_access(filename, 'X')`. Works today; brittle. Also `vim.notify` fires
  before chmod succeeds — move after.

### M9. `next_shell_name` collisions `[ ]`

- `user/terminal.lua:76-84`. Names derived from live count — close "Terminal 1", open
  new → two "Terminal 2"-era duplicates possible. Use monotonically increasing counter.

### M10. `lua/plugins/kubectl.lua` / `ai.lua` / `tree.lua` / `mini-statusline.lua` —
not deep-reviewed this pass `[ ]`

- Skimmed only. Worth a follow-up pass with same lens (deferred FileType races, deprecated
  APIs). Also `user/input.lua` (574 lines), `user/tabular-v2.lua` (1130), `user/pack/float.lua` (880)
  reviewed superficially.

---

## VERIFIED-OK (do not "fix")

- `vim.hl.hl_op { higroup = 'IncSearch', timeout = 200 }` — **valid nightly API**
  (lua.txt:2940), replaces `vim.hl.on_yank`.
- `vim.npcall` — valid (vim.F.npcall is the deprecated one).
- `TextPutPost` — real nightly event (autocmd.txt:1278).
- `vim.treesitter.select 'parent'` — real nightly API (treesitter.txt:1163).
- `pumborder`, `winborder`, `foldinner` fillchar — all real nightly options.
- `vim.net.request(url, opts, cb)` 3-arg form — valid (method optional).
- `vim.lsp.enable` retroactive attach — "Activates LSP for current and future buffers".
- qf `<CR>`: global `<CR>` nohlsearch map ends with raw `<CR>` (noremap) → builtin qf
  jump still works. Not a bug.
- Terminal registry (`user/terminal.lua`) liveness via `pcall(vim.fn.jobpid)` — good
  pattern, keep.
- Conform changedtick-diff notify (format_on_save/format_after_save pair) — clever, keep.
- lint per-linter root-marker cwd (selene.toml/.luacheckrc) — keep.
- PackChanged build hooks pattern — correct (registered before first `vim.pack.add`).

---

## SUGGESTED FIX BATCHES

1. **Batch 1 — one-liners, zero risk:** B1, B8, B9, B10, B13, B14, M6, P2, P4.
2. **Batch 2 — races:** B3 (FileType replay), B5 (augroup restructure), B12, lint
   `args.buf` fix.
3. **Batch 3 — behavior changes (need user confirmation):** B4 (delete custom yank ring),
   B7 (operator rewrite), B11 (Rename order), B2 (filetype callback).
4. **Batch 4 — cleanup:** B6 (guards), B15 (delete databases.lua), P3 (default options),
   M1, M2, M3, M5.

After each batch: `cd nvim/.config/nvim && make test`, then manual smoke:
`nvim foo.lua` (TS highlight on first buffer — validates B3), `:checkhealth vim.lsp`,
yank/put register sanity (B4).
