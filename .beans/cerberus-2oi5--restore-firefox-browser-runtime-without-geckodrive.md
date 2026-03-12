---
# cerberus-2oi5
title: Restore Firefox browser runtime without geckodriver
status: done
type: feature
created_at: 2026-03-12T07:36:47Z
updated_at: 2026-03-12T10:02:00Z
---

Implement Firefox browser support alongside Chrome using direct BiDi startup instead of geckodriver. Reject Chrome-only CDP evaluate on Firefox, restore browser selection/runtime wiring, add a Firefox install task and env support, and verify targeted browser/runtime coverage.

- [x] add browser selection and Firefox runtime startup without geckodriver
- [x] reject use_cdp_evaluate for Firefox
- [x] restore bootstrap/options/runtime/install support for Firefox
- [x] update docs and .envrc for Firefox support
- [x] run focused tests and install task verification
- [x] add summary of changes

Summary:
- restored browser runtime selection with local Firefox startup via `Bibbidi.Browser` and no local geckodriver dependency
- made `use_cdp_evaluate` explicitly Chrome-only and updated shared browser test helpers accordingly
- added `mix cerberus.install.firefox`, simplified `bin/firefox.sh`, and removed geckodriver env wiring from `.envrc`
- updated docs for Firefox support and browser-specific remote endpoint config
- verified targeted runtime/install tests, Firefox browser tests, and Chrome parity smoke coverage
