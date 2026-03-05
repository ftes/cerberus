---
# cerberus-xamy
title: Fix chrome-current symlink startup crash without envrc
status: completed
type: bug
priority: normal
created_at: 2026-03-05T18:27:30Z
updated_at: 2026-03-05T18:44:14Z
---

Reproduce and fix mix test --failed startup cascades caused by managed Chrome startup when CHROME env is unset and runtime falls back to tmp/chrome-current symlink. Ensure fallback resolves to real executable path so app bundle frameworks load correctly.

## Summary of Changes
- Resolved managed Chrome fallback startup crashes when CHROME env is unset by resolving symlink targets to real executable paths in Cerberus.Driver.Browser.Runtime.
- Fixed Playwright fixture routing split so static routes remain on non-CSRF pipeline and live routes use CSRF pipeline, removing a large regression set in mix test --failed.
- Fixed session recycle behavior in Cerberus.Phoenix.Conn by excluding request cookie headers from preserved headers, allowing configure_session(drop: true) logout flows to actually clear auth state.
- Verified with mix test --failed, targeted Playwright assertion and static regression tests, full mix test, and mix test --only slow.

## Validation
- source .envrc && PORT=4713 mix test --failed
- source .envrc && PORT=4712 mix test test/cerberus/password_auth_flow_test.exs
- source .envrc && PORT=4721 mix test test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs:214
- source .envrc && PORT=4722 mix test test/cerberus/phoenix_test_playwright/upstream/static_test.exs:197
- source .envrc && PORT=4765 mix test
- source .envrc && PORT=4766 mix test --only slow

## Summary of Changes
- Resolved managed Chrome fallback startup crashes when  env is unset by resolving symlink targets to real executable paths in .
- Fixed Playwright fixture routing split so static routes remain on non-CSRF pipeline and live routes use CSRF pipeline, removing a large regression set in Running ExUnit with seed: 309754, max_cases: 28
Excluding tags: [slow: true]

***********************************************************************
Finished in 0.1 seconds (0.00s async, 0.1s sync)
71 tests, 0 failures, 71 skipped.
- Fixed session recycle behavior in  by excluding request  headers from preserved headers, allowing  logout flows to actually clear auth state.
- Verified with Running ExUnit with seed: 974528, max_cases: 28
Excluding tags: [slow: true]

***********************************************************************
Finished in 0.1 seconds (0.00s async, 0.1s sync)
71 tests, 0 failures, 71 skipped, targeted Playwright assertion/static regression tests, full Running ExUnit with seed: 629736, max_cases: 28
Excluding tags: [slow: true]

