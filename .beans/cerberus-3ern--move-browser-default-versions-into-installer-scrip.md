---
# cerberus-3ern
title: Move browser default versions into installer scripts
status: completed
type: task
priority: normal
created_at: 2026-03-12T09:30:47Z
updated_at: 2026-03-12T09:33:05Z
---

Move pinned default browser versions out of Elixir install task code and into bin/chrome.sh and bin/firefox.sh, then simplify CI browser cache keys to depend only on those scripts. Update focused tests and docs.

## Summary of Changes

- moved pinned default browser versions out of Elixir install code and into `bin/chrome.sh` and `bin/firefox.sh`
- simplified Mix install tasks so they only forward an explicit `--version` flag and otherwise defer to installer-script precedence
- reduced the CI browser-runtime cache key to hash only `bin/chrome.sh` and `bin/firefox.sh`
- updated focused install-task tests to match the new task/script contract and refreshed install docs wording
- reran the focused install-task test module successfully
