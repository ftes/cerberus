---
# cerberus-3b1u
title: Internalize or remove public helper seams session_for_driver and driver_module
status: completed
type: task
priority: normal
created_at: 2026-02-28T15:08:13Z
updated_at: 2026-02-28T17:32:35Z
---

Finding follow-up: hidden helper functions in Cerberus are still publicly callable and used by harness internals.

## Scope
- Remove/relocate public helper API seams not intended for end users
- Update harness internals to avoid reliance on public helper exposure
- Preserve test behavior and failure messages

## Acceptance
- Helpers are no longer accidental public API

## Summary of Changes
- Removed public helper seams Cerberus.session_for_driver/2 and Cerberus.driver_module!/1 from the public root module.
- Internalized driver dispatch in Cerberus and Cerberus.Assertions via private per-session dispatch helpers.
- Updated harness internals to create sessions and validate driver kinds without calling public helper seams.
- Updated tests that depended on the public seam to use public constructors and per-session driver submit dispatch.
- Ran mix format and mix precommit; precommit passed. Focused mix test runs still hit the known sqlite disk I/O lock issue from test/test_helper.exs.

## Summary of Changes
- Removed public helper seams  and  from the public root module.
- Internalized driver dispatch in  and  via private per-session dispatch helpers.
- Updated harness internals to create sessions and validate driver kinds without calling public helper seams.
- Updated tests that depended on the public seam to use public constructors and per-session driver submit dispatch.
- Ran  and Checking 104 source files (this might take a while) ...

Please report incorrect results: https://github.com/rrrene/credo/issues

Analysis took 0.2 seconds (0.02s to load, 0.2s running 69 checks on 104 files)
1604 mods/funs, found no issues.

Use `mix credo explain` to explain issues, `mix credo --help` for options.
Finding suitable PLTs
Checking PLT...
[:asn1, :cerberus, :compiler, :crypto, :eex, :elixir, :elixir_make, :ex_unit, :fine, :inets, :jason, :kernel, :lazy_html, :logger, :mime, :mix, :nimble_options, :phoenix, :phoenix_html, :phoenix_live_view, :phoenix_pubsub, :phoenix_template, :plug, :plug_crypto, :public_key, :ssl, :stdlib, :telemetry, :websock, :websock_adapter, :websockex]
PLT is up to date!
No :ignore_warnings opt specified in mix.exs and default does not exist.

Starting Dialyzer
[
  check_plt: false,
  init_plt: ~c"/Users/ftes/src/cerberus/_build/dev/dialyxir_erlang-28.3.3_elixir-1.19.5_deps-dev.plt",
  files: [~c"/Users/ftes/src/cerberus/_build/dev/lib/cerberus/ebin/Elixir.Cerberus.UploadFile.beam",
   ~c"/Users/ftes/src/cerberus/_build/dev/lib/cerberus/ebin/Elixir.Cerberus.Options.beam",
   ~c"/Users/ftes/src/cerberus/_build/dev/lib/cerberus/ebin/Elixir.Mix.Tasks.Assets.Build.beam",
   ~c"/Users/ftes/src/cerberus/_build/dev/lib/cerberus/ebin/Elixir.Cerberus.Driver.Browser.BiDi.beam",
   ~c"/Users/ftes/src/cerberus/_build/dev/lib/cerberus/ebin/Elixir.Cerberus.Session.beam",
   ...],
  ...
]
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done in 0m1.6s
done (passed successfully)
Generating docs...
View html docs at "doc/index.html"; precommit passed. Focused Running ExUnit with seed: 916271, max_cases: 28

............
18:32:29.027 [error] GenServer #PID<0.756.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.755.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.027 [error] GenServer #PID<0.753.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.752.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.026 [error] GenServer #PID<0.751.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.728.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.046 [error] GenServer #PID<0.818.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.817.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.046 [error] GenServer #PID<0.821.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.820.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


  1) test screenshot + keyboard + dialog + drag browser extensions work together (Cerberus.CoreBrowserExtensionsTest)
     test/core/browser_extensions_test.exs:31
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/core/browser_extensions_test.exs:36: (test)



  2) test screenshot emits PNG output in browser driver (Cerberus.CoreScreenshotBehaviorTest)
     test/core/screenshot_behavior_test.exs:29
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/screenshot_behavior_test.exs:30: (test)



  3) test describe-level browser override describe tag can force firefox only (Cerberus.CoreBrowserTagShowcaseTest)
     test/core/browser_tag_showcase_test.exs:26
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/browser_tag_showcase_test.exs:28: (test)



  4) test module-level drivers tag uses default browser lane (Cerberus.CoreBrowserTagShowcaseTest)
     test/core/browser_tag_showcase_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/browser_tag_showcase_test.exs:14: (test)



  5) test test-level drivers tag can run both browsers in one test (Cerberus.CoreBrowserTagShowcaseTest)
     test/core/browser_tag_showcase_test.exs:39
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/browser_tag_showcase_test.exs:41: (test)

