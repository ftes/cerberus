defmodule Cerberus.Driver.Browser.UserContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.AssertionHelpers
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.BrowsingContextProcess
  alias Cerberus.Driver.Browser.BrowsingContextSupervisor
  alias Cerberus.Driver.Browser.Runtime

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

  @spec navigate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def navigate(pid, url) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate, url}, 10_000)
  end

  @spec navigate(pid(), String.t(), String.t() | nil) :: {:ok, map()} | {:error, String.t(), map()}
  def navigate(pid, url, tab_id) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate_tab, tab_id, url}, 10_000)
  end

  @spec evaluate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate(pid, expression) when is_pid(pid) and is_binary(expression) do
    evaluate_with_timeout(pid, expression, 10_000)
  end

  @spec evaluate(pid(), String.t(), String.t() | nil) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate(pid, expression, tab_id) when is_pid(pid) and is_binary(expression) do
    evaluate_with_timeout(pid, expression, 10_000, tab_id)
  end

  @spec evaluate_with_timeout(pid(), String.t(), pos_integer()) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate_with_timeout(pid, expression, timeout_ms)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:evaluate, expression, timeout_ms}, timeout_ms + 5_000)
  end

  @spec evaluate_with_timeout(pid(), String.t(), pos_integer(), String.t() | nil) ::
          {:ok, map()} | {:error, String.t(), map()}
  def evaluate_with_timeout(pid, expression, timeout_ms, tab_id)
      when is_pid(pid) and is_binary(expression) and is_integer(timeout_ms) and timeout_ms > 0 do
    GenServer.call(pid, {:evaluate_tab, tab_id, expression, timeout_ms}, timeout_ms + 5_000)
  end

  @spec await_ready(pid(), keyword()) :: {:ok, map()} | {:error, String.t(), map()}
  def await_ready(pid, opts \\ []) when is_pid(pid) and is_list(opts) do
    GenServer.call(pid, {:await_ready, opts}, 10_000)
  end

  @spec await_ready(pid(), keyword(), String.t() | nil) :: {:ok, map()} | {:error, String.t(), map()}
  def await_ready(pid, opts, tab_id) when is_pid(pid) and is_list(opts) do
    GenServer.call(pid, {:await_ready_tab, tab_id, opts}, 10_000)
  end

  @spec open_tab(pid()) :: {:ok, String.t()} | {:error, String.t(), map()}
  def open_tab(pid) when is_pid(pid) do
    GenServer.call(pid, :open_tab, 10_000)
  end

  @spec switch_tab(pid(), String.t()) :: :ok | {:error, String.t(), map()}
  def switch_tab(pid, tab_id) when is_pid(pid) and is_binary(tab_id) do
    GenServer.call(pid, {:switch_tab, tab_id}, 10_000)
  end

  @spec close_tab(pid(), String.t()) :: :ok | {:error, String.t(), map()}
  def close_tab(pid, tab_id) when is_pid(pid) and is_binary(tab_id) do
    GenServer.call(pid, {:close_tab, tab_id}, 10_000)
  end

  @spec tabs(pid()) :: [String.t()]
  def tabs(pid) when is_pid(pid) do
    GenServer.call(pid, :tabs)
  end

  @spec active_tab(pid()) :: String.t() | nil
  def active_tab(pid) when is_pid(pid) do
    GenServer.call(pid, :active_tab)
  end

  @spec set_user_agent(pid(), String.t()) :: :ok | {:error, String.t(), map()}
  def set_user_agent(pid, user_agent) when is_pid(pid) and is_binary(user_agent) do
    GenServer.call(pid, {:set_user_agent, user_agent}, 10_000)
  end

  @spec last_readiness(pid()) :: map()
  def last_readiness(pid) when is_pid(pid) do
    GenServer.call(pid, :last_readiness)
  end

  @spec last_readiness(pid(), String.t() | nil) :: map()
  def last_readiness(pid, tab_id) when is_pid(pid) do
    GenServer.call(pid, {:last_readiness_tab, tab_id})
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
           start_browsing_context(browsing_context_supervisor, user_context_id, browser_context_defaults, bidi_opts) do
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
         active_browsing_context_id: first_tab_id
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

  def handle_call({:evaluate, expression, timeout_ms}, _from, state) do
    {:reply, BrowsingContextProcess.evaluate(active_browsing_context_pid!(state), expression, timeout_ms), state}
  end

  def handle_call({:evaluate_tab, tab_id, expression, timeout_ms}, _from, state) do
    case browsing_context_pid(state, tab_id) do
      {:ok, pid} ->
        {:reply, BrowsingContextProcess.evaluate(pid, expression, timeout_ms), state}

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
             state.bidi_opts
           ),
         {:ok, tab_id, browsing_contexts} <- add_browsing_context(state.browsing_contexts, browsing_context_pid) do
      {:reply, {:ok, tab_id}, %{state | browsing_contexts: browsing_contexts, active_browsing_context_id: tab_id}}
    else
      {:error, reason} ->
        {:reply, {:error, inspect(reason), %{}}, state}
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
        {:reply, :ok, %{state | browsing_contexts: browsing_contexts, active_browsing_context_id: active_tab_id}}
    end
  end

  def handle_call(:tabs, _from, state) do
    tabs = state.browsing_contexts |> Map.keys() |> Enum.sort()
    {:reply, tabs, state}
  end

  def handle_call(:active_tab, _from, state) do
    {:reply, state.active_browsing_context_id, state}
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

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{owner_ref: ref} = state) do
    # Owner/test process finished; tear down userContext as a normal shutdown.
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case pop_browsing_context_by_ref(state.browsing_contexts, ref) do
      {:ok, down_tab_id, browsing_contexts} ->
        active_tab_id = choose_next_active_tab_id(state.active_browsing_context_id, down_tab_id, browsing_contexts)

        if is_nil(active_tab_id) do
          {:stop, {:browsing_context_down, reason}, state}
        else
          {:noreply, %{state | browsing_contexts: browsing_contexts, active_browsing_context_id: active_tab_id}}
        end

      :error ->
        {:noreply, state}
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

  defp start_browsing_context(browsing_context_supervisor, user_context_id, defaults, bidi_opts) do
    DynamicSupervisor.start_child(
      browsing_context_supervisor,
      {BrowsingContextProcess, user_context_id: user_context_id, viewport: defaults.viewport, bidi_opts: bidi_opts}
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
    browser_name = Runtime.browser_name(bidi_opts)

    scripts
    |> Enum.reject(&skip_firefox_assertion_preload?(&1, browser_name))
    |> Enum.reduce_while(:ok, fn script, :ok ->
      case add_preload_script(user_context_id, script, bidi_opts) do
        :ok -> {:cont, :ok}
        {:error, reason, details} -> {:halt, {:error, reason, details}}
      end
    end)
  end

  defp skip_firefox_assertion_preload?(script, :firefox) when is_binary(script) do
    script == AssertionHelpers.preload_script()
  end

  defp skip_firefox_assertion_preload?(_script, _browser_name), do: false

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

  defp await_ready_safe(pid, opts) when is_pid(pid) and is_list(opts) do
    BrowsingContextProcess.await_ready(pid, opts)
  catch
    :exit, {:timeout, {GenServer, :call, _call_args}} ->
      {:error, "browser readiness timeout", %{"reason" => "await_ready process timeout"}}

    :exit, reason ->
      {:error, "browser readiness call failed", %{"reason" => inspect(reason)}}
  end
end
