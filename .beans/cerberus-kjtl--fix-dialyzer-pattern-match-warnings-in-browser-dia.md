---
# cerberus-kjtl
title: Fix dialyzer pattern-match warnings in browser dialog extensions
status: in-progress
type: bug
priority: normal
created_at: 2026-03-01T20:39:00Z
updated_at: 2026-03-01T20:40:17Z
---

Adjust with_dialog task polling/result handling in lib/cerberus/driver/browser/extensions.ex so dialyzer pattern_match warnings are resolved and mix precommit passes.


## Todo
- [x] Refactor with_dialog task outcome handling to match Task.yield/Task.shutdown return types
- [x] Run focused browser extensions tests
- [x] Run mix precommit and confirm clean
- [ ] Commit code + bean file