..............
18:32:29.228 [error] GenServer #PID<0.864.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.863.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.228 [error] GenServer #PID<0.868.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.867.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.228 [error] GenServer #PID<0.871.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.870.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


  6) test text assertions behave consistently for static pages in static and browser drivers (Cerberus.CoreCrossDriverTextTest)
     test/core/cross_driver_text_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/cross_driver_text_test.exs:12: (test)



  7) test parallel browser sessions remain isolated under concurrent actions (Cerberus.CoreBrowserMultiSessionBehaviorTest)
     test/core/browser_multi_session_behavior_test.exs:50
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/core/browser_multi_session_behavior_test.exs:53: (test)



  8) test browser open_tab/switch_tab/close_tab workflows are deterministic (Cerberus.CoreBrowserMultiSessionBehaviorTest)
     test/core/browser_multi_session_behavior_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/core/browser_multi_session_behavior_test.exs:14: (test)


18:32:29.275 [error] GenServer #PID<0.875.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.874.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.275 [error] GenServer #PID<0.878.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.877.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


  9) test run! raises one aggregated error when any driver fails (Cerberus.HarnessTest)
     test/cerberus/harness_test.exs:47
     Expected exception ExUnit.AssertionError but got ArgumentError (failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}})
     code: assert_raise ExUnit.AssertionError, ~r/driver conformance failures/, fn ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/cerberus/harness_test.exs:50: (test)



 10) test run executes one scenario per tagged driver (Cerberus.HarnessTest)
     test/cerberus/harness_test.exs:8
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/cerberus/harness_test.exs:12: (test)

......
18:32:29.281 [error] GenServer #PID<0.888.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.887.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.890.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.889.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.892.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.891.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.896.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.895.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.898.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.897.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.902.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.901.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.281 [error] GenServer #PID<0.906.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.905.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 11) test fill_in matches wrapped labels with nested inline text across static and browser drivers (Cerberus.CoreFormActionsTest)
     test/core/form_actions_test.exs:30
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_actions_test.exs:32: (test)


18:32:29.282 [error] GenServer #PID<0.909.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.908.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.282 [error] GenServer #PID<0.912.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.911.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 12) test path assertions with query options are consistent in static and browser drivers (Cerberus.CorePathScopeBehaviorTest)
     test/core/path_scope_behavior_test.exs:31
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/path_scope_behavior_test.exs:32: (test)


18:32:29.282 [error] GenServer #PID<0.915.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.914.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 13) test form plus path flow from docs works across auto and browser (Cerberus.CoreDocumentationExamplesTest)
     test/core/documentation_examples_test.exs:25
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/documentation_examples_test.exs:26: (test)



 14) test select preserves prior multi-select values across repeated calls (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:24
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:25: (test)


18:32:29.284 [error] GenServer #PID<0.919.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.918.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}



18:32:29.284 [error] GenServer #PID<0.922.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.921.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 15) test owner-form submit includes button payload across drivers (Cerberus.CoreFormButtonOwnershipTest)
     test/core/form_button_ownership_test.exs:40
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_button_ownership_test.exs:41: (test)



 16) test static submissions exclude stale fields after form-shape navigation (Cerberus.CoreLiveFormSynchronizationBehaviorTest)
     test/core/live_form_synchronization_behavior_test.exs:28
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_synchronization_behavior_test.exs:29: (test)



 17) test select rejects disabled options (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:61
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/select_choose_behavior_test.exs:63: (test)


18:32:29.285 [error] GenServer #PID<0.925.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.924.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 18) test within scopes static operations and assertions across static and browser (Cerberus.CorePathScopeBehaviorTest)
     test/core/path_scope_behavior_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/path_scope_behavior_test.exs:12: (test)



 19) test click_link, fill_in, and submit are consistent across static and browser drivers (Cerberus.CoreFormActionsTest)
     test/core/form_actions_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_actions_test.exs:13: (test)



 20) test select submits a chosen option across static and browser drivers (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:13: (test)

.

 21) test choose sets the selected radio value across static and browser drivers (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:49
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:50: (test)



 22) test non-submit controls do not clear active form values before submit (Cerberus.CoreFormButtonOwnershipTest)
     test/core/form_button_ownership_test.exs:15
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_button_ownership_test.exs:16: (test)



 23) test button formaction submit follows redirect and preserves button payload (Cerberus.CoreFormButtonOwnershipTest)
     test/core/form_button_ownership_test.exs:70
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_button_ownership_test.exs:71: (test)

....
18:32:29.288 [error] GenServer #PID<0.945.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.944.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
............

 24) test submit clears active form values for subsequent submits (Cerberus.CoreFormButtonOwnershipTest)
     test/core/form_button_ownership_test.exs:54
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_button_ownership_test.exs:55: (test)

