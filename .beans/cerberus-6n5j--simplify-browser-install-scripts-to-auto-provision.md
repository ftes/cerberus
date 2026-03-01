---
# cerberus-6n5j
title: Simplify browser install scripts to auto-provision stable tmp paths
status: completed
type: task
priority: normal
created_at: 2026-03-01T09:40:48Z
updated_at: 2026-03-01T09:45:24Z
---

Refactor bin/chrome.sh and bin/firefox.sh to always install required binaries unless already present at stable versioned paths in tmp.

- [x] remove tmp/browser-tools and env.sh helper-file workflow
- [x] use stable paths like tmp/chrome-<version> and tmp/chromedriver-<version>
- [x] make install default behavior while reusing existing binaries when present
- [x] update docs for new browser setup behavior
- [x] run mix format and mix precommit

## Summary of Changes

- Rewrote bin/chrome.sh to always provision Chrome for Testing and ChromeDriver into stable tmp/chrome-<version> and tmp/chromedriver-<version> directories.
- Rewrote bin/firefox.sh to always provision Firefox and GeckoDriver into stable tmp/firefox-<version> and tmp/geckodriver-<version> directories.
- Removed browser readiness checks and browser-driver compatibility enforcement from both scripts; scripts now only install/reuse binaries and print resolved paths and versions.
- Removed version env-var inputs and kept version selection argument-driven.
- Updated README helper section to use bin/chrome.sh and bin/firefox.sh with version arguments and new tmp path behavior.
- Ran mix format and mix precommit successfully.
