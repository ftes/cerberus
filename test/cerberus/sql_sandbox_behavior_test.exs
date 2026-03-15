defmodule Cerberus.SQLSandboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus
  import Cerberus.Browser

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.Fixtures.SandboxMessages
  alias Cerberus.TestSupport.BrowserSessions

  setup context do
    {:ok, sandbox_user_agent: user_agent_for_sandbox(Cerberus.Fixtures.Repo, context)}
  end

  for driver <- [:phoenix, :browser] do
    test "sandbox metadata keeps static DB reads isolated across drivers (#{driver})", context do
      session = sandbox_session(unquote(driver), context)
      body = unique_message("static", session)
      SandboxMessages.insert!(body)

      session
      |> visit("/sandbox/messages")
      |> assert_has(text(body, exact: true))
    end

    test "sandbox metadata keeps live DB reads isolated across drivers (#{driver})", context do
      session = sandbox_session(unquote(driver), context)
      body = unique_message("live", session)
      SandboxMessages.insert!(body)

      session
      |> visit("/live/sandbox/messages")
      |> assert_has(text(body, exact: true))
      |> click(role(:button, name: "Refresh", exact: true))
      |> assert_has(text(body, exact: true))
    end
  end

  test "sandbox metadata keeps delayed browser LiveView DB reads isolated on playwright fixture", context do
    :browser
    |> sandbox_session(context)
    |> visit("/phoenix_test/playwright/pw/live/ecto?delay_ms=100")
    |> assert_has(text("Version: PostgreSQL", exact: false), timeout: 5_000)
    |> assert_has(text("Long running: void", exact: true), timeout: 5_000)
    |> assert_has(text("Delayed version: PostgreSQL", exact: false), timeout: 5_000)
  end

  defp unique_message(prefix, session) do
    "#{prefix}-#{driver_tag(session)}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp sandbox_session(:browser, context), do: BrowserSessions.session!(user_agent: context.sandbox_user_agent)

  defp sandbox_session(:phoenix, _context), do: session(:phoenix)

  defp driver_tag(%Static{}), do: "static"
  defp driver_tag(%Live{}), do: "live"
  defp driver_tag(%Browser{}), do: "browser"
end