..........
18:32:29.372 [error] GenServer #PID<0.1076.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1075.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.372 [error] GenServer #PID<0.1079.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1078.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.373 [error] GenServer #PID<0.1086.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1085.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.374 [error] GenServer #PID<0.1092.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1091.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 25) test evaluate_js and cookie helpers cover add_cookie and session cookie semantics (Cerberus.CoreBrowserExtensionsTest)
     test/core/browser_extensions_test.exs:63
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/core/browser_extensions_test.exs:66: (test)


18:32:29.374 [error] GenServer #PID<0.1103.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1102.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.374 [error] GenServer #PID<0.1108.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1107.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 26) test parity live mismatch fixture is reachable in live and browser drivers (Cerberus.CoreParityMismatchFixtureTest)
     test/core/parity_mismatch_fixture_test.exs:23
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/parity_mismatch_fixture_test.exs:24: (test)

..
18:32:29.375 [error] GenServer #PID<0.1111.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1110.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.376 [error] GenServer #PID<0.1118.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1117.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 27) test parity static mismatch fixture is reachable in static and browser drivers (Cerberus.CoreParityMismatchFixtureTest)
     test/core/parity_mismatch_fixture_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/parity_mismatch_fixture_test.exs:12: (test)



 28) test fill_in does not trigger server-side change when form has no phx-change (Cerberus.CoreLiveFormChangeBehaviorTest)
     test/core/live_form_change_behavior_test.exs:24
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_change_behavior_test.exs:25: (test)

.
18:32:29.377 [error] GenServer #PID<0.1133.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1132.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 29) test assert_has with label-only locator fails when label text is missing (Cerberus.CoreAssertionFilterSemanticsTest)
     test/core/assertion_filter_semantics_test.exs:23
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/assertion_filter_semantics_test.exs:25: (test)


18:32:29.378 [error] GenServer #PID<0.1140.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1139.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 30) test sigil modifiers are consistent across static and browser for role/css/exact flows (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:34
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:35: (test)


18:32:29.379 [error] GenServer #PID<0.1143.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1142.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 31) test scoped not-found failures include scope details (Cerberus.CoreLiveNestedScopeBehaviorTest)
     test/core/live_nested_scope_behavior_test.exs:34
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/live_nested_scope_behavior_test.exs:36: (test)


18:32:29.379 [error] GenServer #PID<0.1148.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1147.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 32) test open_browser snapshots live pages consistently in live and browser drivers (Cerberus.CoreOpenBrowserBehaviorTest)
     test/core/open_browser_behavior_test.exs:25
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/open_browser_behavior_test.exs:26: (test)

.
18:32:29.379 [error] GenServer #PID<0.1151.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1150.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 33) test open_browser snapshots static pages consistently in static and browser drivers (Cerberus.CoreOpenBrowserBehaviorTest)
     test/core/open_browser_behavior_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/open_browser_behavior_test.exs:12: (test)



 34) test refute_has supports label-only locators when label text is missing (Cerberus.CoreAssertionFilterSemanticsTest)
     test/core/assertion_filter_semantics_test.exs:14
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/assertion_filter_semantics_test.exs:15: (test)



 35) test click_link follows navigation that redirects back with flash (Cerberus.CoreLiveLinkNavigationTest)
     test/core/live_link_navigation_test.exs:33
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_link_navigation_test.exs:34: (test)



 36) test refute_has rejects unknown option keys with explicit errors (Cerberus.CoreAssertionFilterSemanticsTest)
     test/core/assertion_filter_semantics_test.exs:48
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/assertion_filter_semantics_test.exs:50: (test)



 37) test assert_has rejects unknown option keys with explicit errors (Cerberus.CoreAssertionFilterSemanticsTest)
     test/core/assertion_filter_semantics_test.exs:35
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/assertion_filter_semantics_test.exs:37: (test)

.
18:32:29.383 [error] GenServer #PID<0.1160.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1159.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.383 [error] GenServer #PID<0.1164.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1163.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.383 [error] GenServer #PID<0.1168.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1167.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.383 [error] GenServer #PID<0.1170.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1169.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.383 [error] GenServer #PID<0.1172.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1171.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.383 [error] GenServer #PID<0.1174.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1173.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}



18:32:29.383 [error] GenServer #PID<0.1184.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1183.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 38) test same counter click example runs in live and browser drivers (Cerberus.CoreApiExamplesTest)
     test/core/api_examples_test.exs:26
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, &counter_increment_flow/1)
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/api_examples_test.exs:27: (test)


18:32:29.384 [error] GenServer #PID<0.1191.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1190.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
.
18:32:29.384 [error] GenServer #PID<0.1197.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1196.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.384 [error] GenServer #PID<0.1205.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1203.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.384 [error] GenServer #PID<0.1209.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1207.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.384 [error] GenServer #PID<0.1217.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1215.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}



