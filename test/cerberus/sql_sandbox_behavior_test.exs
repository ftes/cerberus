defmodule Cerberus.SQLSandboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Fixtures.SandboxMessages

  setup context do
    {:ok, sandbox_user_agent: sql_sandbox_user_agent(Cerberus.Fixtures.Repo, context)}
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

  defp unique_message(prefix, session) do
    "#{prefix}-#{driver_tag(session)}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp sandbox_session(:browser, context), do: session(:browser, user_agent: context.sandbox_user_agent)
  defp sandbox_session(:phoenix, _context), do: session(:phoenix)

  defp driver_tag(%StaticSession{}), do: "static"
  defp driver_tag(%LiveSession{}), do: "live"
  defp driver_tag(%BrowserSession{}), do: "browser"
end
