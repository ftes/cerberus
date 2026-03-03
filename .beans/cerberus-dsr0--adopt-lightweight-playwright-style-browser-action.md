---
# cerberus-dsr0
title: Adopt lightweight Playwright-style browser action semantics
status: todo
type: feature
created_at: 2026-03-03T11:30:30Z
updated_at: 2026-03-03T11:30:30Z
---

Decision: move browser driver to lightweight Playwright-like semantics for actions and waits.\n\nGoals:\n- Resolve locator and perform action atomically in browser where feasible.\n- Keep actionability checks and strict target semantics.\n- Avoid global pre and post readiness waits on hot paths.\n- Avoid post-action success snapshots on hot paths.\n- Wait for navigation only when action initiates navigation or caller explicitly asserts/waits.\n\nScope:\n- [ ] Unify action resolve and execute in browser helper APIs to minimize roundtrips per action.\n- [ ] Remove duplicate candidate logic split between action helpers and expression wrappers.\n- [ ] Change link click behavior to literal DOM click semantics first, not URL navigate by href.\n- [ ] Remove fallback collect plus Elixir-side filtering for has in action paths.\n- [ ] Move path assertions to single in-browser wait loop rather than Elixir recursion loop.\n- [ ] Record roundtrip counts before and after for click, submit, fill_in, select, choose, check, uncheck, upload.\n- [ ] Validate behavior and performance on chrome and firefox browser suites.\n- [ ] Update docs where semantics change from settled-before-return to lightweight action waits.
