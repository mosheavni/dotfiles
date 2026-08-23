# Memory Index

- [Skip make test unless spec-covered](feedback_testing.md) — only run nvim Plenary suite when change touches a module with a spec; else headless checks
- [Fix doc format](feedback_fix_docs.md) — fixed findings in review docs need Manual test block + Status before/after lines
- [Runtime guard verification](feedback_runtime_guards.md) — grep whole nvim runtime tree (plugin/, autoload/, pack/dist/opt/) before declaring guards dead; matchparen guard stays in both files
- [Intentional keepers](project_intentional_keepers.md) — morning-routine.sh (macOS Shortcut), zip-code API key (public), unused lua helpers — never flag as dead
- [Don't assume, ask](feedback_dont_assume_ask.md) — preference-shaped decisions (new opt-in behaviors, keymap tradeoffs) get asked via AskUserQuestion, not auto-decided
- [Verify against installed build](feedback_verify_against_installed_build.md) — fetched upstream docs (news.txt etc.) can describe behavior ahead of the actual local nightly; check `:verbose`/`$VIMRUNTIME` files directly
