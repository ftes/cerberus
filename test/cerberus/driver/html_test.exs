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

    doc = Html.parse!(html)

    assert {:ok, %{name: "nested_q", label: "Search term *"}} =
             Html.find_form_field(doc, "Search term *", exact: true)
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

    doc = Html.parse!(html)

    assert {:ok, field} = Html.find_form_field(doc, "Name", exact: true)
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

    doc = Html.parse!(html)

    assert names = Html.form_field_names(doc, ~s(form[id="prune-form"]))
    assert MapSet.member?(names, "profile[version]")
    assert MapSet.member?(names, "profile[version_b_text]")
    refute MapSet.member?(names, "profile[version_a_text]")
  end

  test "find_form_field supports count and position filters" do
    html = """
    <form>
      <label for="code_1">Code</label>
      <input id="code_1" name="codes[one]" type="text" value="" />

      <label for="code_2">Code</label>
      <input id="code_2" name="codes[two]" type="text" value="" />

      <label for="code_3">Code</label>
      <input id="code_3" name="codes[three]" type="text" value="" />
    </form>
    """

    doc = Html.parse!(html)

    assert {:ok, %{name: "codes[two]"}} = Html.find_form_field(doc, "Code", nth: 2, count: 3)
    assert {:ok, %{name: "codes[three]"}} = Html.find_form_field(doc, "Code", last: true, between: {2, 3})
    assert :error = Html.find_form_field(doc, "Code", count: 2)
    assert :error = Html.find_form_field(doc, "Code", nth: 4)
  end

  test "find_button supports count and position filters" do
    html = """
    <main>
      <button id="primary" title="Save primary">Save</button>
      <button id="secondary" title="Save secondary">Save</button>
    </main>
    """

    doc = Html.parse!(html)

    assert {:ok, %{title: "Save secondary"}} =
             Html.find_button(doc, "Save", match_by: :title, last: true, count: 2)

    assert :error = Html.find_button(doc, "Save", match_by: :title, count: 1)
  end

  test "resolver APIs accept a pre-parsed LazyHTML document" do
    html = """
    <main>
      <form id="profile-form">
        <label for="profile_name">Name</label>
        <input id="profile_name" name="profile[name]" value="Aragorn" />
        <button type="submit">Save</button>
      </form>
    </main>
    """

    doc = Html.parse!(html)

    assert {:ok, %{name: "profile[name]"}} = Html.find_form_field(doc, "Name", exact: true)
    assert {:ok, %{text: "Save"}} = Html.find_submit_button(doc, "Save", exact: true)
    assert %{"profile[name]" => "Aragorn"} = Html.form_defaults(doc, ~s(form[id="profile-form"]))
  end

  test "form_defaults keeps selected option values instead of falling back to first options" do
    html = """
    <main>
      <form id="settings-form">
        <label for="week_ending_day">Week ending day</label>
        <select id="week_ending_day" name="timecard_setting[week_ending_day]">
          <option value="1">Monday</option>
          <option value="7" selected>Sunday</option>
        </select>

        <label for="crew_reminder_day">Crew reminder day</label>
        <select id="crew_reminder_day" name="timecard_setting[crew_reminder_day]">
          <option value="1">Monday</option>
          <option value="4" selected>Thursday</option>
        </select>
      </form>
    </main>
    """

    doc = Html.parse!(html)

    assert %{
             "timecard_setting[week_ending_day]" => "7",
             "timecard_setting[crew_reminder_day]" => "4"
           } = Html.form_defaults(doc, ~s(form[id="settings-form"]))
  end

  test "checkbox_unchecked_value finds hidden default for boolean checkboxes" do
    html = """
    <main>
      <form id="document-form">
        <input type="hidden" name="custom_document[retain_across_projects?]" value="false" />
        <label for="retain_flag">Retain document across projects?</label>
        <input
          id="retain_flag"
          type="checkbox"
          name="custom_document[retain_across_projects?]"
          value="true"
          checked
        />
      </form>
    </main>
    """

    doc = Html.parse!(html)

    assert Html.checkbox_unchecked_value(
             doc,
             ~s(form[id="document-form"]),
             "custom_document[retain_across_projects?]"
           ) == "false"
  end
end
