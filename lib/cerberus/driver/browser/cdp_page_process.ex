defmodule Cerberus.Driver.Browser.CdpPageProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.WS

  @connect_timeout_ms 5_000
  @list_retry_attempts 40
  @list_retry_sleep_ms 25

  @type state :: %{
          target_id: String.t(),
          socket: pid(),
          next_id: pos_integer(),
          pending: %{optional(pos_integer()) => %{from: GenServer.from(), timer: reference()}}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec evaluate(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def evaluate(pid, expression, timeout_ms)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:evaluate, expression, timeout_ms}, timeout_ms + 1_000)
  end

  @impl true
  def init(opts) do
    target_id = Keyword.fetch!(opts, :target_id)
    debugger_address = Keyword.fetch!(opts, :debugger_address)
    slow_mo_ms = Keyword.get(opts, :slow_mo_ms, 0)

    with {:ok, socket_url} <- fetch_page_socket_url(debugger_address, target_id, @list_retry_attempts),
         {:ok, socket} <- WS.start_link(socket_url, self(), slow_mo_ms: slow_mo_ms) do
      {:ok, %{target_id: target_id, socket: socket, next_id: 1, pending: %{}}}
    else
      {:error, reason} ->
        {:stop, {:cdp_page_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call({:evaluate, expression, timeout_ms}, from, state) do
    id = state.next_id

    payload =
      JSON.encode!(%{
        "id" => id,
        "method" => "Runtime.evaluate",
        "params" => %{
          "expression" => expression,
          "awaitPromise" => true,
          "returnByValue" => true,
          "userGesture" => true
        }
      })

    :ok = WS.send_text(state.socket, payload)
    timer = Process.send_after(self(), {:command_timeout, id}, timeout_ms)
    pending = Map.put(state.pending, id, %{from: from, timer: timer})
    {:noreply, %{state | next_id: id + 1, pending: pending}}
  end

  @impl true
  def handle_info({:cerberus_bidi_connected, _socket}, state) do
    {:noreply, state}
  end

  def handle_info({:cerberus_bidi_frame, socket, payload}, %{socket: socket} = state) when is_binary(payload) do
    {:noreply, handle_decoded_frame(state, JSON.decode(payload))}
  end

  def handle_info({:cerberus_bidi_disconnected, socket, reason}, %{socket: socket} = state) do
    Enum.each(state.pending, fn {_id, entry} ->
      Process.cancel_timer(entry.timer)
      GenServer.reply(entry.from, {:error, "cdp page socket disconnected", %{"reason" => inspect(reason)}})
    end)

    {:stop, :normal, %{state | pending: %{}}}
  end

  def handle_info({:command_timeout, id}, state) do
    case Map.pop(state.pending, id) do
      {nil, _pending} ->
        {:noreply, state}

      {entry, pending} ->
        GenServer.reply(entry.from, {:error, "cdp command timeout", %{"id" => id}})
        {:noreply, %{state | pending: pending}}
    end
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = WS.close(state.socket)
    :ok
  end

  @spec resolve_pending(state(), pos_integer(), Types.bidi_response()) :: state()
  defp resolve_pending(state, id, reply) do
    case Map.pop(state.pending, id) do
      {nil, pending} ->
        %{state | pending: pending}

      {entry, pending} ->
        Process.cancel_timer(entry.timer)
        GenServer.reply(entry.from, reply)
        %{state | pending: pending}
    end
  end

  @spec fetch_page_socket_url(String.t(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp fetch_page_socket_url(_debugger_address, _target_id, 0) do
    {:error, "cdp page websocket not found for target"}
  end

  defp fetch_page_socket_url(debugger_address, target_id, attempts_left)
       when is_binary(debugger_address) and is_binary(target_id) and is_integer(attempts_left) and attempts_left > 0 do
    url = ~c"http://" ++ String.to_charlist(debugger_address) ++ ~c"/json/list"

    case :httpc.request(:get, {url, []}, [timeout: @connect_timeout_ms], body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, body}} ->
        handle_target_list_response(debugger_address, target_id, attempts_left, body)

      {:ok, {{_version, status, _reason}, _headers, _body}} ->
        {:error, "failed to fetch Chrome target list: status #{status}"}

      {:error, reason} ->
        {:error, "failed to fetch Chrome target list: #{inspect(reason)}"}
    end
  end

  @spec match_target?(map(), String.t()) :: boolean()
  defp match_target?(%{"id" => id, "type" => "page"}, target_id) when is_binary(id), do: id == target_id
  defp match_target?(_, _target_id), do: false

  defp handle_decoded_frame(state, {:ok, %{"id" => id, "result" => %{"result" => _remote_value} = result}})
       when is_integer(id) do
    resolve_pending(state, id, {:ok, result})
  end

  defp handle_decoded_frame(state, {:ok, %{"id" => id, "result" => result}}) when is_integer(id) do
    resolve_pending(state, id, {:ok, result})
  end

  defp handle_decoded_frame(state, {:ok, %{"id" => id, "error" => %{} = error}}) when is_integer(id) do
    resolve_pending(state, id, {:error, error["message"] || "cdp command failed", Map.delete(error, "message")})
  end

  defp handle_decoded_frame(state, {:ok, %{"id" => id, "error" => reason}}) when is_integer(id) do
    resolve_pending(state, id, {:error, to_string(reason), %{}})
  end

  defp handle_decoded_frame(state, _decoded), do: state

  defp handle_target_list_response(debugger_address, target_id, attempts_left, body)
       when is_binary(debugger_address) and is_binary(target_id) and is_integer(attempts_left) and attempts_left > 0 do
    case JSON.decode(body) do
      {:ok, targets} when is_list(targets) ->
        find_page_socket_url(targets, debugger_address, target_id, attempts_left)

      _ ->
        {:error, "failed to decode Chrome target list"}
    end
  end

  defp find_page_socket_url(targets, debugger_address, target_id, attempts_left)
       when is_list(targets) and is_binary(debugger_address) and is_binary(target_id) and is_integer(attempts_left) and
              attempts_left > 0 do
    case Enum.find(targets, &match_target?(&1, target_id)) do
      %{"webSocketDebuggerUrl" => socket_url} when is_binary(socket_url) ->
        {:ok, socket_url}

      _ ->
        Process.sleep(@list_retry_sleep_ms)
        fetch_page_socket_url(debugger_address, target_id, attempts_left - 1)
    end
  end
end
