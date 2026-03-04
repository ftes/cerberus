---
# cerberus-09jw
title: Analyze local vs CI test speed gap
status: completed
type: task
priority: normal
created_at: 2026-03-03T22:24:50Z
updated_at: 2026-03-03T22:27:11Z
---

Compare CI test commands/config/environment with local defaults to explain why browser test lanes are slower locally.

## Summary of Changes

- Compared CI workflow commands and local test defaults.
- Confirmed CI runs two test lanes (Running ExUnit with seed: 729, max_cases: 28
Excluding tags: [slow: true]

..................................
23:26:42.153 [error] GenServer #PID<0.957.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.956.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.950.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.949.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.151 [error] GenServer #PID<0.936.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.935.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.944.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.943.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.946.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.945.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.151 [error] GenServer #PID<0.942.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.941.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.148 [error] GenServer #PID<0.911.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.910.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.148 [error] GenServer #PID<0.909.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.908.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.952.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.951.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.148 [error] GenServer #PID<0.913.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.912.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.151 [error] GenServer #PID<0.938.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.937.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.954.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.953.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.149 [error] GenServer #PID<0.919.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.918.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.150 [error] GenServer #PID<0.932.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.931.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.150 [error] GenServer #PID<0.926.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.925.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.148 [error] GenServer #PID<0.866.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.838.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.160 [error] GenServer #PID<0.976.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.975.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.150 [error] GenServer #PID<0.928.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.927.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.149 [error] GenServer #PID<0.924.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.923.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.149 [error] GenServer #PID<0.917.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.916.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.151 [error] GenServer #PID<0.934.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.933.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.150 [error] GenServer #PID<0.930.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.929.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.152 [error] GenServer #PID<0.948.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.947.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.149 [error] GenServer #PID<0.921.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.920.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.178 [error] GenServer #PID<0.1014.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1013.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.178 [error] GenServer #PID<0.1029.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1028.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.179 [error] GenServer #PID<0.1032.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1031.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.180 [error] GenServer #PID<0.1036.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1035.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.180 [error] GenServer #PID<0.1040.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1039.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.181 [error] GenServer #PID<0.1045.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1041.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.181 [error] GenServer #PID<0.1063.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1062.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.182 [error] GenServer #PID<0.1076.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1075.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.182 [error] GenServer #PID<0.1078.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1077.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.183 [error] GenServer #PID<0.1081.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1080.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.184 [error] GenServer #PID<0.1086.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1085.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.187 [error] GenServer #PID<0.1094.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1093.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.187 [error] GenServer #PID<0.1100.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1099.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.189 [error] GenServer #PID<0.1107.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1106.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.190 [error] GenServer #PID<0.1115.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1114.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.196 [error] GenServer #PID<0.1125.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1124.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


  1) test screenshot defaults to a temp PNG path (Cerberus.BrowserTest)
     test/cerberus/browser_test.exs:16
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_test.exs:19: (test)



  2) test popup_mode :same_tab coerces autonomous window.open into current tab (Cerberus.BrowserPopupModeTest)
     test/cerberus/browser_popup_mode_test.exs:16
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session(browser: [popup_mode: :same_tab])
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_popup_mode_test.exs:19: (test)

???

  3) test browser session uses default browser lane (Cerberus.BrowserTagShowcaseTest)
     test/cerberus/browser_tag_showcase_test.exs:6
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: session = session(:browser)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_tag_showcase_test.exs:7: (test)

?

  4) test multi-tab sharing and multi-user isolation work with one API across drivers (browser) (Cerberus.CrossDriverMultiTabUserTest)
     test/cerberus/cross_driver_multi_tab_user_test.exs:7
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/cross_driver_multi_tab_user_test.exs:10: (test)

????????????????

  4) Cerberus.LiveVisibilityAssertionsTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

?????????????????????????

  4) Cerberus.LiveClickBindingsBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

?????????????????????

  4) Cerberus.StaticUploadBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

??


23:26:42.212 [error] GenServer #PID<0.1152.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1151.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
  4) Cerberus.OpenBrowserBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????

  4) Cerberus.ParityMismatchFixtureTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

??????

  4) Cerberus.BrowserActionSettleBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????????????

  4) Cerberus.LiveNestedScopeBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

???????

  4) Cerberus.StaticNavigationTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????????????

  4) Cerberus.TimeoutBehaviorParityTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



  4) Cerberus.FormButtonOwnershipTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????

  4) Cerberus.AssertionFilterSemanticsTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????????

  4) Cerberus.ApiExamplesTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



  4) Cerberus.LiveUploadBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



  4) Cerberus.FormActionsTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

??

  4) Cerberus.LiveLinkNavigationTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



  4) Cerberus.WithinClosestBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/within_closest_behavior_test.exs:69: anonymous fn/1 in Cerberus.WithinClosestBehaviorTest.start_shared_browser_session!/0

