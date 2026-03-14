defmodule Cerberus.LiveFormActionBenchmarkFlowTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.LiveFormActionBenchmark

  test "repeated live form changes settle to the latest values" do
    :phoenix
    |> session(timeout_ms: 20_000)
    |> LiveFormActionBenchmark.run_flow(timeout_ms: 20_000)
    |> assert_has(text("race: dwarf", exact: true), timeout: 20_000)
    |> assert_has(text("age: 44", exact: true), timeout: 20_000)
    |> assert_has(text("contact: email", exact: true), timeout: 20_000)
  end
end
