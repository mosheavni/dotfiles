---
name: feedback-fix-doc-format
description: Every fix documented in nvim-config-review.md needs a Manual test block with Status before/after lines
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8595f7bc-6127-4556-a2cf-b97f8a8c7cc4
---

When marking a finding fixed in `nvim-config-review.md` (or similar review docs), always append a **Manual test** block: interactive shell + nvim steps the user can run themselves (e.g. `echo 'kind: Deployment' | nvim -` then `:set ft?`), plus explicit `Status before:` and `Status after:` one-liners contrasting broken vs fixed behavior.

**Why:** user wants to verify fixes with own eyes, not trust headless output (requested 2026-06-10: "let me test it manually and see the changes with my own eyes").

**How to apply:** after each fix in the review doc, write the Manual test block before moving to the next issue. Headless verification still done first by AI; manual block mirrors it in interactive form. See [[feedback-skip-make-test]] for when to run the test suite.
