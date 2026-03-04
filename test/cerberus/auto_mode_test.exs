defmodule Cerberus.AutoModeTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static

  test "auto mode starts static and switches to live when navigating to live routes" do
    session()
    |> visit("/articles")
    |> assert_has(text: "Articles", exact: true)
    |> visit("/live/counter")
    |> click(text: "Increment")
    |> assert_has(text: "Count: 1", exact: true)
  end

  test "auto mode starts live and switches to static on non-live navigation" do
    session()
    |> visit("/live/counter")
    |> click(text: "Articles")
    |> assert_has(text: "Articles", exact: true)
  end

  test "auto mode tracks redirect and live_redirect transitions with path and active driver" do
    session = visit(session(), "/live/redirects")
    assert match?(%Live{}, session)

    session = click(session, button("Redirect to Articles", exact: true))
    assert session.current_path == "/articles"
    assert match?(%Static{}, session)
    assert session.last_result.transition.reason == :live_redirect
    assert session.last_result.transition.from_driver == :live
    assert session.last_result.transition.to_driver == :static

    session = visit(session, "/live/redirects")
    assert match?(%Live{}, session)

    session = click(session, button("Hard Redirect to Articles", exact: true))
    assert session.current_path == "/articles"
    assert match?(%Static{}, session)
    assert session.last_result.transition.reason == :redirect
    assert session.last_result.transition.from_driver == :live
    assert session.last_result.transition.to_driver == :static
  end

  test "browser mode stays browser across live and static navigation transitions" do
    session = visit(session(:browser), "/articles")
    assert match?(%Browser{}, session)

    session = click(session, text: "Counter")
    assert match?(%Browser{}, session)
    assert session.current_path == "/live/counter"

    session = click(session, text: "Articles")
    assert match?(%Browser{}, session)
    assert session.current_path == "/articles"
  end

  test "failure output includes transition diagnostics in a consistent shape" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        session()
        |> visit("/articles")
        |> click(text: "Counter")
        |> assert_has(text: "no such text", exact: true)
      end

    assert error.message =~ "transition:"
    assert error.message =~ "from_driver: :static"
    assert error.message =~ "to_driver: :live"
    assert error.message =~ "reason: :click"
  end
end
