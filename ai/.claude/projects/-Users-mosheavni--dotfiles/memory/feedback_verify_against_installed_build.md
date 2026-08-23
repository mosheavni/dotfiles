---
name: feedback-verify-against-installed-build
description: "For Neovim (or any fast-moving nightly software), fetched upstream docs can describe behavior ahead of what's actually installed — verify against the live build, not just the docs"
metadata:
  node_type: memory
  type: feedback
  originSessionId: bfa57fd0-016a-4b4f-93c6-96d9058ea42b
---

When checking whether an upstream behavior change is actually live, don't trust fetched documentation (e.g. `news.txt`/`repeat.txt` pulled from GitHub's `master` branch) as proof the behavior exists in the locally installed build. Docs on `master` can describe target/intended behavior that hasn't landed in the actual nightly build yet. Verify against the real, installed artifact: for Neovim keymaps, run `:verbose <map-command> <key>` or read the actual file under `$VIMRUNTIME` (e.g. `$VIMRUNTIME/lua/vim/_core/defaults.lua`) directly.

**Why:** caught in [[project_nvim_news_tracker]] (row 21, `Q`'s multicursor default). Fetched `repeat.txt`/`vim_diff.txt` from GitHub master, both clearly described Visual-mode `Q` now placing a multicursor by default, and declared the feature "already live, nothing to do." The user then hit `E354: Invalid register name: '^@'` pressing `Q` on a Visual selection — the old "repeat last recorded register" behavior, not multicursor. Headless repro attempts (clean config and full config) never errored, so the live session had to be checked directly: `:verbose xmap Q` pointed at `$VIMRUNTIME/lua/vim/_core/defaults.lua`, and that file — read directly — still contained the *old* mapping. The multicursor implementation module (`mcursor.lua`, described in `dev_arch.txt`) didn't even exist in the installed build. Docs on GitHub's master had gotten ahead of what was actually shipped in the local nightly.

**How to apply:** for any "is this already live in my build" question — not just Neovim, any nightly/fast-moving dependency — treat fetched docs as a *description of intent*, not proof of current state. When a row/decision hinges on "this already works by default," verify with a command or file read against the actual installed thing before writing `skip`. If the user reports behavior that contradicts a documented default, don't defend the docs — check the real artifact first.
