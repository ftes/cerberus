---
# cerberus-nhps
title: Integrate branding images into README and ExDoc
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:09:05Z
updated_at: 2026-02-27T22:13:36Z
---

Add the provided hero and logo images to project docs.

## Todo
- [x] Inspect existing README and ExDoc asset/layout conventions
- [x] Add Image #1 and Image #2 to repository assets in stable paths
- [x] Update README to render both images cleanly
- [x] Update ExDoc config/pages so both images are included in generated docs
- [x] Run mix format after doc changes
- [x] Verify docs render references and summarize changes

## Summary of Changes
- Added hero and icon rendering to README using project-relative image paths (docs/hero.png and docs/icon.png).
- Updated ExDoc config to keep README.md as the main page, copy docs/ into generated docs via assets mapping, and set logo: docs/icon.png so the icon appears in the top-left ExDoc header area.
- Verified docs generation with mix docs; confirmed image references are present and assets are copied into output.
