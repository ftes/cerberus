---
# cerberus-fhnk
title: Fix evaluate_js prompt handling and add regression test
status: completed
type: bug
priority: normal
created_at: 2026-03-04T09:16:36Z
updated_at: 2026-03-04T09:24:44Z
---

Reproduce README evaluate_js(prompt(...)) browser pipeline; add regression test and fix browser driver handling so prompt dialogs do not break evaluation flow.

- [x] Reproduce failure for evaluate_js with prompt in browser session
- [x] Add regression test covering evaluate_js prompt usage
- [x] Implement fix in browser/runtime code
- [x] Run mix format
- [x] Run targeted tests (including browser-tagged test)
- [x] Update bean summary and mark completed

## Summary of Changes

Reproduced the docs snippet failure by adding a browser documentation example test that runs evaluate_js with prompt plus screenshot chaining.
Updated browser evaluate_js implementation to execute script.evaluate directly and poll for opened dialogs during evaluation.
When the opened dialog type is prompt, evaluate_js now dismisses it automatically so evaluation can complete instead of timing out.
Scoped auto-handling to prompt dialogs only, preserving existing confirm/alert flows used by assert_dialog tests.
Updated README 30-second browser snippet to use evaluate_js/3 callback form before screenshot chaining.

Validation:
- mix format
- source .envrc && mix test test/cerberus/documentation_examples_test.exs
- source .envrc && mix test test/cerberus/browser_extensions_test.exs
