---
# cerberus-u6j7
title: Update README positioning and docs GitHub links
status: completed
type: task
priority: normal
created_at: 2026-02-27T22:23:47Z
updated_at: 2026-02-27T22:25:04Z
parent: cerberus-zqpu
---

## Objective
Update docs links to point to the GitHub repository and clarify Cerberus differentiation near the top of README.

## Scope
- Add explicit repository/doc links using https://github.com/ftes/cerberus.
- Add a concise section near top of README explaining key difference from PhoenixTest + PhoenixTestPlaywright.
- Emphasize integrated browser driver as HTML-spec oracle and WebDriver BiDi (instead of Playwright) for slim/fast architecture.

## Done When
- [x] README includes GitHub docs/repo links.
- [x] README top section explains Cerberus vs PhoenixTest/PhoenixTestPlaywright focus points.
- [x] Wording is concise and technically precise.

## Summary of Changes
- Added explicit GitHub links near the top of README (repository, docs folder, ADR index).
- Added a top-level section describing Cerberus vs PhoenixTest/PhoenixTest.Playwright, emphasizing browser-oracle semantics and direct WebDriver BiDi integration.
- Updated ExDoc config in mix.exs with source/homepage GitHub links (source_url/source_ref/homepage_url) so docs link back to repository source.

## Follow-up (2026-02-27)
- [x] Revert the GitHub links section in README while keeping the new key-difference section.

## Summary of Changes (Follow-up)
- Removed the README "Repository and docs" GitHub links block.
- Kept the top "Key Difference vs PhoenixTest + PhoenixTest.Playwright" section intact.
