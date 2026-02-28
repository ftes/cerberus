---
# cerberus-ozra
title: Fix migration verification timeout in CI
status: in-progress
type: bug
priority: normal
created_at: 2026-02-28T19:40:12Z
updated_at: 2026-02-28T19:40:16Z
parent: cerberus-it5x
---

Migration verification step times out in CI while running rows via System.cmd in Cerberus.MigrationVerification.run_mix_test/5. Reproduce, identify bottleneck, and make runtime deterministic under CI timeout constraints without reducing row coverage quality.

\n## Todo\n- [ ] Reproduce timeout locally with migration verification test path used in CI.\n- [ ] Identify root cause in runner/execution strategy.\n- [ ] Implement fix to avoid CI timeout while preserving coverage scope.\n- [ ] Validate with targeted and full migration verification runs.\n- [ ] Update docs/config if behavior changed.
