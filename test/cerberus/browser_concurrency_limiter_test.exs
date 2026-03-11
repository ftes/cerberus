defmodule Cerberus.BrowserConcurrencyLimiterTest do
  use ExUnit.Case, async: false

  alias Cerberus.Browser.TestConcurrencyLimiter

  test "blocks until another holder checks the slot back in" do
    {:ok, token_id} = TestConcurrencyLimiter.checkout(:browser_test_limiter_blocking, 1, 1_000)

    waiter =
      Task.async(fn ->
        TestConcurrencyLimiter.checkout(:browser_test_limiter_blocking, 1, 1_000)
      end)

    refute Task.yield(waiter, 100)

    :ok = TestConcurrencyLimiter.checkin(:browser_test_limiter_blocking, token_id)

    assert {:ok, replacement_token_id} = Task.await(waiter)
    assert is_reference(replacement_token_id)
    refute replacement_token_id == token_id

    :ok = TestConcurrencyLimiter.checkin(:browser_test_limiter_blocking, replacement_token_id)
  end

  test "releases the slot when the holder exits" do
    holder =
      Task.async(fn ->
        TestConcurrencyLimiter.checkout(:browser_test_limiter_owner_exit, 1, 1_000)
      end)

    assert {:ok, token_id} = Task.await(holder)

    waiter =
      Task.async(fn ->
        TestConcurrencyLimiter.checkout(:browser_test_limiter_owner_exit, 1, 1_000)
      end)

    Task.shutdown(holder, :brutal_kill)

    assert {:ok, replacement_token_id} = Task.await(waiter)
    assert is_reference(replacement_token_id)
    refute replacement_token_id == token_id

    :ok = TestConcurrencyLimiter.checkin(:browser_test_limiter_owner_exit, replacement_token_id)
  end

  test "returns an error when the limiter size changes for the same name" do
    assert {:ok, token_id} = TestConcurrencyLimiter.checkout(:browser_test_limiter_size_mismatch, 1, 1_000)

    assert {:error, {:size_mismatch, 1}} =
             TestConcurrencyLimiter.checkout(:browser_test_limiter_size_mismatch, 2, 1_000)

    :ok = TestConcurrencyLimiter.checkin(:browser_test_limiter_size_mismatch, token_id)
  end
end
