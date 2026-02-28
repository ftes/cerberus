defmodule Cerberus.Driver.HtmlTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Html

  test "find_live_clickable_button escapes multiline attribute values in selector" do
    html = """
    <main>
      <button phx-click="select_confirm" data-confirm="Are you sure?
    More text">Create</button>
      <button phx-click="select_other" data-confirm="Other">Create</button>
    </main>
    """

    assert {:ok, %{selector: selector}} =
             Html.find_live_clickable_button(html, "Create", exact: true)

    assert is_binary(selector)
    assert selector =~ "data-confirm="
    assert selector =~ ~r/\\[Aa]\s/
    refute String.contains?(selector, "\n")

    assert 1 = html |> LazyHTML.from_document() |> LazyHTML.query(selector) |> Enum.count()
  end

  test "find_form_field matches wrapped labels with nested inline text" do
    html = """
    <form>
      <label>
        Search term <span class="required">*</span>
        <input name="nested_q" type="text" value="" />
      </label>
    </form>
    """

    assert {:ok, %{name: "nested_q", label: "Search term *"}} =
             Html.find_form_field(html, "Search term *", exact: true)
  end

  test "find_live_clickable_button includes dispatch(change) buttons tied to form-level phx-change" do
    html = """
    <main>
      <form id="dynamic-form" phx-change="validate">
        <button type="button" name="items_drop[]" value="1" phx-click='[["dispatch",{"event":"change"}]]'>
          delete
        </button>
      </form>
    </main>
    """

    assert {:ok,
            %{
              dispatch_change: true,
              button_name: "items_drop[]",
              button_value: "1",
              form: "dynamic-form",
              form_selector: ~s(form[id="dynamic-form"])
            }} = Html.find_live_clickable_button(html, "delete", exact: true)
  end

  test "find_live_clickable_button excludes dispatch-only buttons without form phx-change context" do
    html = """
    <main>
      <button phx-click='[["dispatch",{"event":"change"}]]'>dispatch only</button>
    </main>
    """

    assert :error = Html.find_live_clickable_button(html, "dispatch only", exact: true)
  end

  test "form_field_names returns current named controls for pruning stale params" do
    html = """
    <main>
      <form id="prune-form">
        <input name="profile[version]" type="hidden" value="b" />
        <input name="profile[version_b_text]" type="text" value="" />
        <button type="submit">Save</button>
      </form>
    </main>
    """

    assert names = Html.form_field_names(html, ~s(form[id="prune-form"]))
    assert MapSet.member?(names, "profile[version]")
    assert MapSet.member?(names, "profile[version_b_text]")
    refute MapSet.member?(names, "profile[version_a_text]")
  end
end
