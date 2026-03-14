Code.require_file("phoenix_test_flow_benchmark.ex", __DIR__)
Code.require_file("phoenix_test_performance_benchmark.ex", __DIR__)

results_path = System.get_env("CERBERUS_BENCH_RESULTS_PATH") || "tmp/phoenix-test-flow-benchmark.csv"

File.mkdir_p!(Path.dirname(results_path))
File.rm(results_path)

defmodule Cerberus.PhoenixTestPerformanceBenchmarkTest do
  @concurrency (case System.get_env("CERBERUS_BENCH_CONCURRENCY") do
                  nil ->
                    1

                  value ->
                    case Integer.parse(String.trim(value)) do
                      {number, ""} when number > 0 -> number
                      _ -> 1
                    end
                end)
  use ExUnit.Case,
    async: true,
    parameterize: Enum.map(1..@concurrency, &%{worker: &1})

  alias Cerberus.Bench.PhoenixTestPerformanceBenchmark

  @scenario (case System.get_env("CERBERUS_BENCH_SCENARIO") do
               "churn_no_delay" -> :churn_no_delay
               "locator_stress" -> :locator_stress
               _ -> :churn
             end)

  @results_path System.get_env("CERBERUS_BENCH_RESULTS_PATH") ||
                  "tmp/phoenix-test-flow-benchmark.csv"

  @moduletag timeout: 120_000

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "phoenix test benchmark worker", %{conn: conn, worker: worker} do
    started = System.monotonic_time(:microsecond)

    _session =
      PhoenixTestPerformanceBenchmark.run_flow(conn, @scenario,
        timeout_ms: 20_000,
        step_trace_metadata: %{runner: "phoenix_test", scenario: @scenario, worker: worker}
      )

    finished = System.monotonic_time(:microsecond)

    File.write!(@results_path, "#{worker},#{started},#{finished}\n", [:append])
  end
end

ExUnit.after_suite(fn _results ->
  scenario =
    case System.get_env("CERBERUS_BENCH_SCENARIO") do
      "churn_no_delay" -> :churn_no_delay
      "locator_stress" -> :locator_stress
      _ -> :churn
    end

  concurrency =
    case System.get_env("CERBERUS_BENCH_CONCURRENCY") do
      nil ->
        1

      value ->
        case Integer.parse(String.trim(value)) do
          {number, ""} when number > 0 -> number
          _ -> 1
        end
    end

  if File.exists?(results_path) do
    entries =
      results_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(fn line ->
        case String.split(line, ",", parts: 3) do
          [worker, started, finished] ->
            {String.to_integer(worker), String.to_integer(started), String.to_integer(finished)}

          _ ->
            raise ArgumentError, "invalid benchmark entry #{inspect(line)}"
        end
      end)

    round_ms = Cerberus.Bench.PhoenixTestFlow.round_duration_ms(entries)

    IO.puts(Cerberus.Bench.PhoenixTestFlow.csv_header())
    IO.puts(Cerberus.Bench.PhoenixTestFlow.single_round_row(scenario, concurrency, round_ms))

    File.rm(results_path)
  end
end)
