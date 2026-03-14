---
# cerberus-dl6r
title: Investigate slow EV2 register and accept offer Cerberus test
status: todo
type: task
priority: low
created_at: 2026-03-12T17:07:26Z
updated_at: 2026-03-12T17:07:57Z
---

test/features/register_and_accept_offer_cerberus_test.exs is extremely slow under EV2/Cerberus Firefox runs. Profile where the time goes and decide whether the slowness is from axe, browser readiness, app state setup, or an assertion retry loop.
