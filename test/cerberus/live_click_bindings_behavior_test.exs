defmodule Cerberus.LiveClickBindingsBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession
  alias ExUnit.AssertionError

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "click_button supports actionable JS command bindings across live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/redirects")
      |> click(button("JS Patch Details", exact: true))
      |> assert_path("/live/redirects", query: [details: "true", foo: "js_patch"])
      |> assert_has(text("Live Redirects Details", exact: true))
      |> click(button("JS Dispatch + Push", exact: true))
      |> assert_path("/live/counter", query: [foo: "bar"])
      |> visit("/live/redirects")
      |> click(button("JS Navigate to Counter", exact: true))
      |> assert_path("/live/counter", query: [foo: "bar"])
    end
  end

  test "live driver excludes dispatch-only JS command bindings from server-actionable click resolution" do
    assert_raise AssertionError, ~r/no button matched locator/, fn ->
      session()
      |> visit("/live/redirects")
      |> click(button("JS Dispatch only", exact: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
