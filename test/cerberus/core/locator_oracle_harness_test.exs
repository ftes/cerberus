defmodule Cerberus.CoreLocatorOracleHarnessTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Browser
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError
  alias ExUnit.AssertionError

  @moduletag :browser

  @html_snippet """
  <!doctype html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Locator Oracle</title>
    </head>
    <body>
      <main id="root">
        <h1 data-testid="articles-title">Articles</h1>
        <a href="#counter" id="counter-link">Counter Link</a>
        <button id="increment">Increment</button>
        <div style="display: none;">Secret Hidden Copy</div>

        <form id="profile">
          <label for="email_input">Email Address</label>
          <input id="email_input" name="profile[email]" type="text" value="" />

          <label for="search_q">Search term</label>
          <input id="search_q" name="search[q]" type="text" value="" />

          <label for="language_select">Language</label>
          <select id="language_select" name="profile[language]">
            <option value="">Choose one</option>
            <option value="elixir"> Elixir </option>
            <option value="erlang">Erlang</option>
          </select>

          <label for="item_one">One</label>
          <input id="item_one" name="items[]" type="checkbox" value="one" checked />

          <label for="item_two">Two</label>
          <input id="item_two" name="items[]" type="checkbox" value="two" />

          <label for="contact_email">Email</label>
          <input id="contact_email" name="contact" type="radio" value="email" />

          <label for="contact_sms">SMS</label>
          <input id="contact_sms" name="contact" type="radio" value="sms" />

          <label for="avatar_upload">Avatar</label>
          <input id="avatar_upload" name="profile[avatar]" type="file" />
        </form>
      </main>
    </body>
  </html>
  """

  setup do
    upload_path =
      Path.join(System.tmp_dir!(), "cerberus-locator-oracle-#{System.unique_integer([:positive])}.txt")

    File.write!(upload_path, "locator oracle upload payload")

    on_exit(fn ->
      _ = File.rm(upload_path)
    end)

    {:ok, browser_session: session(:browser), upload_path: upload_path}
  end

  test "snippet locator outcomes match in static and browser worlds", context do
    cases = parity_cases(context.upload_path)

    Enum.each(cases, fn %{name: name, expect: expect, op: op} ->
      static_session = static_snippet_session(@html_snippet)
      browser_session = inject_snippet!(context.browser_session, @html_snippet)

      static_result = run_case(static_session, op)
      browser_result = run_case(browser_session, op)

      assert static_result.status == expect,
             "expected static #{name} to be #{inspect(expect)}, got #{inspect(static_result)}"

      assert browser_result.status == expect,
             "expected browser #{name} to be #{inspect(expect)}, got #{inspect(browser_result)}"

      assert static_result.status == browser_result.status,
             "expected parity for #{name}, static=#{inspect(static_result)} browser=#{inspect(browser_result)}"
    end)
  end

  defp parity_cases(upload_path) do
    [
      %{
        name: "assert_has text (default inexact)",
        expect: :ok,
        op: &assert_has(&1, text("Articles"))
      },
      %{
        name: "assert_has text exact",
        expect: :ok,
        op: &assert_has(&1, text("Articles", exact: true))
      },
      %{
        name: "assert_has text regex",
        expect: :ok,
        op: &assert_has(&1, text(~r/Article/))
      },
      %{
        name: "assert_has hidden text with default visibility fails",
        expect: :error,
        op: &assert_has(&1, text("Secret Hidden Copy"))
      },
      %{
        name: "assert_has hidden text with visible false passes",
        expect: :ok,
        op: &assert_has(&1, text("Secret Hidden Copy"), visible: false)
      },
      %{
        name: "assert_has hidden text with visible any passes",
        expect: :ok,
        op: &assert_has(&1, text("Secret Hidden Copy"), visible: :any)
      },
      %{
        name: "assert_has label helper is treated as text in assertions",
        expect: :ok,
        op: &assert_has(&1, label("Email Address", exact: true))
      },
      %{
        name: "assert_has role button helper maps to text matching",
        expect: :ok,
        op: &assert_has(&1, role(:button, name: "Increment", exact: true))
      },
      %{
        name: "assert_has css locator is unsupported in this slice",
        expect: :error,
        op: &assert_has(&1, css("#root"))
      },
      %{
        name: "assert_has selector option is unsupported in this slice",
        expect: :error,
        op: &assert_has(&1, text("Articles"), selector: "h1")
      },
      %{
        name: "assert_has testid helper is unsupported in this slice",
        expect: :error,
        op: &assert_has(&1, testid("articles-title"))
      },
      %{
        name: "fill_in with label locator",
        expect: :ok,
        op: &fill_in(&1, label("Email Address"), "alice@example.com")
      },
      %{
        name: "fill_in with role textbox locator",
        expect: :ok,
        op: &fill_in(&1, role(:textbox, name: "Search term"), "phoenix")
      },
      %{
        name: "fill_in with css locator",
        expect: :ok,
        op: &fill_in(&1, css("#search_q"), "cerberus")
      },
      %{
        name: "fill_in with explicit text locator is rejected",
        expect: :error,
        op: &fill_in(&1, text("Email Address"), "invalid")
      },
      %{
        name: "select with label locator",
        expect: :ok,
        op: &select(&1, label("Language"), option: "Elixir")
      },
      %{
        name: "select with role combobox locator",
        expect: :ok,
        op: &select(&1, role(:combobox, name: "Language"), option: "Erlang")
      },
      %{
        name: "select with css locator",
        expect: :ok,
        op: &select(&1, css("#language_select"), option: "Elixir")
      },
      %{
        name: "check checkbox by label",
        expect: :ok,
        op: &check(&1, label("Two"))
      },
      %{
        name: "uncheck checkbox by label",
        expect: :ok,
        op: &uncheck(&1, label("One"))
      },
      %{
        name: "choose radio by label",
        expect: :ok,
        op: &choose(&1, label("SMS"))
      },
      %{
        name: "upload file by label",
        expect: :ok,
        op: &upload(&1, label("Avatar"), upload_path)
      }
    ]
  end

  defp static_snippet_session(html) when is_binary(html) do
    %StaticSession{} = static_session = session()

    %{
      static_session
      | html: html,
        current_path: "/__locator_oracle__",
        form_data: %{active_form: nil, values: %{}}
    }
  end

  defp inject_snippet!(browser_session, html) when is_binary(html) do
    encoded_html = JSON.encode!(html)

    expression = """
    (() => {
      const html = #{encoded_html};
      document.open();
      document.write(html);
      document.close();
      return document.documentElement != null;
    })()
    """

    true = Browser.evaluate_js(browser_session, expression)
    browser_session
  end

  defp run_case(session, op) when is_function(op, 1) do
    _ = op.(session)
    %{status: :ok}
  rescue
    error in [AssertionError, ArgumentError, InvalidLocatorError] ->
      %{status: :error, error: Exception.message(error), error_module: error.__struct__}
  end
end
