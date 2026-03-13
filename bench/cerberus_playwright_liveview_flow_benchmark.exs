Code.require_file("../test/test_helper.exs", __DIR__)

defmodule Cerberus.Bench.PlaywrightLiveViewFlow do
  @moduledoc false

  import Cerberus

  alias Cerberus.TestSupport.PlaywrightPerformanceBenchmark

  def run(args \\ []) do
    opts = parse_args(args)

    {_session, samples} =
      Enum.reduce(1..(opts.warmup + opts.iterations), {session(:browser), []}, fn index, {session, samples} ->
        {microseconds, session} =
          :timer.tc(fn ->
            PlaywrightPerformanceBenchmark.run_cerberus_flow(session)
          end)

        samples =
          if index <= opts.warmup do
            samples
          else
            [microseconds / 1_000.0 | samples]
          end

        {session, samples}
      end)

    metrics = summarize(Enum.reverse(samples))

    IO.puts("runner,iterations,warmup,mean_ms,median_ms,p95_ms")

    IO.puts(
      Enum.join(
        [
          "cerberus",
          Integer.to_string(opts.iterations),
          Integer.to_string(opts.warmup),
          format_ms(metrics.mean_ms),
          format_ms(metrics.median_ms),
          format_ms(metrics.p95_ms)
        ],
        ","
      )
    )
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [iterations: :integer, warmup: :integer]
      )

    %{
      iterations: parsed[:iterations] || 10,
      warmup: parsed[:warmup] || 2
    }
  end

  defp summarize(samples) do
    sorted = Enum.sort(samples)

    %{
      mean_ms: Enum.sum(samples) / max(length(samples), 1),
      median_ms: percentile(sorted, 0.5),
      p95_ms: percentile(sorted, 0.95)
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

Cerberus.Bench.PlaywrightLiveViewFlow.run(System.argv())
