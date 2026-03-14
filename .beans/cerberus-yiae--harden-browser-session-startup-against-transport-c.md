---
# cerberus-yiae
title: Harden browser session startup against transport-close init failures
status: in-progress
type: bug
created_at: 2026-03-14T22:54:39Z
updated_at: 2026-03-14T22:54:39Z
---

Investigate remaining Chrome CI Mint.TransportError(:closed) failures during browser driver initialization, fix the startup path in Browser/UserContextProcess/Runtime as needed, and verify the impacted tests.
