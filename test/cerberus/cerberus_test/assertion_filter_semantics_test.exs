defmodule CerberusTest.AssertionFilterSemanticsTest do
  use ExUnit.Case, async: true

  import Cerberus

  @missing_label "Unknown Label"

  for driver <- [:phoenix, :browser] do
    test "refute_has supports label-only locators when label text is missing (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> refute_has(label(@missing_label, exact: true))
    end

    test "assert_has with label-only locator fails when label text is missing (#{driver})" do
      assert_raise ExUnit.AssertionError, ~r/expected text not found/, fn ->
        unquote(driver)
        |> session()
        |> visit("/live/form-change")
        |> assert_has(label(@missing_label, exact: true))
      end
    end

    test "assert_has rejects unknown option keys with explicit errors (#{driver})" do
      assert_raise ArgumentError,
                   ~r/assert_has\/3 invalid options/,
                   fn ->
                     unquote(driver)
                     |> session()
                     |> visit("/articles")
                     |> assert_has("Articles", with: "Articles")
                   end
    end

    test "refute_has rejects unknown option keys with explicit errors (#{driver})" do
      assert_raise ArgumentError,
                   ~r/refute_has\/3 invalid options/,
                   fn ->
                     unquote(driver)
                     |> session()
                     |> visit("/articles")
                     |> refute_has("Articles", with: "Articles")
                   end
    end
  end
end
