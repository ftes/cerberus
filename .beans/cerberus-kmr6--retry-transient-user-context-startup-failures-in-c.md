---
# cerberus-kmr6
title: Retry transient user-context startup failures in Chrome CI
status: completed
type: bug
priority: normal
created_at: 2026-03-14T22:38:12Z
updated_at: 2026-03-14T22:43:25Z
---

Retry browser.createUserContext and related startup steps when Chrome BiDi transport closes transiently during browser session initialization, mirroring existing browsing-context retry behavior.

## Summary of Changes
- added retry-and-cleanup handling around UserContextProcess startup so browser.createUserContext, user-context default configuration, and first browsing-context creation can recover from transient transport-close failures during browser session initialization
- cleanup between attempts now removes any partially created user context and stops the temporary browsing-context supervisor before retrying
- applied the startup retry generically across browser-session startup rather than restricting it to Chrome, while still using the existing configured startup retry count
- verified the original Chrome-sensitive startup files pass locally after the change, along with the transient-errors unit test in both Chrome and Firefox lanes
