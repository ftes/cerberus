results_path = System.get_env("CERBERUS_BENCH_RESULTS_PATH") || "tmp/live-form-submit-benchmark.csv"

File.mkdir_p!(Path.dirname(results_path))
File.rm(results_path)

defmodule Cerberus.Bench.LiveFormSubmitBenchmark do
  @moduledoc false

  @header "runner,browser,scenario,iterations,warmup,concurrency,mean_round_ms,mean_per_flow_ms,median_round_ms,p95_round_ms"

  @spec csv_header() :: String.t()
  def csv_header, do: @header

  @spec round_duration_ms([{term(), integer(), integer()}]) :: float()
  def round_duration_ms(entries) when is_list(entries) do
    timings = Enum.map(entries, fn {_worker, started, finished} -> {started, finished} end)

    case timings do
      [] ->
        0.0

      timings ->
        started = timings |> Enum.map(&elem(&1, 0)) |> Enum.min()
        finished = timings |> Enum.map(&elem(&1, 1)) |> Enum.max()
        (finished - started) / 1_000.0
    end
  end

  @spec single_round_row(pos_integer(), float()) :: String.t()
  def single_round_row(concurrency, round_ms) when is_integer(concurrency) and concurrency > 0 and is_number(round_ms) do
    mean_per_flow_ms = round_ms / concurrency

    Enum.join(
      [
        "live",
        "phoenix",
        "form_submit_loop",
        "1",
        "0",
        Integer.to_string(concurrency),
        format_ms(round_ms),
        format_ms(mean_per_flow_ms),
        format_ms(round_ms),
        format_ms(round_ms)
      ],
      ","
    )
  end

  defp format_ms(value), do: "~.3f" |> :io_lib.format([value]) |> IO.iodata_to_binary()
end

defmodule Cerberus.LiveFormSubmitBenchmarkTest do
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

  import Cerberus

  alias Cerberus.TestSupport.LiveFormSubmitBenchmark

  @results_path System.get_env("CERBERUS_BENCH_RESULTS_PATH") || "tmp/live-form-submit-benchmark.csv"

  @moduletag timeout: 120_000

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "live form submit benchmark worker", %{conn: conn, worker: worker} do
    started = System.monotonic_time(:microsecond)

    [conn: conn, timeout_ms: 20_000]
    |> session()
    |> LiveFormSubmitBenchmark.run_flow(timeout_ms: 20_000)

    finished = System.monotonic_time(:microsecond)

    File.write!(@results_path, "#{worker},#{started},#{finished}\n", [:append])
  end
end

ExUnit.after_suite(fn _results ->
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

    round_ms = Cerberus.Bench.LiveFormSubmitBenchmark.round_duration_ms(entries)

    IO.puts(Cerberus.Bench.LiveFormSubmitBenchmark.csv_header())
    IO.puts(Cerberus.Bench.LiveFormSubmitBenchmark.single_round_row(concurrency, round_ms))

    File.rm(results_path)
  end
end)
