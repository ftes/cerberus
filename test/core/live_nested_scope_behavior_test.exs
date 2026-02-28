defmodule Cerberus.CoreLiveNestedScopeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag drivers: [:static, :live, :browser]
  test "within preserves nested scope stack and isolates nested child actions", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/nested")
        |> within("#child-live-view", fn scoped ->
          scoped
          |> within(".actions", fn nested ->
            click(nested, button("Save"))
          end)
          |> assert_has(text("Child saved: 1", exact: true))
          |> refute_has(text("Parent saved: 1", exact: true))
        end)
        |> assert_has(text("Child saved: 1", exact: true))
        |> refute_has(text("Parent saved: 1", exact: true))
      end
    )
  end

  @tag drivers: [:live, :browser]
  test "scoped not-found failures include scope details", context do
    results =
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/live/nested")
          |> within("#child-live-view", fn scoped ->
            within(scoped, ".child-actions", fn nested ->
              click(nested, button("Missing Action"))
            end)
          end)
        end
      )

    assert Enum.all?(results, fn result ->
             result.status == :error and String.contains?(result.message || "", "scope:") and
               String.contains?(result.message || "", ".child-actions")
           end)
  end
end
