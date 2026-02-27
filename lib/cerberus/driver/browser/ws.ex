defmodule Cerberus.Driver.Browser.WS do
  @moduledoc false

  use WebSockex

  @type owner_event ::
          {:cerberus_bidi_connected, pid()}
          | {:cerberus_bidi_frame, pid(), binary()}
          | {:cerberus_bidi_disconnected, pid(), term()}

  @spec start_link(String.t(), pid()) :: {:ok, pid()} | {:error, term()}
  def start_link(url, owner) when is_binary(url) and is_pid(owner) do
    WebSockex.start_link(url, __MODULE__, %{owner: owner})
  end

  @spec send_text(pid(), binary()) :: :ok
  def send_text(pid, payload) when is_pid(pid) and is_binary(payload) do
    WebSockex.cast(pid, {:send_text, payload})
  end

  @spec close(pid()) :: :ok
  def close(pid) when is_pid(pid) do
    WebSockex.cast(pid, :close)
  end

  @impl true
  def handle_connect(_conn, state) do
    send_owner(state, {:cerberus_bidi_connected, self()})
    {:ok, state}
  end

  @impl true
  def handle_cast({:send_text, payload}, state) do
    {:reply, {:text, payload}, state}
  end

  def handle_cast(:close, state) do
    {:close, state}
  end

  @impl true
  def handle_frame({:text, message}, state) do
    send_owner(state, {:cerberus_bidi_frame, self(), message})
    {:ok, state}
  end

  def handle_frame(_frame, state) do
    {:ok, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    send_owner(state, {:cerberus_bidi_disconnected, self(), reason})
    {:ok, state}
  end

  defp send_owner(%{owner: owner}, event) when is_pid(owner) and is_tuple(event) do
    send(owner, event)
    :ok
  end
end
