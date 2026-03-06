---
# cerberus-6xp0
title: Investigate custom documents flow drift under EV2 shim
status: scrapped
type: bug
priority: normal
created_at: 2026-03-05T12:39:59Z
updated_at: 2026-03-06T20:22:35Z
---

EV2-copy: custom_documents_test entire flow is currently skipped. Assertions around startpack/edit links and custom-doc visibility diverge under shim-driven interaction path; needs root-cause and either shim fix or test-only compatibility adapter.

## Reasons for Scrapping
- Cerberus/PhoenixTest shim flows have been removed, so this shim-specific investigation is obsolete.
- Any remaining custom documents drift should be re-opened as a direct Cerberus coverage issue rather than a shim compatibility task.
