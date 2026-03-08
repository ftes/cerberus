defmodule Cerberus.Driver.Browser.CdpBrowserProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.WS

  @connect_timeout_ms 5_000

  @type state :: %{
          debugger_address: String.t(),
          owner: pid() | nil,
          socket: pid(),
          slow_mo_ms: non_neg_integer(),
          next_id: pos_integer(),
          pending: %{optional(pos_integer()) => %{from: GenServer.from(), timer: reference()}}
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec command(pid(), String.t(), map(), pos_integer()) :: Types.bidi_response()
  def command(pid, method, params, timeout_ms \\ 5_000)
      when is_pid(pid) and is_binary(method) and is_map(params) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:command, method, params, timeout_ms}, timeout_ms + 1_000)
  end

  @spec create_browser_context(pid(), pos_integer()) :: Types.bidi_response()
  def create_browser_context(pid, timeout_ms \\ 5_000) when is_pid(pid) do
    command(pid, "Target.createBrowserContext", %{"disposeOnDetach" => true}, timeout_ms)
  end

  @spec dispose_browser_context(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def dispose_browser_context(pid, browser_context_id, timeout_ms \\ 5_000)
      when is_pid(pid) and is_binary(browser_context_id) do
    command(pid, "Target.disposeBrowserContext", %{"browserContextId" => browser_context_id}, timeout_ms)
  end

  @spec create_target(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def create_target(pid, browser_context_id, timeout_ms \\ 5_000) when is_pid(pid) and is_binary(browser_context_id) do
    command(
      pid,
      "Target.createTarget",
      %{"url" => "about:blank", "browserContextId" => browser_context_id},
      timeout_ms
    )
  end

  @spec close_target(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def close_target(pid, target_id, timeout_ms \\ 5_000) when is_pid(pid) and is_binary(target_id) do
    command(pid, "Target.closeTarget", %{"targetId" => target_id}, timeout_ms)
  end

  @spec get_targets(pid(), pos_integer()) :: Types.bidi_response()
  def get_targets(pid, timeout_ms \\ 5_000) when is_pid(pid) do
    command(pid, "Target.getTargets", %{}, timeout_ms)
  end

  @spec set_download_behavior(pid(), String.t(), String.t(), pos_integer()) :: Types.bidi_response()
  def set_download_behavior(pid, browser_context_id, download_path, timeout_ms \\ 5_000)
      when is_pid(pid) and is_binary(browser_context_id) and is_binary(download_path) do
    command(
      pid,
      "Browser.setDownloadBehavior",
      %{
        "behavior" => "allowAndName",
        "browserContextId" => browser_context_id,
        "downloadPath" => download_path,
        "eventsEnabled" => true
      },
      timeout_ms
    )
  end

  @spec get_cookies(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def get_cookies(pid, browser_context_id, timeout_ms \\ 5_000) when is_pid(pid) and is_binary(browser_context_id) do
    command(pid, "Storage.getCookies", %{"browserContextId" => browser_context_id}, timeout_ms)
  end

  @spec set_cookies(pid(), String.t(), [map()], pos_integer()) :: Types.bidi_response()
  def set_cookies(pid, browser_context_id, cookies, timeout_ms \\ 5_000)
      when is_pid(pid) and is_binary(browser_context_id) and is_list(cookies) do
    command(pid, "Storage.setCookies", %{"browserContextId" => browser_context_id, "cookies" => cookies}, timeout_ms)
  end

  @spec clear_cookies(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def clear_cookies(pid, browser_context_id, timeout_ms \\ 5_000) when is_pid(pid) and is_binary(browser_context_id) do
    command(pid, "Storage.clearCookies", %{"browserContextId" => browser_context_id}, timeout_ms)
  end

  @impl true
  def init(opts) do
    debugger_address = Keyword.fetch!(opts, :debugger_address)
    owner = Keyword.get(opts, :owner)
    slow_mo_ms = Keyword.get(opts, :slow_mo_ms, 0)

    with {:ok, socket_url} <- fetch_browser_socket_url(debugger_address),
         {:ok, socket} <- WS.start_link(socket_url, self(), slow_mo_ms: slow_mo_ms) do
      {:ok,
       %{
         debugger_address: debugger_address,
         owner: owner,
         socket: socket,
         slow_mo_ms: slow_mo_ms,
         next_id: 1,
         pending: %{}
       }}
    else
      {:error, reason} ->
        {:stop, {:cdp_browser_connect_failed, reason}}
    end
  end

  @impl true
  def handle_call({:command, method, params, timeout_ms}, from, state) do
    id = state.next_id
    payload = JSON.encode!(%{"id" => id, "method" => method, "params" => params})
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
    case JSON.decode(payload) do
      {:ok, %{"id" => id, "result" => result}} when is_integer(id) ->
        {:noreply, resolve_pending(state, id, {:ok, result})}

      {:ok, %{"id" => id, "error" => %{} = error}} when is_integer(id) ->
        {:noreply,
         resolve_pending(
           state,
           id,
           {:error, error["message"] || "cdp command failed", Map.delete(error, "message")}
         )}

      {:ok, %{"id" => id, "error" => reason}} when is_integer(id) ->
        {:noreply, resolve_pending(state, id, {:error, to_string(reason), %{}})}

      {:ok, %{"method" => method, "params" => params}} when is_binary(method) and is_map(params) ->
        if is_pid(state.owner) do
          send(state.owner, {:cerberus_cdp_browser_event, method, params})
        end

        {:noreply, state}

      _other ->
        {:noreply, state}
    end
  end

  def handle_info({:cerberus_bidi_disconnected, socket, reason}, %{socket: socket} = state) do
    Enum.each(state.pending, fn {_id, entry} ->
      Process.cancel_timer(entry.timer)
      GenServer.reply(entry.from, {:error, "cdp browser socket disconnected", %{"reason" => inspect(reason)}})
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

  @spec fetch_browser_socket_url(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp fetch_browser_socket_url(debugger_address) when is_binary(debugger_address) do
    url = ~c"http://" ++ String.to_charlist(debugger_address) ++ ~c"/json/version"

    case :httpc.request(:get, {url, []}, [timeout: @connect_timeout_ms], body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, body}} ->
        case JSON.decode(body) do
          {:ok, %{"webSocketDebuggerUrl" => socket_url}} when is_binary(socket_url) ->
            {:ok, socket_url}

          _ ->
            {:error, "failed to decode Chrome browser websocket url"}
        end

      {:ok, {{_version, status, _reason}, _headers, _body}} ->
        {:error, "failed to fetch Chrome browser websocket url: status #{status}"}

      {:error, reason} ->
        {:error, "failed to fetch Chrome browser websocket url: #{inspect(reason)}"}
    end
  end
end
