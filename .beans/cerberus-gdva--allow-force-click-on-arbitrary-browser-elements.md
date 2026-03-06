---
# cerberus-gdva
title: Allow force click on arbitrary browser elements
status: in-progress
type: bug
created_at: 2026-03-06T21:47:01Z
updated_at: 2026-03-06T21:47:01Z
---

## Context

EV2 browser migration exposed a gap in Cerberus browser click semantics. A migrated Playwright/Cerberus test needs to click a TomSelect label element (#job_title_dropdown-ts-label) to open the control. Cerberus browser click currently rejects the label before actionability because plain labels are not treated as click targets.

The user pointed out that if force is passed, Cerberus should allow any matched element to be clicked. That is a clean browser contract: force bypasses normal click-target restrictions and actionability gating, and should dispatch a click against the resolved element rather than requiring it to be a link/button/phx-click target.

This is broader than labels specifically. Labels are the immediate EV2 example, but the desired behavior is force-click support for arbitrary elements in the browser driver.

## Scope

- Add a failing browser regression test for forced clicks on arbitrary elements, including a label case.
- Implement browser click semantics so force: true can click any matched element.
- Keep non-force behavior strict unless there is a separate decision to broaden ordinary click candidates.
- Re-run targeted Cerberus browser tests.
- Then use the new behavior in EV2 migration work if it simplifies the TomSelect helper.

## Notes

Force should not be treated as a generic migration escape hatch, but this browser behavior is a reasonable explicit contract and matches the user expectation for force.

## Todo

- [ ] Add failing browser regression coverage for force-clicking arbitrary elements
- [ ] Implement browser driver support for force-clicking arbitrary matched elements
- [ ] Re-run targeted Cerberus browser tests
- [ ] Apply or evaluate the new behavior in EV2 migration helpers
