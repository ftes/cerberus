defmodule Cerberus.SQLSandboxBehaviorTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Fixtures.SandboxMessages
  alias Cerberus.Session

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
      |> click_button(button("Refresh", exact: true))
      |> assert_has(text(body, exact: true))
    end
  end

  defp unique_message(prefix, session) do
    "#{prefix}-#{Session.driver_kind(session)}-#{System.unique_integer([:positive, :monotonic])}"
  end

  defp sandbox_session(driver, context) when driver in [:phoenix, :browser] do
    opts = [conn: context.sandbox_conn, sandbox_metadata: context.sandbox_metadata]

    case driver do
      :browser -> session(:browser, Keyword.put(opts, :user_agent, context.sandbox_metadata))
      :phoenix -> session(:phoenix, opts)
    end
  end
end
