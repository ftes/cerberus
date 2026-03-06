defmodule Cerberus.LiveFormChangeBehaviorTest do
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
    test "fill_in emits _target for phx-change events (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> fill_in(~l"Email"l, "frodo@example.com")
      |> assert_has(text("_target: [email]", exact: true))
      |> assert_has(text("email: frodo@example.com", exact: true))
    end

    test "fill_in does not trigger server-side change when form has no phx-change (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> within(css("#no-phx-change-form"), fn scoped ->
        fill_in(scoped, ~l"Name (no phx-change)"l, "Aragorn")
      end)
      |> assert_has(text("No change value: unchanged", exact: true))
    end

    test "active form ordering preserves hidden defaults across sequential fill_in (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> within(css("#changes-hidden-input-form"), fn scoped ->
        scoped
        |> fill_in(~l"Name for hidden"l, "Frodo")
        |> fill_in(~l"Email for hidden"l, "frodo@example.com")
      end)
      |> assert_has(text("name: Frodo", exact: true))
      |> assert_has(text("email: frodo@example.com", exact: true))
      |> assert_has(text("hidden_race: hobbit", exact: true))
    end

    test "fill_in matches wrapped nested label text in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> fill_in(~l"Nickname *"l, "Strider")
      |> assert_has(text("_target: [nickname]", exact: true))
      |> assert_has(text("nickname: Strider", exact: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
