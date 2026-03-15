---
# cerberus-yiae
title: Harden browser session startup against transport-close init failures
status: completed
type: bug
priority: normal
created_at: 2026-03-14T22:54:39Z
updated_at: 2026-03-14T23:06:51Z
---

Investigate remaining Chrome CI Mint.TransportError(:closed) failures during browser driver initialization, fix the startup path in Browser/UserContextProcess/Runtime as needed, and verify the impacted tests.


## Summary of Changes
- added one bounded outer retry around Browser.new_session user-context startup so a transient child-start transport close can recover even when the supervisor child fails before the session is returned
- promoted Mint transport-close detection into the shared TransientErrors helper and reused it from both Browser and UserContextProcess startup retry paths
- added coverage for the transport-close matcher and verified the affected Chrome startup files plus the full precommit gate pass locally


## Summary of Changes
- tracked the remaining Chrome CI failure to stale shared runtime/BiDi state: a transport-close could leave Runtime caching a dead Chrome session and BiDi reusing the broken websocket on the next startup attempt
- added Runtime.reset_session/1 and taught BiDi to reset both its cached connection and the cached runtime session whenever a transport-close is observed or when a connection belongs to the wrong browser lane
- kept the existing bounded startup retry in Browser/UserContextProcess so the next retry now reconnects against a fresh Chrome runtime instead of the dead cached one, then verified the focused startup files, precommit, and a full local Chrome mix test all pass
