---
# cerberus-g0jq
title: 'Browser driver slice 1: minimal BiDi one-shot text assertions'
status: todo
type: task
priority: normal
created_at: 2026-02-27T07:41:28Z
updated_at: 2026-02-27T08:15:04Z
parent: cerberus-sfku
blocked_by:
    - cerberus-k4m0
---

## Scope
Implement minimal Browser driver over WebDriver BiDi for one-shot `visit/click/assert_has/refute_has`.

## Details
- use BiDi session transport (no CDP/classic webdriver APIs).
- start with Chromium path; Firefox compatibility tracked separately.
- evaluate text assertions in-page and return structured observed data.

## Technical Steps
- [ ] establish BiDi session + navigation.
- [ ] implement click by text locator for deterministic fixtures.
- [ ] implement one-shot text lookup + matching.
- [ ] capture page URL/title/raw matches for diagnostics.

## Done When
- [ ] browser driver can execute slice 1 conformance scenarios.
- [ ] failures include page-side observed values.
