---
# cerberus-xwqt
title: Implement active-form submit(session) semantics across drivers
status: in-progress
type: task
created_at: 2026-03-04T07:10:30Z
updated_at: 2026-03-04T07:10:30Z
---

Align submit(session) with PhoenixTest semantics across static/live/browser: use active form, and fail when no active form exists.

- [ ] Implement submit(session) active-form semantics in Cerberus facade and drivers
- [ ] Ensure browser driver can resolve active form submit target reliably
- [ ] Add parity tests for active-form submit success and no-active-form failure across drivers
- [ ] Run format and targeted tests
