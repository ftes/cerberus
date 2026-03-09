---
# cerberus-uywj
title: Trim slow locator parity category tests further
status: completed
type: task
priority: normal
created_at: 2026-03-09T11:50:31Z
updated_at: 2026-03-09T12:00:12Z
---

## Scope

- [ ] Profile the split locator parity modules to find which cases still dominate runtime.
- [ ] Decide whether to trim repeated browser setup, reuse sessions differently, or reduce avoidable duplicated assertions without shrinking intended coverage.
- [ ] Implement the smallest clean cut that materially reduces slow-lane time.
- [ ] Re-run targeted parity coverage plus full regular and slow lanes.
- [x] Record before/after timing and summarize the decision.

## Summary of Changes

- Profiled the split locator parity file and found the dominant costs were repeated browser session startup plus unnecessary page reinjection for read-only parity cases.
- Kept the heavy composition and count/scope categories split for parallelism, but merged the lighter follow-up, assertions, and form-control rows onto one shared setup_all browser session.
- Added host-only handling for driver-independent locator validation cases and cached browser/static fixture sessions across consecutive read-only parity cases that reuse the same HTML.
- Reduced the targeted locator parity file from about 9.2s to 7.6s and improved the full slow lane from 21.4s to 20.2s.
