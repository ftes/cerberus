---
# cerberus-rnok
title: Add Firefox CI lane and full local verification
status: completed
type: task
priority: normal
created_at: 2026-03-12T08:06:26Z
updated_at: 2026-03-12T08:08:33Z
---

Add a Firefox browser test lane to GitHub Actions and verify the full test suite locally with CERBERUS_BROWSER_NAME=firefox.

- [x] update CI workflow to install Firefox and run a Firefox test lane
- [x] keep Chrome lane intact
- [x] run full local test suite with CERBERUS_BROWSER_NAME=firefox
- [x] summarize results and any follow-ups

## Summary of Changes

- added a dedicated Firefox GitHub Actions job in .github/workflows/ci.yml while leaving the existing Chrome CI job intact
- wired the workflow to load CERBERUS_FIREFOX_VERSION, cache tmp/firefox-*, install Firefox with mix cerberus.install.firefox, and run mix test under CERBERUS_BROWSER_NAME=firefox
- ran the full local suite with source .envrc && CERBERUS_BROWSER_NAME=firefox PORT=4330 mix test --warnings-as-errors
- full Firefox local verification passed: 619 tests, 0 failures
