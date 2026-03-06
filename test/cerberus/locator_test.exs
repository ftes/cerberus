defmodule Cerberus.LocatorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.InvalidLocatorError
  alias Cerberus.Locator

  test "normalize returns {:ok, locator} for valid locator input" do
    assert {:ok, %Locator{kind: :text, value: "Saved"}} = Locator.normalize(text: "Saved")
  end

  test "normalize returns {:error, invalid_locator_error} for invalid locator input" do
    assert {:error, %InvalidLocatorError{locator: "Saved"}} = Locator.normalize("Saved")
  end

  test "rejects bare string locator input" do
    assert_raise InvalidLocatorError, fn ->
      Locator.normalize!("Saved")
    end
  end

  test "rejects bare regex locator input" do
    regex = ~r/Sav(ed|ing)/

    assert_raise InvalidLocatorError, fn ->
      Locator.normalize!(regex)
    end
  end

  test "rejects exact option when text-like locator value is regex" do
    assert_raise InvalidLocatorError, ~r/:exact cannot be combined with regex :text locators/, fn ->
      Locator.normalize!(text: ~r/Saved/, exact: true)
    end

    assert_raise InvalidLocatorError, ~r/:exact cannot be combined with regex :role locators/, fn ->
      role(:button, name: ~r/Save/, exact: false)
    end
  end

  test "rejects exact option when role locator name is regex" do
    assert_raise InvalidLocatorError, ~r/:exact cannot be combined with regex :role locators/, fn ->
      Locator.normalize!(role: :button, name: ~r/Save/, exact: true)
    end
  end

  test "rejects exact option when normalizing regex struct locators" do
    assert_raise InvalidLocatorError, ~r/:exact cannot be combined with regex :text locators/, fn ->
      Locator.normalize!(%Locator{kind: :text, value: ~r/Saved/, opts: [exact: true]})
    end

    assert_raise InvalidLocatorError, ~r/:exact cannot be combined with regex :role locators/, fn ->
      Locator.normalize!(%Locator{kind: :role, value: ~r/Save/, opts: [role: "button", exact: false]})
    end
  end

  test "normalizes keyword text locator" do
    assert %Locator{kind: :text, value: "Saved"} = Locator.normalize!(text: "Saved")
  end

  test "raises for unsupported locator keys" do
    assert_raise InvalidLocatorError, fn ->
      Locator.normalize!(text: "Saved", role: "button")
    end
  end

  test "raises for invalid locator shape" do
    assert_raise InvalidLocatorError, fn ->
      Locator.normalize!(["Saved"])
    end
  end

  test "~l text locators default to exact matching when no mode modifier is provided" do
    assert %Locator{kind: :text, value: "Saved", opts: [exact: true]} = ~l"Saved"
  end

  test "~l supports exact/inexact modifiers" do
    assert %Locator{kind: :text, value: "Saved", opts: [exact: true]} = ~l"Saved"e
    assert %Locator{kind: :text, value: "Saved", opts: [exact: false]} = ~l"Saved"i

    assert Locator.normalize!(~l"Saved"e) == Locator.normalize!(text: "Saved", exact: true)
    assert Locator.normalize!(~l"Saved"i) == Locator.normalize!(text: "Saved", exact: false)
  end

  test "~l supports role modifier using ROLE:NAME syntax" do
    assert %Locator{kind: :role, value: "Increment", opts: [role: "button", exact: true]} = ~l"button:Increment"r
    assert %Locator{kind: :role, value: "Counter", opts: [role: "link", exact: true]} = ~l"link:Counter"r
    assert %Locator{kind: :role, value: "Search term", opts: [role: "textbox", exact: true]} = ~l"textbox:Search term"r
    assert %Locator{kind: :role, value: "Race 2", opts: [role: "listbox", exact: true]} = ~l"listbox:Race 2"r
    assert %Locator{kind: :role, value: "Age", opts: [role: "spinbutton", exact: true]} = ~l"spinbutton:Age"r
    assert %Locator{kind: :role, value: "Tab Primary", opts: [role: "tab", exact: true]} = ~l"tab:Tab Primary"r

    assert %Locator{kind: :role, value: "Menu Secondary", opts: [role: "menuitem", exact: true]} =
             ~l"menuitem:Menu Secondary"r
  end

  test "~l supports css selector modifier" do
    assert %Locator{kind: :css, value: "#search_q"} = ~l"#search_q"c
  end

  test "~l supports aria-label modifier" do
    assert %Locator{kind: :aria_label, value: "Run search"} = ~l"Run search"a
    assert %Locator{kind: :aria_label, value: "Run search", opts: [exact: true]} = ~l"Run search"ae
  end

  test "~l supports testid modifier with default exact matching" do
    assert %Locator{kind: :testid, value: "search-input", opts: [exact: true]} = ~l"search-input"t
    assert %Locator{kind: :testid, value: "search-input", opts: [exact: true]} = ~l"search-input"te
    assert %Locator{kind: :testid, value: "search-input", opts: [exact: false]} = ~l"search-input"ti
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

    assert_raise InvalidLocatorError, ~r/testid modifier expects non-empty text/, fn ->
      ~l""t
    end
  end

  test "normalizes helper keyword locators" do
    assert %Locator{kind: :role, value: "Counter", opts: [role: "link", exact: true]} =
             Locator.normalize!(role: :link, name: "Counter")

    assert %Locator{kind: :role, value: "Save", opts: [role: "button", exact: true]} =
             Locator.normalize!(role: :button, name: "Save")

    assert %Locator{kind: :label, value: "Search term"} = Locator.normalize!(label: "Search term")
    assert %Locator{kind: :placeholder, value: "Search"} = Locator.normalize!(placeholder: "Search")
    assert %Locator{kind: :title, value: "Main Heading"} = Locator.normalize!(title: "Main Heading")
    assert %Locator{kind: :alt, value: "Hero image"} = Locator.normalize!(alt: "Hero image")
    assert %Locator{kind: :aria_label, value: "Search field"} = Locator.normalize!(aria_label: "Search field")
    assert %Locator{kind: :css, value: "#save"} = Locator.normalize!(css: "#save")
    assert %Locator{kind: :testid, value: "submit-btn"} = Locator.normalize!(testid: "submit-btn")
  end

  test "rejects deprecated link/button keyword kinds" do
    assert_raise InvalidLocatorError, ~r/expected one of :text, :label/, fn ->
      Locator.normalize!(link: "Counter")
    end

    assert_raise InvalidLocatorError, ~r/expected one of :text, :label/, fn ->
      Locator.normalize!(button: "Save")
    end
  end

  test "rejects selector locator option" do
    assert_raise InvalidLocatorError, ~r/selector/, fn ->
      Locator.normalize!(text: "Apply", exact: true, selector: "#primary-actions button")
    end
  end

  test "normalizes has locator option for nested locator kinds" do
    locator = Locator.normalize!(role: :button, name: "Apply", has: testid("apply-secondary"))
    has_locator = locator.opts[:has]

    assert %Locator{kind: :role, value: "Apply", opts: opts} = locator
    assert opts[:role] == "button"
    assert %Locator{kind: :testid, value: "apply-secondary"} = has_locator
    assert has_locator.opts[:exact] == true

    text_has_locator = Locator.normalize!(text: "Apply", has: text("secondary", exact: true)).opts[:has]
    assert %Locator{kind: :text, value: "secondary", opts: [exact: true]} = text_has_locator

    label_has_locator = Locator.normalize!(css: ".fieldset", has: label("Email")).opts[:has]
    assert %Locator{kind: :label, value: "Email"} = label_has_locator

    role_has_locator = Locator.normalize!(text: "Save", has: role(:button, name: "Submit")).opts[:has]
    assert %Locator{kind: :role, value: "Submit", opts: [role: "button", exact: true]} = role_has_locator
  end

  test "supports nested has locators" do
    locator = Locator.normalize!(text: "Apply", has: text("secondary", has: css(".badge")))
    has_locator = locator.opts[:has]
    nested_has = has_locator.opts[:has]

    assert %Locator{kind: :text, value: "Apply"} = locator
    assert %Locator{kind: :text, value: "secondary"} = has_locator
    assert %Locator{kind: :css, value: ".badge"} = nested_has
  end

  test "normalizes has_not locator option for nested locator kinds" do
    locator = Locator.normalize!(role: :button, name: "Apply", has_not: testid("apply-secondary-marker"))
    has_not_locator = locator.opts[:has_not]

    assert %Locator{kind: :role, value: "Apply", opts: opts} = locator
    assert opts[:role] == "button"
    assert %Locator{kind: :testid, value: "apply-secondary-marker"} = has_not_locator
    assert has_not_locator.opts[:exact] == true
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

  test "composes and/or locators and flattens nested members" do
    locator =
      "Run Search"
      |> text()
      |> and_(role(:button, name: "Run Search"))
      |> and_(testid("submit-secondary"))

    assert %Locator{kind: :and, value: members} = locator
    assert Enum.map(members, & &1.kind) == [:text, :role, :testid]

    disjunction =
      or_(
        css("#primary"),
        or_(css("#secondary"), css("#tertiary"))
      )

    assert %Locator{kind: :or, value: disj_members} = disjunction
    assert Enum.map(disj_members, & &1.value) == ["#primary", "#secondary", "#tertiary"]
  end

  test "composes not locators including chained A and not B patterns" do
    negated = not_(role(:button, name: "Run Search"))
    assert %Locator{kind: :not, value: [%Locator{kind: :role, value: "Run Search"}]} = negated

    chained = and_(role(:button, name: "Run Search"), not_(testid("submit-secondary-button")))

    assert %Locator{
             kind: :and,
             value: [
               %Locator{kind: :role, value: "Run Search"},
               %Locator{kind: :not, value: [%Locator{kind: :testid, value: "submit-secondary-button"}]}
             ]
           } = chained

    negated_conjunction = not_(and_(role(:button, name: "Run Search"), testid("submit-secondary-button")))

    assert %Locator{
             kind: :not,
             value: [%Locator{kind: :and, value: [%Locator{kind: :role}, %Locator{kind: :testid}]}]
           } = negated_conjunction
  end

  test "supports map normalization for not composition" do
    locator =
      Locator.normalize!(not: %{and: [%{role: :button, name: "Run Search"}, %{testid: "submit-secondary-button"}]})

    assert %Locator{
             kind: :not,
             value: [%Locator{kind: :and, value: [%Locator{kind: :role}, %Locator{kind: :testid}]}]
           } = locator
  end

  test "pipe composition overloads create scope semantics" do
    scoped = :button |> role(name: "Run Search") |> testid("submit-secondary-marker")
    assert %Locator{kind: :scope, value: [%Locator{kind: :role}, %Locator{kind: :testid}]} = scoped

    intersection = and_(role(:button, name: "Run Search"), testid("submit-secondary-marker"))
    assert %Locator{kind: :and, value: [%Locator{kind: :role}, %Locator{kind: :testid}]} = intersection
  end

  test "preserves role locator kind and metadata" do
    assert %Locator{kind: :role, value: "Increment", opts: [role: "button", exact: true]} =
             Locator.normalize!(role: :button, name: "Increment")

    assert %Locator{kind: :role, value: "Tab Primary", opts: [role: "tab", exact: true]} =
             Locator.normalize!(role: :tab, name: "Tab Primary")

    assert %Locator{kind: :role, value: "Menu Secondary", opts: [role: "menuitem", exact: true]} =
             Locator.normalize!(role: :menuitem, name: "Menu Secondary")

    assert %Locator{kind: :role, value: "Counter", opts: [role: "link", exact: true]} =
             Locator.normalize!(role: "link", name: "Counter")

    assert %Locator{kind: :role, value: "Search term", opts: [role: "textbox", exact: true]} =
             Locator.normalize!(role: :textbox, name: "Search term")

    assert %Locator{kind: :role, value: "Race 2", opts: [role: "listbox", exact: true]} =
             Locator.normalize!(role: :listbox, name: "Race 2")

    assert %Locator{kind: :role, value: "Age", opts: [role: "spinbutton", exact: true]} =
             Locator.normalize!(role: :spinbutton, name: "Age")

    assert %Locator{kind: :role, value: "Email updates", opts: [role: "checkbox", exact: true]} =
             Locator.normalize!(role: :checkbox, name: "Email updates")

    assert %Locator{kind: :role, value: "Logo", opts: [role: "img", exact: true]} =
             Locator.normalize!(role: :img, name: "Logo")

    assert %Locator{kind: :role, value: "Dashboard", opts: [role: "heading", exact: true]} =
             Locator.normalize!(role: :heading, name: "Dashboard")
  end

  test "resolved_kind maps role locators to matcher kinds" do
    assert :button == [role: :button, name: "Increment"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :button == [role: :tab, name: "Tab Primary"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :button == [role: :menuitem, name: "Menu Secondary"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :link == [role: :link, name: "Counter"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :label == [role: :textbox, name: "Search term"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :label == [role: :listbox, name: "Race 2"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :label == [role: :spinbutton, name: "Age"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :label == [role: :checkbox, name: "Email updates"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :alt == [role: :img, name: "Logo"] |> Locator.normalize!() |> Locator.resolved_kind()
    assert :text == [role: :heading, name: "Dashboard"] |> Locator.normalize!() |> Locator.resolved_kind()
  end

  test "role locator requires supported role and name" do
    assert_raise InvalidLocatorError, ~r/unsupported :role/, fn ->
      Locator.normalize!(role: :dialog, name: "Modal")
    end

    assert_raise InvalidLocatorError, ~r/:name must be a string or regex/, fn ->
      Locator.normalize!(role: :button)
    end
  end
end
