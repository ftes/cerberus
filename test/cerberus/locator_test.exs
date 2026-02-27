defmodule Cerberus.LocatorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.InvalidLocatorError
  alias Cerberus.Locator

  test "normalizes string text locator" do
    assert %Locator{kind: :text, value: "Saved"} = Locator.normalize("Saved")
  end

  test "normalizes regex text locator" do
    regex = ~r/Sav(ed|ing)/
    assert %Locator{kind: :text, value: ^regex} = Locator.normalize(regex)
  end

  test "normalizes keyword text locator" do
    assert %Locator{kind: :text, value: "Saved"} = Locator.normalize(text: "Saved")
  end

  test "raises for unsupported locator keys" do
    assert_raise InvalidLocatorError, fn ->
      Locator.normalize(text: "Saved", role: "button")
    end
  end

  test "raises for invalid locator shape" do
    assert_raise InvalidLocatorError, fn ->
      Locator.normalize(["Saved"])
    end
  end

  test "~l normalizes to text locators" do
    assert %Locator{kind: :text, value: "Saved"} = ~l"Saved"
  end

  test "sigil and non-sigil locators normalize identically" do
    assert Locator.normalize(~l"Saved") == Locator.normalize("Saved")
  end

  test "~l modifiers raise explicit locator errors" do
    assert_raise InvalidLocatorError, ~r/modifiers are not supported/, fn ->
      ~l/Saved/i
    end
  end

  test "normalizes helper keyword locators" do
    assert %Locator{kind: :link, value: "Counter"} = Locator.normalize(link: "Counter")
    assert %Locator{kind: :button, value: "Save"} = Locator.normalize(button: "Save")
    assert %Locator{kind: :label, value: "Search term"} = Locator.normalize(label: "Search term")
    assert %Locator{kind: :testid, value: "submit-btn"} = Locator.normalize(testid: "submit-btn")
  end

  test "normalizes role locator to operation-specific kind" do
    assert %Locator{kind: :button, value: "Increment"} = Locator.normalize(role: :button, name: "Increment")
    assert %Locator{kind: :link, value: "Counter"} = Locator.normalize(role: "link", name: "Counter")
    assert %Locator{kind: :label, value: "Search term"} = Locator.normalize(role: :textbox, name: "Search term")
  end

  test "role locator requires supported role and name" do
    assert_raise InvalidLocatorError, ~r/unsupported :role/, fn ->
      Locator.normalize(role: :dialog, name: "Modal")
    end

    assert_raise InvalidLocatorError, ~r/:name must be a string or regex/, fn ->
      Locator.normalize(role: :button)
    end
  end
end
