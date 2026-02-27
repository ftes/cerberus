defmodule Cerberus.Driver.Browser.BiDi do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDiSocket
  alias Cerberus.Driver.Browser.Runtime

  @default_command_timeout 5_000

  @type state :: %{
          next_id: pos_integer(),
          pending: %{optional(pos_integer()) => %{from: GenServer.from(), timer: reference()}},
          socket: pid() | nil
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec command(String.t(), map(), keyword()) :: {:ok, map()} | {:error, String.t(), map()}
  def command(method, params \\ %{}, opts \\ [])
      when is_binary(method) and is_map(params) and is_list(opts) do
    command(__MODULE__, method, params, opts)
  end

  @spec command(GenServer.server(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, String.t(), map()}
  def command(pid, method, params, opts)
      when is_binary(method) and is_map(params) do
    timeout = Keyword.get(opts, :timeout, @default_command_timeout)
    GenServer.call(pid, {:command, method, params, timeout}, timeout + 1_000)
  end

  @spec close(GenServer.server()) :: :ok
  def close(pid \\ __MODULE__) do
    GenServer.stop(pid, :normal)
  end

  @impl true
  def init(_opts) do
    {:ok, %{next_id: 1, pending: %{}, socket: nil}}
  end

  @impl true
  def handle_call({:command, method, params, timeout}, from, state) do
    with {:ok, web_socket_url} <- Runtime.web_socket_url(),
         {:ok, socket} <- BiDiSocket.ensure_connected(web_socket_url),
         {:ok, next_state} <- send_command(state, socket, method, params, timeout, from) do
      {:noreply, next_state}
    else
      {:error, reason} ->
        {:reply, {:error, "failed to dispatch bidi command", %{"reason" => inspect(reason)}},
         state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call(_message, _from, state) do
    {:reply, {:error, "unsupported bidi request", %{}}, state}
  end

  @impl true
  def handle_info({:cerberus_bidi_frame, socket, payload}, %{socket: socket} = state)
      when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, %{"id" => id} = response} ->
        {:noreply, resolve_pending(state, id, response)}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:cerberus_bidi_disconnected, socket, reason}, %{socket: socket} = state)
      when is_pid(socket) do
    BiDiSocket.clear(socket)
    pending = Map.values(state.pending)

    Enum.each(
      pending,
      &reply_and_cancel(&1, {:error, "bidi socket disconnected", %{"reason" => inspect(reason)}})
    )

    {:stop, {:bidi_disconnected, reason}, %{state | pending: %{}}}
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

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Enum.each(
      Map.values(state.pending),
      &reply_and_cancel(&1, {:error, "bidi connection terminating", %{}})
    )

    if is_pid(state.socket), do: BiDiSocket.clear(state.socket)
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

  defp send_command(state, socket, method, params, timeout, from) do
    id = state.next_id
    message = Jason.encode!(%{"id" => id, "method" => method, "params" => params})

    case BiDiSocket.send_text(message) do
      :ok ->
        timer = Process.send_after(self(), {:command_timeout, id}, timeout)
        pending = Map.put(state.pending, id, %{from: from, timer: timer})
        {:ok, %{state | next_id: id + 1, pending: pending, socket: socket}}

      {:error, reason} ->
        {:error, "failed to send bidi message", %{"reason" => inspect(reason)}}
    end
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
end
