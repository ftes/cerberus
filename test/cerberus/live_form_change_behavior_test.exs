defmodule Cerberus.LiveFormChangeBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  for driver <- [:phoenix, :browser] do
    test "fill_in emits _target for phx-change events (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> fill_in("Email", "frodo@example.com")
      |> assert_has(text("_target: [email]", exact: true))
      |> assert_has(text("email: frodo@example.com", exact: true))
    end

    test "fill_in does not trigger server-side change when form has no phx-change (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> within(css("#no-phx-change-form"), fn scoped ->
        fill_in(scoped, "Name (no phx-change)", "Aragorn")
      end)
      |> assert_has(text("No change value: unchanged", exact: true))
    end

    test "active form ordering preserves hidden defaults across sequential fill_in (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> within(css("#changes-hidden-input-form"), fn scoped ->
        scoped
        |> fill_in("Name for hidden", "Frodo")
        |> fill_in("Email for hidden", "frodo@example.com")
      end)
      |> assert_has(text("name: Frodo", exact: true))
      |> assert_has(text("email: frodo@example.com", exact: true))
      |> assert_has(text("hidden_race: hobbit", exact: true))
    end

    test "fill_in matches wrapped nested label text in live and browser drivers (#{driver})" do
      unquote(driver)
      |> session()
      |> visit("/live/form-change")
      |> fill_in("Nickname *", "Strider")
      |> assert_has(text("_target: [nickname]", exact: true))
      |> assert_has(text("nickname: Strider", exact: true))
    end
  end
end
