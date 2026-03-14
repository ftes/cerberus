Code.require_file("../test/test_helper.exs", __DIR__)

defmodule Cerberus.Bench.PlaywrightLiveViewFlow do
  @moduledoc false

  import Cerberus

  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.TestSupport.PlaywrightPerformanceBenchmark

  @benchmark_timeout_ms 5_000
  @benchmark_ready_timeout_ms 5_000
  @round_task_timeout_ms 120_000

  def run(args \\ []) do
    configure_browser_from_env!()
    opts = parse_args(args)
    browser_name = browser_name()
    sessions = for _ <- 1..opts.concurrency, do: session(:browser, benchmark_session_opts())

    {_sessions, round_samples} =
      Enum.reduce(1..(opts.warmup + opts.iterations), {sessions, []}, fn index, {sessions, samples} ->
        {microseconds, sessions} =
          :timer.tc(fn ->
            run_round(sessions, opts.scenario, opts.concurrency)
          end)

        samples =
          if index <= opts.warmup do
            samples
          else
            [microseconds / 1_000.0 | samples]
          end

        {sessions, samples}
      end)

    metrics = summarize(Enum.reverse(round_samples), opts.concurrency)

    IO.puts(
      "runner,browser,scenario,iterations,warmup,concurrency,mean_round_ms,mean_per_flow_ms,median_round_ms,p95_round_ms"
    )

    IO.puts(
      Enum.join(
        [
          "cerberus",
          Atom.to_string(browser_name),
          Atom.to_string(opts.scenario),
          Integer.to_string(opts.iterations),
          Integer.to_string(opts.warmup),
          Integer.to_string(opts.concurrency),
          format_ms(metrics.mean_round_ms),
          format_ms(metrics.mean_per_flow_ms),
          format_ms(metrics.median_round_ms),
          format_ms(metrics.p95_round_ms)
        ],
        ","
      )
    )
  end

  defp run_round(sessions, scenario, concurrency) do
    sessions
    |> Task.async_stream(
      fn session ->
        PlaywrightPerformanceBenchmark.run_cerberus_flow(session, scenario)
      end,
      ordered: true,
      max_concurrency: concurrency,
      timeout: @round_task_timeout_ms
    )
    |> Enum.map(fn
      {:ok, session} -> session
      {:exit, reason} -> exit(reason)
    end)
  end

  defp benchmark_session_opts do
    [
      timeout_ms: @benchmark_timeout_ms,
      ready_timeout_ms: @benchmark_ready_timeout_ms
    ]
  end

  defp configure_browser_from_env! do
    current = Application.get_env(:cerberus, :browser, [])

    override =
      case System.get_env("CERBERUS_BROWSER_NAME") do
        "firefox" ->
          [browser_name: :firefox, firefox_binary: System.fetch_env!("FIREFOX")]

        "chrome" ->
          [
            browser_name: :chrome,
            chrome_binary: System.fetch_env!("CHROME"),
            chromedriver_binary: System.fetch_env!("CHROMEDRIVER")
          ]

        _ ->
          []
      end

    if override != [] do
      Application.put_env(:cerberus, :browser, Keyword.merge(current, override))
    end
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [iterations: :integer, warmup: :integer, scenario: :string, concurrency: :integer]
      )

    %{
      iterations: parsed[:iterations] || 10,
      warmup: parsed[:warmup] || 2,
      scenario: parse_scenario(parsed[:scenario]),
      concurrency: max(parsed[:concurrency] || 1, 1)
    }
  end

  defp parse_scenario("locator_stress"), do: :locator_stress
  defp parse_scenario("churn_no_delay"), do: :churn_no_delay
  defp parse_scenario(_), do: :churn

  defp summarize(round_samples, concurrency) do
    sorted = Enum.sort(round_samples)

    %{
      mean_round_ms: Enum.sum(round_samples) / max(length(round_samples), 1),
      mean_per_flow_ms: Enum.sum(round_samples) / max(length(round_samples) * concurrency, 1),
      median_round_ms: percentile(sorted, 0.5),
      p95_round_ms: percentile(sorted, 0.95)
    }
  end

  defp browser_name do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Runtime.browser_name()
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

Cerberus.Bench.PlaywrightLiveViewFlow.run(System.argv())
