defmodule Cerberus do
  @moduledoc """
  Public session-first facade for Cerberus drivers.

  This module validates option schemas, normalizes locator inputs, and dispatches
  operations to static/live/browser session implementations while preserving a
  consistent API shape.

  Technical guarantees:
  - Public operations accept and return `Cerberus.Session` structs.
  - Locator-based operations keep `session` first and support locator composition forms.
  - Path and assertion operations resolve timeout defaults per driver.
  - Profiling buckets are emitted per operation and driver kind.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Profiling
  alias Cerberus.Session

  @session_common_options_doc NimbleOptions.docs(Options.session_common_schema())
  @session_browser_options_doc NimbleOptions.docs(Options.session_browser_schema())
  @path_options_doc NimbleOptions.docs(Options.path_schema())
  @assert_download_options_doc NimbleOptions.docs(Options.assert_download_schema())
  @click_options_doc NimbleOptions.docs(Options.click_schema())
  @fill_in_options_doc NimbleOptions.docs(Options.fill_in_schema())
  @submit_options_doc NimbleOptions.docs(Options.submit_schema())
  @upload_options_doc NimbleOptions.docs(Options.upload_schema())
  @select_options_doc NimbleOptions.docs(Options.select_schema())
  @assert_options_doc NimbleOptions.docs(Options.assert_schema())
  @assert_value_options_doc NimbleOptions.docs(Options.assert_value_schema())
  @return_result_options_doc NimbleOptions.docs(Options.return_result_schema())

  @doc """
  Starts a default non-browser (`:phoenix`) session with default options.
  """
  @spec session() :: Session.t()
  def session, do: session([])

  @doc """
  Starts a non-browser (`:phoenix`) session.

  This arity also accepts `Plug.Conn` and driver atoms:

  - `session(conn)` seeds the new session from an existing conn.
  - `session(:phoenix)` starts non-browser mode.
  - `session(:browser | :chrome | :firefox)` starts browser mode with defaults.

  ## Options

  #{@session_common_options_doc}
  """
  @spec session(Options.session_common_opts()) :: Session.t()
  def session(opts) when is_list(opts) do
    opts
    |> Options.validate_session_common!()
    |> StaticSession.new_session()
  end

  @spec session(Plug.Conn.t()) :: Session.t()
  def session(%Plug.Conn{} = conn), do: session(conn: conn)

  @spec session(:phoenix) :: Session.t()
  def session(:phoenix), do: session([])

  @spec session(:browser) :: Session.t()
  def session(:browser), do: session(:browser, [])

  @spec session(:chrome) :: Session.t()
  def session(:chrome), do: session(:chrome, [])

  @spec session(:firefox) :: Session.t()
  def session(:firefox), do: session(:firefox, [])

  def session(driver) when is_atom(driver) do
    raise ArgumentError,
          "unsupported public driver #{inspect(driver)}; use session()/session(:phoenix) for non-browser and session(:browser|:chrome|:firefox) for browser"
  end

  @spec session(:phoenix, Options.session_common_opts()) :: Session.t()
  def session(:phoenix, opts) when is_list(opts), do: session(opts)

  @doc """
  Starts a browser session.

  Browser context defaults can be configured globally via `config :cerberus, :browser`
  and overridden per session with:

  - `user_agent: "..."`
  - `browser: [viewport: [width: ..., height: ...] | {w, h}]`
  - `browser: [user_agent: "..."]`
  - `browser: [popup_mode: :allow | :same_tab]` to control `window.open` behavior
    (`:same_tab` is currently unsupported on Firefox)
  - `browser: [init_script: "..."]` or `browser: [init_scripts: ["...", ...]]`
  - `webdriver_url: "http://remote-webdriver:4444"` to use a remote WebDriver endpoint
    without local browser/chromedriver launch.

  ## Options

  #{@session_browser_options_doc}
  """
  @spec session(:browser, Options.session_browser_opts()) :: Session.t()
  def session(:browser, opts) when is_list(opts) do
    new_browser_session(opts)
  end

  @spec session(:chrome, Options.session_browser_opts()) :: Session.t()
  def session(:chrome, opts) when is_list(opts) do
    new_browser_session(opts, :chrome)
  end

  @spec session(:firefox, Options.session_browser_opts()) :: Session.t()
  def session(:firefox, opts) when is_list(opts) do
    new_browser_session(opts, :firefox)
  end

  def session(driver, opts) when is_atom(driver) and is_list(opts) do
    raise ArgumentError,
          "unsupported public driver #{inspect(driver)}; use session()/session(:phoenix) for non-browser and session(:browser|:chrome|:firefox) for browser"
  end

  defp new_browser_session(opts, browser_name \\ nil) when is_list(opts) do
    opts =
      opts
      |> Options.validate_session_browser!()
      |> maybe_put_browser_name(browser_name)

    BrowserSession.new_session(opts)
  end

  defp maybe_put_browser_name(opts, nil), do: opts

  defp maybe_put_browser_name(opts, browser_name) when is_atom(browser_name),
    do: Keyword.put(opts, :browser_name, browser_name)

  @doc """
  Opens a new tab for browser sessions and returns the updated session.
  """
  @spec open_tab(arg) :: arg when arg: var
  def open_tab(session), do: dispatch_tab_operation!(session, :open_tab)

  @doc """
  Switches the active tab to `target_session` for browser sessions.
  """
  @spec switch_tab(Session.t(), Session.t()) :: Session.t()
  def switch_tab(session, target_session), do: dispatch_tab_operation!(session, :switch_tab, [target_session])

  @doc """
  Closes the current tab for browser sessions.
  """
  @spec close_tab(arg) :: arg when arg: var
  def close_tab(session), do: dispatch_tab_operation!(session, :close_tab)

  @doc """
  Executes a callback with driver-native escape-hatch data.

  Browser sessions receive a constrained `Cerberus.Browser.Native` handle.
  Prefer public Cerberus operations and `Cerberus.Browser.*` helpers for stable flows.
  """
  @spec unwrap(arg, (term() -> term())) :: arg when arg: var
  def unwrap(_session, fun) when not is_function(fun, 1) do
    raise ArgumentError, "unwrap/2 expects a callback with arity 1"
  end

  def unwrap(session, fun) do
    driver_module_for_session!(session).unwrap(session, fun)
  end

  @doc """
  Writes the current rendered page snapshot to a temporary HTML file and opens it.

  This is primarily useful for human debugging because it lets you inspect the
  rendered page in a real browser tab.

  For callback-based DOM inspection in-process (for example, by AI tooling), see
  `render_html/2`.
  """
  @spec open_browser(arg) :: arg when arg: var
  def open_browser(session), do: open_browser(session, &OpenBrowser.open_with_system_cmd/1)

  @doc false
  @spec open_browser(arg, (String.t() -> term())) :: arg when arg: var
  def open_browser(session, open_fun) when is_function(open_fun, 1) do
    driver_module_for_session!(session).open_browser(session, open_fun)
  end

  def open_browser(_session, _open_fun) do
    raise ArgumentError, "open_browser/2 expects a callback with arity 1"
  end

  @doc """
  Renders the current page HTML.

  This is primarily for debugging, and can be useful for AI-assisted workflows
  that need to inspect the entire DOM tree in-process.

  Use either:
  - callback form (`render_html(session, fn lazy_html -> ... end)`) to keep piping
  - `return_result: true` (`render_html(session, return_result: true)`) to return `LazyHTML`

  For human-oriented inspection in a browser, see `open_browser/1`.

  ## Options

  #{@return_result_options_doc}
  """
  @spec render_html(arg, Options.return_result_opts()) :: arg | LazyHTML.t() when arg: var
  @spec render_html(arg, (LazyHTML.t() -> term())) :: arg when arg: var
  def render_html(session, callback_or_opts) when is_function(callback_or_opts, 1) or is_list(callback_or_opts) do
    case callback_or_opts do
      callback when is_function(callback, 1) ->
        driver_module_for_session!(session).render_html(session, callback)

      opts ->
        opts = Options.validate_return_result!(opts, "render_html/2")

        if Keyword.get(opts, :return_result, false) do
          render_html_result(session)
        else
          session
        end
    end
  end

  def render_html(_session, _callback_or_opts) do
    raise ArgumentError, "render_html/2 expects a callback with arity 1 or keyword options"
  end

  @doc """
  Builds a text locator.
  """
  @spec text(String.t() | Regex.t()) :: Locator.t()
  def text(value) when is_binary(value) or is_struct(value, Regex), do: text(value, [])

  @doc """
  Builds or composes a text locator.

  Supported forms:
  - `text(value, opts)` for a leaf locator
  - `text(locator, value)` to compose with an existing locator
  """
  @spec text(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def text(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:text, value, opts)
  end

  @spec text(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def text(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, text(value))
  end

  @doc """
  Composes a text constraint into an existing locator with locator options.
  """
  @spec text(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def text(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, text(value, opts))
  end

  @doc """
  Builds a label locator.
  """
  @spec label(String.t() | Regex.t()) :: Locator.t()
  def label(value) when is_binary(value) or is_struct(value, Regex), do: label(value, [])

  @doc """
  Builds or composes a label locator.

  Supported forms:
  - `label(value, opts)` for a leaf locator
  - `label(locator, value)` to compose with an existing locator
  """
  @spec label(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def label(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:label, value, opts)
  end

  @spec label(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def label(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, label(value))
  end

  @doc """
  Composes a label constraint into an existing locator with locator options.
  """
  @spec label(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def label(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, label(value, opts))
  end

  @doc """
  Builds a placeholder locator.
  """
  @spec placeholder(String.t() | Regex.t()) :: Locator.t()
  def placeholder(value) when is_binary(value) or is_struct(value, Regex), do: placeholder(value, [])

  @doc """
  Builds or composes a placeholder locator.

  Supported forms:
  - `placeholder(value, opts)` for a leaf locator
  - `placeholder(locator, value)` to compose with an existing locator
  """
  @spec placeholder(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def placeholder(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:placeholder, value, opts)
  end

  @spec placeholder(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def placeholder(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, placeholder(value))
  end

  @doc """
  Composes a placeholder constraint into an existing locator with locator options.
  """
  @spec placeholder(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def placeholder(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, placeholder(value, opts))
  end

  @doc """
  Builds a title locator.
  """
  @spec title(String.t() | Regex.t()) :: Locator.t()
  def title(value) when is_binary(value) or is_struct(value, Regex), do: title(value, [])

  @doc """
  Builds or composes a title locator.

  Supported forms:
  - `title(value, opts)` for a leaf locator
  - `title(locator, value)` to compose with an existing locator
  """
  @spec title(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def title(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:title, value, opts)
  end

  @spec title(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def title(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, title(value))
  end

  @doc """
  Composes a title constraint into an existing locator with locator options.
  """
  @spec title(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def title(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, title(value, opts))
  end

  @doc """
  Builds an alt-text locator.
  """
  @spec alt(String.t() | Regex.t()) :: Locator.t()
  def alt(value) when is_binary(value) or is_struct(value, Regex), do: alt(value, [])

  @doc """
  Builds or composes an alt-text locator.

  Supported forms:
  - `alt(value, opts)` for a leaf locator
  - `alt(locator, value)` to compose with an existing locator
  """
  @spec alt(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def alt(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:alt, value, opts)
  end

  @spec alt(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def alt(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, alt(value))
  end

  @doc """
  Composes an alt-text constraint into an existing locator with locator options.
  """
  @spec alt(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def alt(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, alt(value, opts))
  end

  @doc """
  Builds an `aria-label` locator.
  """
  @spec aria_label(String.t() | Regex.t()) :: Locator.t()
  def aria_label(value) when is_binary(value) or is_struct(value, Regex), do: aria_label(value, [])

  @doc """
  Builds or composes an `aria-label` locator.

  Supported forms:
  - `aria_label(value, opts)` for a leaf locator
  - `aria_label(locator, value)` to compose with an existing locator
  """
  @spec aria_label(String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def aria_label(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:aria_label, value, opts)
  end

  @spec aria_label(Locator.t(), String.t() | Regex.t()) :: Locator.t()
  def aria_label(locator, value) when is_binary(value) or is_struct(value, Regex) do
    scope(locator, aria_label(value))
  end

  @doc """
  Composes an `aria-label` constraint into an existing locator with locator options.
  """
  @spec aria_label(Locator.t(), String.t() | Regex.t(), Options.locator_leaf_opts()) :: Locator.t()
  def aria_label(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    scope(locator, aria_label(value, opts))
  end

  @doc """
  Builds a CSS locator.
  """
  @spec css(String.t()) :: Locator.t()
  def css(value) when is_binary(value), do: css(value, [])

  @doc """
  Builds or composes a CSS locator.

  Supported forms:
  - `css(value, opts)` for a leaf locator
  - `css(locator, value)` to compose with an existing locator
  """
  @spec css(String.t(), Options.locator_leaf_opts()) :: Locator.t()
  def css(value, opts) when is_binary(value) and is_list(opts) do
    Locator.leaf(:css, value, opts)
  end

  @spec css(Locator.t(), String.t()) :: Locator.t()
  def css(locator, value) when is_binary(value) do
    scope(locator, css(value))
  end

  @doc """
  Composes a CSS constraint into an existing locator with locator options.
  """
  @spec css(Locator.t(), String.t(), Options.locator_leaf_opts()) :: Locator.t()
  def css(locator, value, opts) when is_binary(value) and is_list(opts) do
    scope(locator, css(value, opts))
  end

  @doc """
  Builds a role locator.
  """
  @spec role(String.t() | atom()) :: Locator.t()
  def role(role_name) when is_binary(role_name) or is_atom(role_name), do: role(role_name, [])

  @doc """
  Builds or composes a role locator.

  Supported forms:
  - `role(role_name, opts)` for a leaf locator
  - `role(locator, role_name)` to compose with an existing locator
  """
  @spec role(String.t() | atom(), Options.role_locator_opts()) :: Locator.t()
  def role(role, opts) when (is_binary(role) or is_atom(role)) and is_list(opts) do
    Locator.role(role, opts)
  end

  @spec role(Locator.t(), String.t() | atom()) :: Locator.t()
  def role(locator, role_name) when is_binary(role_name) or is_atom(role_name) do
    scope(locator, role(role_name))
  end

  @doc """
  Composes a role constraint into an existing locator with locator options.
  """
  @spec role(Locator.t(), String.t() | atom(), Options.role_locator_opts()) :: Locator.t()
  def role(locator, role_name, opts) when (is_binary(role_name) or is_atom(role_name)) and is_list(opts) do
    scope(locator, role(role_name, opts))
  end

  @doc """
  Builds a test-id locator.
  """
  @spec testid(String.t()) :: Locator.t()
  def testid(value) when is_binary(value), do: testid(value, [])

  @doc """
  Builds or composes a test-id locator.

  Supported forms:
  - `testid(value, opts)` for a leaf locator
  - `testid(locator, value)` to compose with an existing locator
  """
  @spec testid(String.t(), Options.locator_leaf_opts()) :: Locator.t()
  def testid(value, opts) when is_binary(value) and is_list(opts) do
    Locator.leaf(:testid, value, opts)
  end

  @spec testid(Locator.t(), String.t()) :: Locator.t()
  def testid(locator, value) when is_binary(value) do
    scope(locator, testid(value))
  end

  @doc """
  Composes a test-id constraint into an existing locator with locator options.
  """
  @spec testid(Locator.t(), String.t(), Options.locator_leaf_opts()) :: Locator.t()
  def testid(locator, value, opts) when is_binary(value) and is_list(opts) do
    scope(locator, testid(value, opts))
  end

  @spec scope(Locator.t(), Locator.t()) :: Locator.t()
  @doc """
  Composes two locators with scope chaining (descendant query).

  The right locator is resolved within each element matched by the left locator.
  """
  def scope(left, right), do: Locator.compose_scope(left, right)

  @spec and_(Locator.t(), Locator.t()) :: Locator.t()
  @doc """
  Composes two locators with logical AND (same-element intersection).

  Both sides must match the same DOM node.
  """
  def and_(left, right), do: Locator.compose_and(left, right)

  @spec or_(Locator.t(), Locator.t()) :: Locator.t()
  @doc """
  Composes two locators with logical OR (union).

  Action operations still require a unique final target at execution time.
  """
  def or_(left, right), do: Locator.compose_or(left, right)

  @spec not_(Locator.t()) :: Locator.t()
  @doc """
  Negates a locator.
  """
  def not_(locator), do: Locator.compose_not(locator)

  @spec not_(Locator.t(), Locator.t()) :: Locator.t()
  @doc """
  Composes `left AND NOT(right)`.
  """
  def not_(left, right), do: and_(left, not_(right))

  @spec filter(Locator.t(), keyword()) :: Locator.t()
  @doc """
  Adds locator filters to an existing locator.

  Supported filters:
  - `has: locator`
  - `has_not: locator`
  - `visible: boolean`
  """
  def filter(locator, opts), do: Locator.filter(locator, opts)

  @doc """
  Composes a locator that matches the closest ancestor of a nested `from` locator.

  Example:

      within(session, closest(~l".fieldset"c, from: ~l"textbox:Email"r), &assert_has(&1, ~l"can't be blank"e))
  """
  @spec closest(Locator.t(), Options.closest_opts()) :: Locator.t()
  def closest(locator, opts), do: Locator.closest(locator, opts)

  @doc """
  Builds a locator using `~l`.

  Supported forms:
  - `~l"text"` exact text (default)
  - `~l"text"e` exact text
  - `~l"text"i` inexact text
  - `~l"text"l` label locator form
  - `~l"ROLE:NAME"r` role locator form
  - `~l"selector"c` CSS locator form
  - `~l"text"a` `aria-label` locator form
  - `~l"test-id"t` testid locator form (defaults to exact matching)

  Rules:
  - use at most one locator-kind modifier (`r`, `c`, `l`, `a`, or `t`)
  - `e` and `i` are mutually exclusive
  - `r` requires `ROLE:NAME` input
  """
  @spec sigil_l(String.t(), charlist()) :: Locator.t()
  def sigil_l(value, modifiers) when is_list(modifiers), do: Locator.sigil(value, modifiers)

  @doc """
  Visits `path` and returns the updated session.
  """
  @spec visit(arg, String.t(), Options.visit_opts()) :: arg when arg: var
  def visit(session, path, opts \\ []) when is_binary(path) do
    driver = driver_module_for_session!(session)
    bucket_driver = profiling_bucket_driver_kind!(session)

    Profiling.measure({:driver_operation, bucket_driver, :visit}, fn ->
      driver.visit(session, path, opts)
    end)
  end

  @doc """
  Reloads the current path, defaulting to `/` when the session has no current path.
  """
  @spec reload_page(arg, Options.reload_opts()) :: arg when arg: var
  def reload_page(session, opts \\ []) do
    visit(session, current_path(session, return_result: true) || "/", opts)
  end

  @doc """
  Resolves the normalized current path tracked by the session.

  Use either:
  - callback form (`current_path(session, fn path -> ... end)`) to keep piping
  - `return_result: true` (`current_path(session, return_result: true)`) to return the path

  ## Options

  #{@return_result_options_doc}
  """
  @spec current_path(Session.t()) :: Session.t()
  @spec current_path(Session.t(), Options.return_result_opts()) :: Session.t() | String.t() | nil
  @spec current_path(Session.t(), (String.t() | nil -> term())) :: Session.t()
  def current_path(session, callback_or_opts \\ [])

  def current_path(session, callback) when is_function(callback, 1) do
    callback.(current_path_result(session))
    session
  end

  def current_path(session, opts) when is_list(opts) do
    opts = Options.validate_return_result!(opts, "current_path/2")

    if Keyword.get(opts, :return_result, false) do
      current_path_result(session)
    else
      session
    end
  end

  def current_path(_session, _callback_or_opts) do
    raise ArgumentError, "current_path/2 expects a callback with arity 1 or keyword options"
  end

  @doc """
  Executes `callback` within a narrowed scope.

  `scope` must be a `Locator.t()` (for example, `~l"#secondary-panel"c`).
  Use `closest/2` when scope should resolve to the nearest matching ancestor
  around a nested element (for example, a field wrapper around a label).

  Use `within/3` when you need explicit scope boundaries for mixed operations.

  Browser note: when locator-based `within/3` matches an `<iframe>`, Cerberus switches
  the query root to that iframe document. Only same-origin iframes are supported.
  """
  @spec within(arg, Locator.t(), (arg -> arg)) :: arg when arg: var
  def within(session, locator, callback) when is_struct(locator, Locator) and is_function(callback, 1) do
    driver_module_for_session!(session).within(session, locator, callback)
  end

  @doc """
  Asserts the session path matches `expected`.

  ## Options

  #{@path_options_doc}
  """
  @spec assert_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def assert_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    call_has_timeout = Keyword.has_key?(opts, :timeout)
    opts = Options.validate_path!(opts, "assert_path/3")
    {validated_timeout, opts} = Keyword.pop(opts, :timeout, 0)
    timeout = resolve_path_timeout(session, call_has_timeout, validated_timeout)
    run_path_assertion!(session, :assert_path, expected, opts, timeout)
  end

  @doc """
  Refutes that the session path matches `expected`.

  ## Options

  #{@path_options_doc}
  """
  @spec refute_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def refute_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    call_has_timeout = Keyword.has_key?(opts, :timeout)
    opts = Options.validate_path!(opts, "refute_path/3")
    {validated_timeout, opts} = Keyword.pop(opts, :timeout, 0)
    timeout = resolve_path_timeout(session, call_has_timeout, validated_timeout)
    run_path_assertion!(session, :refute_path, expected, opts, timeout)
  end

  @doc """
  Asserts a file download by suggested filename across drivers.

  Typical flow is sequential:

      session
      |> click(role(:link, name: "Download Report"))
      |> assert_download("report.txt")

  Browser driver waits on BiDi download events. Static/live drivers assert on
  the current response `content-disposition` headers.

  ## Options

  #{@assert_download_options_doc}
  """
  @spec assert_download(arg, String.t(), Options.assert_download_opts()) :: arg when arg: var
  def assert_download(session, filename, opts \\ [])

  def assert_download(session, filename, opts) when is_binary(filename) and is_list(opts) do
    validated_opts = Options.validate_assert_download!(opts)
    driver = driver_module_for_session!(session)
    bucket_driver = profiling_bucket_driver_kind!(session)

    Profiling.measure({:driver_operation, bucket_driver, :assert_download}, fn ->
      driver.assert_download(session, filename, validated_opts)
    end)
  end

  def assert_download(_session, _filename, _opts) do
    raise ArgumentError, "assert_download/3 expects a filename string and options as a keyword list"
  end

  @doc """
  Clicks a matched element using unscoped shorthand (`click(session, locator)`).
  """
  @spec click(arg, Locator.t()) :: arg when arg: var
  def click(session, locator), do: click(session, locator, [])

  @doc """
  Clicks a matched element.

  ## Options

  #{@click_options_doc}
  """
  @spec click(arg, Locator.t(), Options.click_opts()) :: arg when arg: var
  def click(session, locator, opts) when is_list(opts) do
    Assertions.click(session, locator, opts)
  end

  @doc """
  Fills a form field matched by `locator`.

  Bare string/regex shorthand is not supported.

  Use explicit locators like `~l"..."l`, `role(...)`, `placeholder(...)`,
  `title(...)`, `aria_label(...)`, `testid(...)`, `css(...)`, or explicit text sigils
  (`~l"..."e` / `~l"..."i`).

  Sigil examples: `fill_in(session, ~l"#search_q"c, "Aragorn")`,
  `fill_in(session, ~l"search-input"t, "Aragorn")`.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec fill_in(arg, Locator.t(), Options.fill_in_value(), Options.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator, value, opts \\ []) when is_list(opts) do
    Assertions.fill_in(session, locator, value, opts)
  end

  @doc """
  Uploads a file into a matched file input.

  Bare string/regex shorthand is not supported.

  Use explicit locators like `~l"..."l`, `testid(...)`, `css(...)`, or explicit
  text sigils (`~l"..."e` / `~l"..."i`).

  Sigil examples: `upload(session, ~l"#avatar"c, "/tmp/avatar.jpg")`,
  `upload(session, ~l"avatar-upload"t, "/tmp/avatar.jpg")`.

  ## Options

  #{@upload_options_doc}
  """
  @spec upload(arg, Locator.t(), String.t(), Options.upload_opts()) :: arg when arg: var
  def upload(session, locator, path, opts \\ [])

  def upload(session, locator, path, opts) when is_binary(path) and is_list(opts) do
    Assertions.upload(session, locator, path, opts)
  end

  def upload(_session, _locator, _path, _opts) do
    raise ArgumentError, "upload/4 expects a non-empty path string and keyword options"
  end

  @doc """
  Submits the active form (the most recently interacted form field).
  """
  @spec submit(arg) :: arg when arg: var
  def submit(session), do: Assertions.submit(session)

  @doc """
  Submits a matched submit-capable control using default options.
  """
  @spec submit(arg, Locator.t()) :: arg when arg: var
  def submit(session, locator), do: submit(session, locator, [])

  @doc """
  Submits a matched submit-capable control.

  ## Options

  #{@submit_options_doc}
  """
  @spec submit(arg, Locator.t(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator, opts) when is_list(opts) do
    Assertions.submit(session, locator, opts)
  end

  @doc """
  Selects option text in a `<select>` field matched by `locator`.

  Bare string/regex shorthand is not supported.

  For multi-select fields, pass the full desired selection on every call
  (`option: [~l"Elf"e, ~l"Dwarf"e]`). Each `select/3` call replaces the selection
  with the provided option value(s).
  Sigil examples: `select(session, ~l"#race_select"c, option: ~l"Elf"e)`,
  `select(session, ~l"race-select"t, option: ~l"Elf"e)`.
  """
  @spec select(arg, Locator.t()) :: arg when arg: var
  def select(session, locator), do: select(session, locator, [])

  @doc """
  Selects option text in a matched `<select>` field.

  ## Options

  #{@select_options_doc}
  """
  @spec select(arg, Locator.t(), Options.select_opts()) :: arg when arg: var
  def select(session, locator, opts) when is_list(opts) do
    Assertions.select(session, locator, opts)
  end

  @doc """
  Chooses a radio input matched by `locator`.

  Bare string/regex shorthand is not supported.

  Use explicit locators like `~l"..."l`, `testid(...)`, `css(...)`, or explicit
  text sigils (`~l"..."e` / `~l"..."i`).

  Sigil examples: `choose(session, ~l"#contact_email"c)`,
  `choose(session, ~l"contact-email"t)`.
  """
  @spec choose(arg, Locator.t()) :: arg when arg: var
  def choose(session, locator), do: choose(session, locator, [])

  @doc """
  Chooses a matched radio input.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec choose(arg, Locator.t(), Options.choose_opts()) :: arg when arg: var
  def choose(session, locator, opts) when is_list(opts) do
    Assertions.choose(session, locator, opts)
  end

  @doc """
  Checks a checkbox matched by `locator`.

  Bare string/regex shorthand is not supported.

  Use explicit locators like `~l"..."l`, `testid(...)`, `css(...)`, or explicit
  text sigils (`~l"..."e` / `~l"..."i`).

  Sigil examples: `check(session, ~l"#subscribe"c)`,
  `check(session, ~l"subscribe-checkbox"t)`.
  """
  @spec check(arg, Locator.t()) :: arg when arg: var
  def check(session, locator), do: check(session, locator, [])

  @doc """
  Checks a matched checkbox.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec check(arg, Locator.t(), Options.check_opts()) :: arg when arg: var
  def check(session, locator, opts) when is_list(opts) do
    Assertions.check(session, locator, opts)
  end

  @doc """
  Unchecks a checkbox matched by `locator`.

  Bare string/regex shorthand is not supported.

  Use explicit locators like `~l"..."l`, `testid(...)`, `css(...)`, or explicit
  text sigils (`~l"..."e` / `~l"..."i`).

  Sigil examples: `uncheck(session, ~l"#subscribe"c)`,
  `uncheck(session, ~l"subscribe-checkbox"t)`.
  """
  @spec uncheck(arg, Locator.t()) :: arg when arg: var
  def uncheck(session, locator), do: uncheck(session, locator, [])

  @doc """
  Unchecks a matched checkbox.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec uncheck(arg, Locator.t(), Options.check_opts()) :: arg when arg: var
  def uncheck(session, locator, opts) when is_list(opts) do
    Assertions.uncheck(session, locator, opts)
  end

  @doc """
  Asserts that content matched by `locator` exists.

  Unscoped:
  `assert_has(session, ~l"Articles"e)`

  Composed locator form:
  `assert_has(session, and_(css("a"), text("Counter", exact: true)))`

  For explicit scope boundaries, use `within/3`.
  """
  @spec assert_has(arg, Locator.t()) :: arg when arg: var
  def assert_has(session, locator), do: assert_has(session, locator, [])

  @doc """
  Asserts content exists.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_has(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, locator, opts) when is_list(opts) do
    Assertions.assert_has(session, locator, opts)
  end

  @doc """
  Refutes that content matched by `locator` exists.

  Unscoped:
  `refute_has(session, ~l"500 Internal Server Error"e)`

  Composed locator form:
  `refute_has(session, and_(css("button"), text("Dangerous", exact: true)))`

  For explicit scope boundaries, use `within/3`.
  """
  @spec refute_has(arg, Locator.t()) :: arg when arg: var
  def refute_has(session, locator), do: refute_has(session, locator, [])

  @doc """
  Refutes content exists.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_has(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator, opts) when is_list(opts) do
    Assertions.refute_has(session, locator, opts)
  end

  @doc """
  Asserts that at least one element matched by `locator` is checked.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_checked(arg, Locator.t()) :: arg when arg: var
  def assert_checked(session, locator), do: assert_checked(session, locator, [])

  @spec assert_checked(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def assert_checked(session, locator, opts) when is_list(opts) do
    Assertions.assert_checked(session, locator, opts)
  end

  @doc """
  Refutes that any element matched by `locator` is checked.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_checked(arg, Locator.t()) :: arg when arg: var
  def refute_checked(session, locator), do: refute_checked(session, locator, [])

  @spec refute_checked(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def refute_checked(session, locator, opts) when is_list(opts) do
    Assertions.refute_checked(session, locator, opts)
  end

  @doc """
  Asserts that at least one element matched by `locator` is disabled.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_disabled(arg, Locator.t()) :: arg when arg: var
  def assert_disabled(session, locator), do: assert_disabled(session, locator, [])

  @spec assert_disabled(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def assert_disabled(session, locator, opts) when is_list(opts) do
    Assertions.assert_disabled(session, locator, opts)
  end

  @doc """
  Refutes that any element matched by `locator` is disabled.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_disabled(arg, Locator.t()) :: arg when arg: var
  def refute_disabled(session, locator), do: refute_disabled(session, locator, [])

  @spec refute_disabled(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def refute_disabled(session, locator, opts) when is_list(opts) do
    Assertions.refute_disabled(session, locator, opts)
  end

  @doc """
  Asserts that at least one element matched by `locator` is selected.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_selected(arg, Locator.t()) :: arg when arg: var
  def assert_selected(session, locator), do: assert_selected(session, locator, [])

  @spec assert_selected(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def assert_selected(session, locator, opts) when is_list(opts) do
    Assertions.assert_selected(session, locator, opts)
  end

  @doc """
  Refutes that any element matched by `locator` is selected.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_selected(arg, Locator.t()) :: arg when arg: var
  def refute_selected(session, locator), do: refute_selected(session, locator, [])

  @spec refute_selected(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def refute_selected(session, locator, opts) when is_list(opts) do
    Assertions.refute_selected(session, locator, opts)
  end

  @doc """
  Asserts that at least one element matched by `locator` is readonly.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_readonly(arg, Locator.t()) :: arg when arg: var
  def assert_readonly(session, locator), do: assert_readonly(session, locator, [])

  @spec assert_readonly(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def assert_readonly(session, locator, opts) when is_list(opts) do
    Assertions.assert_readonly(session, locator, opts)
  end

  @doc """
  Refutes that any element matched by `locator` is readonly.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_readonly(arg, Locator.t()) :: arg when arg: var
  def refute_readonly(session, locator), do: refute_readonly(session, locator, [])

  @spec refute_readonly(arg, Locator.t(), Options.assert_opts()) :: arg when arg: var
  def refute_readonly(session, locator, opts) when is_list(opts) do
    Assertions.refute_readonly(session, locator, opts)
  end

  @doc """
  Asserts that the current value of a form field matched by `locator` equals `expected`.

  String values use exact matching. Regex values are matched against the current field value.
  """
  @spec assert_value(arg, Locator.t(), String.t() | Regex.t()) :: arg when arg: var
  def assert_value(session, locator, expected), do: assert_value(session, locator, expected, [])

  @doc """
  Asserts a form-field value.

  ## Options

  #{@assert_value_options_doc}
  """
  @spec assert_value(arg, Locator.t(), String.t() | Regex.t(), Options.assert_value_opts()) :: arg when arg: var
  def assert_value(session, locator, expected, opts) when is_list(opts) do
    Assertions.assert_value(session, locator, expected, opts)
  end

  @doc """
  Refutes that the current value of a form field matched by `locator` equals `expected`.

  String values use exact matching. Regex values are matched against the current field value.
  """
  @spec refute_value(arg, Locator.t(), String.t() | Regex.t()) :: arg when arg: var
  def refute_value(session, locator, expected), do: refute_value(session, locator, expected, [])

  @doc """
  Refutes a form-field value.

  ## Options

  #{@assert_value_options_doc}
  """
  @spec refute_value(arg, Locator.t(), String.t() | Regex.t(), Options.assert_value_opts()) :: arg when arg: var
  def refute_value(session, locator, expected, opts) when is_list(opts) do
    Assertions.refute_value(session, locator, expected, opts)
  end

  defp render_html_result(session) do
    result_ref = make_ref()
    caller = self()

    _ =
      driver_module_for_session!(session).render_html(session, fn lazy_html ->
        send(caller, {result_ref, lazy_html})
      end)

    receive do
      {^result_ref, lazy_html} -> lazy_html
    end
  end

  defp current_path_result(session) do
    session
    |> Session.current_path()
    |> Path.normalize()
  end

  defp driver_module_for_session!(%StaticSession{}), do: StaticSession
  defp driver_module_for_session!(%LiveSession{}), do: LiveSession
  defp driver_module_for_session!(%BrowserSession{}), do: BrowserSession

  defp driver_module_for_session!(session) do
    raise ArgumentError,
          "unsupported session #{inspect(session)}; expected a Cerberus session"
  end

  defp run_path_assertion!(session, op, expected, opts, timeout) when op in [:assert_path, :refute_path] do
    driver = driver_module_for_session!(session)
    bucket_driver = profiling_bucket_driver_kind!(session)

    Profiling.measure({:driver_operation, bucket_driver, op}, fn ->
      driver.run_path_assertion(session, expected, opts, timeout, op)
    end)
  end

  defp resolve_path_timeout(_session, true, validated_timeout), do: validated_timeout

  defp resolve_path_timeout(session, false, _validated_timeout),
    do: driver_module_for_session!(session).default_timeout_ms(session)

  defp dispatch_tab_operation!(session, operation, args \\ []) when operation in [:open_tab, :switch_tab, :close_tab] do
    driver = driver_module_for_session!(session)
    apply(driver, operation, [session | args])
  end

  defp profiling_bucket_driver_kind!(%StaticSession{}), do: :static
  defp profiling_bucket_driver_kind!(%LiveSession{}), do: :live
  defp profiling_bucket_driver_kind!(%BrowserSession{}), do: :browser
end
