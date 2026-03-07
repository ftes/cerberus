defmodule Cerberus.PhoenixLoop do
  @moduledoc false

  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.Html
  alias Cerberus.Phoenix.LiveViewClient
  alias ExUnit.AssertionError
  alias Phoenix.LiveView.Channel, as: LiveViewChannel

  @type redirect_info :: {String.t(), map()} | String.t()

  @spec interval_wait_time() :: pos_integer()
  def interval_wait_time, do: 100

  @spec run(session, integer(), (session -> result), (session -> redirect_info())) :: result
        when session: Static.t() | Live.t(), result: var
  def run(session, timeout, action, fetch_redirect_info \\ &via_assert_redirect/1)

  def run(%Static{} = session, timeout, action, _fetch_redirect_info) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def run(%Static{} = session, timeout, action, _fetch_redirect_info) when is_function(action) do
    deadline = timeout_deadline(timeout)
    with_assertion_deadline(deadline, fn -> action.(session) end)
  end

  def run(%Live{view: nil} = session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  def run(%Live{} = session, timeout, action, _fetch_redirect_info) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def run(%Live{} = session, timeout, action, fetch_redirect_info) when is_function(action) do
    deadline = timeout_deadline(timeout)

    with_assertion_deadline(deadline, fn ->
      handle_watched_messages_until(session, deadline, action, fetch_redirect_info)
    end)
  end

  defp handle_watched_messages_until(%Live{view: %{pid: _}} = session, deadline, action, fetch_redirect_info) do
    remaining = remaining_timeout(deadline)

    if remaining <= 0 do
      handle_timeout_exhausted(session, action, fetch_redirect_info)
    else
      baseline_version = live_render_version(session)

      with_retry(session, action, fn retried_session ->
        wait_for_next_liveview_event(
          retried_session,
          baseline_version,
          deadline,
          action,
          fetch_redirect_info
        )
      end)
    end
  end

  defp handle_watched_messages_until(session, deadline, action, fetch_redirect_info) do
    case remaining_timeout(deadline) do
      remaining when remaining <= 0 ->
        action.(session)

      _remaining ->
        with_retry(session, action, fn retried_session ->
          sleep_until_retry_window(deadline)
          handle_watched_messages_until(retried_session, deadline, action, fetch_redirect_info)
        end)
    end
  end

  defp sleep_until_retry_window(deadline) do
    wait_time = max(min(remaining_timeout(deadline), interval_wait_time()), 0)

    if wait_time > 0 do
      Process.sleep(wait_time)
    end
  end

  defp handle_timeout_exhausted(session, action, fetch_redirect_info) do
    action.(session)
  catch
    :exit, _error ->
      check_for_redirect(session, action, fetch_redirect_info)
  end

  defp wait_for_next_liveview_event(session, baseline_version, deadline, action, fetch_redirect_info) do
    remaining = max(remaining_timeout(deadline), 0)

    case LiveViewClient.await_progress(session.view, baseline_version, remaining) do
      {:ok, {:redirect, %{to: path}}} ->
        session
        |> Live.follow_redirect(path)
        |> handle_watched_messages_until(deadline, action, fetch_redirect_info)

      {:ok, {:live_redirect, %{to: path}}} ->
        session
        |> Live.follow_redirect(path)
        |> handle_watched_messages_until(deadline, action, fetch_redirect_info)

      {:ok, {:patch, %{to: path}}} ->
        session
        |> refresh_live_session(path)
        |> handle_watched_messages_until(deadline, action, fetch_redirect_info)

      {:ok, :diff} ->
        session
        |> refresh_live_session(nil)
        |> handle_watched_messages_until(deadline, action, fetch_redirect_info)

      {:ok, :terminated} ->
        check_for_redirect(session, action, fetch_redirect_info)

      :timeout ->
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

  defp check_for_redirect(session, action, fetch_redirect_info) when is_function(action) do
    redirect_info = fetch_redirect_info.(session)
    session |> Live.follow_redirect(normalize_redirect_info(redirect_info)) |> then(action)
  end

  defp refresh_live_session(%Live{} = session, path_override) do
    case LiveViewClient.render(session.view) do
      rendered when is_binary(rendered) ->
        path = path_override || LiveViewClient.current_path(session.view, session.current_path)
        %{session | document: Html.parse!(rendered), current_path: path || session.current_path}

      {:error, {kind, %{to: path}}} when kind in [:redirect, :live_redirect] ->
        Live.follow_redirect(session, path)
    end
  end

  defp live_render_version(%Live{view: view}), do: LiveViewClient.render_version(view)

  defp normalize_redirect_info({path, flash}) when is_binary(path), do: %{kind: :redirect, to: path, flash: flash}
  defp normalize_redirect_info(path) when is_binary(path), do: path
  defp normalize_redirect_info(%{to: path} = info) when is_binary(path), do: info
  defp normalize_redirect_info(_other), do: "/"

  defp via_assert_redirect(session) do
    {path, flash} = LiveViewClient.assert_redirect(session.view)
    %{kind: :redirect, to: path, flash: flash}
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
