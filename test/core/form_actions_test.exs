defmodule Cerberus.CoreFormActionsTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @tag :static
  @tag :browser
  test "click_link, fill_in, and submit are consistent across static and browser drivers",
       context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/search")
        |> click_link(text: "Articles")
        |> assert_has(text: "Articles", exact: true)
        |> visit("/search")
        |> fill_in("Search term", "phoenix")
        |> submit(text: "Run Search")
        |> assert_has(text: "Search query: phoenix", exact: true)
      end
    )
  end

  @tag :static
  @tag :browser
  test "fill_in matches wrapped labels with nested inline text across static and browser drivers",
       context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/search")
        |> fill_in("Search term *", "phoenix")
        |> submit(text: "Run Nested Search")
        |> assert_has(text: "Nested search query: phoenix", exact: true)
      end
    )
  end

  @tag :live
  @tag :browser
  test "click_button works on live counter flow for live and browser drivers", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/live/counter")
        |> click_button(text: "Increment")
        |> assert_has(text: "Count: 1", exact: true)
      end
    )
  end

  @tag :live
  test "live driver reports missing fields for fill_in and missing submit controls on counter page", context do
    fill_results =
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/live/counter")
          |> fill_in("Search term", "x")
        end
      )

    assert [%{status: :error, message: fill_message}] = fill_results
    assert fill_message =~ "no form field matched locator"

    submit_results =
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/live/counter")
          |> submit(text: "Run Search")
        end
      )

    assert [%{status: :error, message: submit_message}] = submit_results
    assert submit_message =~ "no submit button matched locator"
  end
end
