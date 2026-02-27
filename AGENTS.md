IMPORTANT: before you do anything else, run the `beans prime` command and heed its output.
Don't include backticks when using beans CLI (shell expansion).

## Be autonomous
Read a lot up front. Try to ask all questions up front.
Then implement, ideally without asking again.
Keep a log of what you did to present when you're done.

## General Guidelines
- Keep it simple: choose the least complex approach that satisfies the requirement.
- Deliver vertical slices end-to-end whenever possible (API + drivers + harness coverage for the slice).
- Prefer the browser-oracle harness approach to validate HTML/browser behavior and catch static/live semantic drift.
- Update docs when behavior, API semantics, architecture, or harness strategy changes.
- Run `mix format` after each logical change set (and before tests/precommit), since precommit checks formatting and does not rewrite files.
- Commit in small increments and run `mix precommit` before each commit.
- Browser runtime policy:
  - Use a single shared browser process.
  - Use a single shared BiDi connection (per worker/runtime) and multiplex messages by command id.
  - Use an isolated browser context per test for state isolation (not just separate tabs).
  - Run browser-tagged tests outside the Codex sandbox (escalated permissions), since Chrome startup can fail inside the sandbox.
- If in doubt about static/live driver behavior, check PhoenixTest static and live driver implementations for reference patterns.
- If in doubt about browser driver behavior, use Cuprite as the primary implementation reference; use Playwright JS as the secondary reference.
