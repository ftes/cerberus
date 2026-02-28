---
# cerberus-e4sp
title: Add 4-lane browser CI matrix (local/ws x chrome/firefox)
status: in-progress
type: task
priority: normal
created_at: 2026-02-28T20:40:01Z
updated_at: 2026-02-28T21:56:15Z
---

Restructure CI to run browser-tagged tests in four lanes: local chrome, local firefox, websocket chrome, websocket firefox. Minimize duplicate setup via shared non-browser setup and reusable matrix job steps.

## Implementation Checklist

- [x] Create dedicated explicit browser test module tagged explicit_browser
- [x] Keep default browser tests on :browser and remove explicit lane overrides from shared suites
- [x] Add CI browser matrix for local/ws x chrome/firefox regular browser tests
- [x] Add separate explicit-browser CI lane with both local browsers installed
- [x] Update docs/examples that reference moved tests
- [x] Run format and targeted validation commands

## Work Log

- Reviewed existing CI workflow, browser install scripts, and current explicit browser-tagged tests.

- Ran validation: mix precommit; mix test.websocket --browsers chrome,firefox test/core/explicit_browser_test.exs; mix test.websocket --browsers chrome test/core/browser_tag_showcase_test.exs; local chrome lane for browser_tag_showcase passes.

- After first CI run failed, removed leftover websocket/non-browser conformance steps from Checks job and switched matrix regular lanes to run conformance (excluding explicit_browser).

- Simplified CI to a single sequential pipeline: run full default suite once, then re-run browser-driver test files in websocket chrome, local firefox, and websocket firefox lanes without matrix.

- Fixed CI env propagation for browser binaries by stripping 'export ' prefixes before writing to GITHUB_ENV.

- Switched explicit browser lane selection to top-level ExUnit tags (:chrome/:firefox) and taught Harness.drivers/1 to derive lanes from top-level driver tags instead of legacy drivers: [...] tags.

- Removed all ExUnit drivers: [...] tags from test/core, switched Harness driver selection to top-level tags only, and updated CI/README browser selectors to match top-level browser tags.

- Restored pre-migration override semantics by adding explicit false tags where test-level selections should replace module-level tags (for example browser: false, live: false, auto: false, static: false).

- Fixed browser radio/checkbox index mismatches and added multi-select value memory for browser selects, updated timeout assertion examples, tagged firefox-only public API constructor coverage, and adjusted CI to exclude firefox-tagged tests from default lane while keeping local firefox lane best-effort.

- Fixed CI browser-file discovery portability by replacing rg-based selection with find+grep and adding an empty-file-list guard, after websocket lane accidentally ran the full suite when rg was missing in GitHub runner.
