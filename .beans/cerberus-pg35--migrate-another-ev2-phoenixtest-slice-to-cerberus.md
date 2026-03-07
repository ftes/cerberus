---
# cerberus-pg35
title: Migrate another EV2 PhoenixTest slice to Cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-06T20:10:10Z
updated_at: 2026-03-06T22:29:45Z
blocked_by:
    - cerberus-gdva
    - cerberus-56po
---

## Goal

Migrate the next EV2-copy slice from PhoenixTest/PhoenixTestPlaywright to Cerberus with both non-browser and browser coverage.

## Todo

- [x] Identify a non-browser file and migrate a small Cerberus slice
- [x] Identify a browser file on a route that currently works with Cerberus and migrate a small slice
- [x] Run targeted tests with random PORT values and record outcomes
- [x] Summarize the migrated coverage, blockers, and doc follow-ups


## Notes

For the remaining `../ev2-copy` migration work, consult `/Users/ftes/src/cerberus/MIGRATE_FROM_PHOENIX_TEST.md` first. That file is the running list of unexpected findings that would have saved time on a second migration pass.

Specific reminders from the completed slice:
- If a browser login flow lands on `/`, do not assume auth failed; check whether the real issue is readiness or a dependent disabled control.
- Prefer direct actions on dependent LiveView controls first; only add a minimal enabled-state assertion if the remaining case still needs it.
- Browser sandbox metadata should still come from test `context`, including `ConnCase, async: false` modules.

Locator-preservation reminder for migrated assertions:
- When rewriting PhoenixTest assert_has/refute_has calls, preserve the original locator shape whenever it carries semantics beyond plain text.
- Keep CSS/class locators, role-based locators, and similar structured locators instead of flattening everything to text.
- This keeps more intent in the migrated test and should improve debugging by producing more relevant candidate values and failure context.

## Summary of Changes

Migrated one non-browser slice and one browser slice in ../ev2-copy:
- test/ev2_web/live/project_settings_live/contacts_test.exs now uses ConnCase + Cerberus and is tagged :cerbrerus
- test/features/project_form_feature_test.exs now uses ConnCase browser sessions + UI login via Ev2Web.Cerberus and is tagged :cerbrerus

Migration details that mattered in this slice:
- Preserve structured locator semantics from PhoenixTest assertions instead of flattening to plain text when the original locator carried useful intent
- For browser project creation, asserting the stable destination path /projects/:id/contacts was more reliable than asserting a transient success toast
- For the live SPV copy case, assert_value was the wrong fit for a disabled field; scoping to the labeled field container and asserting the rendered input value matched the old PhoenixTest semantics better

Targeted verification:
- PORT=4972 MIX_ENV=test mix test test/features/project_form_feature_test.exs --include integration -> 3 tests, 0 failures
- PORT=4974 MIX_ENV=test mix test test/ev2_web/live/project_settings_live/contacts_test.exs -> 6 tests, 0 failures

Remaining blocker outside this completed slice:
- test/features/create_offer_test.exs is still blocked on Cerberus parity gaps around the TomSelect-backed Job title control and the related browser interaction beans
