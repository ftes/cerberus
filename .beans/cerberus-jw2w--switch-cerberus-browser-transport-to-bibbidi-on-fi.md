---
# cerberus-jw2w
title: Switch Cerberus browser transport to bibbidi on Firefox
status: completed
type: task
priority: normal
created_at: 2026-03-09T08:12:49Z
updated_at: 2026-03-09T09:02:53Z
---

## Scope

- [ ] Replace the current browser transport/runtime layer with Bibbidi-based Firefox execution.
- [ ] Use the project-installed Firefox runtime from the existing install-task locations.
- [ ] Keep Cerberus browser driver semantics working with a clean cut, removing obsolete Chrome/ChromeDriver-specific transport code and docs.
- [x] Run focused browser verification and update docs/config for the Firefox+Bibbidi model.

## Notes

- User explicitly requested Firefox and Bibbidi.
- Clean cut: do not preserve the current Chrome-first browser transport as an active path.
- Reuse existing Cerberus browser driver layers where practical, but replace the runtime/connection substrate rather than wrapping both stacks in parallel.

## Summary of Changes

- Switched the active browser runtime to Firefox launched via Bibbidi.Browser and replaced the old WebDriver/BiDi socket transport with Bibbidi.Connection.
- Removed obsolete WebDriver transport modules and stale websocket transport tests, plus the dead firefox_args option that Bibbidi does not support.
- Fixed Firefox submit and link-navigation readiness semantics so standard HTML form submits and real link navigations wait correctly, while LiveView non-navigation submits still skip post-action readiness.
- Capped ExUnit concurrency at max_cases 8 because the single shared Firefox/Bibbidi lane saturates under the old suite-wide parallelism.
- Verified with focused browser bundles and with MIX_ENV=test mix do format + precommit + test + test --only slow.
