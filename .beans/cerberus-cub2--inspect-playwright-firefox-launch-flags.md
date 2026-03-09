---
# cerberus-cub2
title: Inspect Playwright Firefox launch flags
status: completed
type: task
priority: normal
created_at: 2026-03-09T08:09:21Z
updated_at: 2026-03-09T08:10:57Z
---

Question: which flags does Playwright use to launch Firefox, and should Cerberus match them?

- [x] Identify the Playwright version relevant to this workspace
- [x] Read Playwright's Firefox launch argument construction from source
- [x] Summarize the flags and any Cerberus implications

## Summary of Changes

- Verified the current published `playwright-core` release is `1.58.2`.
- Read the packaged source for both Firefox launchers in Playwright 1.58.2: the regular Firefox launcher and the separate BiDi launcher used for `moz-*` channels.
- Regular Playwright Firefox uses `-no-remote`, `-headless` or (`-wait-for-browser`, `-foreground`), `-profile <dir>`, `-juggler-pipe`, then custom args, and finally `-silent` or `about:blank`.
- Playwright's BiDi Firefox launcher uses `--remote-debugging-port=0`, `--headless` or `--foreground`, `--profile <dir>`, then custom args.
- Cerberus implication: if the goal is Firefox BiDi parity, match the BiDi launcher shape rather than the default Juggler launcher. Copying `-juggler-pipe` would be the wrong transport for Cerberus.
