defmodule Cerberus.LiveViewTimeout do
  @moduledoc false

  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.LiveViewWatcher
  alias ExUnit.AssertionError
  alias Phoenix.LiveView.Channel, as: LiveViewChannel

  @type redirect_info :: {String.t(), map()} | String.t()

  @spec interval_wait_time() :: pos_integer()
  def interval_wait_time, do: 100

  @spec with_timeout(session, integer(), (session -> result), (session -> redirect_info)) :: result
        when session: var, result: var
  def with_timeout(session, timeout, action, fetch_redirect_info \\ &via_assert_redirect/1)

  def with_timeout(%Static{} = session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{view: nil} = session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, _fetch_redirect_info) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, fetch_redirect_info) when is_function(action) do
    {:ok, watcher} = LiveViewWatcher.start_link(%{caller: self(), view: session.view})

    try do
      :ok = LiveViewWatcher.watch_view(watcher, session.view)
      handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info)
    after
      Process.exit(watcher, :normal)
    end
  end

  defp handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info) when timeout <= 0 do
    action.(session)
  catch
    :exit, _error ->
      check_for_redirect(session, action, fetch_redirect_info)
  end

  defp handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info) do
    wait_time = interval_wait_time()
    new_timeout = max(timeout - wait_time, 0)
    view_pid = session.view.pid

    receive do
      {:watcher, ^view_pid, {:live_view_redirected, redirect_tuple}} ->
        session
        |> apply_redirect(redirect_tuple)
        |> with_timeout(new_timeout, action, fetch_redirect_info)

      {:watcher, ^view_pid, :live_view_died} ->
        check_for_redirect(session, action, fetch_redirect_info)
    after
      wait_time ->
        with_retry(session, action, &handle_watched_messages_with_timeout(&1, new_timeout, action, fetch_redirect_info))
    end
  end

  defp with_retry(session, action, retry_fun) when is_function(action) and is_function(retry_fun) do
    :ok = ping_view(session)
    action.(session)
  rescue
    AssertionError ->
      retry_fun.(session)
  catch
    :exit, _error ->
      retry_fun.(session)
  end

  defp ping_view(%Live{view: %{pid: pid}}) when is_pid(pid) do
    :ok = LiveViewChannel.ping(pid)
  end

  defp ping_view(_session), do: :ok

  defp apply_redirect(session, {kind, %{to: path}}) when kind in [:redirect, :live_redirect] and is_binary(path) do
    Live.follow_redirect(session, path)
  end

  defp apply_redirect(session, _redirect_tuple), do: session

  defp check_for_redirect(session, action, fetch_redirect_info) when is_function(action) do
    path = fetch_redirect_path(fetch_redirect_info.(session))
    session |> Live.follow_redirect(path) |> then(action)
  end

  defp fetch_redirect_path({path, _flash}) when is_binary(path), do: path
  defp fetch_redirect_path(path) when is_binary(path), do: path
  defp fetch_redirect_path(_other), do: "/"

  defp via_assert_redirect(session) do
    Phoenix.LiveViewTest.assert_redirect(session.view)
  end
end
