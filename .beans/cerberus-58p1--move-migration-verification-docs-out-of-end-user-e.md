---
# cerberus-58p1
title: Move migration-verification docs out of end-user ExDoc guides
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T16:13:51Z
---

Finding follow-up: contributor/internal migration verification docs are currently included in published ExDoc extras.

## Scope
- Keep maintainer docs in repo
- Exclude internal workflow docs from public end-user docs nav
- Ensure docs set focuses on user-relevant API behavior

## Acceptance
- ExDoc guides no longer include internal migration verification workflow pages

## Summary of Changes

- Removed internal migration verification pages from published ExDoc extras and guide groups in mix.exs.
- Updated README to remove public ExDoc-facing migration verification matrix link and shifted migration verification note to maintainer-focused docs in-repo.
- Verified docs generation remains warning-free with mix docs --warnings-as-errors --formatter html.
