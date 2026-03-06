---
# cerberus-pg35
title: Migrate another EV2 PhoenixTest slice to Cerberus
status: in-progress
type: task
priority: normal
created_at: 2026-03-06T20:10:10Z
updated_at: 2026-03-06T21:51:17Z
blocked_by:
    - cerberus-gdva
    - cerberus-56po
---

## Goal

Migrate the next EV2-copy slice from PhoenixTest/PhoenixTestPlaywright to Cerberus with both non-browser and browser coverage.

## Todo

- [ ] Identify a non-browser file and migrate a small Cerberus slice
- [x] Identify a browser file on a route that currently works with Cerberus and migrate a small slice
- [ ] Run targeted tests with random PORT values and record outcomes
- [ ] Summarize the migrated coverage, blockers, and doc follow-ups


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
