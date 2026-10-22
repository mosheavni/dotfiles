---
name: project-snippets-clipy
description: snippets.xml at repo root is the Clipy app's snippets backup — not dead weight, keep it
metadata:
  type: project
---

`snippets.xml` (repo root, stow-ignored via `.stowrc`) is the snippets export/backup for the [Clipy](https://clipy-app.com/) macOS clipboard manager. It is referenced by nothing in the repo because Clipy imports it manually.

Confirmed by user on 2026-10-22 during a dead-weight audit (it was flagged as a possible IntelliJ leftover — it is not).

**Why:** grep-based audits flag it as orphaned every time; it's an external-app backup like [[project-intentional-keepers]] items.
**How to apply:** never propose deleting `snippets.xml`; treat it as an intentional keeper.
