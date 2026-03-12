---
# cerberus-4lhi
title: Investigate EV2 send_email failure and Cerberus CI timeout
status: completed
type: bug
priority: normal
created_at: 2026-03-11T20:28:28Z
updated_at: 2026-03-11T20:29:09Z
---

Investigate the remaining failure reported at test/worker/distribution/send_email_test.exs:97 and confirm the effective Cerberus assertion timeout used in EV2 CI.

- [x] inspect EV2 Cerberus timeout configuration and code defaults
- [x] reproduce or classify the send_email_test failure source
- [x] summarize findings and mark bean completed if no code changes are needed

## Summary of Changes

Confirmed that Cerberus library defaults are 500ms for live and browser sessions, but EV2 test config overrides them in CI/test runs to 2_000ms for live sessions and 4_000ms for browser sessions. Cerberus assertions use the session timeout unless the assertion call passes its own `timeout:` or the session was created with an explicit `timeout_ms:` override. The reported send_email failure was reclassified as a separate port issue, not a Cerberus assertion timeout problem.
