defmodule CerberusTest.SQLSandboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures.SandboxMessages
  alias Cerberus.Session
  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

  setup context do
    [repo] = Application.get_env(:cerberus, :ecto_repos, [])
    owner_pid = Sandbox.start_owner!(repo, shared: !context.async)

    metadata_header =
      repo
      |> PhoenixSandbox.metadata_for(owner_pid)
      |> PhoenixSandbox.encode_metadata()

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.delete_req_header("user-agent")
      |> Plug.Conn.put_req_header("user-agent", metadata_header)

    on_exit(fn ->
      Sandbox.stop_owner(owner_pid)
    end)

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
    session(driver, conn: context.sandbox_conn, sandbox_metadata: context.sandbox_metadata)
  end
end
