---
# cerberus-ptal
title: Debug EV2 Firefox offer success toast assertion
status: todo
type: bug
created_at: 2026-03-12T10:20:47Z
updated_at: 2026-03-12T10:20:47Z
---

The EV2 Firefox create-offer flow now gets past login and reaches the schedule page, but the final success assertion on and_(css(".toast-success"), text("Offer created")) still fails intermittently even though the DOM contains the toast. Reproduce the locator behavior, determine whether the issue is in Cerberus composed-locator matching or app timing, patch the smallest correct fix, and verify with focused Firefox offer tests.
