---
# cerberus-56po
title: Allow browser clicks on label elements
status: in-progress
type: bug
created_at: 2026-03-06T21:51:15Z
updated_at: 2026-03-06T21:51:15Z
---

## Context

EV2 browser migration is blocked on a TomSelect helper that clicks a label element (#job_title_dropdown-ts-label) to open the control. Real browser behavior allows clicking labels, and the earlier Playwright coverage relied on that. Cerberus browser click currently only treats links, buttons, and phx-click elements as click targets, so a plain label is rejected before the action reaches the browser.

This is narrower than the separate force-click bean. The immediate parity gap is ordinary browser clicking on label elements.

## Scope

- Add a failing browser regression for clicking a plain label element.
- Teach the browser click resolver to include labels as clickable targets.
- Keep the change browser-only.
- Re-run targeted Cerberus browser tests and the focused EV2 case.

## Todo

- [ ] Add failing browser regression coverage for label clicks
- [ ] Implement browser click support for label elements
- [ ] Re-run targeted Cerberus browser tests
- [ ] Re-run focused EV2 browser case
