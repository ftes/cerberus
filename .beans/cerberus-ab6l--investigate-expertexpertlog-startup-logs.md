---
# cerberus-ab6l
title: Investigate .expert/expert.log startup logs
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:27:33Z
updated_at: 2026-03-03T19:29:59Z
---

User asked why lib/cerberus/.expert/expert.log contains OTP application startup and ssl handler logs, and whether this indicates bad LSP config.

## Todo
- [x] Locate code path that writes/redirects .expert/expert.log
- [x] Confirm whether log lines are expected runtime startup messages
- [x] Explain root cause and any config change to reduce noise

## Summary of Changes
Investigated lib/cerberus/.expert/expert.log and confirmed the shown lines are normal Expert/OTP startup logs at debug verbosity, not an LSP root-detection failure.

Key findings:
- Log contains XPExpert/xp_gen_lsp startup and standard OTP app/supervisor boot entries, including ssl logger handler startup.
- The same session in that log resolved project root_uri to file:///Users/ftes/src/cerberus and mix_exs_uri to file:///Users/ftes/src/cerberus/mix.exs.
- That indicates workspace detection was correct for the session despite the log file location under lib/cerberus/.expert.
- Additional non-startup issues were found in .expert/project.log (e.g. CHROME env missing during config/test.exs evaluation), but those are separate from the startup log snippet.
