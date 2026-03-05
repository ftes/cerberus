---
# cerberus-gewx
title: PTP async Ecto sandbox teardown owner-exited noise
status: in-progress
type: bug
priority: normal
created_at: 2026-03-05T14:16:18Z
updated_at: 2026-03-05T20:35:26Z
parent: cerberus-vhzg
---

## Problem
PhoenixTestPlaywright integration runs still emit noisy SQL sandbox teardown errors from async LiveView tasks even when assertions pass.

## Current Impact
- Test output is noisy and can mask real failures.
- Full suite runs become harder to trust because benign noise looks like hard failures.
- Under higher parallelism this may become flaky failure instead of log noise.

## Observed Symptoms
During or after PTP runs, logs include:
- Postgrex.Protocol disconnected with DBConnection.ConnectionError owner pid exited
- DBConnection.OwnershipError cannot find ownership process for Task.Supervised using mode manual
- Task.Supervised errors from async assign tasks in fixture live view code

Common stack traces point to:
- test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex line 46 and line 47 in mount with assign_async
- line 55 version_query
- line 60 long_running_query

## Why This Happens
The LiveView under test starts async tasks that perform Repo queries. On test teardown, the SQL sandbox owner process exits and the connection is checked in before those async tasks finish or are cancelled, so the tasks try to use a repo connection that no longer has ownership.

## Conceptual Reproduction
1. Load test env variables and run browser-backed PTP tests with a random port.
2. Run either targeted ecto sandbox suites or a broader PTP suite where ecto live fixtures are included.
3. Observe that test assertions may pass, but teardown prints owner exited and ownership errors from async tasks.

Representative commands:
- PORT=4xxx source .envrc and mix test test/cerberus/phoenix_test_playwright/playwright/ecto_sandbox_test.exs test/cerberus/phoenix_test_playwright/playwright/ecto_sandbox_async_false_test.exs
- PORT=4xxx source .envrc and mix test test/cerberus/phoenix_test_playwright --max-cases 4

## Suspected Root Cause
Sandbox ownership and async task lifecycle are not synchronized for this fixture path. LiveView async query tasks can outlive the test owner and outlive browser session teardown.

## Proposed Fix Options
Option A
- Ensure async tasks are cancelled before sandbox owner exits.
- Add deterministic shutdown or wait in fixture or test teardown path so LiveView async jobs do not keep querying after owner process termination.

Option B
- Ensure spawned async query processes are explicitly allowed for sandbox usage and tied to owner lifecycle.
- Revisit how sandbox metadata and process allowance are propagated to assign_async jobs.

Option C
- Make fixture async query functions resilient to teardown by catching expected ownership shutdown errors and returning controlled values.
- Keep this as a fallback only, since it hides symptoms but may not fix lifecycle ordering.

## Implementation Targets
- test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex
- test/support/phoenix_test_playwright/case.ex
- any sandbox setup or teardown helper used by these tests

## Acceptance Criteria
- No owner exited or ownership errors in normal passing runs of the two ecto sandbox test files.
- No teardown noise from this root cause when running full PTP suite in moderate parallel mode.
- Existing ecto sandbox assertions continue to pass.