18:32:29.384 [error] GenServer #PID<0.1225.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1224.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 39) test click_button works on live counter flow for live and browser drivers (Cerberus.CoreFormActionsTest)
     test/core/form_actions_test.exs:46
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/form_actions_test.exs:47: (test)


18:32:29.385 [error] GenServer #PID<0.1240.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1239.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.386 [error] GenServer #PID<0.1249.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1248.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.386 [error] GenServer #PID<0.1253.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1252.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.386 [error] GenServer #PID<0.1257.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1256.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.386 [error] GenServer #PID<0.1264.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1263.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.387 [error] GenServer #PID<0.1272.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1271.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.387 [error] GenServer #PID<0.1275.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1273.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.387 [error] GenServer #PID<0.1277.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1276.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 40) test uncheck supports array-named checkbox groups (Cerberus.CoreCheckboxArrayBehaviorTest)
     test/core/checkbox_array_behavior_test.exs:23
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/checkbox_array_behavior_test.exs:24: (test)


18:32:29.387 [error] GenServer #PID<0.1285.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1284.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.387 [error] GenServer #PID<0.1287.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1286.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.388 [error] GenServer #PID<0.1300.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1299.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.388 [error] GenServer #PID<0.1304.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1303.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.388 [error] GenServer #PID<0.1311.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1310.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.388 [error] GenServer #PID<0.1313.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1312.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.389 [error] GenServer #PID<0.1316.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1315.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.389 [error] GenServer #PID<0.1324.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1323.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 41) test click_button handles multiline data-confirm attributes (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:82
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:83: (test)


18:32:29.389 [error] GenServer #PID<0.1333.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1332.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 42) test browser mode stays browser across live and static navigation transitions (Cerberus.CoreAutoModeTest)
     test/core/auto_mode_test.exs:59
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/auto_mode_test.exs:60: (test)


18:32:29.390 [error] GenServer #PID<0.1336.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1335.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.390 [error] GenServer #PID<0.1338.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1337.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.390 [error] GenServer #PID<0.1342.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1341.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.390 [error] GenServer #PID<0.1348.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1347.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 43) test sandbox metadata keeps live DB reads isolated across drivers (Cerberus.CoreSQLSandboxBehaviorTest)
     test/core/sql_sandbox_behavior_test.exs:29
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/sql_sandbox_behavior_test.exs:30: (test)


18:32:29.391 [error] GenServer #PID<0.1355.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1354.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 44) test path assertions track live patch query transitions across drivers (Cerberus.CorePathScopeBehaviorTest)
     test/core/path_scope_behavior_test.exs:67
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/path_scope_behavior_test.exs:68: (test)


18:32:29.391 [error] GenServer #PID<0.1362.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1361.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.391 [error] GenServer #PID<0.1365.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1364.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 45) test select on LiveView triggers change payload updates (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:75
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:76: (test)

.

 46) test static page text presence and absence use public API example flow (Cerberus.CoreApiExamplesTest)
     test/core/api_examples_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/api_examples_test.exs:12: (test)


18:32:29.393 [error] GenServer #PID<0.1378.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1377.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.393 [error] GenServer #PID<0.1382.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1381.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.393 [error] GenServer #PID<0.1384.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1383.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.393 [error] GenServer #PID<0.1389.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1388.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.393 [error] GenServer #PID<0.1391.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1390.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 47) test fill_in emits _target for phx-change events (Cerberus.CoreLiveFormChangeBehaviorTest)
     test/core/live_form_change_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_change_behavior_test.exs:13: (test)

.

 48) test current_path is updated on push navigation in live and browser drivers (Cerberus.CoreCurrentPathTest)
     test/core/current_path_test.exs:25
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/current_path_test.exs:26: (test)



 49) test click_link handles live navigate, patch, and non-live transitions (Cerberus.CoreLiveLinkNavigationTest)
     test/core/live_link_navigation_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_link_navigation_test.exs:13: (test)



 50) test failure messages include locator and options for reproducible debugging (Cerberus.CoreApiExamplesTest)
     test/core/api_examples_test.exs:31
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/api_examples_test.exs:33: (test)


18:32:29.395 [error] GenServer #PID<0.1404.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1403.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 51) test submit keeps default select and radio values when untouched (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:37
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:38: (test)

...

 52) test live redirects are deterministic in live and browser drivers (Cerberus.CoreLiveNavigationTest)
     test/core/live_navigation_test.exs:20
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_navigation_test.exs:21: (test)


18:32:29.396 [error] GenServer #PID<0.1410.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1409.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 53) test check supports array-named checkbox groups (Cerberus.CoreCheckboxArrayBehaviorTest)
     test/core/checkbox_array_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/checkbox_array_behavior_test.exs:13: (test)

