defmodule Cerberus.LocatorParityTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Browser
  alias Cerberus.Driver.Static
  alias Cerberus.InvalidLocatorError
  alias ExUnit.AssertionError

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
                    <h1 data-testid="articles-title" title="Articles heading">Articles</h1>
                    <p id="multiline">Alpha
                    Beta</p>
                    <img
                      id="hero"
                      src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
                      alt="Hero banner"
                      title="Hero image"
                    />
                    <div style="display: none;">Secret Hidden Copy</div>
                    <div hidden>Hidden Attribute Copy</div>
                    <a href="/search" id="counter-link" data-testid="counter-link-id" title="Counter link title">
                      Counter Link
                    </a>
                    <button id="increment" data-testid="increment-button" title="Increment title">Increment</button>

                    <section id="primary">
                      <form id="profile" action="#" method="get" onsubmit="return false">
                        <label for="email_input">Email Address</label>
                        <input
                          id="email_input"
                          name="profile[email]"
                          type="text"
                          value=""
                          placeholder="Email placeholder"
                          title="Email input title"
                          data-testid="email-input"
                        />

                        <label for="search_q">Search term</label>
                        <input
                          id="search_q"
                          name="search[q]"
                          type="text"
                          value=""
                          placeholder="Search placeholder"
                          title="Search input title"
                          data-testid="search-input"
                        />

                        <label for="age_input">Age</label>
                        <input id="age_input" name="profile[age]" type="number" value="33" />

                        <label for="language_select">Language</label>
                        <select
                          id="language_select"
                          name="profile[language]"
                          title="Language selector"
                          data-testid="language-select"
                        >
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

                        <button type="submit" data-testid="profile-submit" title="Save profile title">
                          Save Profile
                        </button>
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

  @inline_upload_label_html @html_prefix <>
                              """
                                <main>
                                <form id="inline-upload">
                                  <label>Inline Avatar
                                    <input name="inline[avatar]" type="file" />
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

  @count_position_html @html_prefix <>
                         """
                           <main>
                           <h2 title="Alpha cluster one">Alpha One</h2>
                           <h2 title="Alpha cluster two">Alpha Two</h2>
                           <h2 title="Beta cluster">Beta One</h2>

                           <form id="count-position-form">
                             <label for="code_1">Code</label>
                             <input id="code_1" name="codes[one]" type="text" value="" />

                             <label for="code_2">Code</label>
                             <input id="code_2" name="codes[two]" type="text" value="" />

                             <label for="code_3">Code</label>
                             <input id="code_3" name="codes[three]" type="text" value="" />

                             <label for="agree_1">Agree</label>
                             <input id="agree_1" name="agree[]" type="checkbox" value="one" />

                             <label for="agree_2">Agree</label>
                             <input id="agree_2" name="agree[]" type="checkbox" value="two" />

                             <label for="contact_1">Contact</label>
                             <input id="contact_1" name="contact_primary" type="radio" value="email" />

                             <label for="contact_2">Contact</label>
                             <input id="contact_2" name="contact_secondary" type="radio" value="sms" />

                             <label for="pet_1">Pet</label>
                             <select id="pet_1" name="pet[one]">
                               <option value="cat">Cat</option>
                               <option value="dog">Dog</option>
                             </select>

                             <label for="pet_2">Pet</label>
                             <select id="pet_2" name="pet[two]">
                               <option value="bird">Bird</option>
                               <option value="fish">Fish</option>
                             </select>
                           </form>
                           </main>
                         """ <>
                         @html_suffix

  @state_filter_html @html_prefix <>
                       """
                         <main>
                         <form id="state-filter-form">
                           <label for="sf_enabled">State Field</label>
                           <input id="sf_enabled" name="state[field][enabled]" type="text" value="" />

                           <label for="sf_disabled">State Field</label>
                           <input id="sf_disabled" name="state[field][disabled]" type="text" value="" disabled />

                           <label for="sf_readonly">Readonly Field</label>
                           <input id="sf_readonly" name="state[field][readonly]" type="text" value="" readonly />

                           <label for="sf_check_a">State Check</label>
                           <input id="sf_check_a" name="state[check][]" type="checkbox" value="a" checked />

                           <label for="sf_check_b">State Check</label>
                           <input id="sf_check_b" name="state[check][]" type="checkbox" value="b" />

                           <label for="sf_contact_a">State Contact</label>
                           <input id="sf_contact_a" name="state[contact]" type="radio" value="email" checked />

                           <label for="sf_contact_b">State Contact</label>
                           <input id="sf_contact_b" name="state[contact]" type="radio" value="sms" />
                         </form>
                         </main>
                       """ <>
                       @html_suffix

  @chained_locator_html @html_prefix <>
                          """
                            <main>
                            <section id="chained-clickables">
                              <button id="apply-primary" data-testid="apply-primary-button">
                                <span data-testid="apply-primary-marker" aria-hidden="true">primary</span>
                                Apply
                              </button>
                              <button id="apply-secondary" data-testid="apply-secondary-button">
                                <span data-testid="apply-secondary-marker" aria-hidden="true">secondary</span>
                                Apply
                              </button>
                            </section>

                            <form id="chained-submit-form" action="#" method="get" onsubmit="return false">
                              <label for="chained_q">Search term</label>
                              <input id="chained_q" name="q" type="text" />

                              <button id="submit-primary" type="submit" data-testid="submit-primary-button">
                                <span class="kind-primary" data-testid="submit-primary-marker" aria-hidden="true">primary</span>
                                Run Search
                              </button>

                              <button id="submit-secondary" type="submit" data-testid="submit-secondary-button">
                                <span class="kind-secondary" data-testid="submit-secondary-marker" aria-hidden="true">secondary</span>
                                Run Search
                              </button>
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

  test "chained snippet submit keeps form controls available for follow-up actions", context do
    browser_session = inject_snippet!(context.browser_session, @chained_locator_html)

    browser_session =
      browser_session
      |> submit(and_(role(:button, name: "Run Search", exact: false), testid("submit-secondary-button")))
      |> fill_in(role(:textbox, name: "Search term"), "after-submit")

    Browser.evaluate_js(browser_session, "document.getElementById('chained_q')?.value", &assert(&1 == "after-submit"))
  end

  @tag :slow
  @tag timeout: 180_000
  test "rich snippet locator corpus stays in static/browser parity", context do
    cases = parity_cases(context.upload_path)

    Enum.each(cases, fn case_def ->
      name = case_def.name
      html = Map.get(case_def, :html, @default_html)
      expect = case_def.expect
      expected_error_module = Map.get(case_def, :error_module)
      expected_error_contains = Map.get(case_def, :error_contains)

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

      assert_expected_error_case!(
        expect,
        name,
        expected_error_module,
        expected_error_contains,
        static_result,
        browser_result
      )
    end)
  end

  defp parity_cases(upload_path) do
    [
      # text matching
      %{name: "assert_has text inexact", expect: :ok, run: &assert_has(&1, text("Article", exact: false))},
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
      %{
        name: "assert_has hidden text using locator visible filter false",
        expect: :ok,
        run: &assert_has(&1, filter(text("Hidden Attribute Copy"), visible: false))
      },
      %{
        name: "assert_has hidden text using locator visible filter true",
        expect: :error,
        error_module: AssertionError,
        run: &assert_has(&1, filter(text("Hidden Attribute Copy"), visible: true))
      },
      # helper mappings in assertions
      %{
        name: "assert_has label helper",
        expect: :ok,
        run: &assert_has(&1, ~l"Email Address"le)
      },
      %{
        name: "assert_has role button helper",
        expect: :ok,
        run: &assert_has(&1, role(:button, name: "Increment", exact: true))
      },
      %{
        name: "assert_has role tab helper",
        expect: :ok,
        run: &assert_has(&1, role(:tab, name: "Increment", exact: true))
      },
      %{
        name: "assert_has role menuitem helper",
        expect: :ok,
        run: &assert_has(&1, role(:menuitem, name: "Increment", exact: true))
      },
      %{
        name: "assert_has role link helper",
        expect: :ok,
        run: &assert_has(&1, role(:link, name: "Counter Link", exact: true))
      },
      %{name: "assert_has title helper", expect: :ok, run: &assert_has(&1, title("Articles heading", exact: true))},
      %{name: "assert_has alt helper", expect: :ok, run: &assert_has(&1, alt("Hero banner", exact: true))},
      %{name: "assert_has placeholder helper", expect: :ok, run: &assert_has(&1, placeholder("Search placeholder"))},
      %{name: "assert_has css locator", expect: :ok, run: &assert_has(&1, css("#root"))},
      %{
        name: "assert_has rejects removed selector option",
        expect: :error,
        error_module: ArgumentError,
        error_contains: "unknown options [:selector]",
        run: &assert_has(&1, text("Articles"), selector: "h1")
      },
      %{name: "assert_has testid helper", expect: :ok, run: &assert_has(&1, testid("articles-title"))},
      # fill_in
      %{name: "fill_in label locator", expect: :ok, run: &fill_in(&1, ~l"Email Address"l, "alice@example.com")},
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
      %{name: "fill_in role spinbutton locator", expect: :ok, run: &fill_in(&1, role(:spinbutton, name: "Age"), "42")},
      %{name: "fill_in css locator", expect: :ok, run: &fill_in(&1, css("#search_q"), "cerberus")},
      %{
        name: "fill_in explicit regex text locator",
        expect: :ok,
        run: &fill_in(&1, text(~r/Search term/), "regex value")
      },
      %{
        name: "fill_in explicit text locator",
        expect: :ok,
        run: &fill_in(&1, text("Email Address"), "invalid")
      },
      %{
        name: "fill_in role link locator errors when no field matches",
        expect: :error,
        error_module: AssertionError,
        run: &fill_in(&1, role(:link, name: "Counter Link"), "invalid")
      },
      %{
        name: "fill_in duplicate labels disambiguated by scope chain",
        expect: :ok,
        run: &fill_in(&1, "#secondary" |> css() |> label("Email Address"), "secondary@example.com")
      },
      %{
        name: "fill_in by placeholder",
        expect: :ok,
        run: &fill_in(&1, placeholder("Search placeholder"), "by placeholder")
      },
      %{name: "fill_in by title", expect: :ok, run: &fill_in(&1, title("Search input title"), "by title")},
      %{name: "fill_in by testid", expect: :ok, run: &fill_in(&1, testid("search-input"), "by testid")},
      %{
        name: "fill_in wrapped label input",
        html: @inline_label_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Inline Email"l, "wrapped@example.com")
      },
      # select
      %{name: "select label locator", expect: :ok, run: &select(&1, ~l"Language"l, option: ~l"Elixir"e)},
      %{
        name: "select role combobox locator",
        expect: :ok,
        run: &select(&1, role(:combobox, name: "Language"), option: ~l"Erlang"e)
      },
      %{
        name: "select role listbox locator",
        expect: :ok,
        run: &select(&1, role(:listbox, name: "Language"), option: ~l"Elixir"e)
      },
      %{name: "select css locator", expect: :ok, run: &select(&1, css("#language_select"), option: ~l"Erlang"e)},
      %{
        name: "select exact_option false supports substring",
        expect: :ok,
        run: &select(&1, ~l"Language"l, option: ~l"Elix"e, exact_option: false)
      },
      %{
        name: "select disabled option errors",
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, ~l"Language"l, option: ~l"Rust"e)
      },
      %{
        name: "select option missing errors",
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, ~l"Language"l, option: ~l"Missing"e)
      },
      # check/uncheck/choose
      %{name: "check checkbox by label", expect: :ok, run: &check(&1, ~l"Two"l)},
      %{name: "uncheck checkbox by label", expect: :ok, run: &uncheck(&1, ~l"One"l)},
      %{
        name: "check duplicate labels disambiguated by scope chain",
        expect: :ok,
        run: &check(&1, "#secondary" |> css() |> label("Two"))
      },
      %{name: "choose radio by label", expect: :ok, run: &choose(&1, ~l"SMS"l)},
      %{
        name: "check on non-checkbox field errors",
        expect: :error,
        error_module: AssertionError,
        run: &check(&1, ~l"Search term"l)
      },
      %{
        name: "choose on non-radio field errors",
        expect: :error,
        error_module: AssertionError,
        run: &choose(&1, ~l"Two"l)
      },
      # state filters
      %{
        name: "fill_in state filter chooses enabled duplicate field",
        html: @state_filter_html,
        expect: :ok,
        run: &fill_in(&1, ~l"State Field"l, "enabled", disabled: false)
      },
      %{
        name: "fill_in state filter chooses readonly field",
        html: @state_filter_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Readonly Field"l, "readonly", readonly: true)
      },
      %{
        name: "check state filter chooses unchecked checkbox",
        html: @state_filter_html,
        expect: :ok,
        run: &check(&1, ~l"State Check"l, checked: false)
      },
      %{
        name: "uncheck state filter chooses checked checkbox",
        html: @state_filter_html,
        expect: :ok,
        run: &uncheck(&1, ~l"State Check"l, checked: true)
      },
      %{
        name: "choose state filter chooses unselected radio",
        html: @state_filter_html,
        expect: :ok,
        run: &choose(&1, ~l"State Contact"l, selected: false)
      },
      # locator composition / chaining
      %{
        name: "submit supports same-element and_ composition with testid",
        html: @chained_locator_html,
        expect: :ok,
        run: &submit(&1, and_(role(:button, name: "Run Search", exact: false), testid("submit-secondary-button")))
      },
      %{
        name: "submit scope chaining targets descendants, not same-element intersection",
        html: @chained_locator_html,
        expect: :error,
        error_module: AssertionError,
        run: &submit(&1, :button |> role(name: "Run Search", exact: false) |> testid("submit-secondary-marker"))
      },
      %{
        name: "submit supports has testid nested locator filter",
        html: @chained_locator_html,
        expect: :ok,
        run:
          &submit(&1, :button |> role(name: "Run Search", exact: false) |> filter(has: testid("submit-secondary-marker")))
      },
      %{
        name: "submit supports has text nested locator filter",
        html: @chained_locator_html,
        expect: :ok,
        run: &submit(&1, :button |> role(name: "Run Search", exact: false) |> filter(has: text("secondary", exact: true)))
      },
      %{
        name: "submit has filter errors when nested locator does not match",
        html: @chained_locator_html,
        expect: :error,
        error_module: AssertionError,
        run: &submit(&1, :button |> role(name: "Run Search", exact: false) |> filter(has: testid("missing-marker")))
      },
      %{
        name: "submit supports has css nested locator filter",
        html: @chained_locator_html,
        expect: :ok,
        run: &submit(&1, :button |> role(name: "Run Search", exact: false) |> filter(has: css(".kind-secondary")))
      },
      %{
        name: "submit supports has_not nested locator filter",
        html: @chained_locator_html,
        expect: :ok,
        run:
          &submit(
            &1,
            :button |> role(name: "Run Search", exact: false) |> filter(has_not: testid("submit-secondary-marker"))
          )
      },
      %{
        name: "submit has_not filter errors when nested locator still matches",
        html: @chained_locator_html,
        expect: :error,
        error_module: AssertionError,
        run: &submit(&1, :button |> role(name: "Run Search", exact: false) |> filter(has_not: css("span")))
      },
      %{
        name: "submit supports nested and composition inside has",
        html: @chained_locator_html,
        expect: :ok,
        run:
          &submit(
            &1,
            :button
            |> role(name: "Run Search", exact: false)
            |> filter(has: and_(testid("submit-secondary-marker"), text("secondary", exact: true)))
          )
      },
      %{
        name: "submit supports nested or composition inside has",
        html: @chained_locator_html,
        expect: :ok,
        run:
          &submit(
            &1,
            :button
            |> role(name: "Run Search", exact: false)
            |> filter(has: or_(testid("submit-primary-marker"), testid("submit-secondary-marker")))
          )
      },
      %{
        name: "submit supports A and not B boolean composition",
        html: @chained_locator_html,
        expect: :ok,
        run: &submit(&1, and_(role(:button, name: "Run Search", exact: false), not_(testid("submit-secondary-button"))))
      },
      %{
        name: "submit supports not(A and B) boolean composition",
        html: @chained_locator_html,
        expect: :ok,
        run:
          &submit(
            &1,
            and_(
              role(:button, name: "Run Search", exact: false),
              not_(and_(role(:button, name: "Run Search", exact: false), testid("submit-secondary-button")))
            )
          )
      },
      %{
        name: "submit or composition enforces strict uniqueness for actions",
        html: @chained_locator_html,
        expect: :error,
        error_module: AssertionError,
        run: &submit(&1, or_(css("#submit-primary"), css("#submit-secondary")))
      },
      %{
        name: "assert_has supports has locator option",
        html: @chained_locator_html,
        expect: :ok,
        run: &assert_has(&1, filter(role(:button, name: "Apply", exact: false), has: text("secondary", exact: true)))
      },
      %{
        name: "assert_has supports has_not locator option",
        html: @chained_locator_html,
        expect: :ok,
        run: &assert_has(&1, filter(role(:button, name: "Apply", exact: false), has_not: text("secondary", exact: true)))
      },
      %{
        name: "assert_has supports composed css and text locator assertions",
        html: @chained_locator_html,
        expect: :ok,
        run: &assert_has(&1, and_(css("#apply-secondary"), text("Apply", exact: false)))
      },
      %{
        name: "fill_in supports same-element and_ composition with css",
        expect: :ok,
        run: &fill_in(&1, and_(~l"Email Address"l, css("#secondary_email")), "secondary@example.com")
      },
      %{
        name: "fill_in or composition resolves when exactly one branch matches",
        expect: :ok,
        run: &fill_in(&1, or_(css("#search_q"), css("#missing-field")), "or-value")
      },
      %{
        name: "fill_in or composition enforces strict uniqueness for actions",
        expect: :error,
        error_module: AssertionError,
        run: &fill_in(&1, or_(css("#email_input"), css("#secondary_email")), "ambiguous")
      },
      # upload
      %{name: "upload file input by label", expect: :ok, run: &upload(&1, ~l"Avatar"l, upload_path)},
      %{
        name: "upload wrapped label input",
        html: @inline_upload_label_html,
        expect: :ok,
        run: &upload(&1, ~l"Inline Avatar"l, upload_path)
      },
      %{
        name: "upload on non-file field errors",
        expect: :error,
        error_module: AssertionError,
        run: &upload(&1, ~l"Nickname"l, upload_path)
      },
      # click/submit with non-clickable locator kinds
      %{
        name: "click with label locator errors when no clickable matches",
        expect: :error,
        error_module: AssertionError,
        run: &click(&1, ~l"Search term"l)
      },
      %{
        name: "submit with label locator errors when no submit control matches",
        expect: :error,
        error_module: AssertionError,
        run: &submit(&1, ~l"Search term"l)
      },
      # sigil-rich cases
      %{name: "sigil css locator for fill_in", expect: :ok, run: &fill_in(&1, ~l"#search_q"c, "sigil css")},
      %{name: "sigil testid locator for fill_in", expect: :ok, run: &fill_in(&1, ~l"search-input"t, "sigil testid")},
      %{
        name: "sigil role locator for select",
        expect: :ok,
        run: &select(&1, ~l"combobox:Language"r, option: ~l"Elixir"e)
      },
      %{
        name: "sigil role locator for listbox",
        expect: :ok,
        run: &select(&1, ~l"listbox:Language"r, option: ~l"Erlang"e)
      },
      %{name: "sigil role exact assertion", expect: :ok, run: &assert_has(&1, ~l"button:Increment"re)},
      %{
        name: "invalid mixed locator sigil modifiers raise",
        expect: :error,
        error_module: InvalidLocatorError,
        run: &assert_has(&1, ~l"button:Increment"rc)
      },
      # count/position filters (assertions + form actions)
      %{
        name: "count filters on assertions support exact count",
        html: @count_position_html,
        expect: :ok,
        run: &assert_has(&1, title("Alpha", exact: false), count: 2)
      },
      %{
        name: "count filters on assertions support min/max",
        html: @count_position_html,
        expect: :ok,
        run: &assert_has(&1, title("Alpha", exact: false), min: 2, max: 2)
      },
      %{
        name: "count filters on assertions support between tuple",
        html: @count_position_html,
        expect: :ok,
        run: &assert_has(&1, title("Alpha", exact: false), between: {1, 2})
      },
      %{
        name: "count filters on assertions support between range",
        html: @count_position_html,
        expect: :ok,
        run: &assert_has(&1, title("Alpha", exact: false), between: 2..3)
      },
      %{
        name: "count filters on assertions fail when count mismatches",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &assert_has(&1, title("Alpha", exact: false), count: 3)
      },
      %{
        name: "refute_has with count filter passes when constraints are not satisfied",
        html: @count_position_html,
        expect: :ok,
        run: &refute_has(&1, title("Alpha", exact: false), count: 3)
      },
      %{
        name: "refute_has with count filter fails when constraints are satisfied",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &refute_has(&1, title("Alpha", exact: false), count: 2)
      },
      %{
        name: "assert_has rejects position filters",
        html: @count_position_html,
        expect: :error,
        error_module: ArgumentError,
        run: &assert_has(&1, title("Alpha", exact: false), first: true)
      },
      %{
        name: "assert_has validates between bounds",
        html: @count_position_html,
        expect: :error,
        error_module: ArgumentError,
        run: &assert_has(&1, title("Alpha", exact: false), between: {2, 1})
      },
      %{
        name: "fill_in supports first count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Code"l, "first-code", first: true, count: 3)
      },
      %{
        name: "fill_in supports last count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Code"l, "last-code", last: true, between: {2, 3})
      },
      %{
        name: "fill_in supports nth count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Code"l, "second-code", nth: 2, min: 3)
      },
      %{
        name: "fill_in supports index count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Code"l, "third-code", index: 2, max: 3)
      },
      %{
        name: "fill_in fails when count filter mismatches",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &fill_in(&1, ~l"Code"l, "mismatch", count: 2)
      },
      %{
        name: "fill_in fails when nth is out of bounds",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &fill_in(&1, ~l"Code"l, "out-of-bounds", nth: 4)
      },
      %{
        name: "fill_in validates mutually exclusive position filters",
        html: @count_position_html,
        expect: :error,
        error_module: ArgumentError,
        run: &fill_in(&1, ~l"Code"l, "invalid", first: true, nth: 2)
      },
      %{
        name: "check supports count-position filters",
        html: @count_position_html,
        expect: :ok,
        run: &check(&1, ~l"Agree"l, last: true, count: 2)
      },
      %{
        name: "check fails when count filter mismatches",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &check(&1, ~l"Agree"l, count: 1)
      },
      %{
        name: "choose supports count-position filters",
        html: @count_position_html,
        expect: :ok,
        run: &choose(&1, ~l"Contact"l, index: 1, between: {2, 2})
      },
      %{
        name: "choose fails when count filter mismatches",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &choose(&1, ~l"Contact"l, count: 1)
      },
      %{
        name: "select supports first count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &select(&1, ~l"Pet"l, option: ~l"Dog"e, first: true, count: 2)
      },
      %{
        name: "select supports last count-position filter",
        html: @count_position_html,
        expect: :ok,
        run: &select(&1, ~l"Pet"l, option: ~l"Fish"e, last: true, between: {2, 2})
      },
      %{
        name: "select fails when position is out of bounds",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, ~l"Pet"l, option: ~l"Dog"e, nth: 3)
      },
      %{
        name: "select fails when count filter mismatches",
        html: @count_position_html,
        expect: :error,
        error_module: AssertionError,
        run: &select(&1, ~l"Pet"l, option: ~l"Dog"e, count: 1)
      },
      # scope chaining disambiguation snippet
      %{
        name: "scope-chain snippet fill_in with scoped locator",
        html: @selector_only_html,
        expect: :ok,
        run: &fill_in(&1, "#selector-form" |> css() |> css("#s2"), "scoped")
      },
      %{
        name: "selector-only snippet ambiguous fill_in still succeeds",
        html: @selector_only_html,
        expect: :ok,
        run: &fill_in(&1, ~l"Field"l, "any")
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
    %Static{} = static_session = session()

    %{
      static_session
      | document: Cerberus.Html.parse!(html),
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

    Browser.evaluate_js(browser_session, expression, &assert(&1 == true))
    browser_session
  end

  defp run_case(session, run_fun) when is_function(run_fun, 1) do
    _ = run_fun.(session)
    %{status: :ok}
  rescue
    error in [AssertionError, ArgumentError, InvalidLocatorError] ->
      %{status: :error, error: Exception.message(error), error_module: error.__struct__}
  end

  defp assert_expected_error_case!(
         :ok,
         name,
         expected_error_module,
         expected_error_contains,
         _static_result,
         _browser_result
       ) do
    assert is_nil(expected_error_module),
           "expected #{name} to omit :error_module when expect is :ok, got #{inspect(expected_error_module)}"

    assert is_nil(expected_error_contains),
           "expected #{name} to omit :error_contains when expect is :ok, got #{inspect(expected_error_contains)}"
  end

  defp assert_expected_error_case!(
         :error,
         name,
         expected_error_module,
         expected_error_contains,
         static_result,
         browser_result
       ) do
    assert is_atom(expected_error_module),
           "expected #{name} to set :error_module when expect is :error"

    assert static_result.error_module == expected_error_module,
           "expected static #{name} error module #{inspect(expected_error_module)}, got #{inspect(static_result)}"

    assert browser_result.error_module == expected_error_module,
           "expected browser #{name} error module #{inspect(expected_error_module)}, got #{inspect(browser_result)}"

    assert_error_contains!(name, :static, static_result, expected_error_contains)
    assert_error_contains!(name, :browser, browser_result, expected_error_contains)
  end

  defp assert_error_contains!(_name, _lane, _result, nil), do: :ok

  defp assert_error_contains!(name, lane, result, expected_error_contains) when is_binary(expected_error_contains) do
    assert is_binary(result.error),
           "expected #{lane} #{name} error message to be present, got #{inspect(result)}"

    assert String.contains?(result.error, expected_error_contains),
           "expected #{lane} #{name} error message to contain #{inspect(expected_error_contains)}, got #{inspect(result.error)}"
  end
end
