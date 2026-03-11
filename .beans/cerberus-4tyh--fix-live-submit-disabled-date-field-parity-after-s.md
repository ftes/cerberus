---
# cerberus-4tyh
title: Fix live submit disabled date-field parity after second submit
status: in-progress
type: bug
priority: normal
created_at: 2026-03-11T10:34:52Z
updated_at: 2026-03-11T11:13:46Z
---

Cerberus live driver diverges from PhoenixTest on EV2 subscriptions flow: after a second submit, the tc_standard date-to input remains enabled in Cerberus but is disabled in PhoenixTest. The toast parity bug is already fixed; this is a separate live form-state/submit bug. Reproduce from subscriptions_cerberus_test.exs, identify whether active form sync or submit result handling drops the disabled state transition, and fix in Cerberus.
