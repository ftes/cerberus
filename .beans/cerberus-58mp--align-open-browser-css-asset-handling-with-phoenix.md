---
# cerberus-58mp
title: Align open_browser CSS asset handling with PhoenixTest
status: completed
type: feature
priority: normal
created_at: 2026-03-04T18:52:19Z
updated_at: 2026-03-04T18:59:06Z
---

Implement open_browser HTML rewrite so stylesheet/script asset URLs resolve correctly from local snapshot files, mirroring PhoenixTest/Playwright behavior. Add tests that validate rewritten app.css path resolution in open_browser output.

## Summary of Changes
- Mirrored PhoenixTest open_browser static-asset handling in Cerberus: root-relative src/href values are rewritten to file:// paths under endpoint priv/static, script tags are stripped, and anchor href values are left untouched.
- Extended snapshot writing to accept endpoint context so static/live/browser open_browser paths can be rewritten consistently.
- Added a dedicated fixture page at /styled-snapshot that links /assets/app.css and includes a script tag.
- Added priv/static/assets/app.css fixture asset used by open_browser tests.
- Added integration parity coverage asserting open_browser output contains a local file:// stylesheet href that points to an existing app.css file path, and that script tags are removed.
- Verified with targeted runs: open_browser behavior suite plus representative open_browser tests in cerberus_test.
