---
# cerberus-2mm8
title: Fix EV2 compare sticky shutdown
status: in-progress
type: bug
priority: normal
created_at: 2026-03-14T20:38:58Z
updated_at: 2026-03-14T20:45:39Z
---

Reproduce the sticky shutdown behavior in EV2 compare original/copy runs, identify what keeps the BEAM alive after test execution, and either fix the shutdown path or produce an honest whole-suite timing harness.\n\n- [x] reproduce sticky shutdown in a controlled run\n- [ ] inspect lingering processes/tasks after tests finish\n- [ ] implement the smallest reliable fix or measurement harness\n- [ ] verify compare.original and compare.copy produce honest runtimes sequentially\n- [ ] summarize findings and results
