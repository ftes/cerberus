---
# cerberus-luje
title: Fix inexact candidate selection for ev2 custom_documents test
status: completed
type: bug
priority: normal
created_at: 2026-03-04T20:34:38Z
updated_at: 2026-03-04T20:44:27Z
---

## Goal
Investigate failing ev2 custom_documents_live index test where possible candidates include an inexact text match that is not selected.

## Tasks
- [x] Reproduce failure in ../ev2 and capture assertion details
- [x] Trace candidate matching/selection path in Cerberus
- [x] Add Cerberus regression test covering inexact candidate preference
- [x] Implement fix and verify with targeted tests in cerberus and ev2

## Summary of Changes
- Reproduced the ev2 failure where click_button with inexact Save text reported no button match while candidate hints included Save custom document.
- Root cause: live click path only matched buttons with phx-click; submit buttons in phx-submit forms were excluded from matching.
- Fixed live driver button resolution to fall back to LiveViewHTML.find_submit_button when no phx-click button matches.
- Updated live click execution to detect submit-button matches and route them through do_live_submit, then normalize the last result operation as click.
- Added regression coverage in PasswordAuthFlowTest: click with inexact Create live locator on the live register submit button now succeeds for phoenix and browser drivers.
- Verification:
  - source .envrc and PORT=4588 mix test test/cerberus/password_auth_flow_test.exs:67 passed.
  - source .envrc and PORT=4589 mix test test/cerberus/form_actions_test.exs:72 passed.
  - PORT=4587 mix test test/ev2_web/admin/pages/custom_documents_live/index_test.exs:32 currently fails at compile-time in ev2 because it still calls removed helper APIs click_link and click_button; runtime verification there needs those calls migrated to click.
