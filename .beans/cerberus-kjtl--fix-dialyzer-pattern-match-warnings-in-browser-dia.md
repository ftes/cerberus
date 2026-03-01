---
# cerberus-kjtl
title: Fix dialyzer pattern-match warnings in browser dialog extensions
status: completed
type: bug
priority: normal
created_at: 2026-03-01T20:39:00Z
updated_at: 2026-03-01T20:40:31Z
---

Adjust with_dialog task polling/result handling in lib/cerberus/driver/browser/extensions.ex so dialyzer pattern_match warnings are resolved and mix precommit passes.


## Todo
- [x] Refactor with_dialog task outcome handling to match Task.yield/Task.shutdown return types
- [x] Run focused browser extensions tests
- [x] Run mix precommit and confirm clean
- [x] Commit code + bean file

## Summary of Changes
- Refactored `with_dialog/3` task outcome polling in `lib/cerberus/driver/browser/extensions.ex` to match actual `Task.yield/2` return shapes.
- Removed unreachable `{:exit, reason}` pattern branches that dialyzer flagged as impossible in dialog-open polling and action-result handling.
- Kept callback failure handling in the `:pending` completion path via `Task.shutdown/2` result matching.
- Verified with focused browser extensions tests and full `mix precommit` (now clean).