?
23:26:42.217 [error] GenServer #PID<0.1160.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1159.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


  4) Cerberus.LiveFormChangeBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

???
23:26:42.217 [error] GenServer #PID<0.1163.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1162.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}



23:26:42.218 [error] GenServer #PID<0.1167.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1166.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
  5) test screenshot rejects invalid options (Cerberus.BrowserTest)
     test/cerberus/browser_test.exs:7
     Wrong message for ArgumentError
     expected:
       ~r/:path must be a non-empty string path/
     actual:
       "failed to initialize browser driver: {\"failed to dispatch bidi command\", %{\"reason\" => \"\\\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\\\"\"}}"
     code: assert_raise ArgumentError, ~r/:path must be a non-empty string path/, fn ->
     stacktrace:
       test/cerberus/browser_test.exs:8: (test)

?
23:26:42.218 [error] GenServer #PID<0.1170.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1169.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
?

  5) Cerberus.LiveTriggerActionBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/live_trigger_action_behavior_test.exs:125: anonymous fn/1 in Cerberus.LiveTriggerActionBehaviorTest.start_shared_browser_session!/0

????
23:26:42.218 [error] GenServer #PID<0.1174.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1173.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


  5) Cerberus.PathScopeBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/path_scope_behavior_test.exs:101: anonymous fn/1 in Cerberus.PathScopeBehaviorTest.start_shared_browser_session!/0



  5) Cerberus.CheckboxArrayBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



  6) test popup_mode :allow keeps autonomous window.open on source tab (Cerberus.BrowserPopupModeTest)
     test/cerberus/browser_popup_mode_test.exs:6
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_popup_mode_test.exs:9: (test)



  7) test unguarded cross-origin iframe DOM access raises browser evaluate error (Cerberus.BrowserIframeLimitationsTest)
     test/cerberus/browser_iframe_limitations_test.exs:44
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_iframe_limitations_test.exs:47: (test)

??????????
23:26:42.220 [error] GenServer #PID<0.1182.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1181.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


  7) Cerberus.DocumentationExamplesTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

????

  7) Cerberus.LiveNavigationTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

....????????????????????????????????.??

  7) Cerberus.SelectChooseBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/select_choose_behavior_test.exs:189: anonymous fn/1 in Cerberus.SelectChooseBehaviorTest.start_shared_browser_session!/0

.

  8) test within locator rejects cross-origin iframe root switching (Cerberus.BrowserIframeLimitationsTest)
     test/cerberus/browser_iframe_limitations_test.exs:79
     Expected exception ExUnit.AssertionError but got ArgumentError (failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}})
     code: assert_raise ExUnit.AssertionError, fn ->
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_iframe_limitations_test.exs:83: anonymous fn/0 in Cerberus.BrowserIframeLimitationsTest."test within locator rejects cross-origin iframe root switching"/1
       test/cerberus/browser_iframe_limitations_test.exs:81: (test)



  9) test cross-origin iframe DOM access is blocked by same-origin policy (Cerberus.BrowserIframeLimitationsTest)
     test/cerberus/browser_iframe_limitations_test.exs:7
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_iframe_limitations_test.exs:10: (test)



 10) test screenshot captures browser PNG output to a requested path (Cerberus.BrowserTest)
     test/cerberus/browser_test.exs:27
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_test.exs:35: (test)


23:26:42.224 [error] GenServer #PID<0.1189.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1188.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 11) test within locator scopes browser operations into same-origin iframe document (Cerberus.BrowserIframeLimitationsTest)
     test/cerberus/browser_iframe_limitations_test.exs:66
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_iframe_limitations_test.exs:68: (test)

????????

 11) Cerberus.LiveFormSynchronizationBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



 12) test explicit driver maps to matching runtime browser (chrome) (Cerberus.ExplicitBrowserTest)
     test/cerberus/explicit_browser_test.exs:19
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/explicit_browser_test.exs:21: (test)


23:26:42.225 [error] GenServer #PID<0.1197.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1196.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 13) test explicit chrome driver runs as expected (chrome) (Cerberus.ExplicitBrowserTest)
     test/cerberus/explicit_browser_test.exs:7
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/explicit_browser_test.exs:10: (test)



 14) test parallel browser sessions remain isolated under concurrent actions (Cerberus.BrowserMultiSessionBehaviorTest)
     test/cerberus/browser_multi_session_behavior_test.exs:47
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_multi_session_behavior_test.exs:50: (test)



 15) test browser open_tab/switch_tab/close_tab workflows are deterministic (Cerberus.BrowserMultiSessionBehaviorTest)
     test/cerberus/browser_multi_session_behavior_test.exs:8
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_multi_session_behavior_test.exs:11: (test)