**..........................................................................................................******************........................................................................................................................................................................*..........................................*............................................................................*...................................*..............................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................................
19:41:13.937 [error] Postgrex.Protocol (#PID<0.309.0> ("db_conn_1")) disconnected: ** (DBConnection.ConnectionError) owner #PID<0.7949.0> exited

Client #PID<0.7966.0> (Task.Supervised) is still using a connection from owner at location:

    (erts 16.2.2) :prim_inet.recv0/3
    (postgrex 0.22.0) lib/postgrex/protocol.ex:3272: Postgrex.Protocol.msg_recv/4
    (postgrex 0.22.0) lib/postgrex/protocol.ex:2274: Postgrex.Protocol.recv_bind/3
    (postgrex 0.22.0) lib/postgrex/protocol.ex:2199: Postgrex.Protocol.bind_execute/4
    (ecto_sql 3.13.4) lib/ecto/adapters/sql/sandbox.ex:412: Ecto.Adapters.SQL.Sandbox.Connection.proxy/3
    (db_connection 2.9.0) lib/db_connection/holder.ex:356: DBConnection.Holder.holder_apply/4
    (db_connection 2.9.0) lib/db_connection.ex:1539: DBConnection.run_execute/5
    (db_connection 2.9.0) lib/db_connection.ex:1587: DBConnection.run_with_retries/5
    (db_connection 2.9.0) lib/db_connection.ex:791: DBConnection.parsed_prepare_execute/5
    (db_connection 2.9.0) lib/db_connection.ex:783: DBConnection.prepare_execute/4
    (postgrex 0.22.0) lib/postgrex.ex:319: Postgrex.query_prepare_execute/4
    (ecto_sql 3.13.4) lib/ecto/adapters/sql.ex:620: Ecto.Adapters.SQL.query!/4
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:60: Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.long_running_query/1
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:47: anonymous fn/1 in Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.mount/3
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:141: anonymous fn/2 in Phoenix.LiveView.Async.assign_async/4
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:289: Phoenix.LiveView.Async.do_async/5
    (elixir 1.19.5) lib/task/supervised.ex:105: Task.Supervised.invoke_mfa/2

The connection itself was checked out by #PID<0.7966.0> (Task.Supervised) at location:

    (postgrex 0.22.0) lib/postgrex.ex:319: Postgrex.query_prepare_execute/4
    (ecto_sql 3.13.4) lib/ecto/adapters/sql.ex:620: Ecto.Adapters.SQL.query!/4
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:60: Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.long_running_query/1
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:47: anonymous fn/1 in Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.mount/3
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:141: anonymous fn/2 in Phoenix.LiveView.Async.assign_async/4
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:289: Phoenix.LiveView.Async.do_async/5
    (elixir 1.19.5) lib/task/supervised.ex:105: Task.Supervised.invoke_mfa/2



19:41:13.940 [error] Task #PID<0.7967.0> started from #PID<0.7964.0> terminating
** (DBConnection.OwnershipError) cannot find ownership process for #PID<0.7967.0> (Task.Supervised)
using mode :manual.

When using ownership, you must manage connections in one
of the four ways:

* By explicitly checking out a connection
* By explicitly allowing a spawned process
* By running the pool in shared mode
* By using :caller option with allowed process

The first two options require every new process to explicitly
check a connection out or be allowed by calling checkout or
allow respectively.

The third option requires a {:shared, pid} mode to be set.
If using shared mode in tests, make sure your tests are not
async.

The fourth option requires [caller: pid] to be used when
checking out a connection from the pool. The caller process
should already be allowed on a connection.

If you are reading this error, it means you have not done one
of the steps above or that the owner process has crashed.

See Ecto.Adapters.SQL.Sandbox docs for more information.
    (ecto_sql 3.13.4) lib/ecto/adapters/sql.ex:1110: Ecto.Adapters.SQL.raise_sql_call_error/1
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:55: Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.version_query/0
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:50: anonymous fn/1 in Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.mount/3
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:141: anonymous fn/2 in Phoenix.LiveView.Async.assign_async/4
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:289: Phoenix.LiveView.Async.do_async/5
    (elixir 1.19.5) lib/task/supervised.ex:105: Task.Supervised.invoke_mfa/2
Function: #Function<7.55729389/0 in Phoenix.LiveView.Async.run_async_task/5>
    Args: []

19:41:13.941 [error] Task #PID<0.7966.0> started from #PID<0.7964.0> terminating
** (DBConnection.ConnectionError) tcp recv: closed (the connection was closed by the pool, possibly due to a timeout or because the pool has been terminated)
    (ecto_sql 3.13.4) lib/ecto/adapters/sql.ex:1113: Ecto.Adapters.SQL.raise_sql_call_error/1
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:60: Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.long_running_query/1
    (cerberus 0.1.3) test/support/fixtures/phoenix_test_playwright/playwright/ecto_live.ex:47: anonymous fn/1 in Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive.mount/3
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:141: anonymous fn/2 in Phoenix.LiveView.Async.assign_async/4
    (phoenix_live_view 1.1.25) lib/phoenix_live_view/async.ex:289: Phoenix.LiveView.Async.do_async/5
    (elixir 1.19.5) lib/task/supervised.ex:105: Task.Supervised.invoke_mfa/2
Function: #Function<7.55729389/0 in Phoenix.LiveView.Async.run_async_task/5>
    Args: []
...................***************..................................................................*********************************.............................................................***************************************************************************************************************************************************
Finished in 272.8 seconds (120.1s async, 152.7s sync)
1302 tests, 0 failures, 219 skipped (3 excluded), and Running ExUnit with seed: 354954, max_cases: 28
Excluding tags: [:test]
Including tags: [:slow]

...
Finished in 29.9 seconds (29.9s async, 0.00s sync)
3 tests, 0 failures (1302 excluded).

## Validation
- source .envrc && PORT=4713 mix test --failed
- source .envrc && PORT=4712 mix test test/cerberus/password_auth_flow_test.exs
- source .envrc && PORT=4721 mix test test/cerberus/phoenix_test_playwright/upstream/assertions_test.exs:214
- source .envrc && PORT=4722 mix test test/cerberus/phoenix_test_playwright/upstream/static_test.exs:197
- source .envrc && PORT=4765 mix test
- source .envrc && PORT=4766 mix test --only slow
