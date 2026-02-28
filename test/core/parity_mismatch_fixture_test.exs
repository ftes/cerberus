defmodule Cerberus.CoreParityMismatchFixtureTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag drivers: [:static, :browser]
  test "parity static mismatch fixture is reachable in static and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/oracle/mismatch")
        |> assert_has(text: "Oracle mismatch static fixture marker", exact: true)
      end
    )
  end

  @tag drivers: [:live, :browser]
  test "parity live mismatch fixture is reachable in live and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/oracle/mismatch")
        |> assert_has(text: "Oracle mismatch live fixture marker", exact: true)
      end
    )
  end
end
