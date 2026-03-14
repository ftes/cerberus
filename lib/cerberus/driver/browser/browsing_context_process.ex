defmodule Cerberus.Driver.Browser.BrowsingContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.TransientErrors
  alias Cerberus.Driver.Browser.Types

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @bidi_events [
    "browsingContext.navigationStarted",
    "browsingContext.domContentLoaded",
    "browsingContext.load",
    "browsingContext.downloadWillBegin",
    "browsingContext.downloadEnd"
  ]
  @download_events ["browsingContext.downloadWillBegin", "browsingContext.downloadEnd"]
  @download_history_limit 50
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

  @spec last_bidi_event(pid()) :: Types.payload() | nil
  def last_bidi_event(pid) when is_pid(pid) do
    GenServer.call(pid, :last_bidi_event)
  end

  @spec await_bidi_event(pid(), [String.t()], Types.payload() | nil, pos_integer()) ::
          {:ok, Types.payload()} | {:error, :timeout, Types.payload() | nil}
  def await_bidi_event(pid, methods, baseline_event, timeout_ms)
      when is_pid(pid) and is_list(methods) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(
      pid,
      {:await_bidi_event, methods, baseline_event, timeout_ms},
      timeout_ms + @call_timeout_padding_ms
    )
  end

  @spec download_events(pid()) :: [Types.payload()]
  def download_events(pid) when is_pid(pid) do
    GenServer.call(pid, :download_events)
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

  @impl true
  def init(opts) do
    user_context_id = Keyword.fetch!(opts, :user_context_id)
    viewport = Keyword.get(opts, :viewport)
    context_id = Keyword.get(opts, :context_id)
    bidi_opts = Keyword.get(opts, :bidi_opts, opts)
    slow_mo_ms = Keyword.get(opts, :slow_mo_ms, 0)

    with {:ok, browsing_context_id} <- resolve_browsing_context_id(user_context_id, context_id, bidi_opts),
         :ok <- maybe_set_viewport_for_context(context_id, browsing_context_id, viewport, bidi_opts),
         :ok <- BiDi.subscribe(self(), bidi_opts),
         {:ok, _} <-
           BiDi.command("session.subscribe", %{"events" => @bidi_events, "contexts" => [browsing_context_id]}, bidi_opts) do
      {:ok,
       %{
         id: browsing_context_id,
         user_context_id: user_context_id,
         bidi_opts: bidi_opts,
         slow_mo_ms: slow_mo_ms,
         last_bidi_event: nil,
         last_bidi_event_sequence: 0,
         last_readiness: %{},
         download_events: [],
         download_waiters: %{},
         bidi_event_waiters: %{},
         pending_evaluations: %{}
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

  def handle_call(:last_readiness, _from, state) do
    {:reply, state.last_readiness, state}
  end

  def handle_call(:last_bidi_event, _from, state) do
    {:reply, state.last_bidi_event, state}
  end

  def handle_call({:await_bidi_event, methods, baseline_event, timeout_ms}, from, state) do
    method_set = MapSet.new(methods)
    baseline_sequence = bidi_event_sequence(baseline_event)

    case matching_bidi_event(state.last_bidi_event, method_set, baseline_sequence) do
      %{} = event ->
        {:reply, {:ok, event}, state}

      nil ->
        waiter_id = make_ref()
        timer = Process.send_after(self(), {:bidi_event_waiter_timeout, waiter_id}, timeout_ms)

        bidi_event_waiters =
          Map.put(state.bidi_event_waiters, waiter_id, %{
            from: from,
            timer: timer,
            method_set: method_set,
            baseline_sequence: baseline_sequence
          })

        {:noreply, %{state | bidi_event_waiters: bidi_event_waiters}}
    end
  end

  def handle_call(:download_events, _from, state) do
    {:reply, state.download_events, state}
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

  def handle_call({:navigate, url}, _from, state) do
    result =
      BiDi.command(
        "browsingContext.navigate",
        %{
          "context" => state.id,
          "url" => url,
          "wait" => "complete"
        },
        state.bidi_opts
      )

    {:reply, result, state}
  end

  def handle_call(:reload, _from, state) do
    result =
      BiDi.command(
        "browsingContext.reload",
        %{
          "context" => state.id,
          "wait" => "complete"
        },
        state.bidi_opts
      )

    {:reply, result, state}
  end

  def handle_call({:await_ready, opts}, _from, state) do
    timeout_ms = normalize_positive_integer(Keyword.get(opts, :timeout_ms), @default_ready_timeout_ms)
    quiet_ms = normalize_positive_integer(Keyword.get(opts, :quiet_ms), @default_ready_quiet_ms)

    case evaluate_readiness_safe(state.id, timeout_ms, quiet_ms, state.bidi_opts) do
      {:ok, %{"ok" => true} = readiness} ->
        readiness = Map.put_new(readiness, "lastBidiEvent", state.last_bidi_event)
        {:reply, {:ok, readiness}, %{state | last_readiness: readiness}}

      {:ok, readiness} ->
        readiness = Map.put_new(readiness, "lastBidiEvent", state.last_bidi_event)
        {:reply, {:error, "browser readiness timeout", readiness}, %{state | last_readiness: readiness}}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call({:evaluate, expression, timeout_ms, started_us}, from, state) do
    record_transport_delay(:browsing_context_queue, started_us)
    {:noreply, start_pending_evaluation(state, expression, timeout_ms, from)}
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    case Map.pop(state.pending_evaluations, ref) do
      {nil, _pending_evaluations} ->
        {:noreply, state}

      {from, pending_evaluations} ->
        Process.demonitor(ref, [:flush])
        GenServer.reply(from, result)
        {:noreply, %{state | pending_evaluations: pending_evaluations}}
    end
  end

  def handle_info({:cerberus_bidi_event, %{"method" => method, "params" => params}}, state)
      when is_binary(method) and is_map(params) do
    event =
      if params["context"] == state.id do
        sequence = state.last_bidi_event_sequence + 1

        %{
          "method" => method,
          "context" => params["context"],
          "url" => params["url"],
          "navigation" => params["navigation"],
          "suggestedFilename" => params["suggestedFilename"],
          "type" => params["type"],
          "message" => params["message"],
          "handler" => params["handler"],
          "accepted" => params["accepted"],
          "userText" => params["userText"],
          "status" => params["status"],
          "timestampMs" => System.monotonic_time(:millisecond),
          "sequence" => sequence
        }
      end

    cond do
      is_map(event) and method in @download_events ->
        state = %{
          state
          | last_bidi_event: event,
            last_bidi_event_sequence: event["sequence"],
            download_events: push_download_event(state.download_events, event)
        }

        state = resolve_download_waiters(state, event)
        {:noreply, resolve_bidi_event_waiters(state, event)}

      is_map(event) ->
        state = %{
          state
          | last_bidi_event: event,
            last_bidi_event_sequence: event["sequence"]
        }

        {:noreply, resolve_bidi_event_waiters(state, event)}

      true ->
        {:noreply, state}
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

  def handle_info({:bidi_event_waiter_timeout, waiter_id}, state) do
    case Map.pop(state.bidi_event_waiters, waiter_id) do
      {nil, _waiters} ->
        {:noreply, state}

      {waiter, bidi_event_waiters} ->
        GenServer.reply(waiter.from, {:error, :timeout, state.last_bidi_event})
        {:noreply, %{state | bidi_event_waiters: bidi_event_waiters}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.pending_evaluations, ref) do
      {nil, _pending_evaluations} ->
        {:noreply, state}

      {from, pending_evaluations} ->
        GenServer.reply(from, {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}})
        {:noreply, %{state | pending_evaluations: pending_evaluations}}
    end
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = BiDi.command("session.unsubscribe", %{"events" => @bidi_events, "contexts" => [state.id]}, state.bidi_opts)
    _ = BiDi.unsubscribe(self(), state.bidi_opts)
    _ = BiDi.command("browsingContext.close", %{"context" => state.id}, state.bidi_opts)
    :ok
  end

  defp create_browsing_context(user_context_id, bidi_opts) do
    create_browsing_context(user_context_id, bidi_opts, 2)
  end

  defp resolve_browsing_context_id(_user_context_id, context_id, _bidi_opts)
       when is_binary(context_id) and context_id != "" do
    {:ok, context_id}
  end

  defp resolve_browsing_context_id(user_context_id, nil, bidi_opts),
    do: create_browsing_context(user_context_id, bidi_opts)

  defp resolve_browsing_context_id(_user_context_id, context_id, _bidi_opts) do
    {:error, "invalid browsing context", %{"context_id" => inspect(context_id)}}
  end

  defp maybe_set_viewport_for_context(nil, context_id, viewport, bidi_opts),
    do: maybe_set_viewport(context_id, viewport, bidi_opts)

  defp maybe_set_viewport_for_context(_context_id, _resolved_context_id, _viewport, _bidi_opts), do: :ok

  defp create_browsing_context(user_context_id, bidi_opts, retries_left)
       when is_integer(retries_left) and retries_left >= 0 do
    with {:ok, result} <-
           BiDi.command(
             "browsingContext.create",
             %{
               "type" => "tab",
               "userContext" => user_context_id
             },
             bidi_opts
           ),
         browsing_context_id when is_binary(browsing_context_id) <- result["context"] do
      {:ok, browsing_context_id}
    else
      {:error, reason, details} ->
        if retries_left > 0 and TransientErrors.retryable?(reason, details) do
          Process.sleep(25)
          create_browsing_context(user_context_id, bidi_opts, retries_left - 1)
        else
          {:error, reason, details}
        end

      _ ->
        {:error, "unexpected browsingContext.create response", %{}}
    end
  end

  defp maybe_set_viewport(_context_id, nil, _bidi_opts), do: :ok

  defp maybe_set_viewport(context_id, %{width: width, height: height}, bidi_opts)
       when is_integer(width) and is_integer(height) and width > 0 and height > 0 do
    params = %{
      "context" => context_id,
      "viewport" => %{"width" => width, "height" => height}
    }

    case BiDi.command("browsingContext.setViewport", params, bidi_opts) do
      {:ok, _result} ->
        :ok

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp maybe_set_viewport(_context_id, viewport, _bidi_opts) do
    {:error, "invalid viewport", %{viewport: inspect(viewport)}}
  end

  defp evaluate_script(context_id, expression, bidi_opts) do
    BiDi.command(
      "script.evaluate",
      %{
        "target" => %{"context" => context_id},
        "expression" => expression,
        "awaitPromise" => true,
        "resultOwnership" => "none"
      },
      bidi_opts
    )
  end

  defp evaluate_json(context_id, expression, bidi_opts) do
    with {:ok, result} <- evaluate_script(context_id, expression, bidi_opts),
         {:ok, json} <- decode_remote_json(result) do
      {:ok, json}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      {:error, reason} ->
        {:error, reason, %{}}
    end
  end

  defp evaluate_readiness(context_id, timeout_ms, quiet_ms, bidi_opts) do
    expression = readiness_expression(timeout_ms, quiet_ms)

    case evaluate_json(context_id, expression, bidi_opts) do
      {:error, reason, details} ->
        if TransientErrors.retryable?(reason, details) do
          Process.sleep(25)
          evaluate_json(context_id, expression, bidi_opts)
        else
          {:error, reason, details}
        end

      result ->
        result
    end
  end

  defp evaluate_readiness_safe(context_id, timeout_ms, quiet_ms, bidi_opts) do
    evaluate_readiness(context_id, timeout_ms, quiet_ms, bidi_opts)
  catch
    :exit, {:timeout, {GenServer, :call, _call_args}} ->
      {:error, "browser readiness timeout", %{"reason" => "script.evaluate timeout"}}

    :exit, reason ->
      {:error, "browser readiness call failed", %{"reason" => inspect(reason)}}
  end

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

  defp start_pending_evaluation(state, expression, timeout_ms, from)
       when is_map(state) and is_binary(expression) and is_integer(timeout_ms) do
    {evaluate_fun, state} = evaluation_fun(state, expression, timeout_ms)

    task =
      Task.async(fn ->
        try do
          Cerberus.Profiling.measure({:browser_transport, :browsing_context_dispatch}, fn ->
            evaluate_fun.()
          end)
        catch
          :exit, reason ->
            {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}}
        end
      end)

    Process.unlink(task.pid)
    %{state | pending_evaluations: Map.put(state.pending_evaluations, task.ref, from)}
  end

  defp evaluation_fun(state, expression, timeout_ms) do
    bidi_opts = Keyword.put(state.bidi_opts, :timeout, timeout_ms)
    {fn -> evaluate_script(state.id, expression, bidi_opts) end, state}
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp push_download_event(download_events, event) when is_list(download_events) and is_map(event) do
    download_events
    |> Kernel.++([event])
    |> Enum.take(-@download_history_limit)
  end

  defp find_download_event(download_events, expected_filename)
       when is_list(download_events) and is_binary(expected_filename) do
    Enum.find(download_events, &download_event_match?(&1, expected_filename))
  end

  defp download_event_match?(%{"method" => method, "suggestedFilename" => filename}, expected_filename)
       when method in @download_events and is_binary(filename) and is_binary(expected_filename) do
    filename_matches_expected_download?(filename, expected_filename)
  end

  defp download_event_match?(_event, _expected_filename), do: false

  defp filename_matches_expected_download?(filename, expected_filename)
       when is_binary(filename) and is_binary(expected_filename) do
    filename == expected_filename or firefox_duplicate_download_name?(filename, expected_filename)
  end

  defp firefox_duplicate_download_name?(filename, expected_filename)
       when is_binary(filename) and is_binary(expected_filename) do
    extname = Path.extname(expected_filename)
    rootname = Path.rootname(expected_filename, extname)

    case {rootname, extname} do
      {"", _extname} ->
        false

      {rootname, ""} ->
        Regex.match?(~r/^#{Regex.escape(rootname)}\(\d+\)$/, filename)

      {rootname, extname} ->
        Regex.match?(~r/^#{Regex.escape(rootname)}\(\d+\)#{Regex.escape(extname)}$/, filename)
    end
  end

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

  defp resolve_bidi_event_waiters(%{bidi_event_waiters: waiters} = state, event)
       when map_size(waiters) == 0 or not is_map(event) do
    state
  end

  defp resolve_bidi_event_waiters(%{bidi_event_waiters: waiters} = state, event) do
    {resolved, pending} =
      Enum.split_with(waiters, fn {_waiter_id, waiter} ->
        matching_bidi_event(event, waiter.method_set, waiter.baseline_sequence) != nil
      end)

    Enum.each(resolved, fn {_waiter_id, waiter} ->
      Process.cancel_timer(waiter.timer)
      GenServer.reply(waiter.from, {:ok, event})
    end)

    %{state | bidi_event_waiters: Map.new(pending)}
  end

  defp matching_bidi_event(%{"method" => method} = event, %MapSet{} = method_set, baseline_sequence)
       when is_binary(method) and is_integer(baseline_sequence) do
    if MapSet.member?(method_set, method) and bidi_event_sequence(event) > baseline_sequence do
      event
    end
  end

  defp matching_bidi_event(_event, _method_set, _baseline_sequence), do: nil

  defp bidi_event_sequence(%{"sequence" => sequence}) when is_integer(sequence), do: sequence
  defp bidi_event_sequence(_event), do: 0

  defp command_call_timeout_ms(timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    timeout_ms + @call_timeout_padding_ms
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
              if (!inFlight && (sourceSignal !== "dom-mutation" || quietTimer === null)) scheduleQuiet();
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
end
