Code.require_file("../test/test_helper.exs", __DIR__)

defmodule Cerberus.Bench.BrowserSessionStartupBreakdown do
  @moduledoc false

  import Cerberus

  alias Cerberus.Profiling

  @startup_buckets [
    {:driver_session, :browser, :new_session},
    {:driver_session, :browser, :start_browsing_context_supervisor},
    {:driver_session, :browser, :create_user_context},
    {:driver_session, :browser, :browser_create_user_context_command},
    {:driver_session, :browser, :configure_user_context_defaults},
    {:driver_session, :browser, :set_user_context_user_agent},
    {:driver_session, :browser, :add_user_context_init_scripts},
    {:driver_session, :browser, :start_initial_browsing_context},
    {:driver_session, :browser, :browsing_context_create_command},
    {:driver_session, :browser, :set_initial_browsing_context_viewport},
    {:driver_session, :browser, :subscribe_initial_browsing_context_events}
  ]

  def run(args \\ []) do
    opts = parse_args(args)

    System.put_env("CERBERUS_PROFILE", "1")
    Profiling.put_enabled_override(true)

    warm_runtime(opts.warmup)

    samples =
      Enum.map(1..opts.iterations, fn iteration ->
        Profiling.clear()

        {elapsed_us, _session} =
          :timer.tc(fn ->
            session(:browser)
          end)

        rows =
          Profiling.snapshot()
          |> Enum.filter(&(&1.bucket in @startup_buckets))
          |> Enum.sort_by(&Enum.find_index(@startup_buckets, fn bucket -> bucket == &1.bucket end))

        %{iteration: iteration, elapsed_us: elapsed_us, rows: rows}
      end)

    print_samples(samples)
    print_summary(samples)
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args, strict: [iterations: :integer, warmup: :integer])

    %{
      iterations: positive_integer(parsed[:iterations], 5),
      warmup: non_negative_integer(parsed[:warmup], 1)
    }
  end

  defp positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp positive_integer(_value, default), do: default

  defp non_negative_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp non_negative_integer(_value, default), do: default

  defp warm_runtime(warmup) when warmup > 0 do
    Enum.each(1..warmup, fn _ ->
      _ = session(:browser)
    end)
  end

  defp warm_runtime(_warmup), do: :ok

  defp print_samples(samples) do
    Enum.each(samples, fn sample ->
      IO.puts("")
      IO.puts("Iteration #{sample.iteration} total: #{format_ms(sample.elapsed_us)}ms")

      Enum.each(sample.rows, fn row ->
        IO.puts("  #{format_bucket(row.bucket)}: #{format_ms(row.total_us)}ms")
      end)
    end)
  end

  defp print_summary(samples) do
    IO.puts("")
    IO.puts("Mean startup breakdown")

    totals_by_bucket =
      Enum.reduce(samples, %{}, fn sample, acc ->
        Enum.reduce(sample.rows, acc, fn row, bucket_acc ->
          Map.update(bucket_acc, row.bucket, row.total_us, &(&1 + row.total_us))
        end)
      end)

    sample_count = max(length(samples), 1)
    mean_total_us = Enum.sum(Enum.map(samples, & &1.elapsed_us)) / sample_count

    IO.puts("  total new_session: #{format_ms(mean_total_us)}ms")

    Enum.each(@startup_buckets, fn bucket ->
      mean_us = Map.get(totals_by_bucket, bucket, 0) / sample_count
      IO.puts("  #{format_bucket(bucket)}: #{format_ms(mean_us)}ms")
    end)
  end

  defp format_bucket(bucket) when is_tuple(bucket) do
    bucket
    |> Tuple.to_list()
    |> Enum.map_join(".", &to_string/1)
  end

  defp format_ms(us) when is_integer(us) or is_float(us) do
    us
    |> Kernel./(1_000.0)
    |> :erlang.float_to_binary(decimals: 3)
  end
end

Cerberus.Bench.BrowserSessionStartupBreakdown.run(System.argv())
