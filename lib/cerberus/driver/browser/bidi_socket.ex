defmodule Cerberus.Driver.Browser.BiDiSocket do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Driver.Browser.WS

  @type state :: %{
          owner: pid() | atom(),
          sockets: %{optional(:chrome | :firefox) => %{socket: pid(), url: String.t(), monitor_ref: reference()}}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec ensure_connected(:chrome | :firefox, String.t()) :: {:ok, pid()} | {:error, term()}
  def ensure_connected(browser_name, url) when browser_name in [:chrome, :firefox] and is_binary(url) do
    GenServer.call(__MODULE__, {:ensure_connected, browser_name, url}, 5_000)
  end

  @spec send_text(:chrome | :firefox, binary()) :: :ok | {:error, term()}
  def send_text(browser_name, payload) when browser_name in [:chrome, :firefox] and is_binary(payload) do
    GenServer.call(__MODULE__, {:send_text, browser_name, payload})
  end

  @spec close() :: :ok
  def close do
    GenServer.call(__MODULE__, :close)
  end

  @spec clear(:chrome | :firefox, pid()) :: :ok
  def clear(browser_name, socket) when browser_name in [:chrome, :firefox] and is_pid(socket) do
    GenServer.cast(__MODULE__, {:clear, browser_name, socket})
  end

  @impl true
  def init(opts) do
    owner = Keyword.get(opts, :owner, Cerberus.Driver.Browser.BiDi)
    {:ok, %{owner: owner, sockets: %{}}}
  end

  @impl true
  def handle_call({:ensure_connected, browser_name, url}, _from, state) do
    case Map.get(state.sockets, browser_name) do
      %{socket: socket, url: ^url} = entry ->
        if Process.alive?(socket) do
          {:reply, {:ok, socket}, state}
        else
          sockets = drop_entry(state.sockets, browser_name, entry)
          connect_socket(state, browser_name, url, sockets)
        end

      %{socket: socket} = entry when is_pid(socket) ->
        _ = WS.close(socket)
        sockets = drop_entry(state.sockets, browser_name, entry)
        connect_socket(state, browser_name, url, sockets)

      _ ->
        connect_socket(state, browser_name, url, state.sockets)
    end
  end

  def handle_call({:send_text, browser_name, payload}, _from, state) do
    case Map.get(state.sockets, browser_name) do
      %{socket: socket} when is_pid(socket) ->
        if Process.alive?(socket) do
          :ok = WS.send_text(socket, payload)
          {:reply, :ok, state}
        else
          sockets = drop_entry(state.sockets, browser_name, Map.fetch!(state.sockets, browser_name))
          {:reply, {:error, :socket_not_alive}, %{state | sockets: sockets}}
        end

      _ ->
        {:reply, {:error, :not_connected}, state}
    end
  end

  def handle_call(:close, _from, state) do
    Enum.each(state.sockets, fn {_browser_name, %{socket: socket}} ->
      _ = WS.close(socket)
    end)

    {:reply, :ok, %{state | sockets: %{}}}
  end

  @impl true
  def handle_cast({:clear, browser_name, socket}, state) do
    case Map.get(state.sockets, browser_name) do
      %{socket: ^socket} = entry ->
        sockets = drop_entry(state.sockets, browser_name, entry)
        {:noreply, %{state | sockets: sockets}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, monitor_ref, :process, socket, _reason}, state) do
    browser_name =
      Enum.find_value(state.sockets, fn {browser_name, entry} ->
        if entry.monitor_ref == monitor_ref and entry.socket == socket, do: browser_name
      end)

    if browser_name do
      entry = Map.fetch!(state.sockets, browser_name)
      sockets = drop_entry(state.sockets, browser_name, entry)

      {:noreply, %{state | sockets: sockets}}
    else
      {:noreply, state}
    end
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

  defp connect_socket(state, browser_name, url, sockets) do
    with {:ok, owner} <- resolve_owner(state.owner),
         {:ok, normalized_browser} <- normalize_browser_name(browser_name),
         {:ok, socket} <- WS.start_link(url, owner, ws_opts(normalized_browser)) do
      monitor_ref = Process.monitor(socket)
      sockets = Map.put(sockets, normalized_browser, %{socket: socket, url: url, monitor_ref: monitor_ref})
      {:reply, {:ok, socket}, %{state | sockets: sockets}}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp drop_entry(sockets, browser_name, %{monitor_ref: monitor_ref}) do
    if is_reference(monitor_ref), do: Process.demonitor(monitor_ref, [:flush])
    Map.delete(sockets, browser_name)
  end

  defp normalize_browser_name(browser_name) do
    {:ok, Runtime.browser_name(browser_name: browser_name)}
  rescue
    _ -> {:error, :invalid_browser_name}
  end

  defp ws_opts(_browser_name) do
    [extra_headers: [{"Sec-WebSocket-Protocol", "webDriverBidi"}]]
  end
end
