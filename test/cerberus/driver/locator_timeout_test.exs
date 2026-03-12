defmodule Cerberus.Driver.LocatorTimeoutTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static
  alias Cerberus.Html

  test "static locator count assertions normalize expired internal deadlines" do
    session = %Static{document: Html.parse!(sample_html()), current_path: "/", form_data: empty_form_data()}
    Html.put_assertion_deadline_ms(System.monotonic_time(:millisecond) - 1)

    try do
      assert {:error, ^session, observed, "assertion timed out while resolving locator candidates"} =
               Static.assert_has(session, sample_locator(), count: 1)

      assert observed.expected == sample_locator()
      assert observed.matched == []
    after
      Html.put_assertion_deadline_ms(nil)
    end
  end

  test "live locator count assertions normalize expired internal deadlines" do
    session = %Live{document: Html.parse!(sample_html()), current_path: "/", form_data: empty_form_data()}
    Html.put_assertion_deadline_ms(System.monotonic_time(:millisecond) - 1)

    try do
      assert {:error, ^session, observed, "assertion timed out while resolving locator candidates"} =
               Live.assert_has(session, sample_locator(), count: 1, timeout: 0)

      assert observed.expected == sample_locator()
      assert observed.matched == []
    after
      Html.put_assertion_deadline_ms(nil)
    end
  end

  defp sample_html do
    """
    <table>
      <tr><td>Van Driver</td></tr>
    </table>
    """
  end

  defp sample_locator do
    and_(~l"td"c, text("Van Driver", exact: true))
  end

  defp empty_form_data do
    %{active_form: nil, active_form_selector: nil, values: %{}}
  end
end
