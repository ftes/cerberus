---
# cerberus-bepv
title: Define explicit behavior for cross-origin iframe limitations
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:12:09Z
updated_at: 2026-03-02T08:47:50Z
---

Limitation scope: cross-origin iframe DOM interaction cannot be driven directly through custom JS due to same-origin policy.

## Scope
- Decide product behavior (explicit error, docs-only limitation, or future API placeholder)
- Add user-facing docs with practical alternatives
- Add tests that pin expected failure behavior/messages

Research note: check Capybara/Cuprite behavior first; if unclear, fallback to Playwright JS/docs for confirmation.

## TODO
- [x] Define and document explicit cross-origin iframe limitation behavior and alternatives
- [x] Add tests that pin expected failure behavior and message surface
- [x] Run precommit and add summary of changes

## Summary of Changes
- Chosen behavior: treat cross-origin iframe DOM access limits as explicit browser constraints, not driver bugs.
- Added user-facing limitation docs and alternatives in browser support policy, and surfaced the limitation warning in README.
- Added deterministic fixtures for cross-origin iframe testing using host flip (localhost <-> 127.0.0.1) on the same test server.
- Added browser tests that pin limitation behavior:
  - guarded iframe access returns a deterministic cross_origin_blocked payload,
  - unguarded iframe access raises evaluate_js failure.
- Improved Browser.evaluate_js error surfacing for script exceptions by mapping BiDi exception payloads to `browser evaluate_js failed: ...` messages.
- Ran targeted browser tests and mix precommit successfully.
