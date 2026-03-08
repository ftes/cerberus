defmodule Cerberus.AutoModeTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static

  test "auto mode starts static and switches to live when navigating to live routes" do
    session()
    |> visit("/articles")
    |> assert_has(~l"Articles"e)
    |> visit("/live/counter")
    |> click(~l"Increment"e)
    |> assert_has(~l"Count: 1"e)
  end

  test "auto mode starts live and switches to static on non-live navigation" do
    session()
    |> visit("/live/counter")
    |> click(~l"Articles"e)
    |> assert_has(~l"Articles"e)
  end

  test "auto mode tracks redirect and live_redirect transitions with path and active driver" do
    session = visit(session(), "/live/redirects")
    assert match?(%Live{}, session)

    session = click(session, role(:button, name: "Redirect to Articles", exact: true))
    assert_path(session, "/articles")
    assert match?(%Static{}, session)
    assert session.last_result.transition.reason == :live_redirect
    assert session.last_result.transition.from_driver == :live
    assert session.last_result.transition.to_driver == :static

    session = visit(session, "/live/redirects")
    assert match?(%Live{}, session)

    session = click(session, role(:button, name: "Hard Redirect to Articles", exact: true))
    assert_path(session, "/articles")
    assert match?(%Static{}, session)
    assert session.last_result.transition.reason == :redirect
    assert session.last_result.transition.from_driver == :live
    assert session.last_result.transition.to_driver == :static
  end

  test "browser mode stays browser across live and static navigation transitions" do
    session = visit(session(:browser), "/articles")
    assert match?(%Browser{}, session)

    session = click(session, ~l"Counter"e)
    assert match?(%Browser{}, session)
    assert_path(session, "/live/counter")

    session = click(session, ~l"Articles"e)
    assert match?(%Browser{}, session)
    assert_path(session, "/articles")
  end

  test "failure output includes transition diagnostics in a consistent shape" do
    error =
      assert_raise ExUnit.AssertionError, fn ->
        session()
        |> visit("/articles")
        |> click(~l"Counter"e)
        |> assert_has(~l"no such text"e)
      end

    assert error.message =~ "transition:"
    assert error.message =~ "from_driver: :static"
    assert error.message =~ "to_driver: :live"
    assert error.message =~ "reason: :click"
  end
end
