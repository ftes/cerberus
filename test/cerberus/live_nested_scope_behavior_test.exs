defmodule Cerberus.LiveNestedScopeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "within preserves nested scope stack and isolates nested child actions (#{driver})" do
      unquote(driver)
      |> session()
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

    test "scoped not-found failures include scope details (#{driver})" do
      error =
        assert_raise ExUnit.AssertionError, fn ->
          unquote(driver)
          |> session()
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
end
