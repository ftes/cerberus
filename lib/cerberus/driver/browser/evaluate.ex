defmodule Cerberus.Driver.Browser.Evaluate do
  @moduledoc false

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Types
  alias Cerberus.Driver.Browser.UserContextProcess

  @default_dialog_timeout_ms 1_500
  @poll_ms 25

  @spec with_prompt_unblock(pid(), String.t(), String.t(), pos_integer(), keyword()) :: Types.bidi_response()
  def with_prompt_unblock(user_context_pid, tab_id, expression, timeout_ms, bidi_opts)
      when is_pid(user_context_pid) and is_binary(tab_id) and is_binary(expression) and is_integer(timeout_ms) and
             timeout_ms > 0 and is_list(bidi_opts) do
    task =
      Task.async(fn ->
        evaluate_script(tab_id, expression, timeout_ms, bidi_opts)
      end)

    Process.unlink(task.pid)
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    try do
      await_result(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts)
    after
      _ = Task.shutdown(task, :brutal_kill)
    end
  end

  defp await_result(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts) do
    case Task.yield(task, 0) do
      {:ok, result} ->
        result

      {:exit, reason} ->
        evaluate_task_crash(reason)

      nil ->
        await_pending_result(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts)
    end
  end

  defp await_pending_result(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts) do
    wait_ms = poll_wait_ms(deadline)

    if wait_ms == 0 do
      shutdown_or_timeout(task, timeout_ms)
    else
      continue_after_prompt_wait(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts, wait_ms)
    end
  end

  defp continue_after_prompt_wait(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts, wait_ms) do
    case maybe_unblock_prompt(user_context_pid, tab_id, wait_ms, bidi_opts) do
      :ok ->
        await_result(task, user_context_pid, tab_id, deadline, timeout_ms, bidi_opts)

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
        {:error, "bidi command timeout", %{"timeoutMs" => timeout_ms}}
    end
  end

  defp evaluate_task_crash(reason), do: {:error, "evaluate task crashed", %{reason: Exception.format_exit(reason)}}

  defp maybe_unblock_prompt(user_context_pid, tab_id, wait_ms, bidi_opts) when wait_ms > 0 do
    case UserContextProcess.await_dialog_open(user_context_pid, wait_ms, tab_id) do
      {:ok, %{"type" => "prompt"}} ->
        dismiss_prompt(tab_id, bidi_opts)

      {:ok, _dialog} ->
        :ok

      {:error, :timeout, _events} ->
        :ok

      {:error, reason, details} ->
        {:error, "failed while waiting for dialog events: #{reason}", details}
    end
  end

  defp dismiss_prompt(tab_id, bidi_opts) do
    params = %{"context" => tab_id, "accept" => false}
    opts = Keyword.put(bidi_opts, :timeout, @default_dialog_timeout_ms)

    case BiDi.command("browsingContext.handleUserPrompt", params, opts) do
      {:ok, _payload} ->
        :ok

      {:error, _reason, %{"error" => "no such alert"}} ->
        :ok

      {:error, reason, details} ->
        {:error, "failed to handle prompt: #{reason}", details}
    end
  end

  defp poll_wait_ms(deadline) do
    now = System.monotonic_time(:millisecond)
    remaining = max(deadline - now, 0)
    min(remaining, @poll_ms)
  end

  defp evaluate_script(tab_id, expression, timeout_ms, bidi_opts) do
    params = %{
      "target" => %{"context" => tab_id},
      "expression" => expression,
      "awaitPromise" => true,
      "resultOwnership" => "none"
    }

    opts = Keyword.put(bidi_opts, :timeout, timeout_ms)
    BiDi.command("script.evaluate", params, opts)
  end
end
