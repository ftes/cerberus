defmodule Cerberus.BrowserUserAgentForSandboxTest do
  use ExUnit.Case, async: false

  import Cerberus.Browser

  alias Cerberus.Fixtures.Repo
  alias Ecto.Adapters.SQL.Sandbox, as: EctoSandbox
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

  test "user_agent_for_sandbox/2 returns encoded metadata" do
    assert "BeamMetadata (" <> _ = user_agent_for_sandbox(Repo, %{async: false})
  end

  test "user_agent_for_sandbox/1 accepts ExUnit context map" do
    assert "BeamMetadata (" <> _ = user_agent_for_sandbox(%{async: false})
  end

  test "user_agent_for_sandbox/2 reuses current process when repo is already checked out" do
    repo = Repo
    :ok = EctoSandbox.checkout(repo)

    on_exit(fn ->
      EctoSandbox.checkin(repo)
    end)

    metadata = repo |> user_agent_for_sandbox(%{async: true}) |> PhoenixSandbox.decode_metadata()

    assert metadata.owner == self()
    assert metadata.repo == repo
  end

  test "user_agent_for_sandbox/2 reuses current process when repo is already shared" do
    repo = Repo
    owner = EctoSandbox.start_owner!(repo, shared: true)

    on_exit(fn ->
      EctoSandbox.stop_owner(owner)
    end)

    metadata = repo |> user_agent_for_sandbox(%{async: false}) |> PhoenixSandbox.decode_metadata()

    assert metadata.owner == self()
    assert metadata.repo == repo
  end
end
