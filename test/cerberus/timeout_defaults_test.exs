defmodule Cerberus.TimeoutDefaultsTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Driver.Browser
  alias ExUnit.AssertionError

  setup do
    previous_assert_timeout = Application.get_env(:cerberus, :assert_timeout_ms)
    previous_browser_config = Application.get_env(:cerberus, :browser, [])

    on_exit(fn ->
      Application.put_env(:cerberus, :assert_timeout_ms, previous_assert_timeout)
      Application.put_env(:cerberus, :browser, previous_browser_config)
    end)

    :ok
  end

  test "app-level assertion timeout default is used when call/session overrides are absent" do
    Application.put_env(:cerberus, :assert_timeout_ms, 300)

    session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"))
  end

  test "session-level assert_timeout_ms overrides app-level default" do
    Application.put_env(:cerberus, :assert_timeout_ms, 0)

    [assert_timeout_ms: 300]
    |> session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"))
  end

  test "call timeout overrides session and app defaults" do
    Application.put_env(:cerberus, :assert_timeout_ms, 300)

    assert_raise AssertionError, ~r/timeout: 0/, fn ->
      [assert_timeout_ms: 300]
      |> session()
      |> visit("/live/async_page")
      |> assert_has(text("Title loaded async"), timeout: 0)
    end
  end

  test "session constructor rejects invalid assert_timeout_ms override" do
    assert_raise ArgumentError, ~r/:assert_timeout_ms must be a non-negative integer/, fn ->
      session(assert_timeout_ms: -1)
    end
  end

  test "browser ready timeout falls back to global browser config and allows session override" do
    Application.put_env(:cerberus, :browser, ready_timeout_ms: 2_200)

    assert Browser.ready_timeout_ms([]) == 2_200
    assert Browser.ready_timeout_ms(browser: [ready_timeout_ms: 2_400]) == 2_400
    assert Browser.ready_timeout_ms(ready_timeout_ms: 1_800, browser: [ready_timeout_ms: 2_400]) == 1_800
  end
end
