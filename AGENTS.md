IMPORTANT: before you do anything else, run the `beans prime` command and heed its output.
Don't include backticks in the text you pass to beans - this WILL cause shell expansion.

## You're not alone
Other agents may be running (beans in-progress).
Pick next bean that won't lead to edit conflicts.
Ignore other changes in git - commit your changes only.
Run tests with random `PORT=4xxx` env var.

## Be autonomous
Read a lot up front. Try to ask all questions up front.
Then implement, ideally without asking again.
Keep a log of what you did to present when you're done.

## General Guidelines
- Keep it simple: choose the least complex approach that satisfies the requirement.
- Deliver vertical slices end-to-end whenever possible (API + drivers + harness coverage for the slice).
- `source .envrc` before running tests to get browser version env vars.
- Run targeted `mix test` often after changing files.
- Run `mix format` after each logical change set (and before tests/precommit), since precommit checks formatting and does not rewrite files.
- Commit in small increments and run `MIX_ENV=test mix do format + precommit + test` before each commit.
- Cerberus is unreleased. Don't preserve backwards compatability. KISS. Don't warn about legacy arguments or functions. Always remove and change with a clean cut.
- Codex: Run real-browser tests outside the Codex sandbox (escalated permissions), since Chrome startup can fail inside the sandbox.
- If public API/behavior/examples changed, update docs in the same change (`README.md`, relevant guides, moduledocs).
- Current browser policy: run Chrome only. Ignore Firefox and websocket lanes locally and in CI unless explicitly requested.
- If in doubt about static/live driver behavior, check PhoenixTest static and live driver implementations for reference patterns.
- If in doubt about browser driver behavior, use Cuprite as the primary implementation reference; use Playwright JS as the secondary reference.
- Tests should default to parity coverage across applicable drivers. Only keep a test driver-specific when it is explicitly asserting driver-specific behavior.
- There is NO `@tag :browser`. Don't try to filter tests with `--only browser` or `--exclude browser`. Running browser tests is cheap and fine.
- All public functions need good typespecs. Avoid generic types (`map()`, `Keyword.t()`). Prefer specific types (structs, NimbleOptions).
