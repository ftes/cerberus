defmodule Cerberus.Profiling do
  @moduledoc false

  @table :cerberus_profiling
  @owner_name __MODULE__.Owner
  @env_name "CERBERUS_PROFILE"
  @false_values ["", "0", "false", "off", "no"]
  @enabled_override_key {__MODULE__, :enabled_override}
  @context_key {__MODULE__, :context}

  @type bucket :: term()
  @type context :: term()
  @type sample :: %{
          bucket: bucket(),
          context: context() | nil,
          count: pos_integer(),
          total_us: non_neg_integer(),
          avg_us: float()
        }

  @spec enabled?() :: boolean()
  def enabled? do
    case Process.get(@enabled_override_key) do
      enabled? when is_boolean(enabled?) ->
        enabled?

      _ ->
        @env_name
        |> System.get_env("")
        |> String.trim()
        |> String.downcase()
        |> then(&(&1 not in @false_values))
    end
  end

  @doc false
  @spec put_enabled_override(boolean() | nil) :: :ok
  def put_enabled_override(enabled?) when is_boolean(enabled?) do
    Process.put(@enabled_override_key, enabled?)
    :ok
  end

  def put_enabled_override(nil) do
    Process.delete(@enabled_override_key)
    :ok
  end

  @spec current_context() :: context() | nil
  def current_context, do: Process.get(@context_key)

  @spec put_context(context() | nil) :: :ok
  def put_context(nil) do
    Process.delete(@context_key)
    :ok
  end

  def put_context(context) do
    Process.put(@context_key, context)
    :ok
  end

  @spec with_context(context() | nil, (-> result)) :: result when result: var
  def with_context(context, fun) when is_function(fun, 0) do
    previous_context = current_context()
    put_context(context)

    try do
      fun.()
    after
      put_context(previous_context)
    end
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

  @spec snapshot(keyword()) :: [sample()]
  def snapshot(opts \\ []) do
    group_by = Keyword.get(opts, :group_by, :bucket)
    context_filter = Keyword.get(opts, :context, :all)

    if group_by not in [:bucket, :context_bucket] do
      raise ArgumentError, ":group_by must be :bucket or :context_bucket, got: #{inspect(group_by)}"
    end

    case :ets.whereis(@table) do
      :undefined ->
        []

      _ ->
        @table
        |> :ets.tab2list()
        |> Enum.map(&normalize_row/1)
        |> Enum.filter(&matches_context_filter?(&1.context, context_filter))
        |> aggregate_rows(group_by)
        |> Enum.sort_by(& &1.total_us, :desc)
    end
  end

  @spec dump_summary(keyword()) :: :ok
  def dump_summary(opts \\ []) when is_list(opts) do
    limit = Keyword.get(opts, :limit, 30)
    rows = opts |> snapshot() |> Enum.take(limit)

    if rows != [] do
      IO.puts("")
      IO.puts("Cerberus profiling summary (Elixir-side)")

      Enum.each(rows, fn row ->
        IO.puts(
          "#{format_row_prefix(row)} count=#{row.count} total_ms=#{format_ms(row.total_us)} avg_ms=#{format_ms(row.avg_us)}"
        )
      end)
    end

    :ok
  end

  defp put_sample(bucket, elapsed_us) when is_integer(elapsed_us) and elapsed_us >= 0 do
    _ = ensure_table!()
    key = {current_context(), bucket}
    :ets.update_counter(@table, key, [{2, 1}, {3, elapsed_us}], {key, 0, 0})
    :ok
  end

  defp normalize_row({{context, bucket}, count, total_us}) do
    %{context: context, bucket: bucket, count: count, total_us: total_us}
  end

  defp normalize_row({bucket, count, total_us}) do
    %{context: nil, bucket: bucket, count: count, total_us: total_us}
  end

  defp matches_context_filter?(_context, :all), do: true
  defp matches_context_filter?(context, context_filter), do: context == context_filter

  defp aggregate_rows(rows, :bucket) do
    rows
    |> Enum.group_by(& &1.bucket)
    |> Enum.map(fn {bucket, bucket_rows} ->
      count = Enum.reduce(bucket_rows, 0, &(&1.count + &2))
      total_us = Enum.reduce(bucket_rows, 0, &(&1.total_us + &2))
      %{bucket: bucket, context: nil, count: count, total_us: total_us, avg_us: total_us / count}
    end)
  end

  defp aggregate_rows(rows, :context_bucket) do
    Enum.map(rows, fn %{context: context, bucket: bucket, count: count, total_us: total_us} ->
      %{context: context, bucket: bucket, count: count, total_us: total_us, avg_us: total_us / count}
    end)
  end

  defp format_row_prefix(%{context: nil, bucket: bucket}), do: inspect(bucket)
  defp format_row_prefix(%{context: context, bucket: bucket}), do: "#{inspect(context)} #{inspect(bucket)}"

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
