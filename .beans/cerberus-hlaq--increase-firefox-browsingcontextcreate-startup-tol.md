---
# cerberus-hlaq
title: Increase Firefox browsingContext.create startup tolerance
status: completed
type: bug
priority: normal
created_at: 2026-03-15T06:29:05Z
updated_at: 2026-03-15T06:31:41Z
---

Investigate Firefox browser session init timeout during browsingContext.create, adjust startup timeout/retry handling if the fixed 10s create-tab timeout is too low, and verify the affected tests.


## Summary of Changes
- confirmed Firefox startup was still using BiDi's fixed 10s default for browsingContext.create, which is too tight under load even though the failure happens during session bootstrap rather than normal page interaction
- added a dedicated browsingContext.create timeout helper in BrowsingContextProcess that respects configured bidi_command_timeout_ms but enforces a 20s floor for Firefox startup tab creation only
- added focused coverage for the timeout helper, verified the original Firefox data-method failure and related startup files pass locally, and reran precommit successfully
