---
# cerberus-3j23
title: Re-verify browser suite stability at max_cases 28
status: completed
type: task
priority: normal
created_at: 2026-03-09T11:10:18Z
updated_at: 2026-03-09T11:12:30Z
---

## Scope

- [ ] Raise ExUnit max_cases back to 28.
- [ ] Run full test and slow lanes with random ports.
- [ ] Keep the change only if the suite stays green and throughput is acceptable.
- [x] Record the result and update docs/notes if needed.

## Summary of Changes

- Restored ExUnit max_cases to 28 in test/test_helper.exs.
- Re-ran the full non-slow lane and the full slow lane with random ports.
- The suite stayed green at 28 on the current Chrome + ChromeDriver + Bibbidi stack.

## Verification

- PORT=4847 MIX_ENV=test mix do format + precommit + test
  - 559 tests, 0 failures, 4 skipped (31 excluded)
- PORT=4848 MIX_ENV=test mix test --only slow
  - 31 tests, 0 failures (559 excluded)
