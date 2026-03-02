defmodule Cerberus.SQLSandboxUserAgentTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Ecto.Adapters.SQL.Sandbox
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

  setup context do
    [repo] = Application.get_env(:cerberus, :ecto_repos, [])
    owner_pid = Sandbox.start_owner!(repo, shared: !context.async)

    on_exit(fn ->
      Sandbox.stop_owner(owner_pid)
    end)

    {:ok, repo: repo, owner_pid: owner_pid}
  end

  test "sql_sandbox_user_agent/2 returns encoded metadata", %{repo: repo, owner_pid: owner_pid} do
    assert sql_sandbox_user_agent(repo, owner_pid) ==
             repo
             |> PhoenixSandbox.metadata_for(owner_pid)
             |> PhoenixSandbox.encode_metadata()
  end

  test "sql_sandbox_user_agent/1 uses first configured repo", %{owner_pid: owner_pid} do
    [repo | _] = Application.get_env(:cerberus, :ecto_repos, [])

    assert sql_sandbox_user_agent(owner_pid) ==
             repo
             |> PhoenixSandbox.metadata_for(owner_pid)
             |> PhoenixSandbox.encode_metadata()
  end

  test "sql_sandbox_user_agent/1 raises when no ecto repos are configured", %{owner_pid: owner_pid} do
    previous_repos = Application.get_env(:cerberus, :ecto_repos, [])

    try do
      Application.put_env(:cerberus, :ecto_repos, [])

      assert_raise ArgumentError, ~r/sql_sandbox_user_agent\/1 requires :cerberus, :ecto_repos/, fn ->
        sql_sandbox_user_agent(owner_pid)
      end
    after
      Application.put_env(:cerberus, :ecto_repos, previous_repos)
    end
  end
end
