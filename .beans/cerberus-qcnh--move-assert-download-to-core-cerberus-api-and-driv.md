---
# cerberus-qcnh
title: Move assert_download to core Cerberus API and driver dispatch
status: completed
type: task
priority: normal
created_at: 2026-03-03T21:49:37Z
updated_at: 2026-03-03T22:00:40Z
parent: cerberus-ql0l
---

Make assert_download/3 a global Cerberus API, remove it from Cerberus.Browser, and dispatch by driver behaviour implementation for static/live/browser consistency.

## Summary of Changes

Moved assert_download/3 to the core Cerberus API and driver dispatch layer. Added Cerberus.Driver callback assert_download/3 and implementations for browser, static, and live drivers. Removed assert_download/3 from Cerberus.Browser. Introduced shared static/live header assertion helper module. Live driver now uses the shared LiveView timeout/retry loop to wait for live-to-static redirect before asserting download headers. Added delayed live redirect fixture coverage and cross-driver test coverage (phoenix + browser), plus updated docs to reference core assert_download/3 usage.
