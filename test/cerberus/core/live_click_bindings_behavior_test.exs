defmodule Cerberus.CoreLiveClickBindingsBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness
  alias ExUnit.AssertionError

  @moduletag :live
  @moduletag :browser

  test "click_button supports actionable JS command bindings across live and browser drivers", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/redirects")
      |> click_button(button("JS Patch Details", exact: true))
      |> assert_path("/live/redirects", query: [details: "true", foo: "js_patch"])
      |> assert_has(text("Live Redirects Details", exact: true))
      |> click_button(button("JS Dispatch + Push", exact: true))
      |> assert_path("/live/counter", query: [foo: "bar"])
      |> visit("/live/redirects")
      |> click_button(button("JS Navigate to Counter", exact: true))
      |> assert_path("/live/counter", query: [foo: "bar"])
    end)
  end

  test "live driver excludes dispatch-only JS command bindings from server-actionable click resolution" do
    assert_raise AssertionError, ~r/no button matched locator/, fn ->
      session()
      |> visit("/live/redirects")
      |> click_button(button("JS Dispatch only", exact: true))
    end
  end
end
