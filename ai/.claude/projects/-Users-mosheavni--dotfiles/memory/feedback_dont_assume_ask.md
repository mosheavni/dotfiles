---
name: feedback-dont-assume-ask
description: "Don't unilaterally decide skip/implement for preference-shaped choices — surface as a question instead"
metadata:
  node_type: memory
  type: feedback
  originSessionId: bfa57fd0-016a-4b4f-93c6-96d9058ea42b
---

When triaging new upstream features (Neovim news, library upgrades, anything with a "should we adopt this" shape), don't silently pick `skip` or `implement` for anything that's actually a preference call — a new opt-in behavior, a keybinding default that could go multiple ways, a tradeoff between two reasonable options. Ask via AskUserQuestion instead of deciding and writing a justification after the fact.

**Why:** caught in [[project_nvim_news_tracker]] — assessed three new Neovim features (`Q`'s new multicursor default, builtin `nvim.dir`'s `DirReadPost` hook, `vim.pack-manifest`) and wrote confident-sounding `skip` rows for all three. The user pushed back hard: one dismissal was flatly wrong (claimed nvim-tree fully replaces builtin `nvim.dir`, but `nvim.dir` isn't actually disabled), one description was factually incorrect (mischaracterized `vim.pack-manifest` as a plugin-list format when it's actually plugin-author-supplied lifecycle hooks), and the `Q` skip was an unrequested assumption about the user's preference — they wanted to remap and adopt the new default, not keep the status quo.

**How to apply:** before writing `skip`/`implement` with a justification, ask: is this a fact I verified (code path doesn't exist, feature genuinely unused, pure bugfix with zero config surface) or a judgment call about what the user *wants*? Facts get decided directly with cited evidence. Judgment calls get asked. If asking surfaces a follow-on collision (e.g. the user's chosen remap key already does something else), surface that collision too and re-ask rather than implementing through it — don't assume the tradeoff is acceptable just because they picked a direction.
