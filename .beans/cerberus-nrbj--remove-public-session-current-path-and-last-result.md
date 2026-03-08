---
# cerberus-nrbj
title: Remove public session current_path and last_result API
status: completed
type: bug
priority: normal
created_at: 2026-03-08T08:54:12Z
updated_at: 2026-03-08T09:02:04Z
---

## Scope

- [x] Remove current_path and last_result from the public Cerberus.Session API.
- [x] Update internal callers to stop relying on those public accessors.
- [x] Update Cerberus tests/docs to stop using session.current_path/session.last_result as public examples.
- [x] Verify targeted Cerberus coverage for the affected areas.

## Summary of Changes

- Removed current_path and last_result from the public Cerberus.Session protocol surface.
- Marked browser, live, and static session structs opaque so their internal fields stop being advertised in public typespecs.
- Updated internal callers to use internal session fields directly instead of the removed public accessors.
- Removed the public Cerberus.current_path API and updated compatibility helpers and doc-style tests away from it.
- Changed browser reload_page to perform a real in-browser reload via browsingContext.reload, then run the normal visit-style readiness and snapshot flow.
- Updated path-related tests to assert via assert_path rather than assuming immediate public path state after browser actions.
