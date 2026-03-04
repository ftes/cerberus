defmodule Cerberus.Phoenix.LiveViewTimeout do
  @moduledoc false

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.Html
  alias Cerberus.Phoenix.LiveViewWatcher
  alias ExUnit.AssertionError
  alias Phoenix.LiveView.Channel, as: LiveViewChannel

  @type redirect_info :: {String.t(), map()} | String.t()

  @spec interval_wait_time() :: pos_integer()
  def interval_wait_time, do: 100

  @spec with_timeout(session, integer(), (session -> result), (session -> redirect_info)) :: result
        when session: var, result: var
  def with_timeout(session, timeout, action, fetch_redirect_info \\ &via_assert_redirect/1)

  def with_timeout(%Static{} = session, timeout, action, _fetch_redirect_info)
      when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Static{} = session, timeout, action, _fetch_redirect_info) when is_function(action) do
    deadline = timeout_deadline(timeout)
    with_assertion_deadline(deadline, fn -> action.(session) end)
  end

  def with_timeout(%Live{view: nil} = session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, _fetch_redirect_info) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, fetch_redirect_info) when is_function(action) do
    {:ok, watcher} = LiveViewWatcher.start_link(%{caller: self(), view: session.view})
    deadline = timeout_deadline(timeout)

    try do
      :ok = LiveViewWatcher.watch_view(watcher, session.view)

      with_assertion_deadline(deadline, fn ->
        handle_watched_messages_until(session, deadline, action, fetch_redirect_info)
      end)
    after
      Process.exit(watcher, :normal)
    end
  end

  def with_timeout(%Browser{} = session, timeout, action, _fetch_redirect_info)
      when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Browser{} = session, timeout, action, _fetch_redirect_info) when is_function(action) do
    deadline = timeout_deadline(timeout)

    with_assertion_deadline(deadline, fn ->
      handle_browser_messages_until(session, deadline, action)
    end)
  end

  def with_timeout(session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  defp handle_watched_messages_until(session, deadline, action, fetch_redirect_info) do
    remaining = remaining_timeout(deadline)

    if remaining <= 0 do
      handle_watched_messages_timeout_exhausted(session, action, fetch_redirect_info)
    else
      with_retry(session, action, fn retried_session ->
        wait_for_next_liveview_event(retried_session, deadline, action, fetch_redirect_info)
      end)
    end
  end

  defp handle_watched_messages_timeout_exhausted(session, action, fetch_redirect_info) do
    action.(session)
  catch
    :exit, _error ->
      check_for_redirect(session, action, fetch_redirect_info)
  end

  defp wait_for_next_liveview_event(session, deadline, action, fetch_redirect_info) do
    remaining = remaining_timeout(deadline)
    wait_time = max(min(remaining, interval_wait_time()), 0)
    view_pid = session.view.pid

    receive do
      {:watcher, ^view_pid, {:live_view_redirected, redirect_tuple}} ->
        session
        |> apply_redirect(redirect_tuple)
        |> handle_watched_messages_until(deadline, action, fetch_redirect_info)

      {:watcher, ^view_pid, :live_view_diff} ->
        handle_watched_messages_until(session, deadline, action, fetch_redirect_info)

      {:watcher, ^view_pid, :live_view_died} ->
        check_for_redirect(session, action, fetch_redirect_info)
    after
      wait_time ->
        handle_watched_messages_until(session, deadline, action, fetch_redirect_info)
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

  defp timeout_deadline(timeout_ms) do
    System.monotonic_time(:millisecond) + timeout_ms
  end

  defp remaining_timeout(deadline) do
    deadline - System.monotonic_time(:millisecond)
  end

  defp apply_redirect(session, {kind, %{to: path}}) when kind in [:redirect, :live_redirect] and is_binary(path) do
    Live.follow_redirect(session, path)
  end

  defp apply_redirect(session, _redirect_tuple), do: session

  defp check_for_redirect(session, action, fetch_redirect_info) when is_function(action) do
    redirect_info = fetch_redirect_info.(session)
    session |> Live.follow_redirect(normalize_redirect_info(redirect_info)) |> then(action)
  end

  defp handle_browser_messages_until(session, deadline, action) do
    remaining = remaining_timeout(deadline)

    if remaining <= 0 do
      action.(session)
    else
      with_browser_retry(session, action, fn retried_session ->
        wait_for_next_browser_event(retried_session, deadline, action)
      end)
    end
  end

  defp wait_for_next_browser_event(session, deadline, action) do
    remaining = remaining_timeout(deadline)
    wait_time = max(min(remaining, interval_wait_time()), 0)
    updated_session = Browser.wait_for_assertion_signal(session, wait_time)
    handle_browser_messages_until(updated_session, deadline, action)
  end

  defp with_browser_retry(session, action, retry_fun) when is_function(action) and is_function(retry_fun) do
    action.(session)
  rescue
    AssertionError ->
      retry_fun.(session)
  catch
    :exit, _error ->
      retry_fun.(session)
  end

  defp normalize_redirect_info({path, flash}) when is_binary(path), do: %{kind: :redirect, to: path, flash: flash}

  defp normalize_redirect_info(path) when is_binary(path), do: path
  defp normalize_redirect_info(%{to: path} = info) when is_binary(path), do: info
  defp normalize_redirect_info(_other), do: "/"

  defp via_assert_redirect(session) do
    case Phoenix.LiveViewTest.assert_redirect(session.view) do
      {path, flash} -> %{kind: :redirect, to: path, flash: flash}
      path -> path
    end
  end

  defp with_assertion_deadline(deadline_ms, fun) when is_integer(deadline_ms) and is_function(fun, 0) do
    previous = Html.current_assertion_deadline_ms()
    Html.put_assertion_deadline_ms(deadline_ms)

    try do
      fun.()
    after
      Html.put_assertion_deadline_ms(previous)
    end
  end
end