.

 54) test conditional submissions exclude fields removed from the rendered form (Cerberus.CoreLiveFormSynchronizationBehaviorTest)
     test/core/live_form_synchronization_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_synchronization_behavior_test.exs:13: (test)

.


18:32:29.397 [error] GenServer #PID<0.1414.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1413.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 55) test within preserves nested scope stack and isolates nested child actions (Cerberus.CoreLiveNestedScopeBehaviorTest)
     test/core/live_nested_scope_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_nested_scope_behavior_test.exs:13: (test)


18:32:29.398 [error] GenServer #PID<0.1418.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1417.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
.

 56) test sandbox metadata keeps static DB reads isolated across drivers (Cerberus.CoreSQLSandboxBehaviorTest)
     test/core/sql_sandbox_behavior_test.exs:13
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/sql_sandbox_behavior_test.exs:14: (test)



 57) test within scopes live duplicate button clicks consistently in live and browser (Cerberus.CorePathScopeBehaviorTest)
     test/core/path_scope_behavior_test.exs:47
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/path_scope_behavior_test.exs:48: (test)




18:32:29.399 [error] GenServer #PID<0.1432.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1431.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 58) test multi-tab sharing and multi-user isolation work with one API across drivers (Cerberus.CoreCrossDriverMultiTabUserTest)
     test/core/cross_driver_multi_tab_user_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/cross_driver_multi_tab_user_test.exs:12: (test)

.

 59) test static submit payload matches browser for unchecked array values (Cerberus.CoreCheckboxArrayBehaviorTest)
     test/core/checkbox_array_behavior_test.exs:46
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/checkbox_array_behavior_test.exs:47: (test)



 60) test current_path is updated on live patch in live and browser drivers (Cerberus.CoreCurrentPathTest)
     test/core/current_path_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/current_path_test.exs:12: (test)

..

 61) test fill_in matches wrapped nested label text in live and browser drivers (Cerberus.CoreLiveFormChangeBehaviorTest)
     test/core/live_form_change_behavior_test.exs:54
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_change_behavior_test.exs:55: (test)



 62) test dynamic counter updates are consistent between live and browser drivers (Cerberus.CoreLiveNavigationTest)
     test/core/live_navigation_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_navigation_test.exs:12: (test)



 63) test LiveView submit keeps default select and radio values when untouched (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:110
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:111: (test)



 64) test helper locators are consistent across static and browser for forms and navigation (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:11
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:12: (test)


18:32:29.403 [error] GenServer #PID<0.1462.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1461.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 65) test click_button supports actionable JS command bindings across live and browser drivers (Cerberus.CoreLiveClickBindingsBehaviorTest)
     test/core/live_click_bindings_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_click_bindings_behavior_test.exs:13: (test)

.

 66) test static submit payload matches browser for checked array values (Cerberus.CoreCheckboxArrayBehaviorTest)
     test/core/checkbox_array_behavior_test.exs:34
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/checkbox_array_behavior_test.exs:35: (test)

.
18:32:29.404 [error] GenServer #PID<0.1476.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1475.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 67) test reload_page preserves current_path after live patch transitions (Cerberus.CoreCurrentPathTest)
     test/core/current_path_test.exs:56
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/current_path_test.exs:57: (test)


18:32:29.404 [error] GenServer #PID<0.1482.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1481.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 68) test submit-only forms still submit filled values without phx-change (Cerberus.CoreLiveFormSynchronizationBehaviorTest)
     test/core/live_form_synchronization_behavior_test.exs:58
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_synchronization_behavior_test.exs:59: (test)



 69) test css sigil selector disambiguates duplicate live button labels (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:68
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:69: (test)



 70) test query strings are preserved in current_path tracking across drivers (Cerberus.CoreCurrentPathTest)
     test/core/current_path_test.exs:40
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/current_path_test.exs:41: (test)


18:32:29.406 [error] GenServer #PID<0.1493.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1492.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 71) test screenshot captures browser PNG output to a requested path (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:516
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:521: (test)


18:32:29.406 [error] GenServer #PID<0.1502.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1501.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}



18:32:29.406 [error] GenServer #PID<0.1506.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1505.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 72) test role link helper navigates from live route consistently (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:96
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:97: (test)



 73) test choose on LiveView updates the selected radio (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:87
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:88: (test)




18:32:29.407 [error] GenServer #PID<0.1513.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1511.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}
 74) test phx-trigger-action submits to static endpoint after phx-submit (Cerberus.CoreLiveTriggerActionBehaviorTest)
     test/core/live_trigger_action_behavior_test.exs:12
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_trigger_action_behavior_test.exs:13: (test)

...
18:32:29.407 [error] GenServer #PID<0.1523.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1522.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 75) test select and choose work for browser sessions (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:589
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:592: (test)

