---
# cerberus-thf9
title: Stabilize browser type/3 BiDi timeout flake
status: completed
type: bug
priority: normal
created_at: 2026-03-03T22:12:10Z
updated_at: 2026-03-03T22:16:26Z
---

Investigate intermittent timeout in Cerberus.BrowserExtensionsTest screenshot+keyboard+dialog+drag test under seed 704742 and harden stability.

## Progress
- Reproduced the reported seed run environment and inspected browser extension timeout flow in type/3.
- Identified that this integration smoke test used aggressive per-call timeout overrides (250ms) for type/press/drag, which are sensitive to full-suite load.

## Summary of Changes
- Removed explicit timeout: 250 overrides from the smoke integration test in test/cerberus/browser_extensions_test.exs so it uses normal browser extension timeout defaults.
- Kept timeout semantics tests separate; this smoke test now focuses on integration behavior instead of micro-timeout constraints.
- Validation:
  - mix test --seed 704742 -> 467 tests, 0 failures (3 excluded)
  - mix precommit -> passed
