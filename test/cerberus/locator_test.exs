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

  test "~l supports exact/inexact modifiers" do
    assert %Locator{kind: :text, value: "Saved", opts: [exact: true]} = ~l"Saved"e
    assert %Locator{kind: :text, value: "Saved", opts: [exact: false]} = ~l"Saved"i
  end

  test "~l supports role modifier using ROLE:NAME syntax" do
    assert %Locator{kind: :button, value: "Increment"} = ~l"button:Increment"r
    assert %Locator{kind: :link, value: "Counter"} = ~l"link:Counter"r
    assert %Locator{kind: :label, value: "Search term"} = ~l"textbox:Search term"r
  end

  test "~l supports css selector modifier" do
    assert %Locator{kind: :css, value: "#search_q"} = ~l"#search_q"c
  end

  test "~l rejects invalid modifier combinations and role syntax" do
    assert_raise InvalidLocatorError, ~r/at most one locator-kind modifier/, fn ->
      ~l"button:Save"rc
    end

    assert_raise InvalidLocatorError, ~r/mutually exclusive/, fn ->
      ~l"Saved"ei
    end

    assert_raise InvalidLocatorError, ~r/ROLE:NAME/, fn ->
      ~l"button"r
    end
  end

  test "normalizes helper keyword locators" do
    assert %Locator{kind: :link, value: "Counter"} = Locator.normalize(link: "Counter")
    assert %Locator{kind: :button, value: "Save"} = Locator.normalize(button: "Save")
    assert %Locator{kind: :label, value: "Search term"} = Locator.normalize(label: "Search term")
    assert %Locator{kind: :css, value: "#save"} = Locator.normalize(css: "#save")
    assert %Locator{kind: :testid, value: "submit-btn"} = Locator.normalize(testid: "submit-btn")
  end

  test "normalizes locator options for exact/selector" do
    locator = Locator.normalize(text: "Apply", exact: true, selector: "#primary-actions button")

    assert %Locator{kind: :text, value: "Apply"} = locator
    assert locator.opts[:exact] == true
    assert locator.opts[:selector] == "#primary-actions button"
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
