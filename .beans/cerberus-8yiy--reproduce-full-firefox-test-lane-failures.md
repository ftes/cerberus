---
# cerberus-8yiy
title: Reproduce full Firefox test lane failures
status: in-progress
type: task
priority: normal
created_at: 2026-03-14T17:29:07Z
updated_at: 2026-03-14T17:29:13Z
---

Run the full Cerberus test suite locally with CERBERUS_BROWSER_NAME=firefox, compare with the CI Firefox lane, and summarize the reproduced failure clusters so follow-up fixes can be split cleanly.


## Notes
- reproduced locally with `source .envrc && PORT=4203 CERBERUS_BROWSER_NAME=firefox mix test`
- full Firefox lane finished with `631 tests, 19 failures`
- reproduced failure clusters include: RuntimeTest assumptions that still expect Chrome defaults; ValueAssertionsTest browser value retry on Firefox; BrowserExtensionsTest download filename expectations (`report.txt` vs Firefox-style `report(N).txt`) and keyboard blur behavior; HelperLocatorBehaviorTest browser session collapse after a Firefox readiness/script.evaluate timeout; and the Firefox-only RuntimeIntegrationTest process-start assertion flake
