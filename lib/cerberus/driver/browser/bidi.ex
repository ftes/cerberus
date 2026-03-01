defmodule Cerberus.Driver.Browser.BiDi do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDiSocket
  alias Cerberus.Driver.Browser.Runtime

  @default_command_timeout_ms 10_000

  @type browser_name :: :chrome | :firefox

  @type state :: %{
          next_id: pos_integer(),
          pending: %{
            optional(pos_integer()) => %{from: GenServer.from(), timer: reference(), browser_name: browser_name()}
          },
          sockets: %{optional(browser_name()) => pid()},
          subscribers: %{optional(browser_name()) => %{optional(pid()) => reference()}}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec command(String.t(), map(), keyword()) :: {:ok, map()} | {:error, String.t(), map()}
  def command(method, params \\ %{}, opts \\ []) when is_binary(method) and is_map(params) and is_list(opts) do
    command(__MODULE__, method, params, opts)
  end

  @spec command(GenServer.server(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, String.t(), map()}
  def command(pid, method, params, opts) when is_binary(method) and is_map(params) do
    timeout =
      case Keyword.fetch(opts, :timeout) do
        {:ok, value} -> value
        :error -> default_command_timeout_ms(opts)
      end

    message =
      if pid == __MODULE__ do
        {:command, method, params, timeout, opts}
      else
        {:command, method, params, timeout}
      end

    GenServer.call(pid, message, timeout + 1_000)
  end

  @spec close(GenServer.server()) :: :ok
  def close(pid \\ __MODULE__) do
    GenServer.stop(pid, :normal)
  end

  @spec subscribe(pid(), keyword()) :: :ok | {:error, term()}
  def subscribe(subscriber, opts \\ []) when is_pid(subscriber) and is_list(opts) do
    browser_name = Runtime.browser_name(opts)
    GenServer.call(__MODULE__, {:subscribe, subscriber, browser_name})
  end

  @spec unsubscribe(pid(), keyword()) :: :ok
  def unsubscribe(subscriber, opts \\ []) when is_pid(subscriber) and is_list(opts) do
    browser_name = Runtime.browser_name(opts)
    GenServer.call(__MODULE__, {:unsubscribe, subscriber, browser_name})
  end

  @impl true
  def init(_opts) do
    {:ok, %{next_id: 1, pending: %{}, sockets: %{}, subscribers: %{}}}
  end

  @impl true
  def handle_call({:subscribe, subscriber, browser_name}, _from, state) do
    state = put_subscriber(state, subscriber, browser_name)
    {:reply, :ok, state}
  end

  def handle_call({:unsubscribe, subscriber, browser_name}, _from, state) do
    state = drop_subscriber(state, subscriber, browser_name)
    {:reply, :ok, state}
  end

  def handle_call({:command, method, params, timeout, opts}, from, state) do
    browser_name = Runtime.browser_name(opts)

    with {:ok, web_socket_url} <- Runtime.web_socket_url(opts),
         {:ok, socket} <- BiDiSocket.ensure_connected(browser_name, web_socket_url),
         {:ok, next_state} <- send_command(state, browser_name, socket, method, params, timeout, from) do
      {:noreply, next_state}
    else
      {:error, reason} ->
        {:reply, {:error, "failed to dispatch bidi command", %{"reason" => inspect(reason)}}, state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call(_message, _from, state) do
    {:reply, {:error, "unsupported bidi request", %{}}, state}
  end

  @impl true
  def handle_info({:cerberus_bidi_frame, socket, payload}, state) when is_binary(payload) do
    case browser_name_for_socket(state, socket) do
      nil ->
        {:noreply, state}

      browser_name ->
        case JSON.decode(payload) do
          {:ok, %{"id" => id} = response} ->
            {:noreply, resolve_pending(state, id, response)}

          {:ok, %{"method" => _method} = event} ->
            broadcast_event(state, browser_name, event)
            {:noreply, state}

          _ ->
            {:noreply, state}
        end
    end
  end

  def handle_info({:cerberus_bidi_disconnected, socket, reason}, state) when is_pid(socket) do
    case browser_name_for_socket(state, socket) do
      nil ->
        {:noreply, state}

      browser_name ->
        BiDiSocket.clear(browser_name, socket)
        {state, failed_pending} = pop_pending_for_browser(state, browser_name)

        Enum.each(
          failed_pending,
          &reply_and_cancel(&1, {:error, "bidi socket disconnected", %{"reason" => inspect(reason)}})
        )

        {:noreply, %{state | sockets: Map.delete(state.sockets, browser_name)}}
    end
  end

  def handle_info({:command_timeout, id}, state) do
    case Map.pop(state.pending, id) do
      {nil, _pending} ->
        {:noreply, state}

      {entry, pending} ->
        GenServer.reply(entry.from, {:error, "bidi command timeout", %{"id" => id}})
        {:noreply, %{state | pending: pending}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    subscribers =
      Enum.reduce(state.subscribers, %{}, fn {browser_name, browser_subscribers}, acc ->
        case Map.get(browser_subscribers, pid) do
          ^ref ->
            Map.put(acc, browser_name, Map.delete(browser_subscribers, pid))

          _ ->
            Map.put(acc, browser_name, browser_subscribers)
        end
      end)

    {:noreply, %{state | subscribers: subscribers}}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Enum.each(
      Map.values(state.pending),
      &reply_and_cancel(&1, {:error, "bidi connection terminating", %{}})
    )

    Enum.each(state.sockets, fn {browser_name, socket} ->
      BiDiSocket.clear(browser_name, socket)
    end)

    :ok
  end

  defp resolve_pending(state, id, response) do
    case Map.pop(state.pending, id) do
      {nil, pending} ->
        %{state | pending: pending}

      {entry, pending} ->
        Process.cancel_timer(entry.timer)
        GenServer.reply(entry.from, decode_response(response))
        %{state | pending: pending}
    end
  end

  defp send_command(state, browser_name, socket, method, params, timeout, from) do
    id = state.next_id
    message = JSON.encode!(%{"id" => id, "method" => method, "params" => params})

    case BiDiSocket.send_text(browser_name, message) do
      :ok ->
        timer = Process.send_after(self(), {:command_timeout, id}, timeout)
        pending = Map.put(state.pending, id, %{from: from, timer: timer, browser_name: browser_name})

        {:ok, %{state | next_id: id + 1, pending: pending, sockets: Map.put(state.sockets, browser_name, socket)}}

      {:error, reason} ->
        {:error, "failed to send bidi message", %{"reason" => inspect(reason)}}
    end
  end

  defp pop_pending_for_browser(state, browser_name) do
    {failed, remaining} = Enum.split_with(state.pending, fn {_id, entry} -> entry.browser_name == browser_name end)
    failed_entries = Enum.map(failed, fn {_id, entry} -> entry end)
    remaining_pending = Map.new(remaining)
    {%{state | pending: remaining_pending}, failed_entries}
  end

  defp browser_name_for_socket(state, socket) when is_pid(socket) do
    Enum.find_value(state.sockets, fn {browser_name, candidate} ->
      if candidate == socket, do: browser_name
    end)
  end

  defp decode_response(%{"type" => "error"} = response) do
    reason =
      response["message"] ||
        response["error"] ||
        "bidi command failed"

    {:error, reason, response}
  end

  defp decode_response(%{"error" => _} = response) do
    reason = response["message"] || response["error"] || "bidi command failed"
    {:error, reason, response}
  end

  defp decode_response(%{"result" => result}) when is_map(result), do: {:ok, result}
  defp decode_response(response), do: {:ok, response}

  defp reply_and_cancel(entry, reply) do
    Process.cancel_timer(entry.timer)
    GenServer.reply(entry.from, reply)
  end

  defp put_subscriber(state, subscriber, browser_name) do
    browser_subscribers = Map.get(state.subscribers, browser_name, %{})

    case Map.get(browser_subscribers, subscriber) do
      nil ->
        ref = Process.monitor(subscriber)
        subscribers = Map.put(state.subscribers, browser_name, Map.put(browser_subscribers, subscriber, ref))
        %{state | subscribers: subscribers}

      _ref ->
        state
    end
  end

  defp drop_subscriber(state, subscriber, browser_name) do
    browser_subscribers = Map.get(state.subscribers, browser_name, %{})

    case Map.pop(browser_subscribers, subscriber) do
      {nil, _} ->
        state

      {ref, remaining} ->
        Process.demonitor(ref, [:flush])
        %{state | subscribers: Map.put(state.subscribers, browser_name, remaining)}
    end
  end

  defp broadcast_event(state, browser_name, event) do
    state.subscribers
    |> Map.get(browser_name, %{})
    |> Map.keys()
    |> Enum.each(fn subscriber ->
      send(subscriber, {:cerberus_bidi_event, event})
    end)
  end

  defp default_command_timeout_ms(opts) when is_list(opts) do
    opts
    |> merged_browser_opts()
    |> Keyword.get(:bidi_command_timeout_ms)
    |> normalize_non_negative_integer(@default_command_timeout_ms)
  end

  defp merged_browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp normalize_non_negative_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_negative_integer(_value, default), do: default
end
