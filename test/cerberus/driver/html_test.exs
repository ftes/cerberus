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
end
