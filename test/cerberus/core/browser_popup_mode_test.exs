defmodule Cerberus.CoreBrowserPopupModeTest do
  use ExUnit.Case, async: true

  import Cerberus

  @browser_name :cerberus
                |> Application.compile_env(:browser, [])
                |> Keyword.get(:browser_name, :chrome)

  test "popup_mode :allow keeps autonomous window.open on source tab" do
    session =
      :browser
      |> session()
      |> visit("/browser/popup/auto")

    assert_path(session, "/browser/popup/auto")
    assert_has(session, text("Popup Auto Source", exact: true))
  end

  test "popup_mode :same_tab raises explicit unsupported error on firefox" do
    assert_raise ArgumentError, ~r/popup_mode :same_tab is currently unsupported on Firefox/, fn ->
      session(:firefox, browser: [popup_mode: :same_tab])
    end
  end

  @tag skip: @browser_name == :firefox
  test "popup_mode :same_tab coerces autonomous window.open into current tab" do
    session =
      :browser
      |> session(browser: [popup_mode: :same_tab])
      |> visit("/browser/popup/auto")

    assert_path(session, "/browser/popup/destination", query: %{source: "auto-load"}, timeout: 1_500)
    assert_has(session, text("Popup Destination", exact: true))
    assert_has(session, text("popup source: auto-load", exact: true))
  end
end
