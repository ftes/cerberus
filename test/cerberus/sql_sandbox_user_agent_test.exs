defmodule Cerberus.SQLSandboxUserAgentTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "sql_sandbox_user_agent/2 returns encoded metadata" do
    assert "BeamMetadata (" <> _ = sql_sandbox_user_agent(Cerberus.Fixtures.Repo, %{async: false})
  end

  test "sql_sandbox_user_agent/1 accepts ExUnit context map" do
    assert "BeamMetadata (" <> _ = sql_sandbox_user_agent(%{async: false})
  end
end
