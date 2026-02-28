defmodule Cerberus.Driver.LiveViewHtmlTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.LiveViewHtml

  test "find_live_clickable_button escapes multiline attribute values in selector" do
    html = """
    <main>
      <button phx-click="select_confirm" data-confirm="Are you sure?
    More text">Create</button>
      <button phx-click="select_other" data-confirm="Other">Create</button>
    </main>
    """

    assert {:ok, %{selector: selector}} =
             LiveViewHtml.find_live_clickable_button(html, "Create", exact: true)

    assert is_binary(selector)
    assert selector =~ "data-confirm="
    assert selector =~ ~r/\\[Aa]\s/
    refute String.contains?(selector, "\n")

    assert 1 = html |> LazyHTML.from_document() |> LazyHTML.query(selector) |> Enum.count()
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
            }} = LiveViewHtml.find_live_clickable_button(html, "delete", exact: true)
  end

  test "find_live_clickable_button excludes dispatch-only buttons without form phx-change context" do
    html = """
    <main>
      <button phx-click='[["dispatch",{"event":"change"}]]'>dispatch only</button>
    </main>
    """

    assert :error = LiveViewHtml.find_live_clickable_button(html, "dispatch only", exact: true)
  end

  test "find_form_field enriches with input/form phx-change metadata" do
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

    assert {:ok, field} = LiveViewHtml.find_form_field(html, "Name", exact: true)
    assert field.input_phx_change
    assert field.form_phx_change
  end

  test "find_submit_button enriches with form phx-submit metadata" do
    html = """
    <main>
      <form id="save-form" phx-submit="save">
        <button type="submit">Save</button>
      </form>
    </main>
    """

    assert {:ok, button} = LiveViewHtml.find_submit_button(html, "Save", exact: true)
    assert button.form_phx_submit
  end

  test "trigger_action_forms returns forms with defaults" do
    html = """
    <main>
      <form id="trigger-form" phx-trigger-action="true" action="/done" method="post">
        <input name="profile[name]" value="Aragorn" />
      </form>
    </main>
    """

    assert [
             %{
               form: "trigger-form",
               form_selector: ~s(form[id="trigger-form"]),
               action: "/done",
               method: "post",
               defaults: %{"profile[name]" => "Aragorn"}
             }
           ] = LiveViewHtml.trigger_action_forms(html)
  end
end
