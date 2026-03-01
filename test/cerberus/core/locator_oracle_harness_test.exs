defmodule Cerberus.CoreLocatorOracleHarnessTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Browser
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.InvalidLocatorError
  alias ExUnit.AssertionError

  @moduletag :browser

  @html_prefix """
  <!doctype html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Locator Oracle</title>
    </head>
    <body>
  """

  @html_suffix """
    </body>
  </html>
  """

  @default_html @html_prefix <>
                  """
                    <main id="root">
                    <h1 data-testid="articles-title">Articles</h1>
                    <p id="multiline">Alpha
                    Beta</p>
                    <div style="display: none;">Secret Hidden Copy</div>
                    <div hidden>Hidden Attribute Copy</div>
                    <a href="#counter" id="counter-link">Counter Link</a>
                    <button id="increment">Increment</button>

                    <section id="primary">
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
                          <option value="rust" disabled>Rust</option>
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

                        <label for="nickname">Nickname</label>
                        <input id="nickname" name="profile[nickname]" type="text" />
                      </form>
                    </section>

                    <section id="secondary">
                      <form id="alternate">
                        <label for="secondary_email">Email Address</label>
                        <input id="secondary_email" name="alt[email]" type="text" value="" />

                        <label>Wrapped Name
                          <input id="wrapped_name" name="wrapped[name]" type="text" value="" />
                        </label>

                        <label for="secondary_two">Two</label>
                        <input id="secondary_two" name="secondary_items[]" type="checkbox" value="two" />

                        <label for="color_select">Favorite Color</label>
                        <select id="color_select" name="alt[color]">
                          <option value="blue">Blue</option>
                          <option value="green">Green</option>
                        </select>
                      </form>
                    </section>
                  </main>
                  """ <>
                  @html_suffix

  @inline_label_html @html_prefix <>
                       """
                         <main>
                         <form id="inline">
                           <label>Inline Email
                             <input id="inline_email" name="inline[email]" type="text" value="" />
                           </label>
                         </form>
                       </main>
                       """ <>
                       @html_suffix

  @selector_only_html @html_prefix <>
                        """
                          <main>
                          <div class="bucket">
                            <button id="save-1">Save</button>
                          </div>
                          <div class="bucket secondary">
                            <button id="save-2">Save</button>
                          </div>
                          <form id="selector-form">
                            <label for="s1">Field</label>
                            <input id="s1" name="selector[field][one]" type="text" value="" />
                            <label for="s2">Field</label>
                            <input id="s2" name="selector[field][two]" type="text" value="" />
                          </form>
                        </main>
                        """ <>
                        @html_suffix

  setup do
    upload_path =
      Path.join(System.tmp_dir!(), "cerberus-locator-oracle-#{System.unique_integer([:positive])}.txt")

    File.write!(upload_path, "locator oracle upload payload")

    on_exit(fn ->
      _ = File.rm(upload_path)
    end)

    {:ok, browser_session: session(:browser), upload_path: upload_path}
  end

  test "rich snippet locator corpus stays in static/browser parity", context do
    cases = parity_cases(context.upload_path)

    Enum.each(cases, fn case_def ->
      name = case_def.name
      html = Map.get(case_def, :html, @default_html)
      expect = case_def.expect
      expected_error_module = Map.get(case_def, :error_module)

      static_session = static_snippet_session(html)
      browser_session = inject_snippet!(context.browser_session, html)

      static_result = run_case(static_session, case_def.run)
      browser_result = run_case(browser_session, case_def.run)

      assert static_result.status == expect,
             "expected static #{name} to be #{inspect(expect)}, got #{inspect(static_result)}"

      assert browser_result.status == expect,
             "expected browser #{name} to be #{inspect(expect)}, got #{inspect(browser_result)}"

      assert static_result.status == browser_result.status,
             "expected parity for #{name}, static=#{inspect(static_result)} browser=#{inspect(browser_result)}"

      if expect == :error and not is_nil(expected_error_module) do
        assert static_result.error_module == expected_error_module,
               "expected static #{name} error module #{inspect(expected_error_module)}, got #{inspect(static_result)}"

        assert browser_result.error_module == expected_error_module,
               "expected browser #{name} error module #{inspect(expected_error_module)}, got #{inspect(browser_result)}"
      end
    end)
  end

  defp parity_cases(upload_path) do
    [
      # text matching
      %{name: "assert_has text inexact", expect: :ok, run: &assert_has(&1, text("Article"))},
      %{name: "assert_has text exact", expect: :ok, run: &assert_has(&1, text("Articles", exact: true))},
      %{name: "assert_has text regex", expect: :ok, run: &assert_has(&1, text(~r/Arti\wles?/))},
      %{name: "assert_has multiline normalized text", expect: :ok, run: &assert_has(&1, text("Alpha Beta", exact: true))},
      %{name: "refute_has text", expect: :ok, run: &refute_has(&1, text("Definitely Missing"))},
      %{
        name: "assert_has hidden text fails by default",
        expect: :error,
        error_module: AssertionError,
        run: &assert_has(&1, text("Secret Hidden Copy"))
      },
      %{
        name: "assert_has hidden text with visible false",
        expect: :ok,
        run: &assert_has(&1, text("Secret Hidden Copy"), visible: false)
      },
      %{
        name: "assert_has hidden text with visible any",
        expect: :ok,
        run: &assert_has(&1, text("Hidden Attribute Copy"), visible: :any)
      },
      # helper mappings in assertions
      %{
        name: "assert_has label helper maps to text",
        expect: :ok,
        run: &assert_has(&1, label("Email Address", exact: true))
      },
      %{
        name: "assert_has role button helper maps to text",
        expect: :ok,
        run: &assert_has(&1, role(:button, name: "Increment", exact: true))
      },
      %{
        name: "assert_has role link helper maps to text",
        expect: :ok,
        run: &assert_has(&1, role(:link, name: "Counter Link", exact: true))
      },
      %{
        name: "assert_has css locator unsupported in this slice",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &assert_has(&1, css("#root"))
      },
      %{
        name: "assert_has selector option unsupported in this slice",
        expect: :error,
        error_module: ArgumentError,
        run: &assert_has(&1, text("Articles"), selector: "h1")
      },
      %{
        name: "assert_has testid unsupported in this slice",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &assert_has(&1, testid("articles-title"))
      },
      # fill_in
      %{name: "fill_in label locator", expect: :ok, run: &fill_in(&1, label("Email Address"), "alice@example.com")},
      %{
        name: "fill_in role textbox locator",
        expect: :ok,
        run: &fill_in(&1, role(:textbox, name: "Search term"), "phoenix")
      },
      %{
        name: "fill_in role searchbox locator",
        expect: :ok,
        run: &fill_in(&1, role(:searchbox, name: "Search term"), "search")
      },
      %{name: "fill_in css locator", expect: :ok, run: &fill_in(&1, css("#search_q"), "cerberus")},
      %{name: "fill_in regex label shorthand", expect: :ok, run: &fill_in(&1, ~r/Search term/, "regex value")},
      %{
        name: "fill_in explicit text locator rejected",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &fill_in(&1, text("Email Address"), "invalid")
      },
      %{
        name: "fill_in role link rejected",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &fill_in(&1, role(:link, name: "Counter Link"), "invalid")
      },
      %{
        name: "fill_in duplicate labels disambiguated by selector",
        expect: :ok,
        run: &fill_in(&1, label("Email Address"), "secondary@example.com", selector: "#secondary input")
      },
      %{
        name: "fill_in wrapped label input",
        html: @inline_label_html,
        expect: :ok,
        run: &fill_in(&1, label("Inline Email"), "wrapped@example.com")
      },
      # select
      %{name: "select label locator", expect: :ok, run: &select(&1, label("Language"), option: "Elixir")},
      %{
        name: "select role combobox locator",
        expect: :ok,
        run: &select(&1, role(:combobox, name: "Language"), option: "Erlang")
      },
      %{name: "select css locator", expect: :ok, run: &select(&1, css("#language_select"), option: "Erlang")},
      %{
        name: "select exact_option false supports substring",
        expect: :ok,
        run: &select(&1, label("Language"), option: "Elix", exact_option: false)
      },
      %{
        name: "select disabled option errors",
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, label("Language"), option: "Rust")
      },
      %{
        name: "select option missing errors",
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, label("Language"), option: "Missing")
      },
      # check/uncheck/choose
      %{name: "check checkbox by label", expect: :ok, run: &check(&1, label("Two"))},
      %{name: "uncheck checkbox by label", expect: :ok, run: &uncheck(&1, label("One"))},
      %{
        name: "check duplicate labels disambiguated by selector",
        expect: :ok,
        run: &check(&1, label("Two"), selector: "#secondary input")
      },
      %{name: "choose radio by label", expect: :ok, run: &choose(&1, label("SMS"))},
      %{
        name: "check on non-checkbox field errors",
        expect: :error,
        error_module: AssertionError,
        run: &check(&1, label("Search term"))
      },
      %{
        name: "choose on non-radio field errors",
        expect: :error,
        error_module: AssertionError,
        run: &choose(&1, label("Two"))
      },
      # upload
      %{name: "upload file input by label", expect: :ok, run: &upload(&1, label("Avatar"), upload_path)},
      %{
        name: "upload on non-file field errors",
        expect: :error,
        error_module: AssertionError,
        run: &upload(&1, label("Nickname"), upload_path)
      },
      # click/submit locator normalization errors
      %{
        name: "click with label locator rejected",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &click(&1, label("Search term"))
      },
      %{
        name: "click with testid locator rejected",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &click(&1, testid("articles-title"))
      },
      %{
        name: "submit with label locator rejected",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &submit(&1, label("Search term"))
      },
      # sigil-rich cases
      %{name: "sigil css locator for fill_in", expect: :ok, run: &fill_in(&1, ~l"#search_q"c, "sigil css")},
      %{name: "sigil role locator for select", expect: :ok, run: &select(&1, ~l"combobox:Language"r, option: "Elixir")},
      %{name: "sigil role exact assertion", expect: :ok, run: &assert_has(&1, ~l"button:Increment"re)},
      %{
        name: "invalid mixed locator sigil modifiers raise",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &assert_has(&1, ~l"button:Increment"rc)
      },
      # selector-only disambiguation snippet
      %{
        name: "selector-only snippet fill_in with selector",
        html: @selector_only_html,
        expect: :error,
        error_module: AssertionError,
        run: &fill_in(&1, label("Field"), "scoped", selector: ".secondary #s2")
      },
      %{
        name: "selector-only snippet ambiguous fill_in still succeeds",
        html: @selector_only_html,
        expect: :ok,
        run: &fill_in(&1, label("Field"), "any")
      },
      %{
        name: "selector-only snippet assertion exact text",
        html: @selector_only_html,
        expect: :ok,
        run: &assert_has(&1, text("Save", exact: true))
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

  defp run_case(session, run_fun) when is_function(run_fun, 1) do
    _ = run_fun.(session)
    %{status: :ok}
  rescue
    error in [AssertionError, ArgumentError, InvalidLocatorError] ->
      %{status: :error, error: Exception.message(error), error_module: error.__struct__}
  end
end
