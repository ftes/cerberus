---
# cerberus-9xq7
title: Restructure README and browser docs
status: completed
type: task
priority: normal
created_at: 2026-03-04T07:49:34Z
updated_at: 2026-03-04T07:53:51Z
---

Implement doc structure cleanup requested by user.

- [x] Tighten Cerberus moduledoc to technical/module-focused content
- [x] Remove README progressive examples and link to Getting Started
- [x] Shorten README locator quick look and point to cheat sheet
- [x] Update README 30-second example with mode switching and chrome install task
- [x] Replace README debugging snapshots with single snippet (open_browser/snapshot/render_html)
- [x] Move browser overrides/defaults/runtime setup from README into docs/browser-tests.md
- [x] Add/verify doc links from README to Getting Started, Cheat Sheet, Browser tests
- [x] Run formatting/checks relevant to touched files
- [x] Update bean summary and mark completed

## Summary of Changes
- Rewrote Cerberus moduledoc to be module-technical and removed README-style quick-look content.
- Slimmed README: removed Progressive Examples, moved mode-switching into the 30-second section, and added a Chrome install step.
- Replaced long locator quick look with a short selector strategy and links to Getting Started + Cheat Sheet.
- Replaced debugging section with one snippet showing open_browser (human), snapshot artifact pattern via open_browser callback (human/AI), and render_html (AI).
- Moved browser-heavy sections out of README into a new docs/browser-tests.md guide.
- Updated README Learn More links to include the new Browser Tests Guide.
- Ran mix format, mix credo lib/cerberus.ex, and mix test test/cerberus/options_test.exs.
