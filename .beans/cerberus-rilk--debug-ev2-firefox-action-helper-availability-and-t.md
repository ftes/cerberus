---
# cerberus-rilk
title: Debug ev2 Firefox action helper availability and toast snapshot drift
status: completed
type: bug
priority: normal
created_at: 2026-03-12T11:53:45Z
updated_at: 2026-03-12T12:06:40Z
---

Investigate Firefox failures in ../ev2-copy where browser actions report action helper is not available and toast assertions miss expected toasts. Reproduce focused cases, inspect browser helper injection and render_html/browser DOM snapshots, and identify whether the gap is in Cerberus helper bootstrap or browser snapshot/assertion behavior.\n\n- [ ] inspect browser action helper failure path in Cerberus\n- [ ] reproduce a focused ev2-copy helper failure under Firefox\n- [ ] reproduce a focused ev2-copy toast failure under Firefox\n- [ ] compare render_html output with browser DOM for the toast case\n- [x] summarize root cause and next fix

\n\n## Summary of Changes\n\n- Confirmed the browser helper failure is literal: action/assertion expressions return helperMissing when the current document lacks window.__cerberusAction or window.__cerberusAssert.\n- Added browser-driver self-heal in /Users/ftes/src/cerberus/lib/cerberus/driver/browser.ex: when a read/action evaluation returns helperMissing, Cerberus reinstalls both preload helpers into the current document and retries once.\n- Added focused Cerberus regression coverage in /Users/ftes/src/cerberus/test/cerberus/browser_timeout_assertions_test.exs by deleting helpers from the live document and requiring both a locator assertion and a click action to recover.\n- Verified focused Cerberus coverage on both Firefox and Chrome.\n- Verified the original EV2-shaped focused cases under Firefox: test/features/malta_cerberus_test.exs passed, and test/features/create_offer_cerberus_test.exs:26 passed on rerun.\n- Ran the full EV2 Firefox compare-copy suite. Result: 689 tests, 54 failures, 30 skipped, 5042 excluded, finished in 77.9s. Remaining failures are now dominated by Firefox session startup pressure under concurrency (session not created, Maximum number of active sessions, session.new timeout) plus existing EV2 sandbox ownership noise, not the original helper/toast issue.\n- Follow-up bean created: cerberus-x72l.
