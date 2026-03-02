# Browser Support Policy

This document defines current browser support for Cerberus WebDriver BiDi execution.
Status last reviewed: February 28, 2026.

## Supported Browsers

Cerberus currently supports:

- Chrome/Chromium via ChromeDriver BiDi
- Firefox via geckodriver BiDi

Both targets are covered by browser conformance suites and shared API examples.
CI keeps chrome as the baseline lane and includes targeted firefox-tagged conformance coverage.

## Runtime Model

- Cerberus uses one shared browser runtime process and one shared BiDi connection per test invocation.
- Browser isolation is done through per-session `userContext` and per-tab `browsingContext`.
- Runtime launch settings are invocation-level, including browser selection, headed/headless mode, WebDriver endpoint, binary paths, and driver args.
- If you need different runtime launch settings, run separate test invocations.

## Popup Lifecycle Support

- `Cerberus.Browser.with_popup/4` is browser-only.
- Popup capture is deterministic: the popup must be opened by the provided trigger callback.
- The interaction callback receives both sessions (`main`, `popup`), callback return is ignored, and Cerberus restores the main tab/session before returning.
- Static/live drivers do not emulate popup lifecycle APIs.

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
