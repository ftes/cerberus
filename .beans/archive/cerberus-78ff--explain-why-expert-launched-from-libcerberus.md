---
# cerberus-78ff
title: Explain why Expert launched from lib/cerberus
status: completed
type: task
priority: normal
created_at: 2026-03-03T19:37:08Z
updated_at: 2026-03-03T19:37:27Z
---

Follow-up: user asked why Expert would launch in lib/cerberus.

## Todo
- [x] Infer launch context from existing logs/process behavior
- [x] Explain practical causes and prevention

## Summary of Changes
Confirmed from timestamps and file contents that lib/cerberus/.expert was created in a short session (20:18:37 to 20:18:52) and only contains expert.log. This pattern indicates Expert was started with current working directory set to lib/cerberus for that session; afterward it still detected project root_uri as /Users/ftes/src/cerberus via opened file/mix.exs discovery.

Practical causes include opening lib/cerberus as a standalone workspace or an editor/plugin launching the language server from the file directory instead of repository root.
