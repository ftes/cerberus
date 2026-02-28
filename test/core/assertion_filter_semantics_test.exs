defmodule Cerberus.CoreAssertionFilterSemanticsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag drivers: [:static, :live, :browser]

  @missing_label "Unknown Label"

  test "refute_has supports label-only locators when label text is missing", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/form-change")
      |> refute_has(label(@missing_label, exact: true))
    end)
  end

  test "assert_has with label-only locator fails when label text is missing", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit("/live/form-change")
        |> assert_has(label(@missing_label, exact: true))
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &String.contains?(&1.message || "", "expected text not found"))
  end

  test "assert_has rejects unknown option keys with explicit errors", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has("Articles", with: "Articles")
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &String.contains?(&1.message || "", "assert_has/3 invalid options"))
    assert Enum.all?(results, &String.contains?(&1.message || "", "with"))
  end

  test "refute_has rejects unknown option keys with explicit errors", context do
    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> refute_has("Articles", with: "Articles")
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &String.contains?(&1.message || "", "refute_has/3 invalid options"))
    assert Enum.all?(results, &String.contains?(&1.message || "", "with"))
  end
end
