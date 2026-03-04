defmodule Cerberus.Driver.Live.FormDataTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Live.FormData

  test "toggled_checkbox_value uses hidden unchecked value for boolean checkboxes" do
    html = """
    <main>
      <form id="document-form" phx-change="validate">
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

    session = %Live{html: html}

    field = %{
      name: "custom_document[retain_across_projects?]",
      form: "document-form",
      form_selector: ~s(form[id="document-form"]),
      input_value: "true"
    }

    assert FormData.toggled_checkbox_value(session, field, false) == "false"
  end
end
