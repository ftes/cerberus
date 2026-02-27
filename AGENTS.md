IMPORTANT: before you do anything else, run the `beans prime` command and heed its output.

## General Guidelines
- Keep it simple: choose the least complex approach that satisfies the requirement.
- Deliver vertical slices end-to-end whenever possible (API + drivers + harness coverage for the slice).
- Prefer the browser-oracle harness approach to validate HTML/browser behavior and catch static/live semantic drift.
- Update docs when behavior, API semantics, architecture, or harness strategy changes.
- Commit in small increments and run `mix precommit` before each commit.
- Browser runtime policy:
  - Use a single shared browser process.
  - Use a single shared BiDi connection (per worker/runtime) and multiplex messages by command id.
  - Use an isolated browser context per test for state isolation (not just separate tabs).
