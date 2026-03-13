defmodule Cerberus.PlaywrightPerformanceBenchmarkTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.TestSupport.PlaywrightPerformanceBenchmark

  test "browser benchmark flow completes on the shared playwright fixture" do
    :browser
    |> session()
    |> PlaywrightPerformanceBenchmark.run_cerberus_flow()
    |> assert_has(text("Candidate carried forward: wizard-prime", exact: true))
  end
end
