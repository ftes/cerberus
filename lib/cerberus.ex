defmodule Cerberus do
  @moduledoc """
  Session-first test API for non-browser Phoenix mode and browser execution.

  Architecture contract (ADR-0001 + ADR-0002):
  - The public API is driver-agnostic and session-first.
  - All public operations take a `Cerberus.Session` and return a `Cerberus.Session`.
  - `locator` is the first argument after `session` for locator-based operations.
  - Browser unwrap payloads are exposed as `Cerberus.Browser.Native` handles, not raw internals.
  - v0 does not expose a public located-element pipeline type.

  Browser assertion/path operations use in-browser wait loops as the fast path.
  Cerberus applies bounded transient eval retries to smooth navigation/context-reset races.

  Locator sigil quick look:

      ~l"Save"          # text
      ~l"Save"e         # exact text
      ~l"Save"i         # inexact text
      ~l"button:Save"r  # role form (ROLE:NAME)
      ~l"#save"c        # css
      ~l"save-btn"t     # testid (defaults exact: true)

  Locator composition quick look:

      button("Run Search") |> testid("submit-secondary-button")     # AND (same element)
      or_(css("#primary"), css("#secondary"))                       # OR (union)
      button("Run Search") |> has(testid("submit-secondary-marker")) # nesting (descendant)
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
  alias Ecto.Adapters.SQL.Sandbox, as: EctoSandbox
  alias Phoenix.Ecto.SQL.Sandbox, as: PhoenixSandbox

  @type locator_input :: Locator.input()
  @type scope_locator_input :: Locator.input()
  @locator_kind_keys [:text, :label, :link, :button, :placeholder, :title, :alt, :role, :css, :testid, :and, :or]
  @locator_kind_string_keys Enum.map(@locator_kind_keys, &Atom.to_string/1)
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
  Returns the encoded SQL sandbox user-agent marker for an ExUnit test context.

  This helper is intended for browser-session sandbox wiring:

      metadata = Cerberus.sql_sandbox_user_agent(MyApp.Repo, context)
      session(:browser, user_agent: metadata)

  The returned value can also be used for raw conn headers:

      conn
      |> Plug.Conn.delete_req_header("user-agent")
      |> Plug.Conn.put_req_header("user-agent", metadata)
  """
  @spec sql_sandbox_user_agent(module() | [module()], map()) :: String.t()
  def sql_sandbox_user_agent(repo, context) when (is_atom(repo) or is_list(repo)) and is_map(context) do
    checkout_ecto_repos(repo, context)
  end

  @doc """
  Returns the encoded SQL sandbox user-agent marker for the first configured Ecto repo.
  """
  @spec sql_sandbox_user_agent(map()) :: String.t()
  def sql_sandbox_user_agent(context) when is_map(context) do
    if repos = Application.get_env(:cerberus, :ecto_repos) do
      sql_sandbox_user_agent(repos, context)
    else
      raise ArgumentError,
            "sql_sandbox_user_agent/1 requires :cerberus, :ecto_repos to include at least one repo; use sql_sandbox_user_agent/2 to pass an explicit repo"
    end
  end

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

  @doc """
  Same as `open_browser/1`, but allows injecting a custom open callback.
  """
  @spec open_browser(arg, (String.t() -> term())) :: arg when arg: var
  def open_browser(session, open_fun) when is_function(open_fun, 1) do
    driver_module_for_session!(session).open_browser(session, open_fun)
  end

  def open_browser(_session, _open_fun) do
    raise ArgumentError, "open_browser/2 expects a callback with arity 1"
  end

  @doc """
  Renders the current page HTML and passes it to the callback as `LazyHTML`.

  This is primarily for debugging, and can be useful for AI-assisted workflows
  that need to inspect the entire DOM tree in-process.

  For human-oriented inspection in a browser, see `open_browser/1`.
  """
  @spec render_html(arg, (LazyHTML.t() -> term())) :: arg when arg: var
  def render_html(session, callback) when is_function(callback, 1) do
    driver_module_for_session!(session).render_html(session, callback)
  end

  def render_html(_session, _callback) do
    raise ArgumentError, "render_html/2 expects a callback with arity 1"
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
  @spec text(String.t() | Regex.t(), keyword()) :: Locator.t()
  def text(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:text, value, opts)
  end

  @spec text(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def text(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, text(value))
  end

  @doc """
  Composes a text constraint into an existing locator with locator options.
  """
  @spec text(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def text(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, text(value, opts))
  end

  @doc """
  Builds a link locator.
  """
  @spec link(String.t() | Regex.t()) :: Locator.t()
  def link(value) when is_binary(value) or is_struct(value, Regex), do: link(value, [])

  @doc """
  Builds or composes a link locator.

  Supported forms:
  - `link(value, opts)` for a leaf locator
  - `link(locator, value)` to compose with an existing locator
  """
  @spec link(String.t() | Regex.t(), keyword()) :: Locator.t()
  def link(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:link, value, opts)
  end

  @spec link(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def link(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, link(value))
  end

  @doc """
  Composes a link constraint into an existing locator with locator options.
  """
  @spec link(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def link(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, link(value, opts))
  end

  @doc """
  Builds a button locator.
  """
  @spec button(String.t() | Regex.t()) :: Locator.t()
  def button(value) when is_binary(value) or is_struct(value, Regex), do: button(value, [])

  @doc """
  Builds or composes a button locator.

  Supported forms:
  - `button(value, opts)` for a leaf locator
  - `button(locator, value)` to compose with an existing locator
  """
  @spec button(String.t() | Regex.t(), keyword()) :: Locator.t()
  def button(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:button, value, opts)
  end

  @spec button(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def button(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, button(value))
  end

  @doc """
  Composes a button constraint into an existing locator with locator options.
  """
  @spec button(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def button(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, button(value, opts))
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
  @spec label(String.t() | Regex.t(), keyword()) :: Locator.t()
  def label(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:label, value, opts)
  end

  @spec label(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def label(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, label(value))
  end

  @doc """
  Composes a label constraint into an existing locator with locator options.
  """
  @spec label(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def label(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, label(value, opts))
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
  @spec placeholder(String.t() | Regex.t(), keyword()) :: Locator.t()
  def placeholder(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:placeholder, value, opts)
  end

  @spec placeholder(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def placeholder(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, placeholder(value))
  end

  @doc """
  Composes a placeholder constraint into an existing locator with locator options.
  """
  @spec placeholder(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def placeholder(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, placeholder(value, opts))
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
  @spec title(String.t() | Regex.t(), keyword()) :: Locator.t()
  def title(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:title, value, opts)
  end

  @spec title(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def title(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, title(value))
  end

  @doc """
  Composes a title constraint into an existing locator with locator options.
  """
  @spec title(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def title(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, title(value, opts))
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
  @spec alt(String.t() | Regex.t(), keyword()) :: Locator.t()
  def alt(value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    Locator.leaf(:alt, value, opts)
  end

  @spec alt(locator_input(), String.t() | Regex.t()) :: Locator.t()
  def alt(locator, value) when is_binary(value) or is_struct(value, Regex) do
    and_(locator, alt(value))
  end

  @doc """
  Composes an alt-text constraint into an existing locator with locator options.
  """
  @spec alt(locator_input(), String.t() | Regex.t(), keyword()) :: Locator.t()
  def alt(locator, value, opts) when (is_binary(value) or is_struct(value, Regex)) and is_list(opts) do
    and_(locator, alt(value, opts))
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
  @spec css(String.t(), keyword()) :: Locator.t()
  def css(value, opts) when is_binary(value) and is_list(opts) do
    Locator.leaf(:css, value, opts)
  end

  @spec css(locator_input(), String.t()) :: Locator.t()
  def css(locator, value) when is_binary(value) do
    and_(locator, css(value))
  end

  @doc """
  Composes a CSS constraint into an existing locator with locator options.
  """
  @spec css(locator_input(), String.t(), keyword()) :: Locator.t()
  def css(locator, value, opts) when is_binary(value) and is_list(opts) do
    and_(locator, css(value, opts))
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
  @spec role(String.t() | atom(), keyword()) :: Locator.t()
  def role(role, opts) when (is_binary(role) or is_atom(role)) and is_list(opts) do
    Locator.role(role, opts)
  end

  @spec role(locator_input(), String.t() | atom()) :: Locator.t()
  def role(locator, role_name) when is_binary(role_name) or is_atom(role_name) do
    and_(locator, role(role_name))
  end

  @doc """
  Composes a role constraint into an existing locator with locator options.
  """
  @spec role(locator_input(), String.t() | atom(), keyword()) :: Locator.t()
  def role(locator, role_name, opts) when (is_binary(role_name) or is_atom(role_name)) and is_list(opts) do
    and_(locator, role(role_name, opts))
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
  @spec testid(String.t(), keyword()) :: Locator.t()
  def testid(value, opts) when is_binary(value) and is_list(opts) do
    Locator.leaf(:testid, value, opts)
  end

  @spec testid(locator_input(), String.t()) :: Locator.t()
  def testid(locator, value) when is_binary(value) do
    and_(locator, testid(value))
  end

  @doc """
  Composes a test-id constraint into an existing locator with locator options.
  """
  @spec testid(locator_input(), String.t(), keyword()) :: Locator.t()
  def testid(locator, value, opts) when is_binary(value) and is_list(opts) do
    and_(locator, testid(value, opts))
  end

  @spec and_(locator_input(), locator_input()) :: Locator.t()
  @doc """
  Composes two locators with logical AND (same-element intersection).

  Both sides must match the same DOM node.
  """
  def and_(left, right), do: Locator.compose_and(left, right)

  @spec or_(locator_input(), locator_input()) :: Locator.t()
  @doc """
  Composes two locators with logical OR (union).

  Action operations still require a unique final target at execution time.
  """
  def or_(left, right), do: Locator.compose_or(left, right)

  @spec has(locator_input(), locator_input()) :: Locator.t()
  @doc """
  Adds a descendant locator constraint (`:has`) to a locator.

  Example:

      button("Apply") |> has(testid("apply-secondary-marker"))
  """
  def has(locator, nested_locator), do: Locator.put_has(locator, nested_locator)

  @doc """
  Composes a locator that matches the closest ancestor of a nested `from` locator.

  Example:

      within(session, closest(~l".fieldset"c, from: ~l"textbox:Email"r), &assert_has(&1, ~l"can't be blank"))
  """
  @spec closest(locator_input(), keyword()) :: Locator.t()
  def closest(locator, opts), do: Locator.closest(locator, opts)

  @doc """
  Builds a locator using `~l`.

  Supported forms:
  - `~l"text"` text locator
  - `~l"text"e` exact text
  - `~l"text"i` inexact text
  - `~l"ROLE:NAME"r` role locator form
  - `~l"selector"c` CSS locator form
  - `~l"test-id"t` testid locator form (defaults to exact matching)

  Rules:
  - use at most one locator-kind modifier (`r`, `c`, or `t`)
  - `e` and `i` are mutually exclusive
  - `r` requires `ROLE:NAME` input
  """
  @spec sigil_l(String.t(), charlist()) :: Locator.t()
  def sigil_l(value, modifiers) when is_list(modifiers), do: Locator.sigil(value, modifiers)

  @doc """
  Visits `path` and returns the updated session.
  """
  @spec visit(arg, String.t(), keyword()) :: arg when arg: var
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
  @spec reload_page(arg, keyword()) :: arg when arg: var
  def reload_page(session, opts \\ []) do
    visit(session, current_path(session) || "/", opts)
  end

  @doc """
  Returns the normalized current path tracked by the session.
  """
  @spec current_path(Session.t()) :: String.t() | nil
  def current_path(session) do
    session
    |> Session.current_path()
    |> Path.normalize()
  end

  @doc """
  Executes `callback` within a narrowed scope.

  `scope` must be a locator input (for example, `~l"#secondary-panel"c`).
  Use `closest/2` when scope should resolve to the nearest matching ancestor
  around a nested element (for example, a field wrapper around a label).

  For scoped assertions without entering a `within/3` callback, you can also use scoped assertion overloads:

      session
      |> assert_has(closest(~l".fieldset"c, from: ~l"textbox:Email"r), ~l"can't be blank")

  Browser note: when locator-based `within/3` matches an `<iframe>`, Cerberus switches
  the query root to that iframe document. Only same-origin iframes are supported.
  """
  @spec within(arg, scope_locator_input(), (arg -> arg)) :: arg when arg: var
  def within(session, locator, callback) when not is_binary(locator) and is_function(callback, 1) do
    normalized_locator = Locator.normalize(locator)
    driver_module_for_session!(session).within(session, normalized_locator, callback)
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
      |> click(link("Download Report"))
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
  @spec click(arg, locator_input()) :: arg when arg: var
  def click(session, locator), do: click(session, locator, [])

  @doc """
  Clicks a matched element.

  Supported forms:
  - `click(session, locator, opts)` for unscoped clicks
  - `click(session, scope_locator, locator)` for scoped clicks

  ## Options

  #{@click_options_doc}
  """
  @spec click(arg, scope_locator_input(), locator_input() | Options.click_opts()) :: arg when arg: var
  def click(session, scope_locator_or_locator, locator_or_opts) do
    if locator_input_term?(locator_or_opts) do
      click(session, scope_locator_or_locator, locator_or_opts, [])
    else
      Assertions.click(session, scope_locator_or_locator, locator_or_opts)
    end
  end

  @doc """
  Clicks a locator within `scope_locator`.

  ## Options

  #{@click_options_doc}
  """
  @spec click(arg, scope_locator_input(), locator_input(), Options.click_opts()) :: arg when arg: var
  def click(session, scope_locator, locator, opts) when is_list(opts) do
    within(session, scope_locator, fn scoped ->
      Assertions.click(scoped, locator, opts)
    end)
  end

  @doc """
  Clicks a locator constrained to link elements.

  ## Options

  #{@click_options_doc}
  """
  @spec click_link(arg, locator_input(), Options.click_opts()) :: arg when arg: var
  def click_link(session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :link))
  end

  @doc """
  Clicks a locator constrained to button elements.

  ## Options

  #{@click_options_doc}
  """
  @spec click_button(arg, locator_input(), Options.click_opts()) :: arg when arg: var
  def click_button(session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :button))
  end

  @doc """
  Fills a form field matched by `locator`.

  Use plain string/regex label shorthand as the first option, for example:
  `fill_in(session, "Search term", "Aragorn")`.

  Helper locators like `label(...)`, `role(...)`, `placeholder(...)`, `title(...)`,
  `testid(...)`, and `css(...)` are also supported.
  Sigil examples: `fill_in(session, ~l"#search_q"c, "Aragorn")`,
  `fill_in(session, ~l"search-input"t, "Aragorn")`.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec fill_in(arg, locator_input(), Options.fill_in_value(), Options.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator, value, opts \\ []) when is_list(opts) do
    Assertions.fill_in(session, locator, value, opts)
  end

  @doc """
  Uploads a file into a matched file input.

  Use plain string/regex label shorthand as the first option, for example:
  `upload(session, "Avatar", "/tmp/avatar.jpg")`.

  Helper locators like `label(...)`, `testid(...)`, and `css(...)` are also supported.
  Sigil examples: `upload(session, ~l"#avatar"c, "/tmp/avatar.jpg")`,
  `upload(session, ~l"avatar-upload"t, "/tmp/avatar.jpg")`.

  ## Options

  #{@upload_options_doc}
  """
  @spec upload(arg, locator_input(), String.t(), Options.upload_opts()) :: arg when arg: var
  def upload(session, locator, path, opts \\ [])

  def upload(session, locator, path, opts) when is_binary(path) and is_list(opts) do
    Assertions.upload(session, locator, path, opts)
  end

  def upload(_session, _locator, _path, _opts) do
    raise ArgumentError, "upload/4 expects a non-empty path string and keyword options"
  end

  @doc """
  Submits the first submit-capable button in scope.
  """
  @spec submit(arg) :: arg when arg: var
  def submit(session), do: submit(session, button(""), [])

  @doc """
  Submits a matched submit-capable control using default options.
  """
  @spec submit(arg, locator_input()) :: arg when arg: var
  def submit(session, locator), do: submit(session, locator, [])

  @doc """
  Submits a matched submit-capable control.

  ## Options

  #{@submit_options_doc}
  """
  @spec submit(arg, locator_input(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator, opts) when is_list(opts) do
    Assertions.submit(session, locator, opts)
  end

  @doc """
  Selects option text in a `<select>` field matched by `locator`.

  Use plain string/regex label shorthand as the first option, for example:
  `select(session, "Race", option: "Elf")`.

  For multi-select fields, pass the full desired selection on every call
  (`option: ["Elf", "Dwarf"]`). Each `select/3` call replaces the selection
  with the provided option value(s).
  Sigil examples: `select(session, ~l"#race_select"c, option: "Elf")`,
  `select(session, ~l"race-select"t, option: "Elf")`.
  """
  @spec select(arg, locator_input()) :: arg when arg: var
  def select(session, locator), do: select(session, locator, [])

  @doc """
  Selects option text in a matched `<select>` field.

  ## Options

  #{@select_options_doc}
  """
  @spec select(arg, locator_input(), Options.select_opts()) :: arg when arg: var
  def select(session, locator, opts) when is_list(opts) do
    Assertions.select(session, locator, opts)
  end

  @doc """
  Chooses a radio input matched by `locator`.

  Use plain string/regex label shorthand as the first option, for example:
  `choose(session, "Email Choice")`.

  Helper locators like `label(...)`, `testid(...)`, and `css(...)` are also supported.
  Sigil examples: `choose(session, ~l"#contact_email"c)`,
  `choose(session, ~l"contact-email"t)`.
  """
  @spec choose(arg, locator_input()) :: arg when arg: var
  def choose(session, locator), do: choose(session, locator, [])

  @doc """
  Chooses a matched radio input.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec choose(arg, locator_input(), Options.choose_opts()) :: arg when arg: var
  def choose(session, locator, opts) when is_list(opts) do
    Assertions.choose(session, locator, opts)
  end

  @doc """
  Checks a checkbox matched by `locator`.

  Use plain string/regex label shorthand as the first option, for example:
  `check(session, "Subscribe to newsletter")`.

  Helper locators like `label(...)`, `testid(...)`, and `css(...)` are also supported.
  Sigil examples: `check(session, ~l"#subscribe"c)`,
  `check(session, ~l"subscribe-checkbox"t)`.
  """
  @spec check(arg, locator_input()) :: arg when arg: var
  def check(session, locator), do: check(session, locator, [])

  @doc """
  Checks a matched checkbox.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec check(arg, locator_input(), Options.check_opts()) :: arg when arg: var
  def check(session, locator, opts) when is_list(opts) do
    Assertions.check(session, locator, opts)
  end

  @doc """
  Unchecks a checkbox matched by `locator`.

  Use plain string/regex label shorthand as the first option, for example:
  `uncheck(session, "Subscribe to newsletter")`.

  Helper locators like `label(...)`, `testid(...)`, and `css(...)` are also supported.
  Sigil examples: `uncheck(session, ~l"#subscribe"c)`,
  `uncheck(session, ~l"subscribe-checkbox"t)`.
  """
  @spec uncheck(arg, locator_input()) :: arg when arg: var
  def uncheck(session, locator), do: uncheck(session, locator, [])

  @doc """
  Unchecks a matched checkbox.

  ## Options

  #{@fill_in_options_doc}
  """
  @spec uncheck(arg, locator_input(), Options.check_opts()) :: arg when arg: var
  def uncheck(session, locator, opts) when is_list(opts) do
    Assertions.uncheck(session, locator, opts)
  end

  @doc """
  Asserts that content matched by `locator` exists.

  Unscoped:
  `assert_has(session, ~l"Articles")`

  Scoped:
  `assert_has(session, ~l"#secondary-panel"c, "Status: secondary")`

  In the scoped form, the second argument is a `scope_locator` and the third
  argument is a `locator`. Passing a binary/regex `locator` uses text-locator shorthand.
  """
  @spec assert_has(arg, locator_input()) :: arg when arg: var
  def assert_has(session, locator), do: assert_has(session, locator, [])

  @doc """
  Asserts content exists, supporting unscoped and scoped forms.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_has(arg, scope_locator_input(), locator_input() | Options.assert_opts()) :: arg when arg: var
  def assert_has(session, scope_locator_or_locator, locator_or_opts) do
    if locator_input_term?(locator_or_opts) do
      assert_has(session, scope_locator_or_locator, locator_or_opts, [])
    else
      Assertions.assert_has(session, scope_locator_or_locator, locator_or_opts)
    end
  end

  @doc """
  Asserts content exists within `scope_locator`.

  ## Options

  #{@assert_options_doc}
  """
  @spec assert_has(arg, scope_locator_input(), locator_input(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, scope_locator, locator, opts) when is_list(opts) do
    within(session, scope_locator, fn scoped ->
      Assertions.assert_has(scoped, locator, opts)
    end)
  end

  @doc """
  Refutes that content matched by `locator` exists.

  Unscoped:
  `refute_has(session, ~l"500 Internal Server Error")`

  Scoped:
  `refute_has(session, ~l"#secondary-panel"c, "Status: primary")`

  In the scoped form, the second argument is a `scope_locator` and the third
  argument is a `locator`. Passing a binary/regex `locator` uses text-locator shorthand.
  """
  @spec refute_has(arg, locator_input()) :: arg when arg: var
  def refute_has(session, locator), do: refute_has(session, locator, [])

  @doc """
  Refutes content exists, supporting unscoped and scoped forms.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_has(arg, scope_locator_input(), locator_input() | Options.assert_opts()) :: arg when arg: var
  def refute_has(session, scope_locator_or_locator, locator_or_opts) do
    if locator_input_term?(locator_or_opts) do
      refute_has(session, scope_locator_or_locator, locator_or_opts, [])
    else
      Assertions.refute_has(session, scope_locator_or_locator, locator_or_opts)
    end
  end

  @doc """
  Refutes content exists within `scope_locator`.

  ## Options

  #{@assert_options_doc}
  """
  @spec refute_has(arg, scope_locator_input(), locator_input(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, scope_locator, locator, opts) when is_list(opts) do
    within(session, scope_locator, fn scoped ->
      Assertions.refute_has(scoped, locator, opts)
    end)
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
    do: driver_module_for_session!(session).default_assert_timeout_ms(session)

  defp dispatch_tab_operation!(session, operation, args \\ []) when operation in [:open_tab, :switch_tab, :close_tab] do
    driver = driver_module_for_session!(session)
    apply(driver, operation, [session | args])
  end

  defp profiling_bucket_driver_kind!(%StaticSession{}), do: :static
  defp profiling_bucket_driver_kind!(%LiveSession{}), do: :live
  defp profiling_bucket_driver_kind!(%BrowserSession{}), do: :browser

  defp locator_input_term?(value) when is_binary(value) or is_struct(value, Regex), do: true
  defp locator_input_term?(%Locator{}), do: true
  defp locator_input_term?(value) when is_map(value), do: true

  defp locator_input_term?(value) when is_list(value) do
    if Keyword.keyword?(value) do
      Enum.any?(Keyword.keys(value), &locator_kind_key?/1)
    else
      false
    end
  end

  defp locator_input_term?(_value), do: false

  defp locator_kind_key?(key) when is_atom(key), do: key in @locator_kind_keys
  defp locator_kind_key?(key) when is_binary(key), do: key in @locator_kind_string_keys
  defp locator_kind_key?(_key), do: false

  defp checkout_ecto_repos(repo, context) do
    repos = List.wrap(repo)
    metadata = sandbox_metadata_for_repos(repos, context)
    PhoenixSandbox.encode_metadata(metadata)
  end

  defp sandbox_metadata_for_repos([repo], context),
    do: PhoenixSandbox.metadata_for(repo, start_sandbox_owner(repo, context))

  defp sandbox_metadata_for_repos(repos, context) when is_list(repos) do
    Enum.each(repos, &start_sandbox_owner(&1, context))
    PhoenixSandbox.metadata_for(repos, self())
  end

  defp start_sandbox_owner(repo, context) do
    pid = EctoSandbox.start_owner!(repo, shared: not context.async)
    ExUnit.Callbacks.on_exit(fn -> stop_sandbox_owner(pid) end)
    pid
  end

  defp stop_sandbox_owner(checkout_pid) do
    EctoSandbox.stop_owner(checkout_pid)
  catch
    :exit, {:noproc, _} -> :ok
  end
end