.

 76) test session constructor returns a browser session (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:64
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: assert %BrowserSession{} = session(:browser)
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:65: (test)

.

 77) test duplicate live button labels are disambiguated for render_click conversion (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:52
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/helper_locator_behavior_test.exs:53: (test)



 78) test active form ordering preserves hidden defaults across sequential fill_in (Cerberus.CoreLiveFormChangeBehaviorTest)
     test/core/live_form_change_behavior_test.exs:37
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_change_behavior_test.exs:38: (test)



 79) test testid helper reports explicit unsupported behavior across drivers (Cerberus.CoreHelperLocatorBehaviorTest)
     test/core/helper_locator_behavior_test.exs:109
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       test/core/helper_locator_behavior_test.exs:111: (test)

.

 80) test dispatch(change) buttons inside forms drive add/remove semantics (Cerberus.CoreLiveFormSynchronizationBehaviorTest)
     test/core/live_form_synchronization_behavior_test.exs:44
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_form_synchronization_behavior_test.exs:45: (test)



 81) test LiveView select preserves multi-select values across repeated calls (Cerberus.CoreSelectChooseBehaviorTest)
     test/core/select_choose_behavior_test.exs:98
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/select_choose_behavior_test.exs:99: (test)



 82) test phx-trigger-action is ignored when click event redirects or navigates (Cerberus.CoreLiveTriggerActionBehaviorTest)
     test/core/live_trigger_action_behavior_test.exs:65
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_trigger_action_behavior_test.exs:66: (test)


18:32:29.410 [error] GenServer #PID<0.1530.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1529.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 83) test upload triggers phx-change validations on file selection (Cerberus.CoreLiveUploadBehaviorTest)
     test/core/live_upload_behavior_test.exs:60
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_upload_behavior_test.exs:63: (test)

...

 84) test phx-trigger-action can be triggered from outside the form (Cerberus.CoreLiveTriggerActionBehaviorTest)
     test/core/live_trigger_action_behavior_test.exs:34
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_trigger_action_behavior_test.exs:35: (test)

........

 85) test dynamically rendered forms can trigger action submit (Cerberus.CoreLiveTriggerActionBehaviorTest)
     test/core/live_trigger_action_behavior_test.exs:79
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_trigger_action_behavior_test.exs:80: (test)

...

 86) test open_browser creates an HTML snapshot for browser sessions (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:498
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:501: (test)

..

 87) test screenshot defaults to a temp PNG path and records it in last_result (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:535
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:538: (test)

..

 88) test browser session applies init script and viewport defaults across new tabs (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:69
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:72: (test)

..

 89) test unwrap in browser mode exposes native tab handles (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:480
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:483: (test)

.

 90) test chrome/firefox aliases construct browser sessions (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:32
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: assert %BrowserSession{} = session(:chrome)
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:33: (test)

...

 91) test switch_tab rejects mixed browser and non-browser sessions (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:100
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/cerberus/public_api_test.exs:103: (test)

....

 92) test screenshot rejects invalid options (Cerberus.PublicApiTest)
     test/cerberus/public_api_test.exs:579
     Wrong message for ArgumentError
     expected:
       ~r/:path must be a non-empty string path/
     actual:
       "failed to initialize browser driver: {\"failed to dispatch bidi command\", %{\"reason\" => \"\\\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\\\"\"}}"
     code: assert_raise ArgumentError, ~r/:path must be a non-empty string path/, fn ->
     stacktrace:
       test/cerberus/public_api_test.exs:580: (test)



 93) test upload follows redirects from progress callbacks (Cerberus.CoreLiveUploadBehaviorTest)
     test/core/live_upload_behavior_test.exs:78
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/live_upload_behavior_test.exs:81: (test)

......
18:32:29.575 [error] GenServer #PID<0.1555.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1554.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 94) test quickstart counter flow from docs works across auto and browser (Cerberus.CoreDocumentationExamplesTest)
     test/core/documentation_examples_test.exs:13
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/documentation_examples_test.exs:14: (test)


18:32:29.577 [error] GenServer #PID<0.1558.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1557.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}

18:32:29.577 [error] GenServer #PID<0.1561.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1560.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 95) test multi-user and multi-tab flow from docs preserves isolation semantics (Cerberus.CoreDocumentationExamplesTest)
     test/core/documentation_examples_test.exs:53
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/documentation_examples_test.exs:54: (test)


18:32:29.578 [error] GenServer #PID<0.1564.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
Last message: {:EXIT, #PID<0.1563.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}}


 96) test browser extension snippet from docs works (Cerberus.CoreDocumentationExamplesTest)
     test/core/documentation_examples_test.exs:84
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       test/core/documentation_examples_test.exs:87: (test)



 97) test scoped navigation flow from docs works across auto and browser (Cerberus.CoreDocumentationExamplesTest)
     test/core/documentation_examples_test.exs:38
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)\""}}
     code: Harness.run!(context, fn session ->
     stacktrace:
       (cerberus 0.1.0) lib/cerberus/driver/browser.ex:70: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.0) test/support/harness.ex:98: Cerberus.Harness.run_driver/3
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (elixir 1.19.5) lib/enum.ex:1688: Enum."-map/2-lists^map/1-1-"/2
       (cerberus 0.1.0) test/support/harness.ex:69: Cerberus.Harness.run/3
       (cerberus 0.1.0) test/support/harness.ex:78: Cerberus.Harness.run!/3
       test/core/documentation_examples_test.exs:39: (test)

