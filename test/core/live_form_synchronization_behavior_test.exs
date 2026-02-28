defmodule Cerberus.CoreLiveFormSynchronizationBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  @moduletag :conformance

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "conditional submissions exclude fields removed from the rendered form", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/form-sync")
      |> fill_in("Version A Text", "some value for A")
      |> click_button(button("Version B", exact: true))
      |> fill_in("Version B Text", "some value for B")
      |> submit(button("Save Conditional", exact: true))
      |> assert_has(text("has version_a_text?: false", exact: true))
      |> assert_has(text("has version_b_text?: true", exact: true))
      |> assert_has(text("submitted version_b_text: some value for B", exact: true))
    end)
  end

  @tag browser: true
  @tag drivers: [:static, :browser]
  test "static submissions exclude stale fields after form-shape navigation", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/search/profile/a")
      |> fill_in("Version A Text", "some value for A")
      |> click_link(text("Switch to Version B", exact: true))
      |> fill_in("Version B Text", "some value for B")
      |> submit(button("Save Profile", exact: true))
      |> assert_has(text("has version_a_text?: false", exact: true))
      |> assert_has(text("has version_b_text?: true", exact: true))
      |> assert_has(text("submitted version_b_text: some value for B", exact: true))
    end)
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "dispatch(change) buttons inside forms drive add/remove semantics", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/form-sync")
      |> assert_has(text("Email count: 1", exact: true))
      |> click_button(button("add more", exact: true))
      |> assert_has(text("Email count: 2", exact: true))
      |> click_button(button("delete", selector: "button[name='mailing_list[emails_drop][]'][value='1']", exact: true))
      |> assert_has(text("Email count: 1", exact: true))
    end)
  end

  @tag browser: true
  @tag drivers: [:live, :browser]
  test "submit-only forms still submit filled values without phx-change", context do
    Harness.run!(context, fn session ->
      session
      |> visit("/live/form-sync")
      |> fill_in("Nickname (submit only)", "Aragorn")
      |> refute_has(text("no-change submitted: Aragorn", exact: true))
      |> submit(button("Save No Change", exact: true))
      |> assert_has(text("no-change submitted: Aragorn", exact: true))
    end)
  end
end
