defmodule Cerberus.LiveFormSubmitBenchmarkFlowTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.LiveFormSubmitBenchmark

  test "repeated live submits keep up with the latest submitted value" do
    :phoenix
    |> session(timeout_ms: 20_000)
    |> LiveFormSubmitBenchmark.run_flow(timeout_ms: 20_000)
    |> assert_has(text("no-change submitted: Frodo", exact: true), timeout: 20_000)
  end
end
