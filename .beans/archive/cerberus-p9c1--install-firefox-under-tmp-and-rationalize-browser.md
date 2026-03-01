---
# cerberus-p9c1
title: Install Firefox under tmp and rationalize browser install scripts
status: completed
type: task
priority: normal
created_at: 2026-02-28T13:36:24Z
updated_at: 2026-02-28T13:42:24Z
---

## Goal
Make Firefox provisioning mirror Chrome/Chromedriver tmp-based setup and clean up bin script naming/entrypoints.

## Todo
- [x] Inspect current browser install scripts and references
- [x] Add/adjust Firefox install path to tmp with consistent conventions
- [x] Rename or merge bin scripts so browser names are explicit/consistent
- [x] Update docs/help text if CLI usage changed
- [x] Run format/tests or relevant checks
- [x] Summarize changes and next steps

## Summary of Changes
- Added browser-specific scripts: bin/check_chrome_bidi_ready.sh and bin/check_firefox_bidi_ready.sh.
- Added merged dispatcher script: bin/check_browser_bidi_ready.sh with browser selection by positional arg or --browser.
- Kept compatibility wrappers: bin/check_bidi_ready.sh -> chrome script and bin/check_gecko_bidi_ready.sh -> firefox script.
- Extended Firefox script with --install support that provisions Firefox and GeckoDriver under tmp/browser-tools, writes tmp/browser-tools/env.sh, and validates BiDi handshake.
- Updated CI workflow to use script-based install for both Chrome and Firefox lanes (removed setup-firefox/setup-geckodriver action dependency).
- Updated README helper commands and .envrc to include CERBERUS_FIREFOX_VERSION, CERBERUS_GECKODRIVER_VERSION, FIREFOX, and GECKODRIVER defaults.
- Validation: bin/check_browser_bidi_ready.sh firefox --install and bin/check_browser_bidi_ready.sh chrome --install passed locally; mix format and mix precommit currently fail due unrelated EEx fixture template syntax in test/support/fixtures/migration_project/deps/phoenix/priv/templates/phx.gen.auth/session_controller.ex.
