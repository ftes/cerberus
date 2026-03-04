---
# cerberus-vr4v
title: Preserve click_link/button locator kind in migration
status: completed
type: bug
priority: normal
created_at: 2026-03-04T20:53:31Z
updated_at: 2026-03-04T20:55:46Z
---

Migration currently rewrites click_link/click_button to click with text locators (~l"..."i), which can fail action resolution. Update canonicalization to emit clickable locators preserving original intent (link/button). Add tests for local and remote calls.

\n## Summary of Changes\n- Fixed migration canonicalization so click_link and click_button keep clickable locator intent when renamed to click.\n- click_link now rewrites to click(link: value) and click_button rewrites to click(button: value) for string and regex locators.\n- Added migration tests for local pipeline and remote PhoenixTest call forms to prevent regression.\n- Extended committed fixture-project migration assertions to verify clickable locator rewrite in migrated files.\n- Verified fast and slow migration task test lanes pass.
