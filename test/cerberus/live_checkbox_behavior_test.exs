defmodule Cerberus.LiveCheckboxBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "outside-form checkbox with phx-click toggles state", %{conn: conn} do
    conn
    |> session()
    |> visit("/phoenix_test/live/index")
    |> within(css("#not-a-form"), fn scoped ->
      scoped
      |> check(~l"Second Breakfast"l)
      |> uncheck(~l"Second Breakfast"l)
    end)
    |> refute_has(and_(css("#form-data"), text("value: second-breakfast")))
  end

  test "label-based nameless checkbox phx-click sends value payloads", %{conn: conn} do
    conn
    |> session()
    |> visit("/phoenix_test/live/index")
    |> check(~l"Checkbox abc"l)
    |> assert_has(and_(css("#checkbox-phx-click-values-abc-value"), text("Checked")))
    |> uncheck(~l"Checkbox abc"l)
    |> assert_has(and_(css("#checkbox-phx-click-values-abc-value"), text("Unchecked")))
  end

  test "outside-form checkbox without phx-click raises contract error", %{conn: conn} do
    live_session =
      conn
      |> session()
      |> visit("/phoenix_test/live/index")

    assert_raise ArgumentError, ~r/have a valid `phx-click` attribute or belong to a `form`/, fn ->
      check(live_session, ~l"Invalid Checkbox"l)
    end
  end
end
