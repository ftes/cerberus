defmodule Cerberus.CoreOracleMismatchTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Fixtures
  alias Cerberus.Harness

  @moduletag :conformance
  @moduletag drivers: [:static, :live, :browser]

  test "oracle mismatch fixtures are reachable in all drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit(Fixtures.oracle_mismatch_path())
      |> assert_has([text: Fixtures.oracle_static_marker()], exact: true)
      |> visit(Fixtures.oracle_live_mismatch_path())
      |> assert_has([text: Fixtures.oracle_live_marker()], exact: true)
    end)
  end
end
