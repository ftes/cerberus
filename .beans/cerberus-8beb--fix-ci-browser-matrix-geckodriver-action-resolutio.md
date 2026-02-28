---
# cerberus-8beb
title: Fix CI browser matrix geckodriver action resolution
status: completed
type: bug
priority: normal
created_at: 2026-02-28T13:49:46Z
updated_at: 2026-02-28T13:50:29Z
---

## Goal
Fix browser_matrix CI failures caused by invalid action references and ensure firefox/chrome setup is lane-specific.

## Todo
- [x] Inspect current CI workflow browser_matrix steps
- [x] Remove invalid geckodriver action dependency and use script provisioning
- [x] Verify workflow has lane-specific setup behavior
- [x] Summarize change and validation

## Summary of Changes
- Confirmed local workflow no longer references browser-actions/setup-geckodriver or browser-actions/setup-firefox.
- Browser matrix now provisions per lane via script entrypoint:
  - chrome lane: bin/check_browser_bidi_ready.sh chrome --install
  - firefox lane: bin/check_browser_bidi_ready.sh firefox --install
- This removes dependency on an invalid action tag and prevents workflow bootstrap failure from action resolution.
- Validation:
  - rg -n "setup-geckodriver|setup-firefox|browser-actions/setup" .github/workflows returned no matches.
  - git diff for .github/workflows/ci.yml shows setup-* action steps removed and script provisioning in place.
