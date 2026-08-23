---
name: feedback-skip-make-test
description: "Skip `make test` for nvim config changes that don't touch test-covered modules; headless verification suffices"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8595f7bc-6127-4556-a2cf-b97f8a8c7cc4
---

Don't run `make test` (nvim Plenary suite) after every Lua change — only when the change touches a module with a corresponding spec in `lua/tests/` (utils, gitbrowse, git, hints, number-separators, open-url, present, tabular-v2, run-buffer, input, gh-actions, lister, pack_float, search-count, terminal).

**Why:** user rejected a test run after an `options.lua` filetype change with "nothing related to tests was changed so let's skip it for now" (2026-06-10). Suite takes time; headless `nvim --headless` behavior checks are the preferred verification for untested config files.

**How to apply:** for changes in `lua/user/options.lua`, `lua/plugins/*`, autocommands, keymaps → verify with targeted headless nvim runs instead. Reserve `make test` for edits to spec-covered `lua/user/` modules (CLAUDE.md rule still applies there).
