defmodule Cerberus.SQLSandboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Fixtures.SandboxMessages

  setup context do
    metadata_header = sql_sandbox_user_agent(Cerberus.Fixtures.Repo, context)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.delete_req_header("user-agent")
      |> Plug.Conn.put_req_header("user-agent", metadata_header)

    {:ok, sandbox_metadata: metadata_header, sandbox_conn: conn}
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
      |> click(button("Refresh", exact: true))
      |> assert_has(text(body, exact: true))
    end
  end

  defp unique_message(prefix, session) do
    "#{prefix}-#{driver_tag(session)}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp sandbox_session(driver, context) when driver in [:phoenix, :browser] do
    opts = [conn: context.sandbox_conn, sandbox_metadata: context.sandbox_metadata]

    case driver do
      :browser -> session(:browser, Keyword.put(opts, :user_agent, context.sandbox_metadata))
      :phoenix -> session(:phoenix, opts)
    end
  end

  defp driver_tag(%StaticSession{}), do: "static"
  defp driver_tag(%LiveSession{}), do: "live"
  defp driver_tag(%BrowserSession{}), do: "browser"
end
