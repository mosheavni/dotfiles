<!-- markdownlint-disable MD013 -->

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
>
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
  printf 'kind: Deployment\napiVersion: apps/v1\n' >/tmp/ftest/templates/plain.yaml
  printf 'kind: Deployment\nname: {{ .Release.Name }}\n' >/tmp/ftest/templates/tpl.yaml
  nvim /tmp/ftest/templates/plain.yaml # then :set ft?  → expect filetype=yaml
  nvim /tmp/ftest/templates/tpl.yaml   # then :set ft?  → expect filetype=helm
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
     and runs for _every_ opened file.
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
  printf 'kind: Deployment\napiVersion: apps/v1\n' >/tmp/ftest/manifest-noext
  nvim /tmp/ftest/manifest-noext # :set ft?  → expect filetype=yaml

  # 2. works via stdin too (StdinReadPost runs detection; buffer has no filename,
  #    only the catch-all matches):
  echo 'kind: Deployment' | nvim - # :set ft?  → expect filetype=yaml

  # 3. catch-all loses to every specific pattern (negative priority):
  printf 'print("hi")\n' >/tmp/ftest/x.lua
  nvim /tmp/ftest/x.lua # :set ft?  → expect filetype=lua

  # 4. helm callback no longer depends on the *current* buffer — detection from a
  #    different active buffer still correct:
  nvim /tmp/ftest/x.lua
  #    inside nvim:
  #    :lua local b = vim.fn.bufadd('/tmp/ftest/templates/tpl.yaml'); vim.fn.bufload(b); print(vim.filetype.match { buf = b })
  #    → expect: helm   (before the fix this inspected x.lua, the current buffer)
  ```

  - **Status before:** catch-all ran for every file with default priority and read lines
    from whatever buffer was _current_ (`vim.fn.getline`) — `vim.filetype.match { buf }`
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
  So all autocmds registered inside the deferred block are created _after_ the initial
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
  be the _filetype_, not the buffer name), but user rejected as ugly hack → replaced
  with eager load. Keep in mind if eager cost ever matters again.
- **Why eager-autocmd-only wasn't enough:** `vim.treesitter.start` needs parser +
  queries on the rtp; nvim-treesitter's `setup { install_dir = ... }` is what puts the
  install dir on the rtp. Autocmd eager + plugin deferred = pcall fails silently for
  the first buffer, same symptom. So the whole spec (pack.add + setup + context/
  ts-comments/autotag) went eager.
- **Measured cost:** `--- NVIM STARTED ---` 37ms → ~49ms. Breakdown: ~2ms actual
  treesitter module requires; remainder is first-buffer parse/highlight/ftplugin work
  that previously ran _after_ the startuptime clock stopped — moved earlier, not added.
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
  printf 'kind: Deployment\napiVersion: apps/v1\nmetadata:\n  name: x\n' >/tmp/ftest/plain.yaml
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

### B4. Two competing yank-rings `[x]` FIXED 2026-06-10

- **Files:** `nvim/.config/nvim/lua/user/autocommands.lua:121-133` (custom register
  shifter on TextYankPost/TextPutPost) **and** `lua/plugins/functionality.lua:58-65`
  (yanky.nvim with `sync_with_numbered_registers = true`).
- **Problem:** Both manipulate numbered registers. Custom autocmd shifts 0→9 on every
  yank _and put_; yanky also syncs its ring to numbered registers. Result: double
  shifting, ring corruption, puts polluting registers. Also the custom shifter runs even
  for yanks yanky already recorded.
- **Fix applied (direction changed by user):** first pass deleted the custom autocmd and
  kept yanky. User then asked the opposite — **remove yanky.nvim entirely** (and its
  sqlite.lua dependency, used by nothing else) and replace with a minimal plugin-free
  ring. Implemented as new module **`lua/user/yank-ring.lua`** (~100 lines), setup
  called from `keymaps.lua`:
  - `TextYankPost` (only `operator == 'y'` AND unnamed register): shifts registers 1→9
    via `getreginfo`/`setreg` dicts (preserves regtype). Explicit-register yanks (`"ay`,
    `cp`→`+`) and deletes do NOT shift.
  - `TextPutPost`: records `{ idx, buf, changedtick, regtype }`. regname `''`/`0` → idx 1,
    `1-9` → that idx, anything else clears state.
  - `<C-n>` / `<C-m>` → `M.cycle(-1 / 1)` (newer / older). Cycle = single
    ``normal! `[v`]"NP`` (vmode matches regtype: v/V/ctrl-V). Key insights:
    - changedtick guard ⇒ `` `[ ``/`` `] `` marks still frame the last put — no stored
      coordinates needed, multibyte-safe for free;
    - `v_P` (visual-mode P) replaces the selection **without touching any register**;
    - that P fires `TextPutPost` with `regname = N` ⇒ state re-records itself — repeated
      cycling needs no extra bookkeeping;
    - after cycling, unnamed register synced to shown entry so plain `p` repeats it.
  - `<leader>y` → `:registers 0123456789` (was YankyRingHistory).
  - Removed from `plugins/functionality.lua`: yanky + sqlite pack entries, setup block,
    p/P Plug maps (builtin p/P restored), menu actions.
