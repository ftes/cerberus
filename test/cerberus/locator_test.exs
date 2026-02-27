defmodule Cerberus.LocatorTest do
  use ExUnit.Case, async: true

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
end
