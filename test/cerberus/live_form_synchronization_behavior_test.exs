defmodule Cerberus.LiveFormSynchronizationBehaviorTest do
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
    test "conditional submissions exclude fields removed from the rendered form (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-sync")
      |> fill_in("Version A Text", "some value for A")
      |> click_button(button("Version B", exact: true))
      |> fill_in("Version B Text", "some value for B")
      |> submit(button("Save Conditional", exact: true))
      |> assert_has(text("has version_a_text?: false", exact: true))
      |> assert_has(text("has version_b_text?: true", exact: true))
      |> assert_has(text("submitted version_b_text: some value for B", exact: true))
    end

    test "static submissions exclude stale fields after form-shape navigation (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search/profile/a")
      |> fill_in("Version A Text", "some value for A")
      |> click_link(text("Switch to Version B", exact: true))
      |> fill_in("Version B Text", "some value for B")
      |> submit(button("Save Profile", exact: true))
      |> assert_has(text("has version_a_text?: false", exact: true))
      |> assert_has(text("has version_b_text?: true", exact: true))
      |> assert_has(text("submitted version_b_text: some value for B", exact: true))
    end

    test "dispatch(change) buttons inside forms drive add/remove semantics (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-sync")
      |> assert_has(text("Email count: 1", exact: true))
      |> click_button(button("add more", exact: true))
      |> assert_has(text("Email count: 2", exact: true))
      |> click_button(button("delete", selector: "button[name='mailing_list[emails_drop][]'][value='1']", exact: true))
      |> assert_has(text("Email count: 1", exact: true))
    end

    test "submit-only forms still submit filled values without phx-change (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-sync")
      |> fill_in("Nickname (submit only)", "Aragorn")
      |> refute_has(text("no-change submitted: Aragorn", exact: true))
      |> submit(button("Save No Change", exact: true))
      |> assert_has(text("no-change submitted: Aragorn", exact: true))
    end
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
