defmodule Cerberus.HarnessTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  test "run executes one scenario per tagged driver" do
    context = %{browser: true, static: true, live: true}

    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "Articles")
      end)

    assert Enum.map(results, & &1.driver) == [:browser, :live, :static]
    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.all?(results, &(&1.operation == :assert_has))
  end

  test "drivers defaults to auto + browser when no tags are present" do
    assert Harness.drivers(%{}) == [:auto, :browser]
  end

  test "drivers derives tagged lanes in canonical order" do
    assert Harness.drivers(%{browser: true, static: true, live: true}) == [:static, :live, :browser]
    assert Harness.drivers(%{chrome: true, firefox: true}) == [:chrome, :firefox]
  end

  test "drivers supports disabling a module-level browser lane with false" do
    assert Harness.drivers(%{chrome: false, firefox: true}) == [:firefox]
  end

  test "drivers raises when explicit driver tags disable every driver lane" do
    assert_raise ArgumentError, ~r/explicit driver tags require at least one enabled tag/, fn ->
      Harness.drivers(%{chrome: false, firefox: false})
    end
  end

  test "drivers rejects legacy drivers tag" do
    assert_raise ArgumentError, ~r/no longer supports the legacy :drivers tag/, fn ->
      Harness.drivers(%{drivers: [:auto, :browser]})
    end
  end

  test "run captures failures with common result shape" do
    context = %{static: true, live: true}

    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "DOES NOT EXIST")
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &is_binary(&1.message))
    assert Enum.all?(results, &match?(%ExUnit.AssertionError{}, &1.error))
  end

  test "run! raises one aggregated error when any driver fails" do
    context = %{static: true, browser: true}

    assert_raise ExUnit.AssertionError, ~r/driver conformance failures/, fn ->
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "DOES NOT EXIST")
      end)
    end
  end

  test "run rejects drivers opt override and requires tag/context selection" do
    context = %{static: true}

    assert_raise ArgumentError, ~r/no longer supports :drivers opt/, fn ->
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/articles")
          |> assert_has(text: "Articles")
        end,
        drivers: [:browser]
      )
    end
  end

  test "sort_results sorts by operation and driver" do
    unsorted = [
      %{driver: :live, operation: :refute_has},
      %{driver: :browser, operation: :assert_has},
      %{driver: :static, operation: :assert_has}
    ]

    assert [
             %{driver: :browser, operation: :assert_has},
             %{driver: :static, operation: :assert_has},
             %{driver: :live, operation: :refute_has}
           ] = Harness.sort_results(unsorted)
  end

  test "context :session_opts are merged into driver session options" do
    assert [assert_timeout_ms: 200] ==
             Harness.session_opts_for_driver(:static, %{session_opts: [assert_timeout_ms: 200]}, [])
  end

  test "browser keyword context merges into browser session options only" do
    browser_opts =
      Harness.session_opts_for_driver(
        :browser,
        %{browser: [viewport: {1280, 720}, user_agent: "module-agent"]},
        []
      )

    assert Keyword.get(browser_opts, :browser)[:viewport] == {1280, 720}
    assert Keyword.get(browser_opts, :browser)[:user_agent] == "module-agent"

    assert [] ==
             Harness.session_opts_for_driver(
               :static,
               %{browser: [viewport: {1280, 720}, user_agent: "module-agent"]},
               []
             )
  end

  test "explicit chrome/firefox drivers set browser_name while keeping browser option merges" do
    chrome_opts =
      Harness.session_opts_for_driver(
        :chrome,
        %{browser: [viewport: {1280, 720}], browser_session_opts: [browser: [user_agent: "chrome-agent"]]},
        []
      )

    assert chrome_opts[:browser_name] == :chrome
    assert chrome_opts[:browser][:viewport] == {1280, 720}
    assert chrome_opts[:browser][:user_agent] == "chrome-agent"

    firefox_opts =
      Harness.session_opts_for_driver(
        :firefox,
        %{browser: [viewport: {1024, 768}], browser_session_opts: [browser: [user_agent: "firefox-agent"]]},
        []
      )

    assert firefox_opts[:browser_name] == :firefox
    assert firefox_opts[:browser][:viewport] == {1024, 768}
    assert firefox_opts[:browser][:user_agent] == "firefox-agent"
  end

  test "browser_session_opts overrides base and browser tag values" do
    merged =
      Harness.session_opts_for_driver(
        :browser,
        %{
          browser: [viewport: {1280, 720}, user_agent: "tag-agent"],
          browser_session_opts: [ready_timeout_ms: 2_400, browser: [user_agent: "test-agent"]]
        },
        ready_timeout_ms: 1_500,
        browser: [viewport: {800, 600}, init_script: "window.base = true;"]
      )

    assert Keyword.get(merged, :ready_timeout_ms) == 2_400

    browser_opts = Keyword.get(merged, :browser)
    assert browser_opts[:viewport] == {1280, 720}
    assert browser_opts[:user_agent] == "test-agent"
    assert browser_opts[:init_script] == "window.base = true;"
  end

  test "invalid browser context values raise clear errors" do
    assert_raise ArgumentError, ~r/context :browser must be true\/false or a keyword list/, fn ->
      Harness.session_opts_for_driver(:browser, %{browser: "yes"}, [])
    end

    assert_raise ArgumentError, ~r/context :browser_session_opts must be a keyword list/, fn ->
      Harness.session_opts_for_driver(:browser, %{browser_session_opts: "bad"}, [])
    end
  end
end
