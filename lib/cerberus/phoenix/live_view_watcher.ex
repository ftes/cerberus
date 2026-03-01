defmodule Cerberus.Phoenix.LiveViewWatcher do
  @moduledoc false

  use GenServer, restart: :transient

  require Logger

  @type view :: %{required(:pid) => pid(), optional(:topic) => String.t(), optional(:proxy) => tuple()}

  @spec start_link(%{caller: pid(), view: view()}) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec watch_view(pid(), view()) :: :ok
  def watch_view(pid, live_view) do
    GenServer.cast(pid, {:watch_view, live_view})
  end

  @impl true
  def init(%{caller: caller, view: live_view}) do
    state = %{caller: caller, views: %{}, proxy_traces: %{}}
    {:ok, add_to_monitored_views(state, live_view)}
  end

  @impl true
  def handle_cast({:watch_view, live_view}, state) do
    {:noreply, add_to_monitored_views(state, live_view)}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, {kind, _data} = redirect_tuple}}, state)
      when kind in [:redirect, :live_redirect] do
    case find_view_by_ref(state, ref) do
      {:ok, view} ->
        notify_caller(state, view.pid, {:live_view_redirected, redirect_tuple})
        {:noreply, remove_view(state, view.pid)}

      :not_found ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:trace, proxy_pid, :receive, %Phoenix.Socket.Message{event: "diff", topic: topic}}, state) do
    {:noreply, notify_diff(state, proxy_pid, topic)}
  end

  @impl true
  def handle_info({:trace, proxy_pid, :receive, %Phoenix.Socket.Reply{topic: topic, payload: payload}}, state)
      when is_map(payload) do
    state =
      if Map.has_key?(payload, :diff) do
        notify_diff(state, proxy_pid, topic)
      else
        state
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:trace, proxy_pid, :receive, message}, state) do
    if Map.has_key?(state.proxy_traces, proxy_pid) do
      {:noreply, state}
    else
      handle_unhandled_message(state, {:trace, proxy_pid, :receive, message})
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case find_proxy_by_ref(state, ref) do
      {:ok, proxy_pid} ->
        {:noreply, stop_proxy_trace(state, proxy_pid)}

      :not_found ->
        case find_view_by_ref(state, ref) do
          {:ok, view} ->
            notify_caller(state, view.pid, :live_view_died)
            {:noreply, remove_view(state, view.pid)}

          :not_found ->
            {:noreply, state}
        end
    end
  end

  @impl true
  def handle_info(message, state) do
    handle_unhandled_message(state, message)
  end

  @impl true
  def terminate(_reason, state) do
    state.proxy_traces
    |> Map.keys()
    |> Enum.each(fn proxy_pid ->
      stop_proxy_trace(state, proxy_pid)
    end)

    :ok
  end

  defp handle_unhandled_message(state, message) do
    Logger.debug(fn -> "Unhandled LiveViewWatcher message received. Message: #{inspect(message)}" end)
    {:noreply, state}
  end

  defp add_to_monitored_views(state, live_view) do
    case state.views[live_view.pid] do
      nil ->
        view = monitor_view(live_view)

        state
        |> put_in([:views, live_view.pid], view)
        |> start_proxy_trace(view)

      %{live_view_ref: _live_view_ref} ->
        state
    end
  end

  defp monitor_view(live_view) do
    live_view_ref = Process.monitor(live_view.pid)

    %{
      pid: live_view.pid,
      topic: Map.get(live_view, :topic),
      proxy_pid: proxy_pid(live_view),
      live_view_ref: live_view_ref
    }
  end

  defp proxy_pid(%{proxy: {_ref, _topic, pid}}) when is_pid(pid), do: pid
  defp proxy_pid(_live_view), do: nil

  defp start_proxy_trace(state, %{proxy_pid: proxy_pid, topic: topic}) when is_pid(proxy_pid) and is_binary(topic) do
    case state.proxy_traces do
      %{^proxy_pid => %{topics: topics} = trace} ->
        put_in(state, [:proxy_traces, proxy_pid], %{trace | topics: MapSet.put(topics, topic)})

      _ ->
        case :erlang.trace(proxy_pid, true, [:receive]) do
          1 ->
            proxy_ref = Process.monitor(proxy_pid)
            put_in(state, [:proxy_traces, proxy_pid], %{proxy_ref: proxy_ref, topics: MapSet.new([topic])})

          _ ->
            state
        end
    end
  catch
    :error, :badarg ->
      state
  end

  defp start_proxy_trace(state, _view), do: state

  defp notify_diff(state, proxy_pid, topic) when is_binary(topic) do
    with {:ok, %{topics: topics}} <- Map.fetch(state.proxy_traces, proxy_pid),
         true <- MapSet.member?(topics, topic),
         {:ok, view_pid} <- view_pid_for_proxy_topic(state, proxy_pid, topic) do
      notify_caller(state, view_pid, :live_view_diff)
      state
    else
      _ -> state
    end
  end

  defp notify_diff(state, _proxy_pid, _topic), do: state

  defp view_pid_for_proxy_topic(state, proxy_pid, topic) do
    Enum.find_value(state.views, :not_found, fn {view_pid, view} ->
      if view.proxy_pid == proxy_pid and view.topic == topic, do: {:ok, view_pid}
    end)
  end

  defp notify_caller(state, view_pid, message) do
    send(state.caller, {:watcher, view_pid, message})
  end

  defp find_view_by_ref(state, ref) do
    Enum.find_value(state.views, :not_found, fn {_pid, view} ->
      if view.live_view_ref == ref, do: {:ok, view}
    end)
  end

  defp remove_view(state, view_pid) do
    case state.views[view_pid] do
      nil ->
        state

      view ->
        state =
          state
          |> Map.update!(:views, &Map.delete(&1, view_pid))
          |> maybe_stop_proxy_trace(view)

        state
    end
  end

  defp maybe_stop_proxy_trace(state, %{proxy_pid: proxy_pid, topic: topic}) when is_pid(proxy_pid) and is_binary(topic) do
    case state.proxy_traces do
      %{^proxy_pid => %{topics: topics} = trace} ->
        remaining_topics = MapSet.delete(topics, topic)

        if MapSet.size(remaining_topics) == 0 do
          stop_proxy_trace(state, proxy_pid)
        else
          put_in(state, [:proxy_traces, proxy_pid], %{trace | topics: remaining_topics})
        end

      _ ->
        state
    end
  end

  defp maybe_stop_proxy_trace(state, _view), do: state

  defp find_proxy_by_ref(state, ref) do
    Enum.find_value(state.proxy_traces, :not_found, fn {proxy_pid, trace} ->
      if trace.proxy_ref == ref, do: {:ok, proxy_pid}
    end)
  end

  defp stop_proxy_trace(state, proxy_pid) do
    case state.proxy_traces do
      %{^proxy_pid => %{proxy_ref: proxy_ref}} ->
        :erlang.trace(proxy_pid, false, [:receive])
        Process.demonitor(proxy_ref, [:flush])
        update_in(state.proxy_traces, &Map.delete(&1, proxy_pid))

      _ ->
        state
    end
  catch
    :error, :badarg ->
      update_in(state.proxy_traces, &Map.delete(&1, proxy_pid))
  end
end
