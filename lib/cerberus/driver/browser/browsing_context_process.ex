defmodule Cerberus.Driver.Browser.BrowsingContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.CdpBrowserProcess
  alias Cerberus.Driver.Browser.CdpPageProcess
  alias Cerberus.Driver.Browser.Types

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @download_events ["Page.downloadWillBegin", "Page.downloadProgress"]
  @dialog_events ["Page.javascriptDialogOpening", "Page.javascriptDialogClosed"]
  @download_history_limit 50
  @dialog_history_limit 50
  @call_timeout_padding_ms 5_000

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: {__MODULE__, make_ref()},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec id(pid()) :: String.t()
  def id(pid) when is_pid(pid) do
    GenServer.call(pid, :id)
  end

  @spec cdp_page_pid(pid()) :: pid() | nil
  def cdp_page_pid(pid) when is_pid(pid) do
    GenServer.call(pid, :cdp_page_pid)
  end

  @spec navigate(pid(), String.t()) :: Types.bidi_response()
  def navigate(pid, url) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate, url}, 10_000)
  end

  @spec reload(pid()) :: Types.bidi_response()
  def reload(pid) when is_pid(pid) do
    GenServer.call(pid, :reload, 10_000)
  end

  @spec evaluate(pid(), String.t()) :: Types.bidi_response()
  def evaluate(pid, expression) when is_pid(pid) and is_binary(expression) do
    evaluate(pid, expression, 10_000)
  end

  @spec evaluate(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def evaluate(pid, expression, timeout_ms)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    started_us = System.monotonic_time(:microsecond)
    GenServer.call(pid, {:evaluate, expression, timeout_ms, started_us}, command_call_timeout_ms(timeout_ms))
  end

  @spec handle_dialog(pid(), boolean(), String.t() | nil, pos_integer()) :: Types.bidi_response()
  def handle_dialog(pid, accept, nil, timeout_ms)
      when is_pid(pid) and is_boolean(accept) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:handle_dialog, accept, nil, timeout_ms}, timeout_ms + @call_timeout_padding_ms)
  end

  def handle_dialog(pid, accept, user_text, timeout_ms)
      when is_pid(pid) and is_boolean(accept) and is_binary(user_text) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:handle_dialog, accept, user_text, timeout_ms}, timeout_ms + @call_timeout_padding_ms)
  end

  @spec perform_keyboard_actions(pid(), [map()], pos_integer()) :: Types.bidi_response()
  def perform_keyboard_actions(pid, actions, timeout_ms)
      when is_pid(pid) and is_list(actions) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:perform_keyboard_actions, actions, timeout_ms}, timeout_ms + @call_timeout_padding_ms)
  end

  @spec set_user_agent(pid(), String.t()) :: :ok | {:error, String.t(), Types.bidi_error_details()}
  def set_user_agent(pid, user_agent) when is_pid(pid) and is_binary(user_agent) do
    case GenServer.call(pid, {:set_user_agent, user_agent}, 10_000) do
      {:ok, _result} -> :ok
      {:error, reason, details} -> {:error, reason, details}
    end
  end

  @spec await_ready(pid(), keyword()) ::
          {:ok, Types.readiness_payload()} | {:error, String.t(), Types.readiness_payload()}
  def await_ready(pid, opts \\ []) when is_pid(pid) and is_list(opts) do
    timeout_ms = normalize_positive_integer(Keyword.get(opts, :timeout_ms), @default_ready_timeout_ms)
    GenServer.call(pid, {:await_ready, opts}, timeout_ms + 5_000)
  end

  @spec last_readiness(pid()) :: Types.readiness_payload()
  def last_readiness(pid) when is_pid(pid) do
    GenServer.call(pid, :last_readiness)
  end

  @spec download_events(pid()) :: [Types.payload()]
  def download_events(pid) when is_pid(pid) do
    GenServer.call(pid, :download_events)
  end

  @spec dialog_events(pid()) :: [Types.payload()]
  def dialog_events(pid) when is_pid(pid) do
    GenServer.call(pid, :dialog_events)
  end

  @spec active_dialog(pid()) :: Types.payload() | nil
  def active_dialog(pid) when is_pid(pid) do
    GenServer.call(pid, :active_dialog)
  end

  @spec await_download(pid(), String.t(), pos_integer()) ::
          {:ok, Types.payload()} | {:error, :timeout, [Types.payload()]}
  def await_download(pid, expected_filename, timeout_ms)
      when is_pid(pid) and is_binary(expected_filename) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(
      pid,
      {:await_download, expected_filename, timeout_ms},
      timeout_ms + @call_timeout_padding_ms
    )
  end

  @spec await_dialog_open(pid(), pos_integer()) ::
          {:ok, Types.payload()} | {:error, :timeout, [Types.payload()]}
  def await_dialog_open(pid, timeout_ms) when is_pid(pid) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:await_dialog_open, timeout_ms}, timeout_ms + @call_timeout_padding_ms)
  end

  @impl true
  def init(opts) do
    browser_context_id = Keyword.fetch!(opts, :browser_context_id)
    cdp_browser_pid = Keyword.fetch!(opts, :cdp_browser_pid)
    debugger_address = Keyword.fetch!(opts, :debugger_address)
    viewport = Keyword.get(opts, :viewport)
    user_agent = Keyword.get(opts, :user_agent)
    init_scripts = Keyword.get(opts, :init_scripts, [])
    context_id = Keyword.get(opts, :context_id)
    slow_mo_ms = Keyword.get(opts, :slow_mo_ms, 0)

    with {:ok, target_id} <- resolve_target_id(browser_context_id, context_id, cdp_browser_pid),
         {:ok, cdp_page_pid} <-
           CdpPageProcess.start_link(
             target_id: target_id,
             debugger_address: debugger_address,
             owner: self(),
             slow_mo_ms: slow_mo_ms
           ),
         :ok <- bootstrap_page(cdp_page_pid, viewport, user_agent, init_scripts) do
      {:ok,
       %{
         id: target_id,
         browser_context_id: browser_context_id,
         cdp_browser_pid: cdp_browser_pid,
         cdp_page_pid: cdp_page_pid,
         debugger_address: debugger_address,
         slow_mo_ms: slow_mo_ms,
         last_page_event: nil,
         last_readiness: %{},
         download_events: [],
         dialog_events: [],
         active_dialog: nil,
         download_waiters: %{},
         dialog_waiters: %{}
       }}
    else
      {:error, reason, details} ->
        {:stop, {:create_browsing_context_failed, reason, details}}

      {:error, reason} ->
        {:stop, {:create_browsing_context_failed, reason, %{}}}
    end
  end

  @impl true
  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call(:cdp_page_pid, _from, state) do
    {:reply, state.cdp_page_pid, state}
  end

  def handle_call(:last_readiness, _from, state) do
    {:reply, state.last_readiness, state}
  end

  def handle_call(:download_events, _from, state) do
    {:reply, state.download_events, state}
  end

  def handle_call(:dialog_events, _from, state) do
    {:reply, state.dialog_events, state}
  end

  def handle_call(:active_dialog, _from, state) do
    {:reply, state.active_dialog, state}
  end

  def handle_call({:await_download, expected_filename, timeout_ms}, from, state) do
    case find_download_event(state.download_events, expected_filename) do
      %{} = event ->
        {:reply, {:ok, event}, state}

      nil ->
        waiter_id = make_ref()
        timer = Process.send_after(self(), {:download_waiter_timeout, waiter_id}, timeout_ms)

        download_waiters =
          Map.put(state.download_waiters, waiter_id, %{from: from, timer: timer, expected: expected_filename})

        {:noreply, %{state | download_waiters: download_waiters}}
    end
  end

  def handle_call({:await_dialog_open, timeout_ms}, from, state) do
    case state.active_dialog do
      %{} = dialog ->
        {:reply, {:ok, dialog}, state}

      _ ->
        waiter_id = make_ref()
        timer = Process.send_after(self(), {:dialog_waiter_timeout, waiter_id}, timeout_ms)
        dialog_waiters = Map.put(state.dialog_waiters, waiter_id, %{from: from, timer: timer})
        {:noreply, %{state | dialog_waiters: dialog_waiters}}
    end
  end

  def handle_call({:navigate, url}, _from, state) do
    {:reply, page_command(state, "Page.navigate", %{"url" => url}, 10_000), state}
  end

  def handle_call(:reload, _from, state) do
    {:reply, page_command(state, "Page.reload", %{}, 10_000), state}
  end

  def handle_call({:handle_dialog, accept, user_text, timeout_ms}, _from, state) do
    params = maybe_put_user_prompt(%{"accept" => accept}, user_text)

    {:reply, page_command(state, "Page.handleJavaScriptDialog", params, timeout_ms), state}
  end

  def handle_call({:perform_keyboard_actions, actions, timeout_ms}, _from, state) do
    reply = perform_key_actions(state, actions, timeout_ms)
    {:reply, reply, state}
  end

  def handle_call({:set_user_agent, user_agent}, _from, state) do
    {:reply, page_command(state, "Emulation.setUserAgentOverride", %{"userAgent" => user_agent}, 10_000), state}
  end

  def handle_call({:await_ready, opts}, _from, state) do
    timeout_ms = normalize_positive_integer(Keyword.get(opts, :timeout_ms), @default_ready_timeout_ms)
    quiet_ms = normalize_positive_integer(Keyword.get(opts, :quiet_ms), @default_ready_quiet_ms)

    case evaluate_readiness(state, timeout_ms, quiet_ms) do
      {:ok, %{"ok" => true} = readiness} ->
        readiness = Map.put_new(readiness, "lastPageEvent", state.last_page_event)
        {:reply, {:ok, readiness}, %{state | last_readiness: readiness}}

      {:ok, readiness} ->
        readiness = Map.put_new(readiness, "lastPageEvent", state.last_page_event)
        {:reply, {:error, "browser readiness timeout", readiness}, %{state | last_readiness: readiness}}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call({:evaluate, expression, timeout_ms, started_us}, _from, state) do
    record_transport_delay(:browsing_context_queue, started_us)

    {result, state} =
      Cerberus.Profiling.measure({:browser_transport, :browsing_context_dispatch}, fn ->
        evaluate_expression(state, expression, timeout_ms)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_info({:cerberus_cdp_page_event, target_id, method, params}, %{id: target_id} = state)
      when is_binary(method) and is_map(params) do
    event =
      params
      |> Map.take([
        "frameId",
        "url",
        "guid",
        "suggestedFilename",
        "type",
        "message",
        "hasBrowserHandler",
        "result",
        "userInput",
        "state"
      ])
      |> Map.put("method", method)
      |> Map.put("context", target_id)
      |> Map.put("timestampMs", System.monotonic_time(:millisecond))

    cond do
      method in @download_events ->
        state = %{
          state
          | last_page_event: event,
            download_events: push_download_event(state.download_events, event)
        }

        {:noreply, resolve_download_waiters(state, event)}

      method in @dialog_events ->
        next_dialog = next_active_dialog(method, event, state.active_dialog)

        state = %{
          state
          | last_page_event: event,
            dialog_events: push_dialog_event(state.dialog_events, event),
            active_dialog: next_dialog
        }

        {:noreply, resolve_dialog_waiters(state, next_dialog)}

      true ->
        {:noreply, %{state | last_page_event: event}}
    end
  end

  def handle_info({:download_waiter_timeout, waiter_id}, state) do
    case Map.pop(state.download_waiters, waiter_id) do
      {nil, _waiters} ->
        {:noreply, state}

      {waiter, download_waiters} ->
        GenServer.reply(waiter.from, {:error, :timeout, state.download_events})
        {:noreply, %{state | download_waiters: download_waiters}}
    end
  end

  def handle_info({:dialog_waiter_timeout, waiter_id}, state) do
    case Map.pop(state.dialog_waiters, waiter_id) do
      {nil, _waiters} ->
        {:noreply, state}

      {waiter, dialog_waiters} ->
        GenServer.reply(waiter.from, {:error, :timeout, state.dialog_events})
        {:noreply, %{state | dialog_waiters: dialog_waiters}}
    end
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    maybe_stop_cdp_page(state.cdp_page_pid)
    _ = CdpBrowserProcess.close_target(state.cdp_browser_pid, state.id)
    :ok
  end

  defp resolve_target_id(_browser_context_id, context_id, _cdp_browser_pid)
       when is_binary(context_id) and context_id != "" do
    {:ok, context_id}
  end

  defp resolve_target_id(browser_context_id, nil, cdp_browser_pid) do
    case CdpBrowserProcess.create_target(cdp_browser_pid, browser_context_id, 10_000) do
      {:ok, %{"targetId" => target_id}} when is_binary(target_id) -> {:ok, target_id}
      {:ok, _other} -> {:error, "unexpected Target.createTarget response", %{}}
      {:error, reason, details} -> {:error, reason, details}
    end
  end

  defp resolve_target_id(_browser_context_id, context_id, _cdp_browser_pid) do
    {:error, "invalid browsing context", %{"context_id" => inspect(context_id)}}
  end

  defp bootstrap_page(cdp_page_pid, viewport, user_agent, init_scripts) when is_pid(cdp_page_pid) do
    with {:ok, _} <- CdpPageProcess.command(cdp_page_pid, "Page.enable", %{}, 5_000),
         :ok <- maybe_set_viewport(cdp_page_pid, viewport),
         :ok <- maybe_set_user_agent(cdp_page_pid, user_agent) do
      with :ok <- maybe_add_init_scripts(cdp_page_pid, init_scripts) do
        maybe_apply_init_scripts_now(cdp_page_pid, init_scripts)
      end
    end
  end

  defp maybe_set_viewport(_cdp_page_pid, nil), do: :ok

  defp maybe_set_viewport(cdp_page_pid, %{width: width, height: height})
       when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    params = %{"width" => width, "height" => height, "deviceScaleFactor" => 1, "mobile" => false}

    case CdpPageProcess.command(cdp_page_pid, "Emulation.setDeviceMetricsOverride", params, 5_000) do
      {:ok, _result} -> :ok
      {:error, reason, details} -> {:error, reason, details}
    end
  end

  defp maybe_set_viewport(_cdp_page_pid, viewport), do: {:error, "invalid viewport", %{viewport: inspect(viewport)}}

  defp maybe_set_user_agent(_cdp_page_pid, nil), do: :ok

  defp maybe_set_user_agent(cdp_page_pid, user_agent) when is_binary(user_agent) do
    case CdpPageProcess.command(cdp_page_pid, "Emulation.setUserAgentOverride", %{"userAgent" => user_agent}, 5_000) do
      {:ok, _result} -> :ok
      {:error, reason, details} -> {:error, reason, details}
    end
  end

  defp maybe_add_init_scripts(_cdp_page_pid, []), do: :ok

  defp maybe_add_init_scripts(cdp_page_pid, init_scripts) when is_list(init_scripts) do
    Enum.reduce_while(init_scripts, :ok, fn script, :ok ->
      case CdpPageProcess.command(cdp_page_pid, "Page.addScriptToEvaluateOnNewDocument", %{"source" => script}, 5_000) do
        {:ok, _result} -> {:cont, :ok}
        {:error, reason, details} -> {:halt, {:error, reason, details}}
      end
    end)
  end

  defp maybe_apply_init_scripts_now(_cdp_page_pid, []), do: :ok

  defp maybe_apply_init_scripts_now(cdp_page_pid, init_scripts) when is_list(init_scripts) do
    Enum.reduce_while(init_scripts, :ok, fn script, :ok ->
      case CdpPageProcess.evaluate(cdp_page_pid, script, 5_000) do
        {:ok, _result} -> {:cont, :ok}
        {:error, reason, details} -> {:halt, {:error, reason, details}}
      end
    end)
  end

  defp evaluate_expression(state, expression, timeout_ms) do
    case ensure_cdp_page(state) do
      {:ok, cdp_page_pid, state} ->
        {CdpPageProcess.evaluate(cdp_page_pid, expression, timeout_ms), state}

      {:error, reason} ->
        {{:error, inspect(reason), %{}}, state}
    end
  end

  defp evaluate_readiness(state, timeout_ms, quiet_ms) do
    expression = readiness_expression(timeout_ms, quiet_ms)

    with {:ok, cdp_page_pid, _state} <- ensure_cdp_page(state),
         {:ok, result} <- CdpPageProcess.evaluate(cdp_page_pid, expression, timeout_ms),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      {:error, "cdp command timeout", _details} ->
        sample_timeout_readiness(state)

      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp sample_timeout_readiness(state) do
    expression = readiness_sample_expression()

    with {:ok, cdp_page_pid, _state} <- ensure_cdp_page(state),
         {:ok, result} <- CdpPageProcess.evaluate(cdp_page_pid, expression, 1_000),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      _other ->
        {:ok,
         %{
           "ok" => false,
           "reason" => "timeout",
           "path" => last_known_path(state),
           "awaited" => ["phx:page-loading-stop", "dom-mutation", "window-load", "liveview-connected", "liveview-down"],
           "lastSignal" => "timeout",
           "lastLiveState" => "unknown",
           "details" => %{}
         }}
    end
  end

  defp last_known_path(%{last_page_event: %{"url" => url}}) when is_binary(url) do
    case URI.parse(url) do
      %URI{path: path, query: query} when is_binary(path) and path != "" ->
        if is_binary(query) and query != "", do: path <> "?" <> query, else: path

      _ ->
        ""
    end
  end

  defp last_known_path(_state), do: ""

  defp ensure_cdp_page(%{cdp_page_pid: pid} = state) when is_pid(pid) do
    if Process.alive?(pid), do: {:ok, pid, state}, else: ensure_cdp_page(clear_cdp_page(state))
  end

  defp ensure_cdp_page(%{debugger_address: debugger_address, id: context_id, slow_mo_ms: slow_mo_ms} = state)
       when is_binary(debugger_address) do
    case CdpPageProcess.start_link(
           target_id: context_id,
           debugger_address: debugger_address,
           owner: self(),
           slow_mo_ms: slow_mo_ms
         ) do
      {:ok, pid} -> {:ok, pid, %{state | cdp_page_pid: pid}}
      {:error, _reason} -> {:error, :cdp_page_unavailable}
    end
  end

  defp ensure_cdp_page(_state), do: {:error, :cdp_page_unavailable}

  defp clear_cdp_page(%{cdp_page_pid: pid} = state) do
    maybe_stop_cdp_page(pid)
    %{state | cdp_page_pid: nil}
  end

  defp maybe_stop_cdp_page(pid) when is_pid(pid) do
    if Process.alive?(pid), do: GenServer.stop(pid, :normal)
    :ok
  end

  defp maybe_stop_cdp_page(_pid), do: :ok

  defp decode_remote_json(%{"result" => %{"type" => "string", "value" => payload}}) when is_binary(payload) do
    case JSON.decode(payload) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "invalid json payload from browser: #{inspect(reason)}"}
    end
  end

  defp decode_remote_json(result) do
    {:error, "unexpected script.evaluate result: #{inspect(result)}"}
  end

  defp record_transport_delay(bucket, started_us) when is_atom(bucket) and is_integer(started_us) do
    Cerberus.Profiling.record_us(
      {:browser_transport, bucket},
      max(System.monotonic_time(:microsecond) - started_us, 0)
    )
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp push_download_event(download_events, event) when is_list(download_events) and is_map(event) do
    download_events
    |> Kernel.++([event])
    |> Enum.take(-@download_history_limit)
  end

  defp push_dialog_event(dialog_events, event) when is_list(dialog_events) and is_map(event) do
    dialog_events
    |> Kernel.++([event])
    |> Enum.take(-@dialog_history_limit)
  end

  defp next_active_dialog("Page.javascriptDialogOpening", event, _active_dialog), do: event
  defp next_active_dialog("Page.javascriptDialogClosed", _event, _active_dialog), do: nil
  defp next_active_dialog(_method, _event, active_dialog), do: active_dialog

  defp find_download_event(download_events, expected_filename)
       when is_list(download_events) and is_binary(expected_filename) do
    Enum.find(download_events, &download_event_match?(&1, expected_filename))
  end

  defp download_event_match?(%{"method" => "Page.downloadWillBegin", "suggestedFilename" => filename}, expected_filename)
       when is_binary(filename) and is_binary(expected_filename) do
    filename == expected_filename
  end

  defp download_event_match?(_event, _expected_filename), do: false

  defp resolve_download_waiters(%{download_waiters: waiters} = state, event)
       when map_size(waiters) == 0 or not is_map(event) do
    state
  end

  defp resolve_download_waiters(%{download_waiters: waiters} = state, event) do
    {resolved, pending} =
      Enum.split_with(waiters, fn {_waiter_id, waiter} ->
        download_event_match?(event, waiter.expected)
      end)

    Enum.each(resolved, fn {_waiter_id, waiter} ->
      Process.cancel_timer(waiter.timer)
      GenServer.reply(waiter.from, {:ok, event})
    end)

    %{state | download_waiters: Map.new(pending)}
  end

  defp resolve_dialog_waiters(%{dialog_waiters: waiters} = state, dialog)
       when map_size(waiters) == 0 or not is_map(dialog) do
    state
  end

  defp resolve_dialog_waiters(%{dialog_waiters: waiters} = state, dialog) do
    Enum.each(waiters, fn {_waiter_id, waiter} ->
      Process.cancel_timer(waiter.timer)
      GenServer.reply(waiter.from, {:ok, dialog})
    end)

    %{state | dialog_waiters: %{}}
  end

  defp command_call_timeout_ms(timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    timeout_ms + @call_timeout_padding_ms
  end

  defp page_command(state, method, params, timeout_ms)
       when is_binary(method) and is_map(params) and is_integer(timeout_ms) and timeout_ms > 0 do
    with {:ok, cdp_page_pid, _state} <- ensure_cdp_page(state) do
      CdpPageProcess.command(cdp_page_pid, method, params, timeout_ms)
    end
  end

  defp maybe_put_user_prompt(params, nil), do: params
  defp maybe_put_user_prompt(params, user_text), do: Map.put(params, "promptText", user_text)

  defp perform_key_actions(_state, [], _timeout_ms), do: {:ok, %{}}

  defp perform_key_actions(state, actions, timeout_ms) do
    Enum.reduce_while(actions, {:ok, %{}}, fn action, _acc ->
      case page_command(state, "Input.dispatchKeyEvent", action, timeout_ms) do
        {:ok, _result} = ok -> {:cont, ok}
        {:error, _reason, _details} = error -> {:halt, error}
      end
    end)
  end

  defp readiness_expression(timeout_ms, quiet_ms) do
    """
    (() => {
      const timeoutMs = #{timeout_ms};
      const quietMs = #{quiet_ms};
      const awaited = [
        "phx:page-loading-stop",
        "dom-mutation",
        "window-load",
        "liveview-connected",
        "liveview-down"
      ];

      const safePath = () => {
        try {
          return window.location.pathname + window.location.search;
        } catch (_error) {
          return "";
        }
      };

      const payload = (ok, reason, lastSignal, liveState, details = {}) => JSON.stringify({
        ok,
        reason,
        path: safePath(),
        awaited,
        lastSignal,
        lastLiveState: liveState,
        details
      });

      try {
        return new Promise((resolve) => {
          let inFlight = false;
          let resolved = false;
          let quietTimer = null;
          let timeoutTimer = null;
          let lastSignal = "initial";
          const cleanupFns = [];

          const roots = () => {
            try {
              return Array.from(document.querySelectorAll("[data-phx-session]"));
            } catch (_error) {
              return [];
            }
          };

          const liveState = () => {
            try {
              const currentRoots = roots();
              if (currentRoots.length === 0) return "down";

              const connectedCount = currentRoots.filter((root) => {
                try {
                  return !!(root && root.classList && root.classList.contains("phx-connected"));
                } catch (_error) {
                  return false;
                }
              }).length;

              return connectedCount > 0 ? "connected" : "disconnected";
            } catch (_error) {
              return "unknown";
            }
          };

          const cleanup = () => {
            cleanupFns.forEach((fn) => {
              try {
                fn();
              } catch (_error) {
                // ignored
              }
            });
            cleanupFns.length = 0;
            clearTimeout(quietTimer);
            clearTimeout(timeoutTimer);
          };

          const finish = (ok, reason, details = {}) => {
            if (resolved) return;
            resolved = true;
            const currentState = liveState();
            cleanup();
            resolve(payload(ok, reason, lastSignal, currentState, details));
          };

          const scheduleQuiet = () => {
            clearTimeout(quietTimer);
            quietTimer = setTimeout(() => finish(true, "settled"), quietMs);
          };

          const note = (signal) => {
            lastSignal = signal;
          };

          const handleStateChange = (sourceSignal) => {
            const currentState = liveState();

            if (currentState === "down") {
              note("liveview-down");
              scheduleQuiet();
              return;
            }

            if (currentState === "connected") {
              note(sourceSignal);
              if (!inFlight) scheduleQuiet();
              return;
            }

            if (currentState === "unknown") {
              note("liveview-state-unknown");
              clearTimeout(quietTimer);
              return;
            }

            note("liveview-disconnected");
            clearTimeout(quietTimer);
          };

          const onPageLoadingStart = () => {
            inFlight = true;
            note("phx:page-loading-start");
            clearTimeout(quietTimer);
          };

          const onPageLoadingStop = () => {
            inFlight = false;
            note("phx:page-loading-stop");
            if (liveState() !== "disconnected") scheduleQuiet();
          };

          window.addEventListener("phx:page-loading-start", onPageLoadingStart);
          window.addEventListener("phx:page-loading-stop", onPageLoadingStop);
          cleanupFns.push(() => window.removeEventListener("phx:page-loading-start", onPageLoadingStart));
          cleanupFns.push(() => window.removeEventListener("phx:page-loading-stop", onPageLoadingStop));

          const onLoad = () => {
            note("window-load");
            if (!inFlight) scheduleQuiet();
          };
          window.addEventListener("load", onLoad);
          cleanupFns.push(() => window.removeEventListener("load", onLoad));

          const setupObserver = () => {
            try {
              const root = document.documentElement || document.body || document;
              if (!root || typeof root.nodeType !== "number") {
                note("observer-root-missing");
                return false;
              }

              const observer = new MutationObserver(() => {
                try {
                  handleStateChange("dom-mutation");
                } catch (_error) {
                  note("observer-callback-error");
                }
              });

              observer.observe(root, {
                subtree: true,
                childList: true,
                attributes: true,
                characterData: true
              });

              cleanupFns.push(() => observer.disconnect());
              note("observer-attached");
              return true;
            } catch (_error) {
              note("observer-attach-error");
              return false;
            }
          };

          if (!setupObserver()) {
            const pollDelayMs = Math.max(quietMs, 50);
            const pollRef = setInterval(() => {
              if (resolved) return;

              try {
                handleStateChange("dom-poll");
              } catch (_error) {
                note("poll-error");
              }
            }, pollDelayMs);

            cleanupFns.push(() => clearInterval(pollRef));
          }

          const initialState = liveState();
          if (initialState === "connected") {
            note("liveview-connected");
          } else if (initialState === "down") {
            note("liveview-down");
          } else if (initialState === "unknown") {
            note("liveview-state-unknown");
          } else {
            note("liveview-disconnected");
          }

          if (!inFlight && initialState !== "disconnected" && initialState !== "unknown") {
            scheduleQuiet();
          }

          timeoutTimer = setTimeout(() => finish(false, "timeout"), timeoutMs);
        });
      } catch (error) {
        return payload(false, "setup-error", "setup-error", "unknown", { error: "" + error });
      }
    })()
    """
  end

  defp readiness_sample_expression do
    """
    (() => {
      const awaited = [
        "phx:page-loading-stop",
        "dom-mutation",
        "window-load",
        "liveview-connected",
        "liveview-down"
      ];

      const roots = () => {
        try {
          return Array.from(document.querySelectorAll("[data-phx-session]"));
        } catch (_error) {
          return [];
        }
      };

      const liveState = () => {
        const currentRoots = roots();
        if (currentRoots.length === 0) return "down";

        const connectedCount = currentRoots.filter((root) => {
          try {
            return !!(root && root.classList && root.classList.contains("phx-connected"));
          } catch (_error) {
            return false;
          }
        }).length;

        return connectedCount > 0 ? "connected" : "disconnected";
      };

      const safePath = () => {
        try {
          return window.location.pathname + window.location.search;
        } catch (_error) {
          return "";
        }
      };

      const currentState = liveState();
      const lastSignal =
        currentState === "down"
          ? "liveview-down"
          : currentState === "connected"
            ? "dom-mutation"
            : currentState === "disconnected"
              ? "liveview-disconnected"
              : "timeout";

      return JSON.stringify({
        ok: false,
        reason: "timeout",
        path: safePath(),
        awaited,
        lastSignal,
        lastLiveState: currentState,
        details: {}
      });
    })()
    """
  end
end
