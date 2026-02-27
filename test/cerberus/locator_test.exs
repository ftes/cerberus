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
end
