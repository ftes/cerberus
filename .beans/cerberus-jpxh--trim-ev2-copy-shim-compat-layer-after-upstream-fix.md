---
# cerberus-jpxh
title: Trim ev2-copy shim compat layer after upstream fixes
status: in-progress
type: task
priority: normal
created_at: 2026-03-05T20:35:11Z
updated_at: 2026-03-05T20:36:08Z
---

Audit ../ev2-copy shim compat helpers against current Cerberus.PhoenixTestShim support, remove unnecessary compat wrappers, and re-run affected tests.

- [ ] Identify wrappers now fully covered by Cerberus.PhoenixTestShim
- [ ] Remove low-risk redundant wrappers from ev2-copy compat
- [ ] Run targeted ev2-copy shim-using tests with random PORT
- [ ] Iterate on remaining wrappers based on failures
- [ ] Document what still must remain in compat
