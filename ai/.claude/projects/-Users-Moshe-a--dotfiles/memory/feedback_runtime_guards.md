---
name: runtime-guard-verification
description: "Verify nvim loaded_* guards across ENTIRE runtime tree (plugin/, autoload/, pack/dist/opt/), not just runtime/plugin/; keep matchparen guard coupled with vim-matchup"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8595f7bc-6127-4556-a2cf-b97f8a8c7cc4
---

When verifying Neovim `g:loaded_*` disable guards (or any runtime behavior), grep the **whole** runtime tree — `runtime/plugin/`, `runtime/autoload/`, `runtime/pack/dist/opt/` — not just `runtime/plugin/`.

**Why:** During B6 fix I declared `loaded_2html_plugin`, `loaded_zip`, `loaded_tar`, `loaded_shada` dead after checking only `runtime/plugin/`. User corrected me with exact paths: tohtml guard lives in `pack/dist/opt/nvim.tohtml/plugin/tohtml.lua`, zip/tar guards in `runtime/autoload/`, shada has two guards (`loaded_shada_plugin` in plugin/, `loaded_shada_autoload` in autoload/). User explicitly said "rethink what you did in a more parent directory, go up 2-3 or even 4 levels".

**How to apply:** Before claiming a flag/feature is dead or misnamed, `grep -rn` from the runtime root (`~/.asdf/installs/neovim/nightly/share/nvim/runtime/`). Same principle generally: widen search scope before declaring something unused.

Also: `vim.g.loaded_matchparen = 1` intentionally lives in BOTH `user/options.lua` (eager, prevents load) and `plugins/functionality.lua` deferred block next to vim-matchup setup — user wants the coupling visible. Do not remove the functionality.lua copy. See [[skip-make-test]].
