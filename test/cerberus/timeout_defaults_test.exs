defmodule Cerberus.TimeoutDefaultsTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Browser.BiDi
  alias ExUnit.AssertionError

  defmodule TimeoutProbe do
    @moduledoc false
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts)
    end

    @impl true
    def init(_opts), do: {:ok, %{}}

    @impl true
    def handle_call({:command, _method, _params, timeout}, _from, state) do
      {:reply, {:ok, %{"timeout" => timeout}}, state}
    end
  end

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

  test "bidi command timeout falls back to global browser config and supports browser opts override" do
    Application.put_env(:cerberus, :browser, bidi_command_timeout_ms: 2_200)
    {:ok, probe} = TimeoutProbe.start_link()

    assert {:ok, %{"timeout" => 2_200}} == BiDi.command(probe, "session.status", %{}, [])

    assert {:ok, %{"timeout" => 2_400}} ==
             BiDi.command(probe, "session.status", %{}, browser: [bidi_command_timeout_ms: 2_400])
  end

  test "bidi command timeout option overrides configured defaults" do
    Application.put_env(:cerberus, :browser, bidi_command_timeout_ms: 2_200)
    {:ok, probe} = TimeoutProbe.start_link()

    assert {:ok, %{"timeout" => 150}} ==
             BiDi.command(probe, "session.status", %{}, timeout: 150, browser: [bidi_command_timeout_ms: 2_400])
  end
end
