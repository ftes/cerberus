defmodule Cerberus.Driver.Browser.TransientErrorsTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.TransientErrors

  test "retryable?/2 matches transient runtime failures regardless of source map shape" do
    assert TransientErrors.retryable?("bidi command failed", %{"message" => "Execution context was destroyed"})
    assert TransientErrors.retryable?(:error, %{message: "Cannot find context with specified id"})

    assert TransientErrors.retryable?("evaluate task crashed", %{
             reason:
               "exited in: GenServer.call(#PID<0.1.0>, {:send_command, \"script.evaluate\", %{}}, 9000)\n    ** (EXIT) time out"
           })

    refute TransientErrors.retryable?("browser evaluate_js failed", %{
             "message" => "ReferenceError: missingValue is not defined"
           })

    refute TransientErrors.retryable?("browser readiness timeout", %{"reason" => "timeout"})
  end

  test "transport_closed?/2 matches serialized Mint transport close payloads" do
    assert TransientErrors.transport_closed?("%Mint.TransportError{reason: :closed}", %{
             "__exception__" => true,
             "reason" => :closed
           })

    refute TransientErrors.transport_closed?("webdriver session request failed", %{
             "message" => "session not created"
           })
  end

  test "recover_tab_id/3 returns recovered tab id when available and falls back otherwise" do
    current_tab_id = "original-tab"
    user_context_pid = self()

    assert TransientErrors.recover_tab_id(user_context_pid, current_tab_id, fn ^user_context_pid, ^current_tab_id ->
             {:ok, "recovered-tab"}
           end) == "recovered-tab"

    assert TransientErrors.recover_tab_id(user_context_pid, current_tab_id, fn ^user_context_pid, ^current_tab_id ->
             {:error, "missing context", %{}}
           end) == current_tab_id
  end
end
