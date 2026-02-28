# Browser Support Policy

This document defines current browser support for Cerberus WebDriver BiDi execution.

## Supported Browsers

Cerberus currently supports:

- Chrome/Chromium via ChromeDriver BiDi
- Firefox via geckodriver BiDi

Both targets are maintained in CI and covered by browser conformance suites and shared API examples.

## Runtime Model

- Cerberus uses one shared browser runtime process and one shared BiDi connection per test invocation.
- Browser isolation is done through per-session `userContext` and per-tab `browsingContext`.
- Runtime launch settings are invocation-level, including browser selection, headed/headless mode, WebDriver endpoint, binary paths, and driver args.
- If you need different runtime launch settings, run separate test invocations.

## Local Managed Runtime

Configure local browser and WebDriver binaries via `:cerberus, :browser`:

```elixir
config :cerberus, :browser,
  chrome_binary: "/path/to/chrome-or-chromium",
  chromedriver_binary: "/path/to/chromedriver",
  firefox_binary: "/path/to/firefox",
  geckodriver_binary: "/path/to/geckodriver"
```

## Remote Runtime

Use a pre-running WebDriver endpoint:

```elixir
config :cerberus, :browser,
  webdriver_url: "http://127.0.0.1:4444"
```

With `webdriver_url` set, Cerberus skips local browser/WebDriver process launch.

## Not Current Targets

Edge and Safari/WebKit are not currently first-class Cerberus runtime targets.
