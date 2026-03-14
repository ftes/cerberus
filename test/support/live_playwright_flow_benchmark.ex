defmodule Cerberus.Bench.LivePlaywrightFlow do
  @moduledoc false

  @header "runner,browser,scenario,iterations,warmup,concurrency,mean_round_ms,mean_per_flow_ms,median_round_ms,p95_round_ms"
  defguardp valid_summary_args(iterations, warmup, concurrency, round_samples)
            when is_integer(iterations) and iterations > 0 and
                   is_integer(warmup) and warmup >= 0 and
                   is_integer(concurrency) and concurrency > 0 and
                   is_list(round_samples)

  @type scenario :: :churn | :churn_no_delay | :locator_stress

  @spec csv_header() :: String.t()
  def csv_header, do: @header

  @spec single_round_row(scenario(), pos_integer(), float()) :: String.t()
  def single_round_row(scenario, concurrency, round_ms)
      when scenario in [:churn, :churn_no_delay, :locator_stress] and is_integer(concurrency) and concurrency > 0 and
             is_number(round_ms) do
    format_row(scenario, 1, 0, concurrency, [round_ms * 1.0])
  end

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

  @spec summary_row(scenario(), pos_integer(), non_neg_integer(), pos_integer(), [number()]) :: String.t()
  def summary_row(scenario, iterations, warmup, concurrency, round_samples)
      when scenario in [:churn, :churn_no_delay, :locator_stress] and
             valid_summary_args(iterations, warmup, concurrency, round_samples) do
    format_row(scenario, iterations, warmup, concurrency, Enum.map(round_samples, &(&1 * 1.0)))
  end

  defp format_row(scenario, iterations, warmup, concurrency, round_samples) do
    metrics = summarize(round_samples, concurrency)

    Enum.join(
      [
        "live",
        "phoenix",
        Atom.to_string(scenario),
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
