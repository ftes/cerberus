---
# cerberus-d9r2
title: BiDi browser support policy beyond Chrome and Firefox
status: completed
type: task
priority: normal
created_at: 2026-02-28T07:07:19Z
updated_at: 2026-02-28T07:34:08Z
parent: cerberus-ykr0
---

Evaluate which additional browsers should be supported via WebDriver BiDi and document support policy and constraints.

## Todo
- [x] Inventory current browser runtime assumptions in code/docs
- [x] Define support tiers and constraints for additional browsers
- [x] Document policy in guides/README
- [x] Run mix format and mix precommit
- [x] Add summary and complete bean

## Summary of Changes
- Added a new browser support policy guide (`docs/browser-support-policy.md`) with explicit Tier 1/Tier 2/Tier 3 support definitions and admission criteria.
- Documented current runtime constraints (Chrome-specific BiDi handshake/capabilities and Chrome/ChromeDriver setup expectations).
- Linked the policy from README and included it in ExDoc extras/groups so it ships with published docs.
- Ran `mix format` and `mix precommit` to keep checks green.
