---
# cerberus-x0ip
title: Add Dialyxir to precommit
status: completed
type: task
priority: normal
created_at: 2026-02-27T15:08:18Z
updated_at: 2026-02-27T15:10:00Z
---

Add dialyxir dependency, configure dialyzer apps to include :ex_unit, and run dialyzer via mix precommit.\n\n## Todo\n- [x] Add :dialyxir dependency\n- [x] Configure dialyzer to include :ex_unit\n- [x] Add dialyzer to mix precommit alias\n- [x] Verify config compiles/tests command path

## Summary of Changes\n- Added {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false} to deps in mix.exs.\n- Added project dialyzer config with plt_add_apps: [:ex_unit].\n- Added dialyzer to the precommit alias and set preferred_envs for dialyzer to :test.\n- Ran mix deps.get, mix precommit (stopped by existing format issue), and mix dialyzer --format short (task ran; reported existing warnings).
