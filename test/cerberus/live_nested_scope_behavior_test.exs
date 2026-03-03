defmodule Cerberus.LiveNestedScopeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "within preserves nested scope stack and isolates nested child actions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/nested")
      |> within(css("#child-live-view"), fn scoped ->
        scoped
        |> within(css(".actions"), fn nested ->
          click(nested, button("Save"))
        end)
        |> assert_has(text("Child saved: 1", exact: true))
        |> refute_has(text("Parent saved: 1", exact: true))
      end)
      |> assert_has(text("Child saved: 1", exact: true))
      |> refute_has(text("Parent saved: 1", exact: true))
    end

    test "scoped not-found failures include scope details (#{driver})", context do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> driver_session(context)
          |> visit("/live/nested")
          |> within(css("#child-live-view"), fn scoped ->
            within(scoped, css(".child-actions"), fn nested ->
              click(nested, button("Missing Action"))
            end)
          end)
        end

      assert error.message =~ "scope:"
      assert error.message =~ "child-actions"
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
