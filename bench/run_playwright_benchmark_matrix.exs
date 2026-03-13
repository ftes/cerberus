defmodule Cerberus.Bench.RunPlaywrightBenchmarkMatrix do
  @moduledoc false

  @header [
    "runner",
    "browser",
    "scenario",
    "iterations",
    "warmup",
    "concurrency",
    "mean_round_ms",
    "mean_per_flow_ms",
    "median_round_ms",
    "p95_round_ms"
  ]

  @default_runners [:cerberus, :playwright, :live, :phoenix_test]
  @default_scenarios ["churn", "churn_no_delay", "locator_stress"]
  @default_browsers %{
    cerberus: ["chrome", "firefox"],
    playwright: ["chromium", "firefox"],
    live: ["phoenix"],
    phoenix_test: ["phoenix"]
  }

  def run(args \\ []) do
    opts = parse_args(args)
    init_outputs(opts)
    emit_csv_row(opts, Enum.join(@header, ","))

    failures =
      opts
      |> selected_runs()
      |> Enum.reduce([], fn entry, failures ->
        case run_entry(entry, opts) do
          {:ok, rows} ->
            Enum.each(rows, &emit_csv_row(opts, &1))
            failures

          {:error, message} ->
            record_failure(opts, entry, message)
            [{entry, message} | failures]
        end
      end)
      |> Enum.reverse()

    if failures != [] do
      raise failure_summary(failures, opts)
    end
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          iterations: :integer,
          warmup: :integer,
          concurrency: :integer,
          out: :string,
          runners: :string,
          scenarios: :string,
          browsers: :string
        ]
      )

    %{
      iterations: parsed[:iterations] || 3,
      warmup: parsed[:warmup] || 1,
      concurrency: max(parsed[:concurrency] || 1, 1),
      out: parsed[:out],
      runners: parse_csv_list(parsed[:runners], Enum.map(@default_runners, &Atom.to_string/1)),
      scenarios: parse_csv_list(parsed[:scenarios], @default_scenarios),
      browsers: parse_browser_filter(parsed[:browsers])
    }
  end

  defp parse_csv_list(nil, default), do: default

  defp parse_csv_list(value, _default) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_browser_filter(nil), do: nil
  defp parse_browser_filter(value), do: parse_csv_list(value, [])

  defp selected_runs(opts) do
    Enum.flat_map(opts.runners, fn runner_name ->
      runner = String.to_existing_atom(runner_name)
      browsers = selected_browsers(runner, opts.browsers)

      for browser <- browsers, scenario <- opts.scenarios do
        %{runner: runner, browser: browser, scenario: scenario}
      end
    end)
  end

  defp selected_browsers(runner, nil), do: Map.fetch!(@default_browsers, runner)

  defp selected_browsers(runner, browser_filter) do
    @default_browsers
    |> Map.fetch!(runner)
    |> Enum.filter(&(&1 in browser_filter))
  end

  defp run_entry(%{runner: :cerberus, browser: browser, scenario: scenario}, opts) do
    args = [
      "run",
      "bench/cerberus_playwright_liveview_flow_benchmark.exs",
      "--iterations",
      Integer.to_string(opts.iterations),
      "--warmup",
      Integer.to_string(opts.warmup),
      "--scenario",
      scenario,
      "--concurrency",
      Integer.to_string(opts.concurrency)
    ]

    env =
      case browser do
        "firefox" -> [{"CERBERUS_BROWSER_NAME", "firefox"}]
        _ -> []
      end

    {:ok, [capture_csv_row!("mix", args, env)]}
  end

  defp run_entry(%{runner: :playwright, browser: browser, scenario: scenario}, opts) do
    env =
      case browser do
        "firefox" -> [{"FIREFOX", ""}]
        _ -> []
      end

    args = [
      "run",
      "bench/run_playwright_liveview_flow_benchmark.exs",
      "--iterations",
      Integer.to_string(opts.iterations),
      "--warmup",
      Integer.to_string(opts.warmup),
      "--scenario",
      scenario,
      "--concurrency",
      Integer.to_string(opts.concurrency),
      "--browser",
      browser
    ]

    {:ok, [capture_csv_row!("mix", args, env)]}
  end

  defp run_entry(%{runner: :live, browser: "phoenix", scenario: scenario}, opts) do
    case live_round_samples(scenario, opts) do
      {:error, message} ->
        {:error, message}

      {:ok, samples} ->
        {:ok,
         [
           summary_row(
             "live",
             "phoenix",
             scenario,
             opts.iterations,
             opts.warmup,
             opts.concurrency,
             Enum.reverse(samples)
           )
         ]}
    end
  end

  defp run_entry(%{runner: :phoenix_test, browser: "phoenix", scenario: scenario}, opts) do
    case phoenix_test_round_samples(scenario, opts) do
      {:error, message} ->
        {:error, message}

      {:ok, samples} ->
        {:ok,
         [
           summary_row(
             "phoenix_test",
             "phoenix",
             scenario,
             opts.iterations,
             opts.warmup,
             opts.concurrency,
             Enum.reverse(samples)
           )
         ]}
    end
  end

  defp live_round_samples(scenario, opts) do
    1..(opts.warmup + opts.iterations)
    |> Enum.reduce_while([], fn round_index, samples ->
      case run_live_round(scenario, round_index, opts) do
        {:ok, round_ms} ->
          next_samples =
            if round_index <= opts.warmup do
              samples
            else
              [round_ms | samples]
            end

          {:cont, next_samples}

        {:error, message} ->
          {:halt, {:error, message}}
      end
    end)
    |> case do
      {:error, message} -> {:error, message}
      samples -> {:ok, Enum.reverse(samples)}
    end
  end

  defp phoenix_test_round_samples(scenario, opts) do
    1..(opts.warmup + opts.iterations)
    |> Enum.reduce_while([], fn round_index, samples ->
      case run_phoenix_test_round(scenario, round_index, opts) do
        {:ok, round_ms} ->
          next_samples =
            if round_index <= opts.warmup do
              samples
            else
              [round_ms | samples]
            end

          {:cont, next_samples}

        {:error, message} ->
          {:halt, {:error, message}}
      end
    end)
    |> case do
      {:error, message} -> {:error, message}
      samples -> {:ok, Enum.reverse(samples)}
    end
  end

  defp run_live_round(scenario, round_index, opts) do
    results_path = live_results_path(scenario, round_index)

    env = [
      {"CERBERUS_BENCH_SCENARIO", scenario},
      {"CERBERUS_BENCH_CONCURRENCY", Integer.to_string(opts.concurrency)},
      {"CERBERUS_BENCH_RESULTS_PATH", results_path}
    ]

    args = [
      "test",
      "--force",
      "--max-cases",
      Integer.to_string(opts.concurrency),
      "bench/live_performance_benchmark_test.exs"
    ]

    try do
      row = capture_csv_row!("mix", args, env)
      {:ok, parse_round_ms!(row)}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp run_phoenix_test_round(scenario, round_index, opts) do
    results_path = phoenix_test_results_path(scenario, round_index)

    env = [
      {"CERBERUS_BENCH_SCENARIO", scenario},
      {"CERBERUS_BENCH_CONCURRENCY", Integer.to_string(opts.concurrency)},
      {"CERBERUS_BENCH_RESULTS_PATH", results_path}
    ]

    args = [
      "test",
      "--force",
      "--max-cases",
      Integer.to_string(opts.concurrency),
      "bench/phoenix_test_performance_benchmark_test.exs"
    ]

    try do
      row = capture_csv_row!("mix", args, env)
      {:ok, parse_round_ms!(row)}
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  defp init_outputs(opts) do
    if out_path = opts[:out] do
      File.mkdir_p!(Path.dirname(out_path))
      File.write!(out_path, "")

      if failure_path = failure_out_path(out_path) do
        File.write!(failure_path, "")
      end
    end
  end

  defp emit_csv_row(opts, row) when is_binary(row) do
    IO.puts(row)

    if out_path = opts[:out] do
      File.write!(out_path, row <> "\n", [:append])
    end
  end

  defp record_failure(opts, entry, message) do
    formatted = format_failure(entry, message)
    IO.write(:stderr, formatted)

    if out_path = opts[:out] do
      File.write!(failure_out_path(out_path), formatted, [:append])
    end
  end

  defp format_failure(entry, message) do
    """
    ## benchmark failure
    runner=#{entry.runner} browser=#{entry.browser} scenario=#{entry.scenario}
    #{message}

    """
  end

  defp failure_out_path(out_path) when is_binary(out_path), do: out_path <> ".failures.txt"

  defp failure_summary(failures, opts) do
    output_note =
      case opts[:out] do
        nil -> "partial rows were already written to stdout"
        out_path -> "partial rows were preserved in #{out_path}"
      end

    failure_note =
      case opts[:out] do
        nil -> "failure details were written to stderr"
        out_path -> "failure details were preserved in #{failure_out_path(out_path)}"
      end

    labels =
      Enum.map_join(failures, ", ", fn {entry, _message} -> "#{entry.runner}/#{entry.browser}/#{entry.scenario}" end)

    "benchmark matrix completed with #{length(failures)} failed row(s): #{labels}; #{output_note}; #{failure_note}"
  end

  defp live_results_path(scenario, round_index) do
    Path.join("tmp", "live-benchmark-#{scenario}-#{round_index}-#{System.unique_integer([:positive])}.csv")
  end

  defp phoenix_test_results_path(scenario, round_index) do
    Path.join("tmp", "phoenix-test-benchmark-#{scenario}-#{round_index}-#{System.unique_integer([:positive])}.csv")
  end

  defp capture_csv_row!(cmd, args, env) do
    {output, exit_code} =
      System.cmd(cmd, args,
        env: [{"MIX_ENV", "test"} | env],
        stderr_to_stdout: true
      )

    if exit_code != 0 do
      raise """
      benchmark command failed: #{Enum.join([cmd | args], " ")}

      #{output}
      """
    end

    output
    |> String.split("\n", trim: true)
    |> Enum.reverse()
    |> Enum.find(
      &(String.starts_with?(&1, "cerberus,") or String.starts_with?(&1, "playwright,") or
          String.starts_with?(&1, "live,") or String.starts_with?(&1, "phoenix_test,"))
    )
    |> case do
      nil ->
        raise """
        benchmark command did not emit a CSV row: #{Enum.join([cmd | args], " ")}

        #{output}
        """

      row ->
        row
    end
  end

  defp parse_round_ms!(row) when is_binary(row) do
    row
    |> String.split(",")
    |> Enum.at(6)
    |> case do
      nil -> raise "benchmark row missing mean_round_ms: #{row}"
      value -> String.to_float(value)
    end
  end

  defp summary_row(runner, browser, scenario, iterations, warmup, concurrency, round_samples) do
    metrics = summarize(round_samples, concurrency)

    Enum.join(
      [
        runner,
        browser,
        scenario,
        Integer.to_string(iterations),
        Integer.to_string(warmup),
        Integer.to_string(concurrency),
        format_ms(metrics.mean_round_ms),
        format_ms(metrics.mean_per_flow_ms),
        format_ms(metrics.median_round_ms),
        format_ms(metrics.p95_round_ms)
      ],
      ","
    )
  end

  defp summarize(round_samples, concurrency) do
    sorted = Enum.sort(round_samples)

    %{
      mean_round_ms: Enum.sum(round_samples) / max(length(round_samples), 1),
      mean_per_flow_ms: Enum.sum(round_samples) / max(length(round_samples) * concurrency, 1),
      median_round_ms: percentile(sorted, 0.5),
      p95_round_ms: percentile(sorted, 0.95)
    }
  end

  defp percentile([], _pct), do: 0.0

  defp percentile(samples, pct) do
    index =
      samples
      |> length()
      |> Kernel.*(pct)
      |> Float.ceil()
      |> trunc()
      |> max(1)
      |> Kernel.-(1)
      |> min(length(samples) - 1)

    Enum.at(samples, index)
  end

  defp format_ms(value), do: "~.3f" |> :io_lib.format([value]) |> IO.iodata_to_binary()
end

Cerberus.Bench.RunPlaywrightBenchmarkMatrix.run(System.argv())