??

 15) Cerberus.BrowserLinkClickSemanticsTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0



 16) test assert_dialog handles a dialog that is already open (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:287
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:290: (test)



 17) test browser default timeout waits for async navigate path updates (Cerberus.BrowserTimeoutAssertionsTest)
     test/cerberus/browser_timeout_assertions_test.exs:16
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_timeout_assertions_test.exs:18: (test)



 18) test browser timeout handles async redirect path updates (Cerberus.BrowserTimeoutAssertionsTest)
     test/cerberus/browser_timeout_assertions_test.exs:33
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_timeout_assertions_test.exs:35: (test)



 19) test browser defaults use 500ms assertion timeout and wait for async text (Cerberus.BrowserTimeoutAssertionsTest)
     test/cerberus/browser_timeout_assertions_test.exs:7
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: session = session(:browser)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_timeout_assertions_test.exs:8: (test)



 20) test browser assert_path falls back to direct URL checks when helper is missing (Cerberus.BrowserTimeoutAssertionsTest)
     test/cerberus/browser_timeout_assertions_test.exs:41
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_timeout_assertions_test.exs:44: (test)



 21) test browser assertion eval retries across async navigation context resets (Cerberus.BrowserTimeoutAssertionsTest)
     test/cerberus/browser_timeout_assertions_test.exs:24
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_timeout_assertions_test.exs:26: (test)

??????????????????????????????????????

 21) Cerberus.HelperLocatorBehaviorTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/helper_locator_behavior_test.exs:240: anonymous fn/1 in Cerberus.HelperLocatorBehaviorTest.start_shared_browser_session!/0



 22) test text assertions behave consistently for static pages in static and browser drivers (browser) (Cerberus.CrossDriverTextTest)
     test/cerberus/cross_driver_text_test.exs:7
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/cross_driver_text_test.exs:9: (test)

????????

 22) Cerberus.CurrentPathTest: failure on setup_all callback, all tests have been invalidated
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       (cerberus 0.1.2) test/support/shared_browser_session.ex:14: anonymous fn/1 in Cerberus.TestSupport.SharedBrowserSession.start!/0

...........................................
23:26:42.301 [error] GenServer #PID<0.1271.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1270.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.301 [error] GenServer #PID<0.1274.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1273.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 23) test with_popup surfaces callback failure and restores main tab (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:262
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:265: (test)


23:26:42.301 [error] GenServer #PID<0.1277.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1276.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 24) test assert_download waits for download emitted after assertion starts (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:322
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:325: (test)


23:26:42.302 [error] GenServer #PID<0.1280.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1279.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 25) test assert_dialog raises when observed dialog message does not match expected text (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:404
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:407: (test)



 26) test assert_dialog validates prompt_text requires accept: true (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:451
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:454: (test)

.
23:26:42.304 [error] GenServer #PID<0.1284.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1283.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.304 [error] GenServer #PID<0.1287.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1286.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 27) test screenshot + keyboard + dialog + drag browser extensions work together (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:52
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:60: (test)


23:26:42.305 [error] GenServer #PID<0.1290.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1289.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}



23:26:42.305 [error] GenServer #PID<0.1293.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1292.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
 28) test browser keyword options are validated with NimbleOptions (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:128
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:131: (test)



 29) test assert_dialog waits for a dialog that opens after assertion starts (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:300
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:303: (test)



 30) test assert_dialog supports explicit accept/confirm behavior (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:437
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:440: (test)

..
23:26:42.377 [error] GenServer #PID<0.1319.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1318.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.378 [error] GenServer #PID<0.1322.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1321.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 31) test evaluate_js supports optional callback assertions and returns session for chaining (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:163
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:166: (test)

.
23:26:42.378 [error] GenServer #PID<0.1325.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1324.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.378 [error] GenServer #PID<0.1328.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1327.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 32) test with_popup captures popup tab, yields main+popup sessions, and returns canonical main session (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:183
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:186: (test)


23:26:42.378 [error] GenServer #PID<0.1334.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1333.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 33) test browser mode stays browser across live and static navigation transitions (Cerberus.AutoModeTest)
     test/cerberus/auto_mode_test.exs:48
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: session = visit(session(:browser), "/articles")
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/auto_mode_test.exs:49: (test)


23:26:42.379 [error] GenServer #PID<0.1337.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1336.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}

23:26:42.379 [error] GenServer #PID<0.1340.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1339.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 34) test assert_download waits for delayed live redirect to static download response (browser) (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:351
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:354: (test)


23:26:42.379 [error] GenServer #PID<0.1344.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1343.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}



23:26:42.380 [error] GenServer #PID<0.1347.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1346.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
 35) test evaluate_js and cookie helpers cover add_cookie and session cookie semantics (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:86
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:89: (test)



 36) test with_popup times out when trigger does not open popup (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:239
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:242: (test)


23:26:42.381 [error] GenServer #PID<0.1367.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1366.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 37) test assert_download times out with helpful observed filenames (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:388
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:391: (test)



 38) test assert_dialog times out when no dialog opens (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:423
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:426: (test)



 39) test with_popup waits for popup opened after waiter registration (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:214
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:217: (test)

....

 40) test sandbox metadata keeps live DB reads isolated across drivers (browser) (Cerberus.SQLSandboxBehaviorTest)
     test/cerberus/sql_sandbox_behavior_test.exs:33
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: session = sandbox_session(unquote(driver), context)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/sql_sandbox_behavior_test.exs:34: (test)

