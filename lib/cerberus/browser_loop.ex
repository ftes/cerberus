defmodule Cerberus.BrowserLoop do
  @moduledoc false

  alias Cerberus.Driver.Browser
  alias ExUnit.AssertionError

  @spec interval_wait_time() :: pos_integer()
  def interval_wait_time, do: 100

  @spec run(Browser.t(), integer(), (Browser.t() -> result)) :: result when result: var
  def run(%Browser{} = session, timeout, action) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def run(%Browser{} = session, timeout, action) when is_function(action) do
    deadline = System.monotonic_time(:millisecond) + timeout
    handle_messages_until(session, deadline, action)
  end

  defp handle_messages_until(session, deadline, action) do
    remaining = remaining_timeout(deadline)

    if remaining <= 0 do
      action.(session)
    else
      with_retry(session, action, fn retried_session ->
        wait_for_next_browser_event(retried_session, deadline, action)
      end)
    end
  end

  defp wait_for_next_browser_event(session, deadline, action) do
    remaining = remaining_timeout(deadline)
    wait_time = max(min(remaining, interval_wait_time()), 0)
    updated_session = Browser.wait_for_assertion_signal(session, wait_time)
    handle_messages_until(updated_session, deadline, action)
  end

  defp with_retry(session, action, retry_fun) when is_function(action) and is_function(retry_fun) do
    action.(session)
  rescue
    AssertionError ->
      retry_fun.(session)
  catch
    :exit, _error ->
      retry_fun.(session)
  end

  defp remaining_timeout(deadline) do
    deadline - System.monotonic_time(:millisecond)
  end
end
