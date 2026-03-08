---
# cerberus-4s0x
title: Add Firefox CI lane via mix test.firefox
status: scrapped
type: task
priority: normal
created_at: 2026-03-08T20:11:58Z
updated_at: 2026-03-08T20:44:26Z
---

## Scope

- [ ] Add Firefox/geckodriver cache and install steps to CI.
- [ ] Add a normal-suite Firefox lane using mix test.firefox.
- [ ] Run targeted local verification so the workflow change matches local behavior.

## Notes

- Keep Chrome as the primary default lane.
- Do not expand websocket Firefox coverage in this change unless needed.

## Reasons for Scrapping

- The user redirected this work away from Cerberus CI and toward EV2 Firefox and protocol performance investigation.
- The local Firefox lane work remains available, but the CI expansion was intentionally stopped before completion.