......................updated /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-records-row-level-parity-for-multiple-rows-ac741d2e/work/test/features/migration_ready_test.exs

Migration summary:
  Files scanned: 1
  Files changed: 1
  Warnings: 0
  Mode: write
updated /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-records-row-level-parity-for-multiple-rows-ac741d2e/work/test/features/migration_ready_second_test.exs

Migration summary:
  Files scanned: 1
  Files changed: 1
  Warnings: 0
  Mode: write
.

 98) test runs end-to-end against committed migration fixture (Cerberus.MigrationVerificationTest)
     test/cerberus/migration_verification_test.exs:148
     match (=) failed
     code:  assert {:ok, result} =
              MigrationVerification.run(
                [root_dir: root_dir, fixture_dir: fixture_dir, work_dir: work_dir, rows: rows, keep: false],
                &System.cmd/3
              )
     left:  {:ok, result}
     right: {:error,
             %{
               command: ["mix", "test",
                "test/features/migration_ready_test.exs"],
               output: "    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 21 │   defp elixirc_paths(:test), do: ['lib', 'test/support']\n    │                                   ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:21:35\n\n    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 21 │   defp elixirc_paths(:test), do: ['lib', 'test/support']\n    │                                          ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:21:42\n\n    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 22 │   defp elixirc_paths(_), do: ['lib']\n    │                               ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:22:31\n\n==> websockex\n:elixirc_paths should be a list of string paths, got: [~c\"lib\"]\nCompiling 6 files (.ex)\n     warning: using single-quoted strings to represent charlists is deprecated.\n     Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n     You may run \"mix format --migrate\" to change all single-quoted\n     strings to use the ~c sigil and fix this warning.\n     │\n 167 │             :error_logger.format('~p: ignoring bad debug options ~p~n', [name, opts])\n     │                                  ~\n     │\n     └─ lib/websockex/utils.ex:167:34\n\n     warning: ^^^ is deprecated. It is typically used as xor but it has the wrong precedence, use Bitwise.bxor/2 instead\n     │\n 394 │       masked = part ^^^ key\n     │                     ~\n     │\n     └─ lib/websockex/frame.ex:394:21\n\n     warning: ^^^ is deprecated. It is typically used as xor but it has the wrong precedence, use Bitwise.bxor/2 instead\n     │\n 400 │     masked = part ^^^ key\n     │                   ~\n     │\n     └─ lib/websockex/frame.ex:400:19\n\n     warning: using single-quoted strings to represent charlists is deprecated.\n     Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n     You may run \"mix format --migrate\" to change all single-quoted\n     strings to use the ~c sigil and fix this warning.\n     │\n 503 │       {:header, 'Status for WebSockex process \#{inspect(self())}'},\n     │                 ~\n     │\n     └─ lib/websockex.ex:503:17\n\n     warning: :sys.get_debug/3 is deprecated. Incorrectly documented and only for internal use. Can often be replaced with sys:get_log/1\n     │\n 499 │     log = :sys.get_debug(:log, debug, [])\n     │                ~\n     │\n     └─ lib/websockex.ex:499:16: WebSockex.format_status/2\n\n      warning: System.stacktrace/0 is deprecated. Use __STACKTRACE__ instead\n      │\n 1116 │       stacktrace = System.stacktrace()\n      │                           ~\n      │\n      └─ lib/websockex.ex:1116:27: WebSockex.try_callback/3\n\nGenerated websockex app\n==> playwright_ex\nCompiling 19 files (.ex)\nGenerated playwright_ex app\n==> cerberus\nCompiling 34 files (.ex)\nGenerated cerberus app\n==> phoenix_test_playwright\nCompiling 12 files (.ex)\nGenerated phoenix_test_playwright app\n==> migration_fixture\nCompiling 9 files (.ex)\nGenerated migration_fixture app\nRunning ExUnit with seed: 824787, max_cases: 28\n\n\n\n  1) test single flow can run pre and post migration (MigrationFixtureWeb.MigrationReadyTest)\n     test/features/migration_" <> ...,
               status: 2,
               report: %{
                 rows: [
                   %{
                     id: "pt_migration_ready",
                     pre: %{
                       output: "    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 21 │   defp elixirc_paths(:test), do: ['lib', 'test/support']\n    │                                   ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:21:35\n\n    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 21 │   defp elixirc_paths(:test), do: ['lib', 'test/support']\n    │                                          ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:21:42\n\n    warning: using single-quoted strings to represent charlists is deprecated.\n    Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n    You may run \"mix format --migrate\" to change all single-quoted\n    strings to use the ~c sigil and fix this warning.\n    │\n 22 │   defp elixirc_paths(_), do: ['lib']\n    │                               ~\n    │\n    └─ /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-end-to-end-against-committed-migration-fixture-95cb0445/work/deps/websockex/mix.exs:22:31\n\n==> websockex\n:elixirc_paths should be a list of string paths, got: [~c\"lib\"]\nCompiling 6 files (.ex)\n     warning: using single-quoted strings to represent charlists is deprecated.\n     Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n     You may run \"mix format --migrate\" to change all single-quoted\n     strings to use the ~c sigil and fix this warning.\n     │\n 167 │             :error_logger.format('~p: ignoring bad debug options ~p~n', [name, opts])\n     │                                  ~\n     │\n     └─ lib/websockex/utils.ex:167:34\n\n     warning: ^^^ is deprecated. It is typically used as xor but it has the wrong precedence, use Bitwise.bxor/2 instead\n     │\n 394 │       masked = part ^^^ key\n     │                     ~\n     │\n     └─ lib/websockex/frame.ex:394:21\n\n     warning: ^^^ is deprecated. It is typically used as xor but it has the wrong precedence, use Bitwise.bxor/2 instead\n     │\n 400 │     masked = part ^^^ key\n     │                   ~\n     │\n     └─ lib/websockex/frame.ex:400:19\n\n     warning: using single-quoted strings to represent charlists is deprecated.\n     Use ~c\"\" if you indeed want a charlist or use \"\" instead.\n     You may run \"mix format --migrate\" to change all single-quoted\n     strings to use the ~c sigil and fix this warning.\n     │\n 503 │       {:header, 'Status for WebSockex process \#{inspect(self())}'},\n     │                 ~\n     │\n     └─ lib/websockex.ex:503:17\n\n     warning: :sys.get_debug/3 is deprecated. Incorrectly documented and only for internal use. Can often be replaced with sys:get_log/1\n     │\n 499 │     log = :sys.get_debug(:log, debug, [])\n     │                ~\n     │\n     └─ lib/websockex.ex:499:16: WebSockex.format_status/2\n\n      warning: System.stacktrace/0 is deprecated. Use __STACKTRACE__ instead\n      │\n 1116 │       stacktrace = System.stacktrace()\n      │                           ~\n      │\n      └─ lib/websockex.ex:1116:27: WebSockex.try_callback/3\n\nGenerated websockex app\n==> playwright_ex\nCompiling 19 files (.ex)\nGenerated playwright_ex app\n==> cerberus\nCompiling 34 files (.ex)\nGenerated cerberus app\n==> phoenix_test_playwright\nCompiling 12 files (.ex)\nGenerated phoenix_test_playwright app\n==> migration_fixture\nCompiling 9 files (.ex)\nGenerated migration_fixture app\nRunning ExUnit with seed: 824787, max_cases: 28\n\n\n\n  1) test single flow can run pre and post migration (MigrationFixtureWeb.MigrationReadyTest)\n     test/features/migration_" <> ...,
                       status: 2
                     },
                     post: nil,
                     test_file: "test/features/migration_ready_test.exs",
                     parity: false,
                     pre_status: :fail,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_static_nav",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_static_nav_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_text_assert",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_text_assert_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_text_refute",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_text_refute_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_click_navigation",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_click_navigation_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_form_fill",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_form_fill_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_checkbox_array",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_checkbox_array_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_submit_action",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_submit_action_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_path_assert",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_path_assert_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_path_refute",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_path_refute_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   %{
                     id: "pt_multi_user_tab",
                     pre: nil,
                     post: nil,
                     test_file: "test/features/pt_multi_user_tab_test.exs",
                     parity: false,
                     pre_status: :not_run,
                     post_status: :not_run
                   },
                   ...
                 ],
                 ...
               },
               ...
             }}
     stacktrace:
       test/cerberus/migration_verification_test.exs:169: (test)

updated /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-runs-pre-test,-migration,-and-post-test-in-order-32b20f2b/work/test/features/migration_ready_test.exs

Migration summary:
  Files scanned: 1
  Files changed: 1
  Warnings: 0
  Mode: write
..updated /Users/ftes/src/cerberus/tmp/Cerberus.MigrationVerificationTest/test-returns-detailed-failure-for-post-test-failures-43a3f6ca/work/test/features/migration_ready_test.exs

Migration summary:
  Files scanned: 1
  Files changed: 1
  Warnings: 0
  Mode: write
.
Finished in 6.2 seconds (1.1s async, 5.1s sync)
242 tests, 98 failures runs still hit the known sqlite disk I/O lock issue from .
