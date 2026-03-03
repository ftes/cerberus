defmodule Cerberus.Profiling do
  @moduledoc false

  @table :cerberus_profiling
  @owner_name __MODULE__.Owner
  @env_name "CERBERUS_PROFILE"
  @false_values ["", "0", "false", "off", "no"]

  @type bucket :: term()
  @type sample :: %{
          bucket: bucket(),
          count: pos_integer(),
          total_us: non_neg_integer(),
          avg_us: float()
        }

  @spec enabled?() :: boolean()
  def enabled? do
    @env_name
    |> System.get_env("")
    |> String.trim()
    |> String.downcase()
    |> then(&(&1 not in @false_values))
  end

  @spec measure(bucket(), (-> result)) :: result when result: var
  def measure(bucket, fun) when is_function(fun, 0) do
    if enabled?() do
      start = System.monotonic_time()

      try do
        fun.()
      after
        elapsed_us =
          System.monotonic_time()
          |> Kernel.-(start)
          |> System.convert_time_unit(:native, :microsecond)

        put_sample(bucket, elapsed_us)
      end
    else
      fun.()
    end
  end

  @spec record_us(bucket(), non_neg_integer()) :: :ok
  def record_us(bucket, elapsed_us) when is_integer(elapsed_us) and elapsed_us >= 0 do
    if enabled?() do
      put_sample(bucket, elapsed_us)
    end

    :ok
  end

  @spec clear() :: :ok
  def clear do
    case :ets.whereis(@table) do
      :undefined -> :ok
      _ -> :ets.delete_all_objects(@table)
    end

    :ok
  end

  @spec snapshot() :: [sample()]
  def snapshot do
    case :ets.whereis(@table) do
      :undefined ->
        []

      _ ->
        @table
        |> :ets.tab2list()
        |> Enum.map(fn {bucket, count, total_us} ->
          %{
            bucket: bucket,
            count: count,
            total_us: total_us,
            avg_us: total_us / count
          }
        end)
        |> Enum.sort_by(& &1.total_us, :desc)
    end
  end

  @spec dump_summary(keyword()) :: :ok
  def dump_summary(opts \\ []) when is_list(opts) do
    limit = Keyword.get(opts, :limit, 30)

    rows = Enum.take(snapshot(), limit)

    if rows != [] do
      IO.puts("")
      IO.puts("Cerberus profiling summary (Elixir-side)")

      Enum.each(rows, fn %{bucket: bucket, count: count, total_us: total_us, avg_us: avg_us} ->
        IO.puts("#{inspect(bucket)} count=#{count} total_ms=#{format_ms(total_us)} avg_ms=#{format_ms(avg_us)}")
      end)
    end

    :ok
  end

  defp put_sample(bucket, elapsed_us) when is_integer(elapsed_us) and elapsed_us >= 0 do
    _ = ensure_table!()
    :ets.update_counter(@table, bucket, [{2, 1}, {3, elapsed_us}], {bucket, 0, 0})
    :ok
  end

  defp ensure_table! do
    ensure_owner!()
    @table
  end

  defp ensure_owner! do
    case Process.whereis(@owner_name) do
      pid when is_pid(pid) ->
        :ok

      _ ->
        case Agent.start(fn -> init_table!() end, name: @owner_name) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
        end
    end
  end

  defp init_table! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, {:write_concurrency, true}, {:read_concurrency, true}])

      _ ->
        @table
    end
  end

  defp format_ms(microseconds) when is_integer(microseconds) do
    :erlang.float_to_binary(microseconds / 1_000.0, decimals: 3)
  end

  defp format_ms(microseconds) when is_float(microseconds) do
    :erlang.float_to_binary(microseconds / 1_000.0, decimals: 3)
  end
end
