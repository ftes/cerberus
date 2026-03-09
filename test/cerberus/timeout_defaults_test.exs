defmodule Cerberus.TimeoutDefaultsTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.Runtime
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
    previous_timeout = Application.get_env(:cerberus, :timeout_ms)
    previous_static_config = Application.get_env(:cerberus, :static, [])
    previous_live_config = Application.get_env(:cerberus, :live, [])
    previous_browser_config = Application.get_env(:cerberus, :browser, [])

    on_exit(fn ->
      Application.put_env(:cerberus, :timeout_ms, previous_timeout)
      Application.put_env(:cerberus, :static, previous_static_config)
      Application.put_env(:cerberus, :live, previous_live_config)
      Application.put_env(:cerberus, :browser, previous_browser_config)
    end)

    :ok
  end

  test "app-level assertion timeout default is used when call/session overrides are absent" do
    Application.put_env(:cerberus, :timeout_ms, 300)

    session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"))
  end

  test "session-level timeout_ms overrides app-level default" do
    Application.put_env(:cerberus, :timeout_ms, 0)

    [timeout_ms: 300]
    |> session()
    |> visit("/live/async_page")
    |> assert_has(text("Title loaded async"))
  end

  test "call timeout overrides session and app defaults" do
    Application.put_env(:cerberus, :timeout_ms, 300)

    assert_raise AssertionError, ~r/timeout: 0/, fn ->
      [timeout_ms: 300]
      |> session()
      |> visit("/live/async_page")
      |> assert_has(text("Title loaded async"), timeout: 0)
    end
  end

  test "session constructor rejects invalid timeout_ms override" do
    assert_raise ArgumentError, ~r/session\/1 invalid options:.*timeout_ms/, fn ->
      session(timeout_ms: -1)
    end
  end

  test "per-driver config overrides global timeout config" do
    Application.put_env(:cerberus, :timeout_ms, 300)
    Application.put_env(:cerberus, :static, timeout_ms: 120)
    Application.put_env(:cerberus, :live, timeout_ms: 700)
    Application.put_env(:cerberus, :browser, timeout_ms: 900)

    assert session().timeout_ms == 120
    assert :phoenix |> session() |> visit("/live/async_page") |> Map.fetch!(:timeout_ms) == 700
    assert session(:browser).timeout_ms == 900
  end

  test "driver transitions re-resolve default timeout unless session override was explicit" do
    Application.put_env(:cerberus, :timeout_ms, 300)
    Application.put_env(:cerberus, :static, timeout_ms: 120)
    Application.put_env(:cerberus, :live, timeout_ms: 700)

    assert session() |> visit("/live/async_page") |> Map.fetch!(:timeout_ms) == 700
    assert [timeout_ms: 450] |> session() |> visit("/live/async_page") |> Map.fetch!(:timeout_ms) == 450
  end

  test "session timeout default is used for live action waits when call timeout is absent" do
    :phoenix
    |> session(timeout_ms: 600)
    |> visit("/live/actionability/delayed")
    |> select(~l"Category"l, option: ~l"Advanced"e)
    |> select(~l"Role"l, option: ~l"Analyst"e)
    |> assert_has(text("role: analyst", exact: true))
  end

  test "browser session constructor rejects invalid ready timeout options before driver startup" do
    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*ready_timeout_ms/, fn ->
      session(:browser, ready_timeout_ms: 0)
    end

    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*ready_quiet_ms/, fn ->
      session(:browser, ready_quiet_ms: -1)
    end
  end

  test "browser session constructor rejects invalid nested browser option shapes before driver startup" do
    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*popup_mode/, fn ->
      session(:browser, browser: [popup_mode: :new_tab])
    end

    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*chrome_args/, fn ->
      session(:browser, chrome_args: [123])
    end

    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*user_agent/, fn ->
      session(:browser, user_agent: "   ")
    end

    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*conn/, fn ->
      session(:browser, conn: Phoenix.ConnTest.build_conn())
    end

    assert_raise ArgumentError, ~r/session\(:browser, opts\) invalid options:.*sandbox_metadata/, fn ->
      session(:browser, sandbox_metadata: "BeamMetadata (...)")
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

  test "runtime http timeout falls back to global browser config and supports overrides" do
    Application.put_env(:cerberus, :browser, runtime_http_timeout_ms: 9_000)

    assert Runtime.runtime_http_timeout_ms([]) == 9_000
    assert Runtime.runtime_http_timeout_ms(browser: [runtime_http_timeout_ms: 4_400]) == 4_400

    assert Runtime.runtime_http_timeout_ms(runtime_http_timeout_ms: 3_300, browser: [runtime_http_timeout_ms: 4_400]) ==
             3_300
  end

  test "screenshot full-page default falls back to global browser config and allows override" do
    Application.put_env(:cerberus, :browser, screenshot_full_page: true)

    assert Browser.screenshot_full_page([]) == true
    assert Browser.screenshot_full_page(browser: [screenshot_full_page: false]) == false
    assert Browser.screenshot_full_page(full_page: false, browser: [screenshot_full_page: true]) == false
  end

  @tag :tmp_dir
  test "screenshot path uses configured policy and allows per-call override", %{tmp_dir: tmp_dir} do
    artifact_dir = Path.join(tmp_dir, "cerberus-screenshot-defaults")

    Application.put_env(:cerberus, :browser,
      screenshot_artifact_dir: artifact_dir,
      screenshot_path: Path.join(artifact_dir, "global.png")
    )

    assert Browser.screenshot_path([]) == Path.join(artifact_dir, "global.png")
    assert Browser.screenshot_path(path: "tmp/override.png") == "tmp/override.png"

    Application.put_env(:cerberus, :browser, screenshot_artifact_dir: artifact_dir)

    generated = Browser.screenshot_path([])
    assert String.starts_with?(generated, artifact_dir <> "/")
    assert String.ends_with?(generated, ".png")
  end
end
