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
    assert %Locator{kind: :label, value: "Race 2"} = ~l"listbox:Race 2"r
    assert %Locator{kind: :label, value: "Age"} = ~l"spinbutton:Age"r
    assert %Locator{kind: :button, value: "Tab Primary"} = ~l"tab:Tab Primary"r
    assert %Locator{kind: :button, value: "Menu Secondary"} = ~l"menuitem:Menu Secondary"r
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
    assert %Locator{kind: :placeholder, value: "Search"} = Locator.normalize(placeholder: "Search")
    assert %Locator{kind: :title, value: "Main Heading"} = Locator.normalize(title: "Main Heading")
    assert %Locator{kind: :alt, value: "Hero image"} = Locator.normalize(alt: "Hero image")
    assert %Locator{kind: :css, value: "#save"} = Locator.normalize(css: "#save")
    assert %Locator{kind: :testid, value: "submit-btn"} = Locator.normalize(testid: "submit-btn")
  end

  test "normalizes locator options for exact/selector" do
    locator = Locator.normalize(text: "Apply", exact: true, selector: "#primary-actions button")

    assert %Locator{kind: :text, value: "Apply"} = locator
    assert locator.opts[:exact] == true
    assert locator.opts[:selector] == "#primary-actions button"
  end

  test "normalizes has locator option for nested locator kinds" do
    locator = Locator.normalize(button: "Apply", has: testid("apply-secondary"))
    has_locator = locator.opts[:has]

    assert %Locator{kind: :button, value: "Apply"} = locator
    assert %Locator{kind: :testid, value: "apply-secondary"} = has_locator
    assert has_locator.opts[:exact] == true

    text_has_locator = Locator.normalize(text: "Apply", has: text("secondary", exact: true)).opts[:has]
    assert %Locator{kind: :text, value: "secondary", opts: [exact: true]} = text_has_locator

    label_has_locator = Locator.normalize(css: ".fieldset", has: label("Email")).opts[:has]
    assert %Locator{kind: :label, value: "Email"} = label_has_locator

    role_has_locator = Locator.normalize(text: "Save", has: role(:button, name: "Submit")).opts[:has]
    assert %Locator{kind: :button, value: "Submit"} = role_has_locator
  end

  test "rejects nested has locators" do
    assert_raise InvalidLocatorError, ~r/nested :has locators are not supported/, fn ->
      Locator.normalize(text: "Apply", has: text("secondary", has: css(".badge")))
    end
  end

  test "closest helper composes base locator with from locator" do
    locator = closest(css(".fieldset"), from: label("Email"))

    assert %Locator{kind: :css, value: ".fieldset"} = locator
    assert %Locator{kind: :label, value: "Email"} = locator.opts[:from]
  end

  test "closest rejects nested from locators" do
    assert_raise ArgumentError, ~r/nested :from/, fn ->
      closest(css(".outer"), from: closest(css(".inner"), from: label("Email")))
    end
  end

  test "normalizes role locator to operation-specific kind" do
    assert %Locator{kind: :button, value: "Increment"} = Locator.normalize(role: :button, name: "Increment")
    assert %Locator{kind: :button, value: "Tab Primary"} = Locator.normalize(role: :tab, name: "Tab Primary")
    assert %Locator{kind: :button, value: "Menu Secondary"} = Locator.normalize(role: :menuitem, name: "Menu Secondary")
    assert %Locator{kind: :link, value: "Counter"} = Locator.normalize(role: "link", name: "Counter")
    assert %Locator{kind: :label, value: "Search term"} = Locator.normalize(role: :textbox, name: "Search term")
    assert %Locator{kind: :label, value: "Race 2"} = Locator.normalize(role: :listbox, name: "Race 2")
    assert %Locator{kind: :label, value: "Age"} = Locator.normalize(role: :spinbutton, name: "Age")
    assert %Locator{kind: :label, value: "Email updates"} = Locator.normalize(role: :checkbox, name: "Email updates")
    assert %Locator{kind: :alt, value: "Logo"} = Locator.normalize(role: :img, name: "Logo")
    assert %Locator{kind: :text, value: "Dashboard"} = Locator.normalize(role: :heading, name: "Dashboard")
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
