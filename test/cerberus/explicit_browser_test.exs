defmodule Cerberus.ExplicitBrowserTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:chrome] do
    test "explicit chrome driver runs as expected (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))

      assert session.browser_name == unquote(driver)
    end
  end

  for driver <- [:chrome] do
    test "explicit driver maps to matching runtime browser (#{driver})" do
      unquote(driver)
      |> session()
      |> Cerberus.Browser.evaluate_js("navigator.userAgent", fn user_agent ->
        assert user_agent =~ "Chrome"
      end)
    end
  end

  for driver <- [:chrome] do
    test "slow_mo delays browser command dispatch (#{driver})" do
      session =
        unquote(driver)
        |> session(slow_mo: 120)
        |> visit("/articles")

      started_at = System.monotonic_time(:millisecond)
      assert session == Cerberus.Browser.evaluate_js(session, "1 + 1", &assert(&1 == 2))
      elapsed_ms = System.monotonic_time(:millisecond) - started_at

      assert elapsed_ms >= 100
    end
  end
end