....
23:26:42.384 [error] GenServer #PID<0.1382.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1381.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 41) test sandbox metadata keeps static DB reads isolated across drivers (browser) (Cerberus.SQLSandboxBehaviorTest)
     test/cerberus/sql_sandbox_behavior_test.exs:23
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: session = sandbox_session(unquote(driver), context)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/sql_sandbox_behavior_test.exs:24: (test)

.
23:26:42.386 [error] GenServer #PID<0.1393.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1392.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 42) test select and choose work for browser sessions (CerberusTest)
     test/cerberus_test.exs:607
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:610: (test)

......
23:26:42.399 [error] GenServer #PID<0.1409.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1408.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 43) test open_browser creates an HTML snapshot for browser sessions (CerberusTest)
     test/cerberus_test.exs:561
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:564: (test)

..
23:26:42.399 [error] GenServer #PID<0.1414.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1413.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 44) test chrome alias constructs browser sessions (CerberusTest)
     test/cerberus_test.exs:43
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: assert %BrowserSession{} = session(:chrome)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:44: (test)

.....
23:26:42.403 [error] GenServer #PID<0.1427.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1426.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 45) test unwrap in browser mode exposes constrained native browser handles (CerberusTest)
     test/cerberus_test.exs:540
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:543: (test)

......
23:26:42.405 [error] GenServer #PID<0.1440.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1439.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 46) test session constructor returns a browser session (CerberusTest)
     test/cerberus_test.exs:72
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: assert %BrowserSession{} = session(:browser)
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:73: (test)

..
23:26:42.405 [error] GenServer #PID<0.1445.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1444.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 47) test switch_tab rejects mixed browser and non-browser sessions (CerberusTest)
     test/cerberus_test.exs:108
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:111: (test)

........
23:26:42.430 [error] GenServer #PID<0.1476.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1475.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 48) test browser session applies init script and viewport defaults across new tabs (CerberusTest)
     test/cerberus_test.exs:76
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session(
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus_test.exs:79: (test)

......
23:26:42.448 [error] GenServer #PID<0.1484.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.1483.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}


 49) test assert_download matches download emitted before assertion call and keeps events non-consuming (Cerberus.BrowserExtensionsTest)
     test/cerberus/browser_extensions_test.exs:311
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     code: |> session()
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/browser_extensions_test.exs:314: (test)

..................................................
Finished in 6.6 seconds (6.2s async, 0.4s sync)
467 tests, 49 failures, 237 invalid (3 excluded) and Running ExUnit with seed: 210700, max_cases: 28
Excluding tags: [:test]
Including tags: [:slow]



  1) test rich snippet locator corpus stays in static/browser parity (Cerberus.LocatorParityTest)
     test/cerberus/locator_parity_test.exs:283
     ** (ArgumentError) failed to initialize browser driver: {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
     stacktrace:
       (cerberus 0.1.2) lib/cerberus/driver/browser.ex:109: Cerberus.Driver.Browser.new_session/1
       test/cerberus/locator_parity_test.exs:279: Cerberus.LocatorParityTest.__ex_unit_setup_0/1
       test/cerberus/locator_parity_test.exs:1: Cerberus.LocatorParityTest.__ex_unit__/2


23:26:49.371 [error] GenServer #PID<0.901.0> terminating
** (stop) {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}
Last message: {:EXIT, #PID<0.892.0>, {"failed to dispatch bidi command", %{"reason" => "\"chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary), set CHROMEDRIVER, or run mix cerberus.install.chrome\""}}}
..
Finished in 21.8 seconds (21.8s async, 0.00s sync)
3 tests, 1 failure (467 excluded)) with slow tests excluded by default in test_helper.
- Identified major local-vs-CI difference: local schedulers are high (14 -> ExUnit max_cases 28), which drives heavy browser-session contention across many async browser suites.
- Confirmed CI caches deps/build and browser runtimes, reducing cold-start overhead compared with local uncached runs.
- Produced concrete local command adjustments to align with CI-like throughput (lower max_cases for browser-heavy runs, ensure env/runtime parity).
