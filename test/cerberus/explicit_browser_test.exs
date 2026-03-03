defmodule Cerberus.ExplicitBrowserTest do
  use ExUnit.Case, async: false

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
end
