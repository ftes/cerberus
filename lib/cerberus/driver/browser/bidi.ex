defmodule Cerberus.Driver.Browser.BiDi do
  @moduledoc false

  use GenServer

  alias Bibbidi.Connection
  alias Bibbidi.Session, as: BibbidiSession
  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Driver.Browser.TransientErrors
  alias Cerberus.Driver.Browser.Types

  @default_command_timeout_ms 10_000
  @event_methods [
    "browsingContext.navigationStarted",
    "browsingContext.domContentLoaded",
    "browsingContext.load",
    "browsingContext.downloadWillBegin",
    "browsingContext.downloadEnd"
  ]

  @type state :: %{
          browser_name: Types.browser_name() | nil,
          connection: pid() | nil,
          connection_ref: reference() | nil,
          subscribers: %{optional(pid()) => reference()}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec command(String.t(), Types.bidi_params(), keyword()) :: Types.bidi_response()
  def command(method, params \\ %{}, opts \\ []) when is_binary(method) and is_map(params) and is_list(opts) do
    command_via_manager(__MODULE__, method, params, opts)
  end

  @spec command(GenServer.server(), String.t(), Types.bidi_params(), keyword()) ::
          Types.bidi_response()
  def command(pid, method, params, opts) when pid != __MODULE__ and is_binary(method) and is_map(params) do
    timeout =
      case Keyword.fetch(opts, :timeout) do
        {:ok, value} -> value
        :error -> default_command_timeout_ms(opts)
      end

    GenServer.call(pid, {:command, method, params, timeout}, timeout + 1_000)
  end

  def command(pid, method, params, opts) when is_binary(method) and is_map(params) do
    command_via_manager(pid, method, params, opts)
  end

  defp command_via_manager(pid, method, params, opts) when is_binary(method) and is_map(params) and is_list(opts) do
    timeout =
      case Keyword.fetch(opts, :timeout) do
        {:ok, value} -> value
        :error -> default_command_timeout_ms(opts)
      end

    slow_mo_ms = Runtime.slow_mo_ms(opts)
    started_us = System.monotonic_time(:microsecond)
    record_transport_delay({:browser_bidi, :command_queue}, started_us)
    maybe_sleep_for_slow_mo(slow_mo_ms)

    case GenServer.call(pid, {:connection, opts}, timeout + 1_000 + slow_mo_ms) do
      {:ok, connection} ->
        maybe_reset_after_transport_close(
          command_response(connection, method, params, timeout),
          pid,
          opts
        )

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  @spec close(GenServer.server()) :: :ok
  def close(pid \\ __MODULE__) do
    GenServer.stop(pid, :normal)
  end

  @spec subscribe(pid(), keyword()) :: :ok | {:error, term()}
  def subscribe(subscriber, _opts \\ []) when is_pid(subscriber) do
    GenServer.call(__MODULE__, {:subscribe, subscriber})
  end

  @spec unsubscribe(pid(), keyword()) :: :ok
  def unsubscribe(subscriber, _opts \\ []) when is_pid(subscriber) do
    GenServer.call(__MODULE__, {:unsubscribe, subscriber})
  end

  @impl true
  def init(_opts) do
    {:ok, %{browser_name: nil, connection: nil, connection_ref: nil, subscribers: %{}}}
  end

  @impl true
  def handle_call({:subscribe, subscriber}, _from, state) do
    {:reply, :ok, put_subscriber(state, subscriber)}
  end

  def handle_call({:unsubscribe, subscriber}, _from, state) do
    {:reply, :ok, drop_subscriber(state, subscriber)}
  end

  def handle_call({:connection, opts}, _from, state) do
    case ensure_connected(state, opts) do
      {:ok, connection, next_state} ->
        {:reply, {:ok, connection}, next_state}

      {:error, reason, next_state} ->
        {:reply, {:error, reason}, next_state}
    end
  end

  def handle_call({:reset_connection, opts}, _from, state) do
    {:reply, :ok, reset_transport(state, opts)}
  end

  def handle_call(_message, _from, state) do
    {:reply, {:error, "unsupported bidi request", %{}}, state}
  end

  @impl true
  def handle_info({:bibbidi_event, method, params}, state) when is_binary(method) and is_map(params) do
    event = %{"method" => method, "params" => params}
    Enum.each(Map.keys(state.subscribers), &send(&1, {:cerberus_bidi_event, event}))
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, %{connection_ref: ref, connection: pid} = state) do
    state = reset_transport(state)
    {:stop, {:bidi_connection_down, reason}, %{state | connection: nil, connection_ref: nil}}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    subscribers =
      Enum.reduce(state.subscribers, %{}, fn {subscriber, subscriber_ref}, acc ->
        if subscriber == pid and subscriber_ref == ref do
          acc
        else
          Map.put(acc, subscriber, subscriber_ref)
        end
      end)

    {:noreply, %{state | subscribers: subscribers}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    maybe_close_connection(state.connection)
    :ok
  end

  defp ensure_connected(%{browser_name: browser_name, connection: pid} = state, opts) when is_pid(pid) do
    requested_browser_name = Runtime.browser_name(opts)

    if browser_name == requested_browser_name and Process.alive?(pid) do
      {:ok, pid, state}
    else
      ensure_connected(reset_transport(state, opts), opts)
    end
  end

  defp ensure_connected(state, opts) do
    browser_name = Runtime.browser_name(opts)

    with {:ok, web_socket_url} <- Runtime.web_socket_url(opts),
         {:ok, connection} <- Connection.start_link(url: web_socket_url),
         :ok <- maybe_start_direct_firefox_session(connection, opts),
         :ok <- subscribe_connection_events(connection) do
      Process.unlink(connection)
      connection_ref = Process.monitor(connection)
      {:ok, connection, %{state | connection: connection, connection_ref: connection_ref, browser_name: browser_name}}
    else
      {:error, reason} ->
        {:error, inspect(reason), state}
    end
  end

  defp maybe_reset_after_transport_close({:error, reason, details} = error, pid, opts) do
    if TransientErrors.transport_closed?(reason, details) do
      _ = GenServer.call(pid, {:reset_connection, opts})
    end

    error
  end

  defp maybe_reset_after_transport_close(result, _pid, _opts), do: result

  defp reset_transport(state, opts \\ []) do
    maybe_close_connection(state.connection)
    _ = Runtime.reset_session(runtime_reset_opts(state, opts))

    %{
      state
      | browser_name: nil,
        connection: nil,
        connection_ref: nil
    }
  end

  defp runtime_reset_opts(%{browser_name: browser_name}, opts) when is_atom(browser_name) and is_list(opts) do
    Keyword.put_new(opts, :browser_name, browser_name)
  end

  defp runtime_reset_opts(_state, opts), do: opts

  defp subscribe_connection_events(connection) when is_pid(connection) do
    Enum.reduce_while(@event_methods, :ok, fn method, :ok ->
      :ok = Connection.subscribe(connection, method, self())
      {:cont, :ok}
    end)
  end

  defp maybe_start_direct_firefox_session(connection, opts) when is_pid(connection) and is_list(opts) do
    if Runtime.browser_name(opts) == :firefox and is_nil(Runtime.remote_webdriver_url(opts)) do
      case BibbidiSession.new(connection) do
        {:ok, _capabilities} -> :ok
        {:error, reason} -> {:error, inspect(reason)}
      end
    else
      :ok
    end
  end

  defp maybe_close_connection(pid) when is_pid(pid) do
    _ = Connection.close(pid)
    :ok
  catch
    :exit, _reason -> :ok
  end

  defp maybe_close_connection(_pid), do: :ok

  defp put_subscriber(state, subscriber) do
    ref =
      case Map.get(state.subscribers, subscriber) do
        ref when is_reference(ref) -> ref
        _ -> Process.monitor(subscriber)
      end

    %{state | subscribers: Map.put(state.subscribers, subscriber, ref)}
  end

  defp drop_subscriber(state, subscriber) do
    case Map.pop(state.subscribers, subscriber) do
      {ref, subscribers} when is_reference(ref) ->
        Process.demonitor(ref, [:flush])
        %{state | subscribers: subscribers}

      {_, subscribers} ->
        %{state | subscribers: subscribers}
    end
  end

  defp normalize_response({:ok, result}) when is_map(result), do: {:ok, stringify_map_keys(result)}

  defp normalize_response({:error, error}) when is_map(error) do
    details = stringify_map_keys(error)
    reason = details["message"] || details["error"] || inspect(error)
    {:error, reason, details}
  end

  defp normalize_response({:error, reason}) do
    {:error, inspect(reason), %{}}
  end

  defp command_response(connection, method, params, timeout)
       when is_pid(connection) and is_binary(method) and is_map(params) and is_integer(timeout) do
    connection
    |> measure_command_roundtrip(method, params, timeout)
    |> normalize_response()
  end

  defp measure_command_roundtrip(connection, method, params, timeout) do
    Cerberus.Profiling.measure({:browser_bidi, method, :roundtrip}, fn ->
      Cerberus.Profiling.measure({:browser_bidi, :roundtrip}, fn ->
        Connection.send_command(connection, method, params, timeout: timeout)
      end)
    end)
  end

  defp stringify_map_keys(map) when is_struct(map) do
    map
    |> Map.from_struct()
    |> stringify_map_keys()
  end

  defp stringify_map_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_value(value)}
      {key, value} -> {key, stringify_value(value)}
    end)
  end

  defp stringify_value(value) when is_struct(value), do: stringify_map_keys(value)
  defp stringify_value(value) when is_map(value), do: stringify_map_keys(value)
  defp stringify_value(value) when is_list(value), do: Enum.map(value, &stringify_value/1)
  defp stringify_value(value), do: value

  defp maybe_sleep_for_slow_mo(ms) when is_integer(ms) and ms > 0 do
    Process.sleep(ms)
  end

  defp maybe_sleep_for_slow_mo(_ms), do: :ok

  defp record_transport_delay(bucket, started_us) when is_integer(started_us) do
    Cerberus.Profiling.record_us(bucket, max(System.monotonic_time(:microsecond) - started_us, 0))
  end

  defp default_command_timeout_ms(opts) do
    browser_opts =
      :cerberus
      |> Application.get_env(:browser, [])
      |> Keyword.merge(Keyword.get(opts, :browser, []))

    Keyword.get(opts, :bidi_command_timeout_ms, browser_opts[:bidi_command_timeout_ms] || @default_command_timeout_ms)
  end
end
