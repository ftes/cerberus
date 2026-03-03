---
# cerberus-hvxh
title: Fix browser static upload filename parity
status: completed
type: bug
priority: normal
created_at: 2026-03-03T22:14:17Z
updated_at: 2026-03-03T22:14:49Z
---

Browser multipart upload to fixture endpoint should parse into Plug.Upload so static upload result includes filename like phoenix mode.

## Summary of Changes

- Identified root cause of browser/phoenix static upload mismatch: fixture endpoint lacked Plug.Parsers, so browser multipart requests were not decoded into Plug.Upload params.
- Added Plug.Parsers (urlencoded, multipart, json) to test fixture endpoint.
- Restored strict parity assertion in static upload behavior test to require filename text (Uploaded file: elixir.jpg).
- Verified targeted parity and split timeout suites pass (18 tests, 0 failures).
