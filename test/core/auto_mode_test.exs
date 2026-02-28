defmodule Cerberus.CoreAutoModeTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness
  alias Cerberus.Session

  @moduletag :conformance
  @moduletag drivers: [:auto]

  test "auto mode starts static and switches to live when navigating to live routes", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/articles")
      |> assert_has([text: "Articles"], exact: true)
      |> visit("/live/counter")
      |> click_button(text: "Increment")
      |> assert_has([text: "Count: 1"], exact: true)
    end)
  end

  test "auto mode starts live and switches to static on non-live navigation", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/counter")
      |> click_link(text: "Articles")
      |> assert_has([text: "Articles"], exact: true)
    end)
  end

  test "auto mode tracks redirect and live_redirect transitions with path and active driver", context do
    Harness.run!(context, fn session ->
      session = visit(session, "/live/redirects")
      assert Session.driver_kind(session) == :live

      session = click_button(session, "Redirect to Articles", exact: true)
      assert session.current_path == "/articles"
      assert Session.driver_kind(session) == :static
      assert session.last_result.observed.transition.reason == :live_redirect
      assert session.last_result.observed.transition.from_driver == :live
      assert session.last_result.observed.transition.to_driver == :static

      session = visit(session, "/live/redirects")
      assert Session.driver_kind(session) == :live

      session = click_button(session, "Hard Redirect to Articles", exact: true)
      assert session.current_path == "/articles"
      assert Session.driver_kind(session) == :static
      assert session.last_result.observed.transition.reason == :redirect
      assert session.last_result.observed.transition.from_driver == :live
      assert session.last_result.observed.transition.to_driver == :static

      session
    end)
  end

  @tag drivers: [:browser]
  test "browser mode stays browser across live and static navigation transitions", context do
    Harness.run!(context, fn session ->
      session = visit(session, "/articles")
      assert Session.driver_kind(session) == :browser

      session = click_link(session, text: "Counter")
      assert Session.driver_kind(session) == :browser
      assert session.current_path == "/live/counter"

      session = click_link(session, text: "Articles")
      assert Session.driver_kind(session) == :browser
      assert session.current_path == "/articles"

      session
    end)
  end

  test "failure output includes transition diagnostics in a consistent shape" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        session()
        |> visit("/articles")
        |> click_link(text: "Counter")
        |> assert_has([text: "no such text"], exact: true)
      end

    assert error.message =~ "transition:"
    assert error.message =~ "from_driver: :static"
    assert error.message =~ "to_driver: :live"
    assert error.message =~ "reason: :click"
  end
end
