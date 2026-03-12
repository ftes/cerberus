defmodule Cerberus.Driver.Browser.UserContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.BrowsingContextProcess
  alias Cerberus.Driver.Browser.BrowsingContextSupervisor
  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Driver.Browser.Types

  @popup_poll_ms 25
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

  @spec base_url(pid()) :: String.t()
  def base_url(pid) when is_pid(pid) do
    GenServer.call(pid, :base_url)
  end

  @spec navigate(pid(), String.t()) :: Types.bidi_response()
  def navigate(pid, url) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate, url}, 10_000)
  end

  @spec navigate(pid(), String.t(), String.t() | nil) :: Types.bidi_response()
  def navigate(pid, url, tab_id) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate_tab, tab_id, url}, 10_000)
  end

  @spec reload(pid()) :: Types.bidi_response()
  def reload(pid) when is_pid(pid) do
    GenServer.call(pid, :reload, 10_000)
  end

  @spec reload(pid(), String.t() | nil) :: Types.bidi_response()
  def reload(pid, tab_id) when is_pid(pid) do
    GenServer.call(pid, {:reload_tab, tab_id}, 10_000)
  end

  @spec evaluate(pid(), String.t()) :: Types.bidi_response()
  def evaluate(pid, expression) when is_pid(pid) and is_binary(expression) do
    evaluate_with_timeout(pid, expression, 10_000)
  end

  @spec evaluate(pid(), String.t(), String.t() | nil) :: Types.bidi_response()
  def evaluate(pid, expression, tab_id) when is_pid(pid) and is_binary(expression) do
    evaluate_with_timeout(pid, expression, 10_000, tab_id)
  end

  @spec evaluate_with_timeout(pid(), String.t(), pos_integer()) :: Types.bidi_response()
  def evaluate_with_timeout(pid, expression, timeout_ms)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    started_us = System.monotonic_time(:microsecond)
    GenServer.call(pid, {:evaluate, expression, timeout_ms, started_us}, timeout_ms + 5_000)
  end

  @spec evaluate_with_timeout(pid(), String.t(), pos_integer(), String.t() | nil) ::
          Types.bidi_response()
  def evaluate_with_timeout(pid, expression, timeout_ms, tab_id)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    started_us = System.monotonic_time(:microsecond)
    GenServer.call(pid, {:evaluate_tab, tab_id, expression, timeout_ms, started_us}, timeout_ms + 5_000)
  end

  @spec await_ready(pid(), keyword()) ::
          {:ok, Types.readiness_payload()} | {:error, String.t(), Types.readiness_payload()}
  def await_ready(pid, opts \\ []) when is_pid(pid) and is_list(opts) do
    GenServer.call(pid, {:await_ready, opts}, 10_000)
  end

  @spec await_ready(pid(), keyword(), String.t() | nil) ::
          {:ok, Types.readiness_payload()} | {:error, String.t(), Types.readiness_payload()}
  def await_ready(pid, opts, tab_id) when is_pid(pid) and is_list(opts) do
    GenServer.call(pid, {:await_ready_tab, tab_id, opts}, 10_000)
  end

  @spec open_tab(pid()) :: {:ok, String.t()} | {:error, String.t(), Types.bidi_error_details()}
  def open_tab(pid) when is_pid(pid) do
    GenServer.call(pid, :open_tab, 10_000)
  end

  @spec switch_tab(pid(), String.t()) :: :ok | {:error, String.t(), Types.bidi_error_details()}
  def switch_tab(pid, tab_id) when is_pid(pid) and is_binary(tab_id) do
    GenServer.call(pid, {:switch_tab, tab_id}, 10_000)
  end

  @spec close_tab(pid(), String.t()) :: :ok | {:error, String.t(), Types.bidi_error_details()}
  def close_tab(pid, tab_id) when is_pid(pid) and is_binary(tab_id) do
    GenServer.call(pid, {:close_tab, tab_id}, 10_000)
  end

  @spec attach_tab(pid(), String.t()) :: :ok | {:error, String.t(), Types.bidi_error_details()}
  def attach_tab(pid, tab_id) when is_pid(pid) and is_binary(tab_id) do
    GenServer.call(pid, {:attach_tab, tab_id}, 10_000)
  end

  @spec tabs(pid()) :: [String.t()]
  def tabs(pid) when is_pid(pid) do
    GenServer.call(pid, :tabs)
  end

  @spec context_ids(pid()) :: [String.t()]
  def context_ids(pid) when is_pid(pid) do
    GenServer.call(pid, :context_ids)
  end

  @spec active_tab(pid()) :: String.t() | nil
  def active_tab(pid) when is_pid(pid) do
    GenServer.call(pid, :active_tab)
  end

  @spec recover_active_tab(pid(), String.t() | nil) ::
          {:ok, String.t()} | {:error, String.t(), Types.bidi_error_details()}
  def recover_active_tab(pid, tab_id) when is_pid(pid) do
    GenServer.call(pid, {:recover_active_tab, tab_id}, 10_000)
  end

  @spec set_user_agent(pid(), String.t()) :: :ok | {:error, String.t(), Types.bidi_error_details()}
  def set_user_agent(pid, user_agent) when is_pid(pid) and is_binary(user_agent) do
    GenServer.call(pid, {:set_user_agent, user_agent}, 10_000)
  end

  @spec last_readiness(pid()) :: Types.readiness_payload()
  def last_readiness(pid) when is_pid(pid) do
    GenServer.call(pid, :last_readiness)
  end

  @spec last_readiness(pid(), String.t() | nil) :: Types.readiness_payload()
  def last_readiness(pid, tab_id) when is_pid(pid) do
    GenServer.call(pid, {:last_readiness_tab, tab_id})
  end

  @spec download_events(pid()) :: [Types.payload()]
  def download_events(pid) when is_pid(pid) do
    GenServer.call(pid, {:download_events_tab, nil})
  end

  @spec download_events(pid(), String.t() | nil) :: [Types.payload()]
  def download_events(pid, tab_id) when is_pid(pid) do
    GenServer.call(pid, {:download_events_tab, tab_id})
  end

  @spec await_download(pid(), String.t(), pos_integer()) ::
          {:ok, Types.payload()} | {:error, :timeout, [Types.payload()]} | {:error, String.t(), map()}
  def await_download(pid, expected_filename, timeout_ms)
      when is_pid(pid) and is_binary(expected_filename) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(
      pid,
      {:await_download_tab, nil, expected_filename, timeout_ms},
      timeout_ms + @call_timeout_padding_ms
    )
  end

  @spec await_download(pid(), String.t(), pos_integer(), String.t() | nil) ::
          {:ok, Types.payload()} | {:error, :timeout, [Types.payload()]} | {:error, String.t(), map()}
  def await_download(pid, expected_filename, timeout_ms, tab_id)
      when is_pid(pid) and is_binary(expected_filename) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(
      pid,
      {:await_download_tab, tab_id, expected_filename, timeout_ms},
      timeout_ms + @call_timeout_padding_ms
    )
  end

  @spec await_popup_tab(pid(), [String.t()] | MapSet.t(String.t()), pos_integer()) ::
          {:ok, String.t()} | {:error, :timeout} | {:error, :multiple, [String.t()]}
  def await_popup_tab(pid, baseline_tabs, timeout_ms) when is_pid(pid) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(
      pid,
      {:await_popup_tab, baseline_tabs, timeout_ms},
      timeout_ms + @call_timeout_padding_ms
    )
  end

  @impl true
  def init(opts) do
    owner = Keyword.fetch!(opts, :owner)
    owner_ref = Process.monitor(owner)
    bidi_opts = Keyword.get(opts, :bidi_opts, opts)

    browser_context_defaults =
      Keyword.get(opts, :browser_context_defaults, %{viewport: nil, user_agent: nil, init_scripts: [], popup_mode: :allow})

    with {:ok, browsing_context_supervisor} <- BrowsingContextSupervisor.start_link(),
         {:ok, user_context_id} <- create_user_context(bidi_opts),
         :ok <- configure_user_context_defaults(user_context_id, browser_context_defaults, bidi_opts),
         {:ok, browsing_context_pid} <-
           start_browsing_context(
             browsing_context_supervisor,
             user_context_id,
             browser_context_defaults,
             bidi_opts,
             slow_mo_ms: Runtime.slow_mo_ms(bidi_opts)
           ) do
      {:ok, first_tab_id, browsing_contexts} =
        add_browsing_context(%{}, browsing_context_pid)

      {:ok,
       %{
         owner: owner,
         owner_ref: owner_ref,
         base_url: Runtime.base_url(),
         user_context_id: user_context_id,
         browsing_context_supervisor: browsing_context_supervisor,
         browser_context_defaults: browser_context_defaults,
         bidi_opts: bidi_opts,
         browsing_contexts: browsing_contexts,
         active_browsing_context_id: first_tab_id,
         known_context_ids: MapSet.new([first_tab_id]),
         popup_waiters: %{},
         pending_evaluations: %{}
       }}
    else
      {:error, reason} ->
        {:stop, reason}

      {:error, reason, details} ->
        {:stop, {reason, details}}
    end
  end

  @impl true
  def handle_call(:base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call({:navigate, url}, _from, state) do
    {:reply, BrowsingContextProcess.navigate(active_browsing_context_pid!(state), url), state}
  end

  def handle_call({:navigate_tab, tab_id, url}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.navigate(pid, url), state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call(:reload, _from, state) do
    {:reply, BrowsingContextProcess.reload(active_browsing_context_pid!(state)), state}
  end

  def handle_call({:reload_tab, tab_id}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.reload(pid), state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call({:evaluate, expression, timeout_ms, started_us}, from, state) do
    record_transport_delay(:user_context_queue, started_us)
    pid = active_browsing_context_pid!(state)
    {:noreply, start_pending_evaluation(state, pid, expression, timeout_ms, from)}
  end

  def handle_call({:evaluate_tab, tab_id, expression, timeout_ms, started_us}, from, state) do
    record_transport_delay(:user_context_queue, started_us)

    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:noreply, start_pending_evaluation(state, pid, expression, timeout_ms, from)}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call({:await_ready, opts}, _from, state) do
    {:reply, await_ready_safe(active_browsing_context_pid!(state), opts), state}
  end

  def handle_call({:await_ready_tab, tab_id, opts}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, await_ready_safe(pid, opts), state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call(:open_tab, _from, state) do
    with {:ok, browsing_context_pid} <-
           start_browsing_context(
             state.browsing_context_supervisor,
             state.user_context_id,
             state.browser_context_defaults,
             state.bidi_opts,
             slow_mo_ms: Runtime.slow_mo_ms(state.bidi_opts)
           ),
         {:ok, tab_id, browsing_contexts} <- add_browsing_context(state.browsing_contexts, browsing_context_pid) do
      known_context_ids = MapSet.put(state.known_context_ids, tab_id)

      {:reply, {:ok, tab_id},
       %{
         state
         | browsing_contexts: browsing_contexts,
           active_browsing_context_id: tab_id,
           known_context_ids: known_context_ids
       }}
    else
      {:error, reason} ->
        {:reply, {:error, inspect(reason), %{}}, state}
    end
  end

  def handle_call({:attach_tab, tab_id}, _from, state) do
    if Map.has_key?(state.browsing_contexts, tab_id) do
      {:reply, :ok, state}
    else
      with {:ok, browsing_context_pid} <-
             start_browsing_context(
               state.browsing_context_supervisor,
               state.user_context_id,
               state.browser_context_defaults,
               state.bidi_opts,
               context_id: tab_id,
               slow_mo_ms: Runtime.slow_mo_ms(state.bidi_opts)
             ),
           {:ok, _attached_tab_id, browsing_contexts} <-
             add_browsing_context(state.browsing_contexts, browsing_context_pid) do
        known_context_ids = MapSet.put(state.known_context_ids, tab_id)
        {:reply, :ok, %{state | browsing_contexts: browsing_contexts, known_context_ids: known_context_ids}}
      else
        {:error, reason} ->
          {:reply, {:error, inspect(reason), %{tab_id: tab_id}}, state}
      end
    end
  end

  def handle_call({:switch_tab, tab_id}, _from, state) do
    if Map.has_key?(state.browsing_contexts, tab_id) do
      {:reply, :ok, %{state | active_browsing_context_id: tab_id}}
    else
      {:reply, {:error, "unknown tab", %{tab_id: tab_id}}, state}
    end
  end

  def handle_call({:close_tab, tab_id}, _from, state) do
    case Map.fetch(state.browsing_contexts, tab_id) do
      :error ->
        {:reply, {:error, "unknown tab", %{tab_id: tab_id}}, state}

      {:ok, _entry} when map_size(state.browsing_contexts) == 1 ->
        {:reply, {:error, "cannot close last tab", %{tab_id: tab_id}}, state}

      {:ok, entry} ->
        Process.demonitor(entry.ref, [:flush])
        _ = DynamicSupervisor.terminate_child(state.browsing_context_supervisor, entry.pid)
        browsing_contexts = Map.delete(state.browsing_contexts, tab_id)
        active_tab_id = choose_next_active_tab_id(state.active_browsing_context_id, tab_id, browsing_contexts)
        known_context_ids = MapSet.delete(state.known_context_ids, tab_id)

        {:reply, :ok,
         %{
           state
           | browsing_contexts: browsing_contexts,
             active_browsing_context_id: active_tab_id,
             known_context_ids: known_context_ids
         }}
    end
  end

  def handle_call(:tabs, _from, state) do
    tabs = state.browsing_contexts |> Map.keys() |> Enum.sort()
    {:reply, tabs, state}
  end

  def handle_call(:context_ids, _from, state) do
    context_ids = state.known_context_ids |> MapSet.to_list() |> Enum.sort()
    {:reply, context_ids, state}
  end

  def handle_call(:active_tab, _from, state) do
    {:reply, state.active_browsing_context_id, state}
  end

  def handle_call({:recover_active_tab, tab_id}, _from, state) do
    state = refresh_known_context_ids(state)
    recover_active_tab_reply(state, tab_id)
  end

  def handle_call({:set_user_agent, user_agent}, _from, state) do
    {:reply, set_user_agent_override(state.user_context_id, user_agent, state.bidi_opts), state}
  end

  def handle_call(:last_readiness, _from, state) do
    {:reply, BrowsingContextProcess.last_readiness(active_browsing_context_pid!(state)), state}
  end

  def handle_call({:last_readiness_tab, tab_id}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.last_readiness(pid), state}

      {:error, _reason, _details} ->
        {:reply, %{}, state}
    end
  end

  def handle_call({:download_events_tab, tab_id}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.download_events(pid), state}

      {:error, _reason, _details} ->
        {:reply, [], state}
    end
  end

  def handle_call({:await_download_tab, tab_id, expected_filename, timeout_ms}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.await_download(pid, expected_filename, timeout_ms), state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  def handle_call({:await_popup_tab, baseline_tabs, timeout_ms}, from, state) do
    state = refresh_known_context_ids(state)
    baseline_tabs = normalize_context_set(baseline_tabs)

    case popup_waiter_result(state.known_context_ids, baseline_tabs) do
      {:ok, popup_tab_id} ->
        {:reply, {:ok, popup_tab_id}, state}

      {:error, :multiple, tabs} ->
        {:reply, {:error, :multiple, tabs}, state}

      :none ->
        waiter_id = make_ref()
        timer = Process.send_after(self(), {:popup_waiter_timeout, waiter_id}, timeout_ms)
        _ = Process.send_after(self(), {:popup_waiter_poll, waiter_id}, @popup_poll_ms)

        popup_waiters =
          Map.put(state.popup_waiters, waiter_id, %{from: from, baseline_tabs: baseline_tabs, timer: timer})

        {:noreply, %{state | popup_waiters: popup_waiters}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{owner_ref: ref} = state) do
    # Owner/test process finished; tear down userContext as a normal shutdown.
    {:stop, :normal, state}
  end

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

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.pending_evaluations, ref) do
      {from, pending_evaluations} when not is_nil(from) ->
        GenServer.reply(from, {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}})
        {:noreply, %{state | pending_evaluations: pending_evaluations}}

      {nil, _pending_evaluations} ->
        case pop_browsing_context_by_ref(state.browsing_contexts, ref) do
          {:ok, down_tab_id, browsing_contexts} ->
            handle_browsing_context_down(state, browsing_contexts, down_tab_id, reason)

          :error ->
            {:noreply, state}
        end
    end
  end

  def handle_info({:popup_waiter_poll, waiter_id}, state) do
    state = refresh_known_context_ids(state)

    case Map.fetch(state.popup_waiters, waiter_id) do
      :error ->
        {:noreply, state}

      {:ok, waiter} ->
        case popup_waiter_result(state.known_context_ids, waiter.baseline_tabs) do
          {:ok, popup_tab_id} ->
            Process.cancel_timer(waiter.timer)
            GenServer.reply(waiter.from, {:ok, popup_tab_id})
            {:noreply, %{state | popup_waiters: Map.delete(state.popup_waiters, waiter_id)}}

          {:error, :multiple, tabs} ->
            Process.cancel_timer(waiter.timer)
            GenServer.reply(waiter.from, {:error, :multiple, tabs})
            {:noreply, %{state | popup_waiters: Map.delete(state.popup_waiters, waiter_id)}}

          :none ->
            _ = Process.send_after(self(), {:popup_waiter_poll, waiter_id}, @popup_poll_ms)
            {:noreply, state}
        end
    end
  end

  def handle_info({:popup_waiter_timeout, waiter_id}, state) do
    case Map.pop(state.popup_waiters, waiter_id) do
      {nil, _waiters} ->
        {:noreply, state}

      {waiter, popup_waiters} ->
        GenServer.reply(waiter.from, {:error, :timeout})
        {:noreply, %{state | popup_waiters: popup_waiters}}
    end
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = maybe_remove_user_context(state)

    if is_pid(state.browsing_context_supervisor) and
         Process.alive?(state.browsing_context_supervisor) do
      _ = DynamicSupervisor.stop(state.browsing_context_supervisor)
    end

    :ok
  end

  defp create_user_context(bidi_opts) do
    with {:ok, result} <- BiDi.command("browser.createUserContext", %{}, bidi_opts),
         user_context_id when is_binary(user_context_id) <- result["userContext"] do
      {:ok, user_context_id}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      _ ->
        {:error, "unexpected browser.createUserContext response", %{}}
    end
  end

  defp remove_user_context(user_context_id, bidi_opts) when is_binary(user_context_id) do
    BiDi.command("browser.removeUserContext", %{"userContext" => user_context_id}, bidi_opts)
  end

  defp remove_user_context(_, _), do: :ok

  defp maybe_remove_user_context(%{owner: owner, user_context_id: user_context_id, bidi_opts: bidi_opts})
       when is_pid(owner) do
    if Process.alive?(owner) do
      try do
        remove_user_context(user_context_id, bidi_opts)
      catch
        :exit, _reason -> :ok
      end
    else
      :ok
    end
  end

  defp maybe_remove_user_context(_state), do: :ok

  defp start_browsing_context(browsing_context_supervisor, user_context_id, defaults, bidi_opts, extra_opts) do
    DynamicSupervisor.start_child(
      browsing_context_supervisor,
      {BrowsingContextProcess,
       [user_context_id: user_context_id, viewport: defaults.viewport, bidi_opts: bidi_opts] ++ extra_opts}
    )
  end

  defp add_browsing_context(browsing_contexts, browsing_context_pid) do
    tab_id = BrowsingContextProcess.id(browsing_context_pid)
    ref = Process.monitor(browsing_context_pid)
    {:ok, tab_id, Map.put(browsing_contexts, tab_id, %{pid: browsing_context_pid, ref: ref})}
  end

  defp pop_browsing_context_by_ref(browsing_contexts, ref) do
    case Enum.find(browsing_contexts, fn {_tab_id, entry} -> entry.ref == ref end) do
      nil ->
        :error

      {tab_id, _entry} ->
        {:ok, tab_id, Map.delete(browsing_contexts, tab_id)}
    end
  end

  defp choose_next_active_tab_id(active_tab_id, closed_tab_id, browsing_contexts) do
    cond do
      active_tab_id != closed_tab_id and Map.has_key?(browsing_contexts, active_tab_id) ->
        active_tab_id

      map_size(browsing_contexts) == 0 ->
        nil

      true ->
        browsing_contexts
        |> Map.keys()
        |> Enum.sort()
        |> List.first()
    end
  end

  defp handle_browsing_context_down(state, browsing_contexts, down_tab_id, reason) do
    active_tab_id = choose_next_active_tab_id(state.active_browsing_context_id, down_tab_id, browsing_contexts)

    if is_nil(active_tab_id) do
      {:stop, {:browsing_context_down, reason}, state}
    else
      known_context_ids = MapSet.delete(state.known_context_ids, down_tab_id)

      {:noreply,
       %{
         state
         | browsing_contexts: browsing_contexts,
           active_browsing_context_id: active_tab_id,
           known_context_ids: known_context_ids
       }}
    end
  end

  defp active_browsing_context_pid!(state) do
    case Map.fetch(state.browsing_contexts, state.active_browsing_context_id) do
      {:ok, entry} ->
        entry.pid

      :error ->
        raise "active browsing context is unavailable"
    end
  end

  defp browsing_context_pid(state, nil), do: {:ok, active_browsing_context_pid!(state)}

  defp browsing_context_pid(state, tab_id) when is_binary(tab_id) do
    case Map.fetch(state.browsing_contexts, tab_id) do
      {:ok, entry} -> {:ok, entry.pid}
      :error -> {:error, "unknown tab", %{tab_id: tab_id}}
    end
  end

  defp record_transport_delay(bucket, started_us) when is_atom(bucket) and is_integer(started_us) do
    Cerberus.Profiling.record_us(
      {:browser_transport, bucket},
      max(System.monotonic_time(:microsecond) - started_us, 0)
    )
  end

  defp start_pending_evaluation(state, pid, expression, timeout_ms, from)
       when is_map(state) and is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) do
    task =
      Task.async(fn ->
        try do
          Cerberus.Profiling.measure({:browser_transport, :user_context_dispatch}, fn ->
            BrowsingContextProcess.evaluate(pid, expression, timeout_ms)
          end)
        catch
          :exit, reason ->
            {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}}
        end
      end)

    Process.unlink(task.pid)
    %{state | pending_evaluations: Map.put(state.pending_evaluations, task.ref, from)}
  end

  defp set_user_agent_override(user_context_id, user_agent, bidi_opts) do
    params = %{
      "userAgent" => user_agent,
      "userContexts" => [user_context_id]
    }

    case BiDi.command("emulation.setUserAgentOverride", params, bidi_opts) do
      {:ok, _result} ->
        :ok

      {:error, emulation_reason, emulation_details} ->
        # Chrome BiDi coverage varies by channel; fallback keeps sandbox metadata working.
        headers = [
          %{
            "name" => "user-agent",
            "value" => %{"type" => "string", "value" => user_agent}
          }
        ]

        fallback_params = %{"headers" => headers, "userContexts" => [user_context_id]}

        case BiDi.command("network.setExtraHeaders", fallback_params, bidi_opts) do
          {:ok, _result} ->
            :ok

          {:error, network_reason, network_details} ->
            {:error, network_reason,
             %{
               emulation_reason: emulation_reason,
               emulation_details: emulation_details,
               network_details: network_details
             }}
        end
    end
  end

  defp configure_user_context_defaults(user_context_id, defaults, bidi_opts) do
    with :ok <- maybe_set_user_agent(user_context_id, defaults.user_agent, bidi_opts) do
      maybe_add_init_scripts(user_context_id, defaults.init_scripts, bidi_opts)
    end
  end

  defp maybe_set_user_agent(_user_context_id, nil, _bidi_opts), do: :ok

  defp maybe_set_user_agent(user_context_id, user_agent, bidi_opts),
    do: set_user_agent_override(user_context_id, user_agent, bidi_opts)

  defp maybe_add_init_scripts(_user_context_id, [], _bidi_opts), do: :ok

  defp maybe_add_init_scripts(user_context_id, scripts, bidi_opts) when is_list(scripts) do
    Enum.reduce_while(scripts, :ok, fn script, :ok ->
      case add_preload_script(user_context_id, script, bidi_opts) do
        :ok -> {:cont, :ok}
        {:error, reason, details} -> {:halt, {:error, reason, details}}
      end
    end)
  end

  defp add_preload_script(user_context_id, script, bidi_opts) when is_binary(script) do
    params = %{
      "functionDeclaration" => preload_function_declaration(script),
      "userContexts" => [user_context_id]
    }

    case BiDi.command("script.addPreloadScript", params, bidi_opts) do
      {:ok, _result} -> :ok
      {:error, reason, details} -> {:error, reason, details}
    end
  end

  defp preload_function_declaration(script) do
    """
    () => {
      #{script}
    }
    """
  end

  defp refresh_known_context_ids(state) do
    case fetch_user_context_tabs(state.user_context_id, state.bidi_opts) do
      {:ok, context_ids} ->
        %{state | known_context_ids: MapSet.new(context_ids)}

      {:error, _reason, _details} ->
        state
    end
  end

  defp open_and_activate_tab(state) do
    with {:ok, browsing_context_pid} <-
           start_browsing_context(
             state.browsing_context_supervisor,
             state.user_context_id,
             state.browser_context_defaults,
             state.bidi_opts,
             slow_mo_ms: Runtime.slow_mo_ms(state.bidi_opts)
           ),
         {:ok, tab_id, browsing_contexts} <- add_browsing_context(state.browsing_contexts, browsing_context_pid) do
      known_context_ids = MapSet.put(state.known_context_ids, tab_id)

      next_state = %{
        state
        | browsing_contexts: browsing_contexts,
          active_browsing_context_id: tab_id,
          known_context_ids: known_context_ids
      }

      {:ok, next_state, tab_id}
    else
      {:error, reason} ->
        {:error, inspect(reason), %{}}
    end
  end

  defp ensure_context_attached(state, context_id) when is_binary(context_id) do
    if Map.has_key?(state.browsing_contexts, context_id) do
      {:ok, %{state | active_browsing_context_id: context_id}, context_id}
    else
      with {:ok, browsing_context_pid} <-
             start_browsing_context(
               state.browsing_context_supervisor,
               state.user_context_id,
               state.browser_context_defaults,
               state.bidi_opts,
               context_id: context_id,
               slow_mo_ms: Runtime.slow_mo_ms(state.bidi_opts)
             ),
           {:ok, tab_id, browsing_contexts} <- add_browsing_context(state.browsing_contexts, browsing_context_pid) do
        known_context_ids = MapSet.put(state.known_context_ids, tab_id)

        next_state = %{
          state
          | browsing_contexts: browsing_contexts,
            active_browsing_context_id: tab_id,
            known_context_ids: known_context_ids
        }

        {:ok, next_state, tab_id}
      else
        {:error, reason} ->
          {:error, inspect(reason), %{tab_id: context_id}}
      end
    end
  end

  defp recover_active_tab_reply(state, requested_tab_id) do
    case recover_or_open_active_tab(state, requested_tab_id) do
      {:ok, next_state, recovered_tab_id} ->
        {next_state, response_tab_id} = rebind_requested_tab_alias(next_state, requested_tab_id, recovered_tab_id)
        {:reply, {:ok, response_tab_id}, next_state}

      {:error, reason, details} ->
        {:reply, {:error, reason, details}, state}
    end
  end

  defp recover_or_open_active_tab(state, requested_tab_id) do
    case preferred_recovery_context_id(state, requested_tab_id) do
      nil ->
        open_and_activate_tab(state)

      context_id ->
        case ensure_context_attached(state, context_id) do
          {:ok, _next_state, _recovered_tab_id} = success ->
            success

          {:error, _reason, _details} ->
            open_and_activate_tab(state)
        end
    end
  end

  defp preferred_recovery_context_id(state, requested_tab_id) do
    candidate_ids = state.known_context_ids |> MapSet.to_list() |> Enum.sort()

    cond do
      is_binary(requested_tab_id) and requested_tab_id in candidate_ids ->
        requested_tab_id

      is_binary(state.active_browsing_context_id) and state.active_browsing_context_id in candidate_ids ->
        state.active_browsing_context_id

      true ->
        List.first(candidate_ids)
    end
  end

  defp rebind_requested_tab_alias(state, requested_tab_id, recovered_tab_id)
       when is_binary(requested_tab_id) and requested_tab_id != "" and requested_tab_id != recovered_tab_id do
    case Map.fetch(state.browsing_contexts, recovered_tab_id) do
      {:ok, recovered_entry} ->
        browsing_contexts =
          state.browsing_contexts
          |> Map.delete(requested_tab_id)
          |> Map.put(requested_tab_id, recovered_entry)

        {
          %{
            state
            | browsing_contexts: browsing_contexts,
              active_browsing_context_id: requested_tab_id
          },
          requested_tab_id
        }

      :error ->
        {state, recovered_tab_id}
    end
  end

  defp rebind_requested_tab_alias(state, _requested_tab_id, recovered_tab_id), do: {state, recovered_tab_id}

  defp fetch_user_context_tabs(user_context_id, bidi_opts) when is_binary(user_context_id) and is_list(bidi_opts) do
    case BiDi.command("browsingContext.getTree", %{"maxDepth" => 0}, bidi_opts) do
      {:ok, %{"contexts" => contexts}} when is_list(contexts) ->
        entries = flatten_tree_context_entries(contexts)

        tabs =
          entries
          |> Enum.filter(&(&1.user_context == user_context_id))
          |> Enum.map(& &1.context_id)
          |> Enum.uniq()

        {:ok, tabs}

      {:error, reason, details} ->
        {:error, reason, details}

      _ ->
        {:error, "unexpected browsingContext.getTree response", %{}}
    end
  end

  defp flatten_tree_context_entries(contexts) when is_list(contexts) do
    Enum.flat_map(contexts, &flatten_tree_context_entry/1)
  end

  defp flatten_tree_context_entries(nil), do: []

  defp flatten_tree_context_entry(%{"context" => context_id} = entry) when is_binary(context_id) do
    children = flatten_tree_context_entries(Map.get(entry, "children", []))
    [%{context_id: context_id, user_context: entry["userContext"]} | children]
  end

  defp flatten_tree_context_entry(_entry), do: []

  defp normalize_context_set(%MapSet{} = tabs), do: tabs
  defp normalize_context_set(tabs) when is_list(tabs), do: MapSet.new(Enum.filter(tabs, &is_binary/1))
  defp normalize_context_set(_tabs), do: MapSet.new()

  defp popup_waiter_result(known_context_ids, baseline_tabs)
       when is_struct(known_context_ids, MapSet) and is_struct(baseline_tabs, MapSet) do
    case known_context_ids |> MapSet.difference(baseline_tabs) |> MapSet.to_list() do
      [popup_tab_id] ->
        {:ok, popup_tab_id}

      [] ->
        :none

      tabs ->
        {:error, :multiple, Enum.sort(tabs)}
    end
  end

  defp await_ready_safe(pid, opts) when is_pid(pid) and is_list(opts) do
    BrowsingContextProcess.await_ready(pid, opts)
  catch
    :exit, {:timeout, {GenServer, :call, _call_args}} ->
      {:error, "browser readiness timeout", %{"reason" => "await_ready process timeout"}}

    :exit, reason ->
      {:error, "browser readiness call failed", %{"reason" => inspect(reason)}}
  end
end
