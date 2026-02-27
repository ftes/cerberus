defmodule Cerberus.CoreApiExamplesTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag drivers: [:static, :browser]
  test "static page text presence and absence use public API example flow", context do
    Harness.run!(
      context,
      fn session ->
        session
        |> visit("/articles")
        |> assert_has(~l"Articles")
        |> assert_has(~l"This is an articles index page")
        |> refute_has(~l"500 Internal Server Error")
      end
    )
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "same counter click example runs in live and browser drivers", context do
    Harness.run!(context, &counter_increment_flow/1)
  end

  @tag drivers: [:static, :browser]
  test "failure messages include locator and options for reproducible debugging", context do
    results =
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/articles")
          |> assert_has([text: "DOES NOT EXIST"], exact: true, normalize_ws: false)
        end
      )

    assert Enum.all?(results, &(&1.status == :error))

    Enum.each(results, fn result ->
      assert result.message =~ "assert_has failed"
      assert result.message =~ ~s(locator: [text: "DOES NOT EXIST"])
      assert result.message =~ "opts:"
      assert result.message =~ "exact: true"
      assert result.message =~ "normalize_ws: false"
    end)
  end

  defp counter_increment_flow(session) do
    session
    |> visit("/live/counter")
    |> click(~l"Increment")
    |> assert_has([text: "Count: 1"], exact: true)
  end
end
