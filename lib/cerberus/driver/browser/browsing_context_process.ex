defmodule Cerberus.Driver.Browser.BrowsingContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Runtime

  @default_ready_timeout_ms 1_500
  @default_ready_quiet_ms 40
  @bidi_events [
    "browsingContext.navigationStarted",
    "browsingContext.domContentLoaded",
    "browsingContext.load",
    "browsingContext.userPromptOpened",
    "browsingContext.userPromptClosed"
  ]

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

  @spec navigate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def navigate(pid, url) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate, url}, 10_000)
  end

  @spec evaluate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate(pid, expression) when is_pid(pid) and is_binary(expression) do
    evaluate(pid, expression, 10_000)
  end

  @spec evaluate(pid(), String.t(), pos_integer()) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate(pid, expression, timeout_ms)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:evaluate, expression, timeout_ms}, command_call_timeout_ms(timeout_ms))
  end

  @spec await_ready(pid(), keyword()) :: {:ok, map()} | {:error, String.t(), map()}
  def await_ready(pid, opts \\ []) when is_pid(pid) and is_list(opts) do
    timeout_ms = normalize_positive_integer(Keyword.get(opts, :timeout_ms), @default_ready_timeout_ms)
    GenServer.call(pid, {:await_ready, opts}, timeout_ms + 5_000)
  end

  @spec last_readiness(pid()) :: map()
  def last_readiness(pid) when is_pid(pid) do
    GenServer.call(pid, :last_readiness)
  end

  @impl true
  def init(opts) do
    user_context_id = Keyword.fetch!(opts, :user_context_id)
    viewport = Keyword.get(opts, :viewport)
    bidi_opts = Keyword.get(opts, :bidi_opts, opts)
    browser_name = Runtime.browser_name(bidi_opts)
    bidi_opts = Keyword.put_new(bidi_opts, :browser_name, browser_name)

    with {:ok, browsing_context_id} <- create_browsing_context(user_context_id, bidi_opts),
         :ok <- maybe_set_viewport(browsing_context_id, viewport, bidi_opts),
         :ok <- BiDi.subscribe(self(), bidi_opts),
         {:ok, _} <-
           BiDi.command("session.subscribe", %{"events" => @bidi_events, "contexts" => [browsing_context_id]}, bidi_opts) do
      {:ok,
       %{
         id: browsing_context_id,
         user_context_id: user_context_id,
         browser_name: browser_name,
         bidi_opts: bidi_opts,
         last_bidi_event: nil,
         last_readiness: %{}
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

  def handle_call({:await_ready, opts}, _from, state) do
    timeout_ms = normalize_positive_integer(Keyword.get(opts, :timeout_ms), @default_ready_timeout_ms)
    quiet_ms = normalize_positive_integer(Keyword.get(opts, :quiet_ms), @default_ready_quiet_ms)

    case evaluate_readiness(state.id, timeout_ms, quiet_ms, state.bidi_opts) do
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

  def handle_call({:evaluate, expression, timeout_ms}, _from, state) do
    bidi_opts = Keyword.put(state.bidi_opts, :timeout, timeout_ms)
    result = evaluate_script(state.id, expression, bidi_opts)

    {:reply, result, state}
  end

  @impl true
  def handle_info({:cerberus_bidi_event, %{"method" => method, "params" => params}}, state)
      when is_binary(method) and is_map(params) do
    event =
      if params["context"] == state.id do
        %{
          "method" => method,
          "context" => params["context"],
          "url" => params["url"],
          "navigation" => params["navigation"],
          "timestampMs" => System.monotonic_time(:millisecond)
        }
      end

    if is_map(event) do
      {:noreply, %{state | last_bidi_event: event}}
    else
      {:noreply, state}
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
        if retries_left > 0 and transient_create_browsing_context_error?(reason, details) do
          Process.sleep(25)
          create_browsing_context(user_context_id, bidi_opts, retries_left - 1)
        else
          {:error, reason, details}
        end

      _ ->
        {:error, "unexpected browsingContext.create response", %{}}
    end
  end

  defp transient_create_browsing_context_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"

    String.contains?(combined, "DiscardedBrowsingContextError") or
      String.contains?(combined, "no such frame") or
      String.contains?(combined, "argument is not a global object")
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
        if transient_readiness_error?(reason, details) do
          Process.sleep(25)
          evaluate_json(context_id, expression, bidi_opts)
        else
          {:error, reason, details}
        end

      result ->
        result
    end
  end

  defp transient_readiness_error?(reason, details) do
    combined = "#{reason} #{inspect(details)}"

    Enum.any?(
      [
        "JSWindowActorChild cannot send",
        "argument is not a global object",
        "Inspected target navigated or closed",
        "Cannot find context with specified id",
        "execution contexts cleared",
        "DiscardedBrowsingContextError",
        "no such frame"
      ],
      &String.contains?(combined, &1)
    )
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

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default

  defp command_call_timeout_ms(timeout_ms) when is_integer(timeout_ms) and timeout_ms > 0 do
    timeout_ms + 5_000
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

              const allConnected = currentRoots.every((root) => {
                try {
                  return !!(root && root.classList && root.classList.contains("phx-connected"));
                } catch (_error) {
                  return false;
                }
              });

              return allConnected ? "connected" : "disconnected";
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
end
