defmodule Cerberus.ParityMismatchFixtureTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "parity static mismatch fixture is reachable in static and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/oracle/mismatch")
      |> assert_has(text: "Oracle mismatch static fixture marker", exact: true)
    end

    test "parity live mismatch fixture is reachable in live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/oracle/mismatch")
      |> assert_has(text: "Oracle mismatch live fixture marker", exact: true)
    end
  end
end
