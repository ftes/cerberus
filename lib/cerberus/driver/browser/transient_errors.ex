defmodule Cerberus.Driver.Browser.TransientErrors do
  @moduledoc false

  alias Cerberus.Driver.Browser.UserContextProcess

  @retryable_markers [
    "JSWindowActorChild cannot send",
    "argument is not a global object",
    "Inspected target navigated or closed",
    "Cannot find context with specified id",
    "Execution context was destroyed",
    "execution contexts cleared",
    "DiscardedBrowsingContextError",
    "no such frame",
    "navigation canceled by concurrent navigation"
  ]

  @type recover_active_tab_result ::
          {:ok, String.t()} | {:error, String.t(), map()} | term()

  @spec retryable?(term(), term()) :: boolean()
  def retryable?(reason, details) do
    payload = "#{stringify(reason)} #{stringify(details)}"

    Enum.any?(@retryable_markers, &String.contains?(payload, &1)) or
      stale_script_evaluate_timeout?(payload)
  end

  @spec recover_tab_id(pid(), String.t() | nil) :: String.t() | nil
  def recover_tab_id(user_context_pid, current_tab_id) when is_pid(user_context_pid) do
    recover_tab_id(user_context_pid, current_tab_id, &UserContextProcess.recover_active_tab/2)
  end

  @spec recover_tab_id(pid(), String.t() | nil, (pid(), String.t() | nil -> recover_active_tab_result())) ::
          String.t() | nil
  def recover_tab_id(user_context_pid, current_tab_id, recover_fun)
      when is_pid(user_context_pid) and is_function(recover_fun, 2) do
    case recover_fun.(user_context_pid, current_tab_id) do
      {:ok, recovered_tab_id} when is_binary(recovered_tab_id) and recovered_tab_id != "" -> recovered_tab_id
      _ -> current_tab_id
    end
  end

  defp stringify(value) when is_binary(value), do: value
  defp stringify(value), do: inspect(value)

  defp stale_script_evaluate_timeout?(payload) when is_binary(payload) do
    String.contains?(payload, "evaluate task crashed") and
      String.contains?(payload, "script.evaluate") and
      String.contains?(payload, "** (EXIT) time out")
  end
end
