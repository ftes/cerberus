defmodule Cerberus.HtmlTest do
  use ExUnit.Case, async: true

  alias Cerberus.Html

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

  test "find_form_field remains framework-agnostic and omits phx metadata" do
    html = """
    <main>
      <form id="profile-form" phx-change="validate">
        <label>
          Name
          <input id="profile_name" name="profile[name]" phx-change="validate_input" />
        </label>
      </form>
    </main>
    """

    assert {:ok, field} = Html.find_form_field(html, "Name", exact: true)
    refute Map.has_key?(field, :input_phx_change)
    refute Map.has_key?(field, :form_phx_change)
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
