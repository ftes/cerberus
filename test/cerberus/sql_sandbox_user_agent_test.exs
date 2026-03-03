defmodule Cerberus.SQLSandboxUserAgentTest do
  use ExUnit.Case, async: true

  import Cerberus

  test "sql_sandbox_user_agent/2 returns encoded metadata" do
    assert "BeamMetadata (" <> _ = sql_sandbox_user_agent(Cerberus.Fixtures.Repo, %{async: false})
  end
end
