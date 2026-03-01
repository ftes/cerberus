---
# cerberus-9mit
title: 30 second start should include mix.exs dependency step
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:23:12Z
updated_at: 2026-02-28T07:25:32Z
---

## Objective
Update the 30 second start docs so they explicitly include adding the `cerberus` dependency to `mix.exs`.

## Todo
- [x] Find the 30 second start section
- [x] Add dependency step and example in docs
- [x] Run mix format (if needed for changed files)
- [x] Verify docs read cleanly
- [x] Add summary and complete bean

## Summary of Changes
- Updated the README 30-Second Start section to explicitly mention adding `{:cerberus, github: "ftes/cerberus"}` in `mix.exs`.
- Kept the section concise by removing extra install ceremony and preserving the first runnable flow example.
- Ran `mix format` and `mix precommit` to verify repository checks remained green.
