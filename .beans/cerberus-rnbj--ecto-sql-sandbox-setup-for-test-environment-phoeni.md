---
# cerberus-rnbj
title: Ecto SQL sandbox setup for test environment (PhoenixTestPlaywright parity)
status: in-progress
type: bug
priority: normal
created_at: 2026-02-27T18:25:35Z
updated_at: 2026-02-27T18:35:30Z
---

Implement Ecto SQL Sandbox setup for test runs, aligned with PhoenixTestPlaywright patterns and official Ecto test environment guidance.

Scope:
- Configure test-time Ecto SQL sandbox ownership/checkout according to Ecto instructions.
- Integrate sandbox behavior with Cerberus browser/static/live test harnesses.
- Avoid introducing a required *Case module unless technically unavoidable.
- If a *Case module is required, provide a minimal one and document why.

Acceptance criteria:
- Browser-oriented tests can safely use DB state under sandbox isolation.
- Setup follows Ecto SQL sandbox recommendations for tests.
- Any required docs are updated to explain usage and constraints.
