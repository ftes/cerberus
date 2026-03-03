defmodule Cerberus.ExplicitBrowserTest do
  use ExUnit.Case, async: false

  import Cerberus

  for driver <- [:chrome, :firefox] do
    test "explicit chrome/firefox drivers run as expected (#{driver})" do
      session =
        unquote(driver)
        |> session()
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))

      assert session.browser_name == unquote(driver)
    end
  end

  test "firefox can be targeted directly" do
    :firefox
    |> session()
    |> visit("/articles")
    |> assert_has(text("Articles", exact: true))
  end

  for driver <- [:chrome, :firefox] do
    test "explicit driver maps to matching runtime browser (#{driver})" do
      unquote(driver)
      |> session()
      |> Cerberus.Browser.evaluate_js("navigator.userAgent", fn user_agent ->
        expected = if unquote(driver) == :chrome, do: "Chrome", else: "Firefox"
        assert user_agent =~ expected
      end)
    end
  end
end