- **Tests:** new `lua/tests/yank-ring_spec.lua` (8 cases: shift, explicit-reg skip,
  delete skip, cycle older/newer, registers untouched while cycling, unnamed sync,
  stale-state no-ops, charwise). Full suite green.
- **Disk cleanup pending:** `:lua vim.pack.del { 'yanky.nvim', 'sqlite.lua' }` to remove
  installed plugin dirs + lockfile entries.
- **Manual test:**

  ```sh
  nvim # empty buffer, type three lines: aaa / bbb / ccc (esc)
  # gg yy  j yy  j yy   (three linewise yanks), then:
  :reg 0 1 2 3
  # → 0=ccc  1=ccc  2=bbb  3=aaa
  # G p     → puts ccc below
  # <C-m>   → line becomes bbb (previous yank)
  # <C-m>   → line becomes aaa (older still)
  # <C-n>   → back to bbb (newer)
  # :reg 1 2 3 → STILL ccc/bbb/aaa — cycling never mutates the ring
  # p       → puts bbb again (unnamed synced to shown entry)
  # <leader>y → :registers view of the ring
  ```

  - **Status before:** yanky.nvim + sqlite.lua + custom autocmd double-shifting
    registers; puts also shifted; ring stored in sqlite database.
  - **Status after:** zero plugins, registers 0-9 ARE the ring, `<C-n>`/`<C-m>` cycle
    the last put in place, puts never shift, cycling never mutates registers.

### B5. LSP document-highlight detach handler race `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/lsp/config.lua:139-166`
- **Problems (as found):**
  1. `nvim_create_augroup('lsp-document-highlight-detach', { clear = true })` ran inside
     **every** LspAttach → wiped detach handlers registered for previously attached
     buffers. With >1 buffer attached, only the last buffer had a working detach handler.
  2. The LspDetach autocmd had no `buffer =` scope → fired for ANY client detach in any
     buffer, and called `vim.lsp.buf.clear_references()` which operates on the _current_
     buffer — cleared highlights in an unrelated buffer.
  3. CursorHold/CursorMoved highlight autocmds were registered once per _attaching
     client_; with 2+ clients supporting documentHighlight on one buffer, duplicate
     handlers accumulated (group has `clear = false`, buffer-scoped but re-entered per
     client).
- **Fix applied:**
  - Per-buffer once-guard `vim.b[bufnr].lsp_dochl_configured` (mirrors the keymap guard)
    → no duplicate CursorHold/CursorMoved/LspDetach handlers when multiple clients attach.
  - LspDetach handler moved into the same `lsp-document-highlight` augroup,
    **buffer-scoped** (`buffer = bufnr`) — the separate `lsp-document-highlight-detach`
    augroup is gone entirely.
  - Teardown only when the _last_ documentHighlight-capable client detaches:
    `#vim.lsp.get_clients { bufnr = ev.buf, method = 'textDocument/documentHighlight' } <= 1`.
    LspDetach fires _just before_ the client detaches (`:h LspDetach`), so the detaching
    client is still counted — `<= 1` means "no capable client will remain".
    (`method` filter verified in nightly `runtime/lua/vim/lsp.lua` get_clients.)
  - `vim.lsp.util.buf_clear_references(ev.buf)` instead of `vim.lsp.buf.clear_references()`
    — detach can fire while a _different_ buffer is current (`:bdelete` on hidden buffer,
    `vim.lsp.stop_client`), so target the detaching buffer explicitly.
  - Guard reset (`vim.b[ev.buf].lsp_dochl_configured = nil`) on teardown so a later
    re-attach re-registers cleanly.
