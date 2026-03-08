defmodule Cerberus.Driver.Browser.Evaluate do
  @moduledoc false

  alias Cerberus.Driver.Browser.CdpPageProcess
  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.UserContextProcess

  @default_dialog_timeout_ms 1_500
  @poll_ms 25

  @spec with_dialog_unblock(pid(), String.t(), String.t(), pos_integer()) :: Types.bidi_response()
  def with_dialog_unblock(user_context_pid, tab_id, expression, timeout_ms)
      when is_pid(user_context_pid) and is_binary(tab_id) and is_binary(expression) and is_integer(timeout_ms) and
             timeout_ms > 0 do
    cdp_page_pid = UserContextProcess.cdp_page_pid(user_context_pid, tab_id)

    task =
      Task.async(fn ->
        evaluate_script(user_context_pid, tab_id, expression, timeout_ms)
      end)

    Process.unlink(task.pid)
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    try do
      await_result(task, cdp_page_pid, deadline, timeout_ms)
    after
      _ = Task.shutdown(task, :brutal_kill)
    end
  end

  defp await_result(task, cdp_page_pid, deadline, timeout_ms) do
    case Task.yield(task, poll_wait_ms(deadline)) do
      {:ok, result} ->
        result

      {:exit, reason} ->
        evaluate_task_crash(reason)

      nil ->
        await_pending_result(task, cdp_page_pid, deadline, timeout_ms)
    end
  end

  defp await_pending_result(task, cdp_page_pid, deadline, timeout_ms) do
    wait_ms = poll_wait_ms(deadline)

    if wait_ms == 0 do
      shutdown_or_timeout(task, timeout_ms)
    else
      continue_after_dialog_wait(task, cdp_page_pid, deadline, timeout_ms)
    end
  end

  defp continue_after_dialog_wait(task, cdp_page_pid, deadline, timeout_ms) do
    case maybe_unblock_dialog(cdp_page_pid) do
      :ok ->
        await_result(task, cdp_page_pid, deadline, timeout_ms)

      {:error, reason, details} ->
        {:error, reason, details}
    end
  end

  defp shutdown_or_timeout(task, timeout_ms) do
    case Task.shutdown(task, :brutal_kill) do
      {:ok, result} ->
        result

      {:exit, reason} ->
        evaluate_task_crash(reason)

      nil ->
        {:error, "cdp command timeout", %{"timeoutMs" => timeout_ms}}
    end
  end

  defp evaluate_task_crash(reason), do: {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}}

  defp maybe_unblock_dialog(cdp_page_pid) when is_pid(cdp_page_pid) do
    case CdpPageProcess.command(
           cdp_page_pid,
           "Page.handleJavaScriptDialog",
           %{"accept" => true, "promptText" => ""},
           @default_dialog_timeout_ms
         ) do
      {:ok, _payload} ->
        :ok

      {:error, _reason, %{"error" => "no such alert"}} ->
        :ok

      {:error, reason, details} ->
        {:error, "failed to handle dialog: #{reason}", details}
    end
  end

  defp maybe_unblock_dialog(_cdp_page_pid), do: :ok

  defp poll_wait_ms(deadline) do
    now = System.monotonic_time(:millisecond)
    remaining = max(deadline - now, 0)
    min(remaining, @poll_ms)
  end

  defp evaluate_script(user_context_pid, tab_id, expression, timeout_ms) do
    UserContextProcess.evaluate_with_timeout(user_context_pid, expression, timeout_ms, tab_id)
  end
end
