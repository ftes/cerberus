defmodule Cerberus.Options do
  @moduledoc """
  Shared option and option-schema types used by Cerberus public APIs and drivers.

  This module centralizes validation and normalized defaults for operation
  option lists (`click`, `fill_in`, `assert_has`, `submit`, and related helpers).
  """

  @type locator_match_by :: :text | :label | :link | :button | :placeholder | :title | :alt | :aria_label | :testid
  @type role_locator_name :: String.t() | Regex.t() | nil
  @type locator_nested_input :: Cerberus.Locator.input()
  @type visibility_filter :: boolean() | :any
  @type fill_in_value :: String.t() | integer() | float() | boolean()
  @type select_value :: String.t() | [String.t()]
  @type between_filter :: {non_neg_integer(), non_neg_integer()} | Range.t() | nil
  @type text_match_opts :: [exact: boolean(), normalize_ws: boolean()]
  @type selector_filter_opts :: [selector: String.t() | nil]
  @type locator_leaf_opts :: [
          exact: boolean(),
          selector: String.t() | nil,
          has: locator_nested_input() | nil,
          has_not: locator_nested_input() | nil,
          from: locator_nested_input() | nil
        ]
  @type role_locator_opts :: [
          name: role_locator_name(),
          exact: boolean(),
          selector: String.t() | nil,
          has: locator_nested_input() | nil,
          has_not: locator_nested_input() | nil
        ]
  @type closest_opts :: [from: locator_nested_input()]
  @type state_filter_opts :: [
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil
        ]
  @type count_filter_opts :: [
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]
  @type locator_filter_opts :: [
          exact: boolean(),
          normalize_ws: boolean(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil,
          match_by: locator_match_by(),
          has: Cerberus.Locator.t() | nil,
          has_not: Cerberus.Locator.t() | nil
        ]
  @type path_match_opts :: [exact: boolean()]
  @type visit_opts :: []
  @type reload_opts :: visit_opts()
  @type session_common_opts :: [
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          assert_timeout_ms: non_neg_integer()
        ]
  @type browser_override_opts :: [
          viewport: {pos_integer(), pos_integer()} | %{width: pos_integer(), height: pos_integer()} | keyword() | nil,
          user_agent: String.t() | nil,
          popup_mode: :allow | :same_tab | nil,
          init_script: String.t() | nil,
          init_scripts: [String.t()] | nil,
          ready_timeout_ms: pos_integer() | nil,
          ready_quiet_ms: pos_integer() | nil,
          screenshot_full_page: boolean() | nil,
          screenshot_artifact_dir: String.t() | nil,
          screenshot_path: String.t() | nil,
          bidi_command_timeout_ms: pos_integer() | nil,
          runtime_http_timeout_ms: pos_integer() | nil,
          dialog_timeout_ms: pos_integer() | nil,
          webdriver_url: String.t() | nil,
          chrome_webdriver_url: String.t() | nil,
          firefox_webdriver_url: String.t() | nil,
          browser_name: :chrome | :firefox | nil,
          headless: boolean() | nil,
          slow_mo: non_neg_integer() | nil,
          chrome_binary: String.t() | nil,
          firefox_binary: String.t() | nil,
          chromedriver_binary: String.t() | nil,
          geckodriver_binary: String.t() | nil,
          chrome_startup_retries: non_neg_integer() | nil,
          chromedriver_log_path: String.t() | nil,
          startup_log_tail_bytes: non_neg_integer() | nil,
          startup_log_tail_lines: non_neg_integer() | nil
        ]
  @type session_browser_opts :: [
          endpoint: module(),
          conn: Plug.Conn.t() | nil,
          assert_timeout_ms: non_neg_integer(),
          ready_timeout_ms: pos_integer(),
          ready_quiet_ms: pos_integer(),
          user_agent: String.t() | nil,
          sandbox_metadata: String.t() | nil,
          browser: browser_override_opts(),
          browser_name: :chrome | :firefox,
          webdriver_url: String.t() | nil,
          chrome_webdriver_url: String.t() | nil,
          firefox_webdriver_url: String.t() | nil,
          chrome_binary: String.t() | nil,
          firefox_binary: String.t() | nil,
          chromedriver_binary: String.t() | nil,
          geckodriver_binary: String.t() | nil,
          chrome_args: [String.t()] | nil,
          firefox_args: [String.t()] | nil,
          headless: boolean() | nil,
          slow_mo: non_neg_integer() | nil,
          chromedriver_port: pos_integer() | nil,
          chrome_startup_retries: non_neg_integer() | nil,
          chromedriver_log_path: String.t() | nil,
          startup_log_tail_bytes: non_neg_integer() | nil,
          startup_log_tail_lines: non_neg_integer() | nil,
          base_url: String.t() | nil
        ]

  @type click_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type assert_opts :: [
          visible: visibility_filter(),
          timeout: non_neg_integer(),
          match_by: locator_match_by() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter()
        ]

  @type fill_in_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type check_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type select_opts :: [
          option: select_value(),
          exact_option: boolean(),
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type choose_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type upload_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type submit_opts :: [
          timeout: non_neg_integer(),
          selector: String.t() | nil,
          checked: boolean() | nil,
          disabled: boolean() | nil,
          selected: boolean() | nil,
          readonly: boolean() | nil,
          count: non_neg_integer() | nil,
          min: non_neg_integer() | nil,
          max: non_neg_integer() | nil,
          between: between_filter(),
          first: boolean(),
          last: boolean(),
          nth: pos_integer() | nil,
          index: non_neg_integer() | nil
        ]

  @type screenshot_opts :: [
          path: String.t() | nil,
          full_page: boolean()
        ]

  @type path_query :: map() | keyword() | nil
  @type path_opts :: [
          exact: boolean(),
          query: path_query(),
          timeout: non_neg_integer()
        ]

  @type browser_selector_opts :: [selector: String.t() | nil]

  @type browser_type_opts :: [
          selector: String.t() | nil,
          clear: boolean(),
          timeout: non_neg_integer()
        ]

  @type browser_press_opts :: [
          selector: String.t() | nil,
          timeout: non_neg_integer()
        ]

  @type browser_drag_opts :: [
          timeout: non_neg_integer()
        ]

  @type assert_download_opts :: [
          timeout: pos_integer()
        ]

  @type browser_assert_dialog_opts :: [
          timeout: pos_integer(),
          browser: keyword()
        ]

  @type browser_with_popup_opts :: [
          timeout: pos_integer()
        ]

  @type cookie_same_site_opt :: :strict | :lax | :none | String.t()

  @type browser_add_cookie_opts :: [
          domain: String.t(),
          path: String.t(),
          http_only: boolean(),
          secure: boolean(),
          same_site: cookie_same_site_opt()
        ]

  @click_opts_schema [
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."],
    selector: [type: :any, default: nil, doc: "Limits matching to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched elements to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched elements to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched elements to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched elements to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @assert_opts_schema [
    visible: [
      type: {:in, [true, false, :any]},
      default: true,
      doc: "Chooses visible text only, hidden only, or both."
    ],
    match_by: [
      type: {:in, [nil, :text, :label, :link, :button, :placeholder, :title, :alt, :aria_label, :testid]},
      default: nil,
      doc: "Chooses which attribute/source to match against for text assertions."
    ],
    timeout: [
      type: :non_neg_integer,
      default: 0,
      doc: "Retries text assertions for up to this many milliseconds."
    ],
    count: [type: :any, default: nil, doc: "Requires exactly this many text matches."],
    min: [type: :any, default: nil, doc: "Requires at least this many text matches."],
    max: [type: :any, default: nil, doc: "Requires at most this many text matches."],
    between: [type: :any, default: nil, doc: "Requires text match count to fall within an inclusive range."]
  ]

  @fill_in_opts_schema [
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."],
    selector: [type: :any, default: nil, doc: "Limits field lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched fields to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched fields to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched fields to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched fields to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @submit_opts_schema [
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."],
    selector: [
      type: :any,
      default: nil,
      doc: "Limits submit control lookup to elements that satisfy the CSS selector."
    ],
    checked: [type: :any, default: nil, doc: "Requires matched submit controls to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched submit controls to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched submit controls to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched submit controls to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @upload_opts_schema [
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."],
    selector: [type: :any, default: nil, doc: "Limits file-input lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched file inputs to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched file inputs to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched file inputs to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched file inputs to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @select_opts_schema [
    option: [
      type: :any,
      required: true,
      doc:
        ~s{Text locator (`~l"..."e`/`text("...", exact: true)`) or list of text locators to select; for multi-select inputs pass all desired values on each call.}
    ],
    exact_option: [type: :boolean, default: true, doc: "Requires exact option-text matches unless disabled."],
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."],
    selector: [type: :any, default: nil, doc: "Limits select lookup to elements that satisfy the CSS selector."],
    checked: [type: :any, default: nil, doc: "Requires matched selects to be checked/unchecked."],
    disabled: [type: :any, default: nil, doc: "Requires matched selects to be disabled/enabled."],
    selected: [type: :any, default: nil, doc: "Requires matched selects to be selected/unselected."],
    readonly: [type: :any, default: nil, doc: "Requires matched selects to be readonly/editable."],
    count: [type: :any, default: nil, doc: "Requires exactly this many matched candidates."],
    min: [type: :any, default: nil, doc: "Requires at least this many matched candidates."],
    max: [type: :any, default: nil, doc: "Requires at most this many matched candidates."],
    between: [type: :any, default: nil, doc: "Requires matched candidate count to fall within an inclusive range."],
    first: [type: :boolean, default: false, doc: "Selects the first matched candidate."],
    last: [type: :boolean, default: false, doc: "Selects the last matched candidate."],
    nth: [type: :any, default: nil, doc: "Selects the nth (1-based) matched candidate."],
    index: [type: :any, default: nil, doc: "Selects the index (0-based) matched candidate."]
  ]

  @path_opts_schema [
    exact: [type: :boolean, default: true, doc: "Requires an exact path match unless disabled."],
    query: [
      type: :any,
      default: nil,
      doc: "Optionally validates query params as a subset map/keyword."
    ],
    timeout: [
      type: :non_neg_integer,
      default: 0,
      doc: "Retries path assertions for up to this many milliseconds."
    ]
  ]

  @screenshot_opts_schema [
    path: [type: :any, default: nil, doc: "Optional file path for the screenshot output."],
    full_page: [type: :boolean, doc: "Captures the full document instead of only the viewport."]
  ]

  @session_common_opts_schema [
    endpoint: [type: :any, doc: "Endpoint module override."],
    conn: [type: :any, doc: "Seed Plug.Conn for session state."],
    assert_timeout_ms: [type: :non_neg_integer, doc: "Default assertion timeout in milliseconds."]
  ]

  @session_browser_opts_schema [
    endpoint: [type: :any, doc: "Endpoint module override."],
    conn: [type: :any, doc: "Seed Plug.Conn for browser session state."],
    assert_timeout_ms: [type: :non_neg_integer, doc: "Default assertion timeout in milliseconds."],
    ready_timeout_ms: [type: :pos_integer, doc: "Browser readiness timeout in milliseconds."],
    ready_quiet_ms: [type: :pos_integer, doc: "Browser readiness quiet window in milliseconds."],
    user_agent: [type: :any, doc: "Top-level user-agent override for browser session context."],
    sandbox_metadata: [type: :any, doc: "Optional sandbox metadata user-agent marker."],
    browser: [type: :keyword_list, doc: "Per-session browser overrides."],
    browser_name: [type: {:in, [:chrome, :firefox]}, doc: "Browser lane selector."],
    webdriver_url: [type: :any, doc: "Remote WebDriver URL."],
    chrome_webdriver_url: [type: :any, doc: "Remote Chrome WebDriver URL."],
    firefox_webdriver_url: [type: :any, doc: "Remote Firefox WebDriver URL."],
    chrome_binary: [type: :any, doc: "Chrome binary path override."],
    firefox_binary: [type: :any, doc: "Firefox binary path override."],
    chromedriver_binary: [type: :any, doc: "ChromeDriver binary path override."],
    geckodriver_binary: [type: :any, doc: "GeckoDriver binary path override."],
    chrome_args: [type: :any, doc: "Additional Chrome launch arguments."],
    firefox_args: [type: :any, doc: "Additional Firefox launch arguments."],
    headless: [type: :boolean, doc: "Headless browser toggle."],
    slow_mo: [type: :non_neg_integer, doc: "Delay in milliseconds applied before each browser BiDi command."],
    chromedriver_port: [type: :pos_integer, doc: "ChromeDriver port override."],
    chrome_startup_retries: [type: :non_neg_integer, doc: "Chrome startup retry count."],
    chromedriver_log_path: [type: :any, doc: "ChromeDriver log file path."],
    startup_log_tail_bytes: [type: :non_neg_integer, doc: "Startup log tail byte limit."],
    startup_log_tail_lines: [type: :non_neg_integer, doc: "Startup log tail line limit."],
    base_url: [type: :any, doc: "Base URL override for remote runtime."]
  ]

  @browser_override_opts_schema [
    viewport: [type: :any, doc: "Viewport override."],
    user_agent: [type: :any, doc: "User agent override."],
    popup_mode: [type: {:in, [:allow, :same_tab]}, doc: "Popup behavior mode."],
    init_script: [type: :any, doc: "Single preload script."],
    init_scripts: [type: :any, doc: "Multiple preload scripts."],
    ready_timeout_ms: [type: :pos_integer, doc: "Browser readiness timeout in milliseconds."],
    ready_quiet_ms: [type: :pos_integer, doc: "Browser readiness quiet window in milliseconds."],
    screenshot_full_page: [type: :boolean, doc: "Full-page screenshot default."],
    screenshot_artifact_dir: [type: :any, doc: "Screenshot artifact directory."],
    screenshot_path: [type: :any, doc: "Default screenshot file path."],
    bidi_command_timeout_ms: [type: :pos_integer, doc: "BiDi command timeout in milliseconds."],
    runtime_http_timeout_ms: [type: :pos_integer, doc: "Runtime HTTP timeout in milliseconds."],
    dialog_timeout_ms: [type: :pos_integer, doc: "Dialog lifecycle timeout in milliseconds."],
    webdriver_url: [type: :any, doc: "Remote WebDriver URL."],
    chrome_webdriver_url: [type: :any, doc: "Remote Chrome WebDriver URL."],
    firefox_webdriver_url: [type: :any, doc: "Remote Firefox WebDriver URL."],
    browser_name: [type: {:in, [:chrome, :firefox]}, doc: "Browser lane selector."],
    headless: [type: :boolean, doc: "Headless browser toggle."],
    slow_mo: [type: :non_neg_integer, doc: "Delay in milliseconds applied before each browser BiDi command."],
    chrome_binary: [type: :any, doc: "Chrome binary path override."],
    firefox_binary: [type: :any, doc: "Firefox binary path override."],
    chromedriver_binary: [type: :any, doc: "ChromeDriver binary path override."],
    geckodriver_binary: [type: :any, doc: "GeckoDriver binary path override."],
    chrome_args: [type: :any, doc: "Additional Chrome launch arguments."],
    firefox_args: [type: :any, doc: "Additional Firefox launch arguments."],
    chrome_startup_retries: [type: :non_neg_integer, doc: "Chrome startup retry count."],
    chromedriver_log_path: [type: :any, doc: "ChromeDriver log file path."],
    startup_log_tail_bytes: [type: :non_neg_integer, doc: "Startup log tail byte limit."],
    startup_log_tail_lines: [type: :non_neg_integer, doc: "Startup log tail line limit."]
  ]

  @browser_type_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits typing target to elements that satisfy the CSS selector."],
    clear: [type: :boolean, default: false, doc: "Clears the field before typing."],
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."]
  ]

  @browser_press_opts_schema [
    selector: [type: :any, default: nil, doc: "Limits keypress target to elements that satisfy the CSS selector."],
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."]
  ]

  @browser_drag_opts_schema [
    timeout: [type: :non_neg_integer, doc: "Browser action timeout in milliseconds."]
  ]

  @assert_download_opts_schema [
    timeout: [type: :pos_integer, default: 1_500, doc: "Wait timeout in milliseconds for download detection."]
  ]

  @browser_assert_dialog_opts_schema [
    timeout: [type: :pos_integer, doc: "Wait timeout in milliseconds for dialog lifecycle events."],
    browser: [type: :keyword_list, default: [], doc: "Per-call browser config overrides used for timeout defaults."]
  ]

  @browser_with_popup_opts_schema [
    timeout: [type: :pos_integer, default: 1_500, doc: "Wait timeout in milliseconds for popup capture."]
  ]

  @browser_add_cookie_opts_schema [
    domain: [type: :any, default: nil, doc: "Cookie domain override."],
    path: [type: :any, default: "/", doc: "Cookie path override."],
    http_only: [type: :boolean, default: false, doc: "Marks cookie as HttpOnly."],
    secure: [type: :boolean, default: false, doc: "Marks cookie as Secure."],
    same_site: [type: :any, default: :lax, doc: "Cookie sameSite policy (:strict, :lax, :none)."]
  ]

  @spec click_schema() :: keyword()
  def click_schema, do: @click_opts_schema

  @spec assert_schema() :: keyword()
  def assert_schema, do: @assert_opts_schema

  @spec fill_in_schema() :: keyword()
  def fill_in_schema, do: @fill_in_opts_schema

  @spec submit_schema() :: keyword()
  def submit_schema, do: @submit_opts_schema

  @spec upload_schema() :: keyword()
  def upload_schema, do: @upload_opts_schema

  @spec select_schema() :: keyword()
  def select_schema, do: @select_opts_schema

  @spec path_schema() :: keyword()
  def path_schema, do: @path_opts_schema

  @spec screenshot_schema() :: keyword()
  def screenshot_schema, do: @screenshot_opts_schema

  @spec browser_type_schema() :: keyword()
  def browser_type_schema, do: @browser_type_opts_schema

  @spec browser_press_schema() :: keyword()
  def browser_press_schema, do: @browser_press_opts_schema

  @spec browser_drag_schema() :: keyword()
  def browser_drag_schema, do: @browser_drag_opts_schema

  @spec assert_download_schema() :: keyword()
  def assert_download_schema, do: @assert_download_opts_schema

  @spec browser_assert_dialog_schema() :: keyword()
  def browser_assert_dialog_schema, do: @browser_assert_dialog_opts_schema

  @spec browser_with_popup_schema() :: keyword()
  def browser_with_popup_schema, do: @browser_with_popup_opts_schema

  @spec browser_add_cookie_schema() :: keyword()
  def browser_add_cookie_schema, do: @browser_add_cookie_opts_schema

  @spec session_common_schema() :: keyword()
  def session_common_schema, do: @session_common_opts_schema

  @spec session_browser_schema() :: keyword()
  def session_browser_schema, do: @session_browser_opts_schema

  @spec browser_override_schema() :: keyword()
  def browser_override_schema, do: @browser_override_opts_schema

  @spec validate_click!(keyword()) :: click_opts()
  def validate_click!(opts) do
    opts
    |> validate!(@click_opts_schema, "click/3")
    |> validate_selector!("click/3")
    |> validate_state_filters!("click/3")
    |> validate_match_filters!("click/3", true)
  end

  @spec validate_assert!(keyword(), String.t()) :: assert_opts()
  def validate_assert!(opts, op_name),
    do: opts |> validate!(@assert_opts_schema, op_name) |> validate_match_filters!(op_name, false)

  @spec validate_fill_in!(keyword()) :: fill_in_opts()
  def validate_fill_in!(opts) do
    opts
    |> validate!(@fill_in_opts_schema, "fill_in/4")
    |> validate_selector!("fill_in/4")
    |> validate_state_filters!("fill_in/4")
    |> validate_match_filters!("fill_in/4", true)
  end

  @spec validate_check!(keyword(), String.t()) :: check_opts()
  def validate_check!(opts, op_name) do
    opts
    |> validate!(@fill_in_opts_schema, op_name)
    |> validate_selector!(op_name)
    |> validate_state_filters!(op_name)
    |> validate_match_filters!(op_name, true)
  end

  @spec validate_choose!(keyword(), String.t()) :: choose_opts()
  def validate_choose!(opts, op_name) do
    opts
    |> validate!(@fill_in_opts_schema, op_name)
    |> validate_selector!(op_name)
    |> validate_state_filters!(op_name)
    |> validate_match_filters!(op_name, true)
  end

  @spec validate_select!(keyword()) :: select_opts()
  def validate_select!(opts) do
    opts
    |> validate!(@select_opts_schema, "select/3")
    |> validate_selector!("select/3")
    |> validate_state_filters!("select/3")
    |> validate_match_filters!("select/3", true)
    |> validate_select_option!("select/3")
  end

  @spec validate_submit!(keyword()) :: submit_opts()
  def validate_submit!(opts) do
    opts
    |> validate!(@submit_opts_schema, "submit/3")
    |> validate_selector!("submit/3")
    |> validate_state_filters!("submit/3")
    |> validate_match_filters!("submit/3", true)
  end

  @spec validate_upload!(keyword()) :: upload_opts()
  def validate_upload!(opts) do
    opts
    |> validate!(@upload_opts_schema, "upload/4")
    |> validate_selector!("upload/4")
    |> validate_state_filters!("upload/4")
    |> validate_match_filters!("upload/4", true)
  end

  @spec validate_path!(keyword(), String.t()) :: path_opts()
  def validate_path!(opts, op_name) do
    validated = validate!(opts, @path_opts_schema, op_name)
    query = Keyword.get(validated, :query)

    cond do
      is_nil(query) ->
        validated

      is_map(query) ->
        validated

      Keyword.keyword?(query) ->
        validated

      is_list(query) and Enum.all?(query, &match?({_, _}, &1)) ->
        validated

      true ->
        raise ArgumentError,
              "#{op_name} invalid options: :query must be a map, keyword list, or nil"
    end
  end

  @spec validate_screenshot!(keyword()) :: screenshot_opts()
  def validate_screenshot!(opts) do
    opts
    |> validate!(@screenshot_opts_schema, "screenshot/2")
    |> validate_path_string!("screenshot/2", :path)
  end

  @spec validate_browser_type!(keyword()) :: browser_type_opts()
  def validate_browser_type!(opts) do
    opts
    |> validate!(@browser_type_opts_schema, "Browser.type/3")
    |> validate_selector!("Browser.type/3")
  end

  @spec validate_browser_press!(keyword()) :: browser_press_opts()
  def validate_browser_press!(opts) do
    opts
    |> validate!(@browser_press_opts_schema, "Browser.press/3")
    |> validate_selector!("Browser.press/3")
  end

  @spec validate_browser_drag!(keyword()) :: browser_drag_opts()
  def validate_browser_drag!(opts) do
    validate!(opts, @browser_drag_opts_schema, "Browser.drag/4")
  end

  @spec validate_assert_download!(keyword()) :: assert_download_opts()
  def validate_assert_download!(opts) do
    validate!(opts, @assert_download_opts_schema, "assert_download/3")
  end

  @spec validate_browser_assert_dialog!(keyword()) :: browser_assert_dialog_opts()
  def validate_browser_assert_dialog!(opts) do
    validate!(opts, @browser_assert_dialog_opts_schema, "Browser.assert_dialog/3")
  end

  @spec validate_browser_with_popup!(keyword()) :: browser_with_popup_opts()
  def validate_browser_with_popup!(opts) do
    validate!(opts, @browser_with_popup_opts_schema, "Browser.with_popup/4")
  end

  @spec validate_browser_add_cookie!(keyword()) :: browser_add_cookie_opts()
  def validate_browser_add_cookie!(opts) do
    opts
    |> validate!(@browser_add_cookie_opts_schema, "Browser.add_cookie/4")
    |> validate_optional_string!("Browser.add_cookie/4", :domain)
    |> validate_optional_string!("Browser.add_cookie/4", :path)
    |> validate_cookie_same_site!("Browser.add_cookie/4")
  end

  @spec validate_session_common!(keyword()) :: session_common_opts()
  def validate_session_common!(opts) do
    opts
    |> validate_known!(@session_common_opts_schema, "session/1")
    |> validate_optional_module_atom!("session/1", :endpoint)
    |> validate_optional_conn!("session/1", :conn)
  end

  @spec validate_session_browser!(keyword()) :: session_browser_opts()
  def validate_session_browser!(opts) do
    opts
    |> validate_known!(@session_browser_opts_schema, "session(:browser, opts)")
    |> validate_optional_module_atom!("session(:browser, opts)", :endpoint)
    |> validate_optional_conn!("session(:browser, opts)", :conn)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :user_agent)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :sandbox_metadata)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :webdriver_url)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :chrome_webdriver_url)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :firefox_webdriver_url)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :chrome_binary)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :firefox_binary)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :chromedriver_binary)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :geckodriver_binary)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :chromedriver_log_path)
    |> validate_optional_non_empty_string!("session(:browser, opts)", :base_url)
    |> validate_optional_string_list!("session(:browser, opts)", :chrome_args)
    |> validate_optional_string_list!("session(:browser, opts)", :firefox_args)
    |> validate_browser_override!("session(:browser, opts)")
  end

  defp validate!(opts, schema, op_name) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{} = error} ->
        raise ArgumentError, "#{op_name} invalid options: #{Exception.message(error)}"
    end
  end

  defp validate_known!(opts, schema, op_name) do
    keys = Keyword.keys(schema)
    known_opts = Keyword.take(opts, keys)
    validated_known_opts = validate!(known_opts, schema, op_name)

    opts
    |> Keyword.drop(keys)
    |> Keyword.merge(validated_known_opts)
  end

  defp validate_selector!(opts, op_name) do
    case Keyword.get(opts, :selector) do
      nil ->
        opts

      selector when is_binary(selector) ->
        if String.trim(selector) == "" do
          raise ArgumentError, "#{op_name} invalid options: :selector must be a non-empty CSS selector string"
        else
          opts
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :selector must be a non-empty CSS selector string"
    end
  end

  defp validate_path_string!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      path when is_binary(path) ->
        if String.trim(path) == "" do
          raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string path"
        else
          opts
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string path"
    end
  end

  defp validate_optional_string!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_binary(value) ->
        if String.trim(value) == "" do
          raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string"
        else
          opts
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a non-empty string or nil"
    end
  end

  defp validate_optional_non_empty_string!(opts, op_name, key), do: validate_optional_string!(opts, op_name, key)

  defp validate_optional_module_atom!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_atom(value) ->
        opts

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a module atom or nil"
    end
  end

  defp validate_optional_conn!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      %Plug.Conn{} ->
        opts

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a Plug.Conn struct or nil"
    end
  end

  defp validate_optional_string_list!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      values when is_list(values) ->
        if Enum.all?(values, &(is_binary(&1) and String.trim(&1) != "")) do
          opts
        else
          raise ArgumentError, "#{op_name} invalid options: :#{key} must be a list of non-empty strings"
        end

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a list of non-empty strings or nil"
    end
  end

  defp validate_browser_override!(opts, op_name) do
    case Keyword.get(opts, :browser) do
      nil ->
        opts

      browser_opts when is_list(browser_opts) ->
        browser_opts
        |> validate_known!(@browser_override_opts_schema, op_name)
        |> validate_optional_non_empty_string!(op_name, :user_agent)
        |> validate_optional_non_empty_string!(op_name, :init_script)
        |> validate_optional_non_empty_string!(op_name, :screenshot_artifact_dir)
        |> validate_optional_non_empty_string!(op_name, :screenshot_path)
        |> validate_optional_non_empty_string!(op_name, :webdriver_url)
        |> validate_optional_non_empty_string!(op_name, :chrome_webdriver_url)
        |> validate_optional_non_empty_string!(op_name, :firefox_webdriver_url)
        |> validate_optional_non_empty_string!(op_name, :chrome_binary)
        |> validate_optional_non_empty_string!(op_name, :firefox_binary)
        |> validate_optional_non_empty_string!(op_name, :chromedriver_binary)
        |> validate_optional_non_empty_string!(op_name, :geckodriver_binary)
        |> validate_optional_non_empty_string!(op_name, :chromedriver_log_path)
        |> validate_optional_string_list!(op_name, :init_scripts)
        |> validate_optional_string_list!(op_name, :chrome_args)
        |> validate_optional_string_list!(op_name, :firefox_args)

        opts

      _other ->
        raise ArgumentError, "#{op_name} invalid options: :browser must be a keyword list or nil"
    end
  end

  defp validate_cookie_same_site!(opts, op_name) do
    case Keyword.get(opts, :same_site) do
      same_site when same_site in [:strict, :lax, :none, "strict", "lax", "none"] ->
        opts

      other ->
        raise ArgumentError,
              "#{op_name} invalid options: :same_site must be one of :strict, :lax, :none, \"strict\", \"lax\", or \"none\" (got #{inspect(other)})"
    end
  end

  defp validate_state_filters!(opts, op_name) do
    opts
    |> validate_boolean_or_nil_opt!(op_name, :checked)
    |> validate_boolean_or_nil_opt!(op_name, :disabled)
    |> validate_boolean_or_nil_opt!(op_name, :selected)
    |> validate_boolean_or_nil_opt!(op_name, :readonly)
  end

  defp validate_boolean_or_nil_opt!(opts, op_name, key) do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_boolean(value) ->
        opts

      _ ->
        raise ArgumentError, "#{op_name} invalid options: :#{key} must be a boolean or nil"
    end
  end

  defp validate_select_option!(opts, op_name) do
    case Keyword.get(opts, :option) do
      option when is_binary(option) ->
        if String.trim(option) == "" do
          raise ArgumentError,
                "#{op_name} invalid options: :option must be a non-empty string or list of non-empty strings"
        else
          opts
        end

      [_ | _] = options ->
        if Enum.all?(options, &(is_binary(&1) and String.trim(&1) != "")) do
          opts
        else
          raise ArgumentError,
                "#{op_name} invalid options: :option list must contain only non-empty strings"
        end

      [] ->
        raise ArgumentError, "#{op_name} invalid options: :option list must contain at least one value"

      _ ->
        raise ArgumentError, "#{op_name} invalid options: :option must be a non-empty string or list of non-empty strings"
    end
  end

  defp validate_match_filters!(opts, op_name, allow_position?) do
    opts
    |> validate_non_neg_integer_opt!(op_name, :count)
    |> validate_non_neg_integer_opt!(op_name, :min)
    |> validate_non_neg_integer_opt!(op_name, :max)
    |> validate_between_opt!(op_name)
    |> validate_position_opts!(op_name, allow_position?)
  end

  defp validate_non_neg_integer_opt!(opts, op_name, key) when key in [:count, :min, :max] do
    case Keyword.get(opts, key) do
      nil ->
        opts

      value when is_integer(value) and value >= 0 ->
        opts

      _ ->
        raise ArgumentError, key_error_prefix(op_name, key)
    end
  end

  defp validate_between_opt!(opts, op_name) do
    case normalize_between_value(Keyword.get(opts, :between), op_name) do
      nil -> opts
      {min, max} -> Keyword.put(opts, :between, {min, max})
    end
  end

  defp normalize_between_value(nil, _op_name), do: nil

  defp normalize_between_value(%Range{first: first, last: last, step: step}, op_name)
       when is_integer(first) and is_integer(last) and is_integer(step) do
    if first >= 0 and last >= 0 and first <= last and step == 1 do
      {first, last}
    else
      raise ArgumentError,
            "#{op_name} invalid options: :between must be an inclusive ascending range with non-negative bounds"
    end
  end

  defp normalize_between_value({min, max}, _op_name)
       when is_integer(min) and is_integer(max) and min >= 0 and max >= 0 and min <= max do
    {min, max}
  end

  defp normalize_between_value(_other, op_name) do
    raise ArgumentError,
          "#{op_name} invalid options: :between must be a {min, max} tuple or range with non-negative inclusive bounds"
  end

  defp validate_position_opts!(opts, op_name, allow_position?) do
    first = Keyword.get(opts, :first, false)
    last = Keyword.get(opts, :last, false)
    nth = Keyword.get(opts, :nth)
    index = Keyword.get(opts, :index)

    validate_boolean_opt!(op_name, :first, first)
    validate_boolean_opt!(op_name, :last, last)
    validate_nth_opt!(op_name, nth)
    validate_index_opt!(op_name, index)

    active_positions = active_position_filters(first, last, nth, index)
    validate_position_filter_usage!(op_name, allow_position?, active_positions)

    opts
  end

  defp validate_boolean_opt!(op_name, key, value) do
    if not is_boolean(value) do
      raise ArgumentError, "#{op_name} invalid options: :#{key} must be a boolean"
    end
  end

  defp validate_nth_opt!(op_name, nth) do
    if not is_nil(nth) and not (is_integer(nth) and nth > 0) do
      raise ArgumentError, "#{op_name} invalid options: :nth must be a positive integer or nil"
    end
  end

  defp validate_index_opt!(op_name, index) do
    if not is_nil(index) and not (is_integer(index) and index >= 0) do
      raise ArgumentError, "#{op_name} invalid options: :index must be a non-negative integer or nil"
    end
  end

  defp active_position_filters(first, last, nth, index) do
    []
    |> maybe_add_position_flag(:first, first)
    |> maybe_add_position_flag(:last, last)
    |> maybe_add_position_flag(:nth, nth)
    |> maybe_add_position_flag(:index, index)
  end

  defp validate_position_filter_usage!(_op_name, true, []), do: :ok

  defp validate_position_filter_usage!(op_name, false, active_positions) when active_positions != [] do
    raise ArgumentError,
          "#{op_name} invalid options: position filters (:first/:last/:nth/:index) are not supported for this operation"
  end

  defp validate_position_filter_usage!(op_name, _allow_position?, active_positions) when length(active_positions) > 1 do
    raise ArgumentError,
          "#{op_name} invalid options: position filters are mutually exclusive; use only one of :first, :last, :nth, or :index"
  end

  defp validate_position_filter_usage!(_op_name, _allow_position?, _active_positions), do: :ok

  defp maybe_add_position_flag(acc, _name, false), do: acc
  defp maybe_add_position_flag(acc, _name, nil), do: acc
  defp maybe_add_position_flag(acc, name, _value), do: acc ++ [name]

  defp key_error_prefix(op_name, key) do
    "#{op_name} invalid options: :#{key} must be a non-negative integer or nil"
  end
end