- **Manual test:**
  1. `cd ~/.dotfiles/nvim/.config/nvim && nvim lua/user/utils.lua` — wait for lua_ls attach
     (statusline shows it).
  2. `:edit lua/user/git.lua` — wait for attach again.
  3. `:autocmd lsp-document-highlight` → should list CursorHold/CursorMoved/**LspDetach**
     entries for BOTH buffers (`<buffer=N>` scoped), exactly one set per buffer.
  4. `:autocmd lsp-document-highlight-detach` → `E367: No such group` (old global group
     no longer created).
  5. Hold cursor on a symbol until references highlight, then
     `:lua vim.lsp.stop_client(vim.lsp.get_clients())` → highlights clear in the buffer,
     and `:autocmd lsp-document-highlight` shows no entries for it;
     `:echo b:lsp_dochl_configured` → E121 (guard reset).
- **Status before:** with 2+ LSP buffers open, only the last-attached buffer had a detach
  handler (earlier ones leaked highlight autocmds on detach); any client detaching
  anywhere cleared reference highlights in whatever buffer was current; multi-client
  buffers stacked duplicate CursorHold highlight handlers.
- **Status after:** each buffer has exactly one set of highlight autocmds + its own
  buffer-scoped detach handler; teardown happens only when the last capable client
  leaves, targets the right buffer, and re-attach works again.

### B6. Broken / dead `vim.g.loaded_*` disable guards `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/options.lua:5-22`
- **IMPORTANT — original analysis was too narrow.** First pass only checked
  `runtime/plugin/`. User correctly pointed out guards also live in
  `runtime/autoload/` and `runtime/pack/dist/opt/`. Always grep the **entire**
  runtime tree when verifying guard names. Whole-tree verdicts:

| Flag                                                                                                                                                                                             | Verdict (whole runtime tree)                                                                                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loaded_rplugin`                                                                                                                                                                                 | **WRONG NAME** — real guard `g:loaded_remote_plugins` (plugin/rplugin.vim). Replaced.                                                                                                                      |
| `loaded_tutor`                                                                                                                                                                                   | **WRONG NAME** — real guard `g:loaded_tutor_mode_plugin` (plugin/tutor.vim). Replaced.                                                                                                                     |
| `loaded_shada`                                                                                                                                                                                   | **WRONG NAME** — TWO real guards: `g:loaded_shada_plugin` (plugin/shada.lua) + `g:loaded_shada_autoload` (autoload/shada.vim). Affects _editing_ `.shada` files only, not persistence. Replaced with both. |
| `loaded_2html_plugin`                                                                                                                                                                            | **REAL** — guards `pack/dist/opt/nvim.tohtml/plugin/tohtml.lua` (opt pack, loads only on `:packadd nvim.tohtml`). Kept.                                                                                    |
| `loaded_zip`                                                                                                                                                                                     | **REAL** — guards `autoload/zip.vim` (belt-and-braces with `loaded_zipPlugin`). Kept.                                                                                                                      |
| `loaded_tar`                                                                                                                                                                                     | **REAL** — guards `autoload/tar.vim`. Kept.                                                                                                                                                                |
| `loaded_gzip`, `loaded_matchit`, `loaded_matchparen`, `loaded_netrw`, `loaded_netrwPlugin`, `loaded_spellfile_plugin`, `loaded_tarPlugin`, `loaded_zipPlugin`                                    | correct, kept                                                                                                                                                                                              |
| `loaded_getscript`, `loaded_getscriptPlugin`, `loaded_logipat`, `loaded_rrhelper`, `loaded_vimball`, `loaded_vimballPlugin`, `loaded_netrwFileHandlers`, `loaded_netrwSettings`, `loaded_tohtml` | dead — zero hits anywhere in runtime tree. Deleted.                                                                                                                                                        |

- **Fix applied:** options.lua block rewritten — 18 guards, all verified real;
  9 dead flags deleted; 3 wrong names corrected (`loaded_remote_plugins`,
  `loaded_tutor_mode_plugin`, `loaded_shada_plugin` + `loaded_shada_autoload`).
- **matchparen note (user decision):** `loaded_matchparen = 1` stays in BOTH
  options.lua (eager — actually prevents plugin load) AND
  `plugins/functionality.lua` deferred block, coupled with the vim-matchup setup
  that replaces it. Do NOT remove the functionality.lua one again.
- **Untouched on purpose:** `nvim.difftool` (packadd'd in keymaps.lua:454),
  `:Man` (used), net.lua, editorconfig, osc52.
- **Manual test:**
  1. `nvim` → `:Tutor` → `E464: Ambiguous use of user-defined command`-style
     unknown command error (plugin no longer loads).
  2. `:UpdateRemotePlugins` → unknown command (rplugin.vim no longer loads).
  3. `:Man man` → still works (kept).
  4. `:packadd nvim.difftool` → no error (kept working, used by keymaps).
  5. `:echo g:loaded_shada_plugin` → `1`.
- **Status before:** rplugin.vim and tutor.vim loaded every startup despite the
  "disable" flags (wrong guard names); 9 flags referenced plugins that no longer
  exist anywhere in the runtime tree.
- **Status after:** every flag in the block maps to a real guard in the nightly
  runtime; rplugin + tutor actually disabled (`:Tutor`, `:UpdateRemotePlugins`
  gone, verified headless); dead flags removed.

### B7. Operator-func helpers broken for visual / multiline `[x]` FIXED 2026-06-10

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
- **Fix applied:**
  - New shared helpers in keymaps.lua (after `_G.op` init):
    - `region_bounds(motion)` — 0-indexed `'[`/`']` bounds for `nvim_buf_get_text`.
      Linewise: col 0 → `#getline(end)`. Charwise: end col = `finish[2] + #last_char`
      where `last_char = vim.fn.strpart(line, col, 1, true)` (char-wise strpart) —
      multibyte-safe, fixes the old `finish[2] + 1` byte off-by-one.
    - `arm(fn)` — returns expr-map callback: sets `operatorfunc = fn`, returns `'g@'`.
  - All three ops (`surround_with_interpolation`, `base64_encode`, `base64_decode`)
    are now pure operatorfunc bodies — no nil/'line' re-arm guard, no
    `vim.fn.feedkeys 'g@'`.
  - Maps: `mt` → `arm(...)` with `expr = true` (normal); `<leader>64`/`<leader>46` →
    one `map({ 'n', 'x' }, ...)` each, `expr = true` (`g@` in visual applies the
    operator to the selection directly; `x` instead of `v` to skip select mode).
  - `b64()` joins ALL lines from `nvim_buf_get_text` with `\n` (multiline charwise
    no longer truncated); `surround_with_interpolation` wraps first/last line of
    region (`"${` … `}"`), cursor lands at region start.
  - **Bonus:** expr-map pattern makes `.` (dot-repeat) work for all three operators.
  - **Follow-up (user-reported):** decoding text that is not a single valid base64
    token (e.g. selecting `aGVsbG8= d29ybGQ=` — two tokens + space) made
    `vim.base64.decode` throw a raw Lua stacktrace. Now wrapped in `pcall`:
    invalid input → `vim.notify` error ("Base64 decode failed: invalid input"),
    buffer untouched. Decode each token separately (`<leader>46iw` per word).
  - Verified headless via feedkeys end-to-end, 8/8: n-charwise, V-linewise (hung
    before), multiline charwise visual (truncated before), decode→multiline
    roundtrip, mt charwise, mt linewise motion (hung before), multibyte tail
    (`héllo`), dot-repeat.
- **Manual test:**
  1. `nvim` scratch buffer, type `hello world`, cursor on `hello`, `<leader>64iw` →
     `aGVsbG8= world`. Press `j` then `.` on another word → dot-repeat encodes it.
  2. Line `abc` then `def`: `vj$` (select both lines charwise), `<leader>64` →
     single line `YWJjCmRlZg==`. Select it (`0v$h`), `<leader>46` → back to two
     lines `abc`/`def`.
     2b. Line `aGVsbG8= d29ybGQ=` (two tokens): `0v$h<leader>46` → error notification
     "Base64 decode failed: invalid input", buffer unchanged, no stacktrace.
  3. `V<leader>64` on a line → encodes whole line (no hang waiting for motion).
  4. `mtiw` on word `name` → `"${name}"`; `mt_` → wraps whole line.
  5. Word `héllo`: `<leader>64iw` → decodes back to exactly `héllo` (no torn
     UTF-8 byte).
- **Status before:** linewise invocations (`V<leader>64`, `mt_`) re-armed
  operatorfunc and hung waiting for a motion; multiline charwise selections
  silently encoded only the first line; multibyte last char got truncated
  (`finish[2] + 1` counts bytes); no dot-repeat.
- **Status after:** all motions (char/line, single/multi-line, multibyte) work,
  visual mode works in both directions, `.` repeats the operation.

### B8. `filter_yank` appends to register e forever `[-]` NOT A BUG (user: intended)

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:282`
- `vim.fn.setreg('E', ...)` — uppercase register name appends (`:h setreg()`).
- **User confirmed 2026-06-10: append behavior is intentional.** Do not "fix".

### B9. `<leader>bh` (delete hidden buffers) aborts on modified buffer `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:350-360`
- **Problem:** `nvim_buf_delete(buf, {})` throws on modified buffers / some special
  buffers → loop died mid-iteration, count misleading.
- **Fix applied:** skip `vim.bo[buf].modified` buffers, `pcall(nvim_buf_delete)`,
  count only successes. Dropped redundant `nvim_buf_is_valid` (list_bufs only
  returns valid buffers).
- **Manual test:** open `nvim a.txt`, `:edit b.txt`, type text in b.txt WITHOUT
  saving, `:edit c.txt`. Now a.txt + b.txt hidden, b.txt modified. `<leader>bh` →
  notification "1 hidden buffer(s) deleted", `:ls` shows b.txt still alive
  (changes safe), a.txt gone.
- **Status before:** `<leader>bh` with any modified hidden buffer → E5108 error
  mid-loop, remaining buffers not processed.
- **Status after:** modified buffers skipped silently, rest deleted, accurate count.
  Verified headless.

### B10. `cii` (change indentation) crashes/nils options on cancel `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:420-431`
- **Problem:** Cancel (`<Esc>`) → `indent_size = nil` → `tonumber(nil)` → nil →
  assigned nil to `shiftwidth/softtabstop/tabstop` (reset local values to defaults
  unexpectedly). Non-numeric input same path.
- **Fix applied:** `if not indent_size_normalized then return end` guard before
  assignment.
- **Manual test:** `:setlocal shiftwidth=2`, press `cii`, hit `<Esc>` →
  `:set shiftwidth?` still 2. `cii` + `abc<CR>` → still 2. `cii` + `4<CR>` → 4.
- **Status before:** cancel or garbage input silently reset local
  shiftwidth/softtabstop/tabstop to global defaults.
- **Status after:** cancel/garbage = no-op; numeric input applies. Verified
  headless (vim.ui.input stubbed; real impl is the floating user/input.lua).

### B11. `:Rename` sends `workspace/willRenameFiles` AFTER the rename `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/plugins/functionality.lua` (deferred block)
- **Problem:** LSP spec: `willRenameFiles` is a request sent **before** the file
  operation so the server can compute edits against the old URI; `didRenameFiles`
  after. Old code: `vim.fn.rename` → `saveas` → `notify_lsp_rename` (will+did
  together, both post-hoc). Servers that resolve the old file (import updates)
  could return empty/wrong edits.
- **Fix applied:** split into `lsp_will_rename(changes)` (request_sync + apply
  edits) and `lsp_did_rename(changes)` (notify); `:Rename` now does
  will → `vim.fn.rename` → `keepalt saveas` → did. Shared
  `lsp_rename_changes(old, new)` builds the URI pair once.
  `_G._notify_lsp_rename` kept as a combined post-hoc wrapper for the nvim-tree
  NodeRenamed subscriber (tree.lua:244) — that event fires after the rename
  already happened, so post-hoc is the best it can do there.
- **Manual test:** in a TS/Go project with LSP attached, open a file that other
  files import, `:Rename` it (change basename). Importing files should get
  updated import paths (willRenameFiles edits) — before the fix servers often
  returned no edits because the old URI no longer existed.
- **Status before:** willRenameFiles requested after the file was already moved →
  cross-file import updates unreliable/no-op.
- **Status after:** will before the move (per LSP spec), did after; `:Rename`
  registers verified headless.

### B12. `tmp_write` temp-file cleanup usually skipped `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/init.lua:41-50`
- **Problem:** `nvim_create_autocmd('VimLeavePre', { buffer = 0, ... })` —
  buffer-local autocmd for a global event only fires when that buffer is
  **current** at exit. Temp files leaked in most sessions.
- **Fix applied:** dropped `buffer = 0`; global VimLeavePre autocmd, `tmp` path
  captured in closure (one autocmd per temp file — sessions create few).
- **Manual test:** `:lua print(_G.tmp_write { new = false })` (note path),
  `:new`, `:qa!` → `ls <path>` in shell → file gone. Before: file remained
  whenever another buffer was focused at exit.
- **Status before:** temp files leaked unless their buffer happened to be current
  at exit.
- **Status after:** deleted on every exit regardless of current buffer. Verified
  headless end-to-end.

> **Open follow-up (2026-06-10):** full `make test` after B9-B12: 270 pass,
> 1 fail — `user.yank-ring ring registers does not shift on deletes` — only when
> run inside the full suite (passed standalone at B4 time; B9-B12 touch no
> register code). Likely test-order/shared-state flake OR native numbered-register
> shift on `dd` (`:h quote_number`) interacting with prior spec state. Investigate
> separately.

### B13. Duplicate `<C-h/j/k/l>` window maps `[-]` NOT A BUG (user: intended)

- **Files:** `nvim/.config/nvim/lua/user/keymaps.lua:98-101` then
  `lua/plugins/functionality.lua:33-36` overwrites with smart-splits versions.
- **User confirmed 2026-06-10: not an issue.** Deliberate layering — leave both.

### B14. `:Whereami` passes unsupported `verbose` opt `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/user/keymaps.lua:398-418`
- **Problem:** nightly `vim.net.request` opts are `body`, `headers`, `outbuf`,
  `outpath`, `retry` — no `verbose`. Also `vim.json.decode(result.body)` unguarded
  (network body may be error HTML).
- **Fix applied:** dropped `verbose = true` (empty opts table); wrapped decode in
  `pcall` → notify "Failed to parse location data" on bad body.
- **Manual test:** `:Whereami` → notification like `You're in Israel 🇮🇱`.
- **Status before:** unsupported opt passed (silently ignored or future error);
  non-JSON response → Lua stacktrace.
- **Status after:** clean opts, graceful parse failure. Verified headless against
  live endpoint — notification "You're in Israel 🇮🇱".

### B15. Dead plugin spec file `[x]` FIXED 2026-06-10

- **File:** `nvim/.config/nvim/lua/plugins/databases.lua` — DELETED (git rm)
- Old lazy.nvim spec (`enabled = false` already), never required by
  `user/pack/init.lua`, zero references in config. Pure dead code since the
  vim.pack migration. User chose deletion.
- **Manual test:** `nvim` starts clean; `grep -r databases lua/` → no hits.
- **Status before:** 60+ lines of dead lazy.nvim spec shipped in repo.
- **Status after:** file removed.

---

## RACE CONDITIONS (summary index)

- B3 — deferred FileType/BufReadPost autocmds vs initial buffer (treesitter, lint, switch, mini).
- B5 — LspAttach/LspDetach augroup clearing + non-buffer-scoped detach. FIXED 2026-06-10.
- B12 — buffer-local VimLeavePre. FIXED 2026-06-10.
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

- `user/yank-ring.lua` maps `<c-m>` (cycle to older yank; was yanky's CycleBackward before B4). Works in wezterm
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
