defmodule Cerberus.PlaywrightPerformanceBenchmarkTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.TestSupport.BrowserSessions
  alias Cerberus.TestSupport.PlaywrightPerformanceBenchmark

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "browser benchmark flow completes on the shared playwright fixture" do
    BrowserSessions.session!()
    |> PlaywrightPerformanceBenchmark.run_cerberus_flow()
    |> assert_has(text("Candidate carried forward: wizard-prime", exact: true))
  end

  test "browser locator-stress benchmark flow completes on the shared playwright fixture" do
    BrowserSessions.session!()
    |> PlaywrightPerformanceBenchmark.run_cerberus_flow(:locator_stress)
    |> assert_has(text("Assignment carried forward: queue-cobalt", exact: true))
  end

  test "browser benchmark flow completes concurrently across sessions" do
    sessions = for _ <- 1..2, do: BrowserSessions.session!()

    sessions
    |> Task.async_stream(
      fn session ->
        session
        |> PlaywrightPerformanceBenchmark.run_cerberus_flow()
        |> assert_has(text("Candidate carried forward: wizard-prime", exact: true))
      end,
      ordered: true,
      max_concurrency: 2,
      timeout: 30_000
    )
    |> Enum.each(fn result ->
      assert match?({:ok, _}, result)
    end)
  end

  for driver <- [:phoenix, :browser] do
    test "assignment modal probe opens and selects on the shared playwright fixture (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> PlaywrightPerformanceBenchmark.run_assignment_modal_probe(timeout_ms: 20_000)
      |> assert_has(text("Selected assignment: Queue Cobalt", exact: true))
    end
  end

  defp driver_session(:phoenix, %{conn: conn}), do: session(conn: conn, timeout_ms: 20_000)
  defp driver_session(:browser, _context), do: BrowserSessions.session!(timeout_ms: 20_000)
end
