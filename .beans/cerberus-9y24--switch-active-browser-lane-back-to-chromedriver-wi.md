---
# cerberus-9y24
title: Switch active browser lane back to ChromeDriver with Bibbidi transport
status: completed
type: task
priority: normal
created_at: 2026-03-09T09:39:46Z
updated_at: 2026-03-09T09:50:49Z
---

## Scope

- [ ] Restore Chrome + ChromeDriver as the active browser runtime/session bootstrap path.
- [ ] Keep Bibbidi.Connection as the BiDi websocket transport.
- [ ] Remove Firefox-only runtime assumptions and restore Chrome-specific config/install/docs.
- [x] Re-run focused browser verification plus full quality gates and compare concurrency behavior.

## Summary of Changes

- Restored the Chrome + ChromeDriver runtime/session bootstrap path while keeping Bibbidi.Connection as the active BiDi websocket transport.
- Removed the extra Bibbidi session.new handshake on WebDriver-provided webSocketUrl endpoints, which fixed ChromeDriver session creation failures.
- Restored Chrome-focused runtime/config/bootstrap defaults and reset the active browser driver to Chrome.
- Removed the Firefox/Bibbidi-specific suite cap and set ExUnit max_cases to 16 as the stable concurrency point for the restored Chrome path.
- Verified focused browser bundles at max_cases 28, measured the full suite at max_cases 16, and ran MIX_ENV=test mix do format + precommit + test + test --only slow successfully.
