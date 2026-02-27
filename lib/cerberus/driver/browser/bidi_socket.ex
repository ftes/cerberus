defmodule Cerberus.Driver.Browser.BiDiSocket do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.WS

  @type state :: %{
          owner: pid() | atom(),
          socket: pid() | nil,
          monitor_ref: reference() | nil
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec ensure_connected(String.t()) :: {:ok, pid()} | {:error, term()}
  def ensure_connected(url) when is_binary(url) do
    GenServer.call(__MODULE__, {:ensure_connected, url}, 5_000)
  end

  @spec send_text(binary()) :: :ok | {:error, term()}
  def send_text(payload) when is_binary(payload) do
    GenServer.call(__MODULE__, {:send_text, payload})
  end

  @spec close() :: :ok
  def close do
    GenServer.call(__MODULE__, :close)
  end

  @spec clear(pid()) :: :ok
  def clear(socket) when is_pid(socket) do
    GenServer.cast(__MODULE__, {:clear, socket})
  end

  @impl true
  def init(opts) do
    owner = Keyword.get(opts, :owner, Cerberus.Driver.Browser.BiDi)
    {:ok, %{owner: owner, socket: nil, monitor_ref: nil}}
  end

  @impl true
  def handle_call({:ensure_connected, _url}, _from, %{socket: socket} = state) when is_pid(socket) do
    if Process.alive?(socket) do
      {:reply, {:ok, socket}, state}
    else
      {:reply, {:error, :socket_not_alive}, clear_state(state)}
    end
  end

  def handle_call({:ensure_connected, url}, _from, state) do
    with {:ok, owner} <- resolve_owner(state.owner),
         {:ok, socket} <- WS.start_link(url, owner) do
      monitor_ref = Process.monitor(socket)
      {:reply, {:ok, socket}, %{state | socket: socket, monitor_ref: monitor_ref}}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:send_text, payload}, _from, %{socket: socket} = state) when is_pid(socket) do
    if Process.alive?(socket) do
      :ok = WS.send_text(socket, payload)
      {:reply, :ok, state}
    else
      {:reply, {:error, :socket_not_alive}, clear_state(state)}
    end
  end

  def handle_call({:send_text, _payload}, _from, state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:close, _from, %{socket: socket} = state) when is_pid(socket) do
    _ = WS.close(socket)
    {:reply, :ok, clear_state(state)}
  end

  def handle_call(:close, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:clear, socket}, %{socket: socket} = state) do
    {:noreply, clear_state(state)}
  end

  def handle_cast({:clear, _socket}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, monitor_ref, :process, socket, _reason}, %{monitor_ref: monitor_ref, socket: socket} = state) do
    {:noreply, clear_state(state)}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp resolve_owner(owner) when is_pid(owner) do
    if Process.alive?(owner), do: {:ok, owner}, else: {:error, :owner_not_alive}
  end

  defp resolve_owner(owner) when is_atom(owner) do
    case Process.whereis(owner) do
      nil -> {:error, :owner_not_registered}
      pid -> {:ok, pid}
    end
  end

  defp clear_state(state) do
    if is_reference(state.monitor_ref), do: Process.demonitor(state.monitor_ref, [:flush])
    %{state | socket: nil, monitor_ref: nil}
  end
end
