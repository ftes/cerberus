defmodule Cerberus.ExplicitBrowserTest do
  use ExUnit.Case, async: true

  import Cerberus

  @moduletag :slow

  test "browser session runs as expected on chrome" do
    session =
      :browser
      |> session()
      |> visit("/articles")
      |> assert_has(text("Articles", exact: true))

    assert session.browser_name == :chrome
  end

  test "browser session maps to the chrome runtime" do
    :browser
    |> session()
    |> Cerberus.Browser.evaluate_js("navigator.userAgent", fn user_agent ->
      assert user_agent =~ "Chrome"
    end)
  end

  test "slow_mo delays browser command dispatch" do
    session =
      :browser
      |> session(slow_mo: 120)
      |> visit("/articles")

    started_at = System.monotonic_time(:millisecond)
    assert session == Cerberus.Browser.evaluate_js(session, "1 + 1", &assert(&1 == 2))
    elapsed_ms = System.monotonic_time(:millisecond) - started_at

    assert elapsed_ms >= 100
  end
end
