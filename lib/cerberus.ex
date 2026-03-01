defmodule Cerberus do
  @moduledoc """
  Session-first test API for non-browser Phoenix mode and browser execution.

  Architecture contract (ADR-0001 + ADR-0002):
  - The public API is driver-agnostic and session-first.
  - All public operations take a `Cerberus.Session` and return a `Cerberus.Session`.
  - `locator` is the first argument after `session` for locator-based operations.
  - v0 does not expose a public located-element pipeline type.

  Slice 1 provides one-shot operations over deterministic adapters.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Phoenix.Conn, as: DriverConn
  alias Cerberus.Phoenix.LiveViewTimeout
  alias Cerberus.Session
  alias ExUnit.AssertionError
  alias Phoenix.LiveViewTest.View

  @type driver_kind :: Session.driver_kind()

  @spec session() :: Session.t()
  def session, do: session([])

  @spec session(keyword()) :: Session.t()
  def session(opts) when is_list(opts) do
    StaticSession.new_session(opts)
  end

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

  @spec session(:phoenix, keyword()) :: Session.t()
  def session(:phoenix, opts) when is_list(opts), do: session(opts)

  @doc """
  Starts a browser session.

  Browser context defaults can be configured globally via `config :cerberus, :browser`
  and overridden per session with:

  - `browser: [viewport: [width: ..., height: ...] | {w, h}]`
  - `browser: [user_agent: "..."]`
  - `browser: [popup_mode: :allow | :same_tab]` to control `window.open` behavior
    (`:same_tab` is currently unsupported on Firefox)
  - `browser: [init_script: "..."]` or `browser: [init_scripts: ["...", ...]]`
  - `webdriver_url: "http://remote-webdriver:4444"` to use a remote WebDriver endpoint
    without local browser/chromedriver launch.
  """
  @spec session(:browser, keyword()) :: Session.t()
  def session(:browser, opts) when is_list(opts) do
    BrowserSession.new_session(opts)
  end

  @spec session(:chrome, keyword()) :: Session.t()
  def session(:chrome, opts) when is_list(opts) do
    opts
    |> Keyword.put(:browser_name, :chrome)
    |> BrowserSession.new_session()
  end

  @spec session(:firefox, keyword()) :: Session.t()
  def session(:firefox, opts) when is_list(opts) do
    opts
    |> Keyword.put(:browser_name, :firefox)
    |> BrowserSession.new_session()
  end

  def session(driver, opts) when is_atom(driver) and is_list(opts) do
    raise ArgumentError,
          "unsupported public driver #{inspect(driver)}; use session()/session(:phoenix) for non-browser and session(:browser|:chrome|:firefox) for browser"
  end

  @spec open_user(arg) :: arg when arg: var
  def open_user(%BrowserSession{} = session), do: BrowserSession.open_user(session)
  def open_user(%StaticSession{} = session), do: StaticSession.open_user(session)
  def open_user(%LiveSession{} = session), do: LiveSession.open_user(session)

  @spec open_tab(arg) :: arg when arg: var
  def open_tab(%BrowserSession{} = session), do: BrowserSession.open_tab(session)
  def open_tab(%StaticSession{} = session), do: StaticSession.open_tab(session)
  def open_tab(%LiveSession{} = session), do: LiveSession.open_tab(session)

  @spec switch_tab(Session.t(), Session.t()) :: Session.t()
  def switch_tab(%BrowserSession{} = session, %BrowserSession{} = target_session) do
    BrowserSession.switch_tab(session, target_session)
  end

  def switch_tab(%BrowserSession{}, _target_session) do
    raise ArgumentError, "cannot switch browser tab to a non-browser session"
  end

  def switch_tab(%StaticSession{} = session, %StaticSession{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    StaticSession.switch_tab(session, target_session)
  end

  def switch_tab(%StaticSession{} = session, %LiveSession{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    StaticSession.switch_tab(session, target_session)
  end

  def switch_tab(%LiveSession{} = session, %StaticSession{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    LiveSession.switch_tab(session, target_session)
  end

  def switch_tab(%LiveSession{} = session, %LiveSession{} = target_session) do
    ensure_same_endpoint!(session, target_session)
    LiveSession.switch_tab(session, target_session)
  end

  @spec close_tab(arg) :: arg when arg: var
  def close_tab(%BrowserSession{} = session), do: BrowserSession.close_tab(session)
  def close_tab(%StaticSession{} = session), do: StaticSession.close_tab(session)
  def close_tab(%LiveSession{} = session), do: LiveSession.close_tab(session)

  @spec unwrap(arg, (term() -> term())) :: arg when arg: var
  def unwrap(_session, fun) when not is_function(fun, 1) do
    raise ArgumentError, "unwrap/2 expects a callback with arity 1"
  end

  def unwrap(%StaticSession{} = session, fun) do
    session.conn
    |> DriverConn.ensure_conn()
    |> fun.()
    |> unwrap_conn_result(session, :static)
  end

  def unwrap(%LiveSession{view: nil}, _fun) do
    raise ArgumentError, "unwrap/2 requires an active LiveView; visit a live route first"
  end

  def unwrap(%LiveSession{} = session, fun) do
    session.view
    |> fun.()
    |> unwrap_live_result(session)
  end

  def unwrap(%BrowserSession{} = session, fun) do
    _ =
      fun.(%{
        user_context_pid: session.user_context_pid,
        tab_id: session.tab_id
      })

    session
  end

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

  @spec text(String.t() | Regex.t(), keyword()) :: keyword()
  def text(value, opts \\ []) when is_list(opts) do
    build_text_locator(:text, value, opts)
  end

  @spec link(String.t() | Regex.t(), keyword()) :: keyword()
  def link(value, opts \\ []) when is_list(opts) do
    build_text_locator(:link, value, opts)
  end

  @spec button(String.t() | Regex.t(), keyword()) :: keyword()
  def button(value, opts \\ []) when is_list(opts) do
    build_text_locator(:button, value, opts)
  end

  @spec label(String.t() | Regex.t(), keyword()) :: keyword()
  def label(value, opts \\ []) when is_list(opts) do
    build_text_locator(:label, value, opts)
  end

  @spec placeholder(String.t() | Regex.t(), keyword()) :: keyword()
  def placeholder(value, opts \\ []) when is_list(opts) do
    build_text_locator(:placeholder, value, opts)
  end

  @spec title(String.t() | Regex.t(), keyword()) :: keyword()
  def title(value, opts \\ []) when is_list(opts) do
    build_text_locator(:title, value, opts)
  end

  @spec alt(String.t() | Regex.t(), keyword()) :: keyword()
  def alt(value, opts \\ []) when is_list(opts) do
    build_text_locator(:alt, value, opts)
  end

  @spec css(String.t()) :: keyword()
  def css(value) when is_binary(value), do: [css: value]

  @spec role(String.t() | atom(), keyword()) :: keyword()
  def role(role, opts \\ []) when is_list(opts) do
    [role: role, name: Keyword.get(opts, :name)]
    |> maybe_put_locator_opt(opts, :exact)
    |> maybe_put_locator_opt(opts, :selector)
  end

  @spec testid(String.t()) :: keyword()
  def testid(value) when is_binary(value), do: [testid: value]

  @spec sigil_l(String.t(), charlist()) :: Locator.t()
  def sigil_l(value, modifiers) when is_list(modifiers), do: Locator.sigil(value, modifiers)

  @spec visit(arg, String.t(), keyword()) :: arg when arg: var
  def visit(session, path, opts \\ []) when is_binary(path) do
    driver_module_for_session!(session).visit(session, path, opts)
  end

  @spec reload_page(arg, keyword()) :: arg when arg: var
  def reload_page(session, opts \\ []) do
    visit(session, current_path(session) || "/", opts)
  end

  @spec current_path(Session.t()) :: String.t() | nil
  def current_path(session) do
    session
    |> Session.current_path()
    |> Path.normalize()
  end

  @spec within(arg, String.t(), (arg -> arg)) :: arg when arg: var
  def within(%LiveSession{} = session, scope, callback) when is_binary(scope) and is_function(callback, 1) do
    if String.trim(scope) == "" do
      raise ArgumentError, "within/3 expects a non-empty CSS selector"
    end

    previous_scope = Session.scope(session)

    case live_child_view_for_scope(session, scope) do
      {:ok, child_view} ->
        child_session =
          session
          |> Map.put(:view, child_view)
          |> Map.put(:html, Phoenix.LiveViewTest.render(child_view))
          |> Session.with_scope(nil)

        callback_result = callback.(child_session)
        restore_live_child_scope(callback_result, session, previous_scope)

      :error ->
        scoped_session = Session.with_scope(session, compose_scope(previous_scope, scope))
        callback_result = callback.(scoped_session)
        restore_scope(callback_result, previous_scope)
    end
  end

  def within(session, scope, callback) when is_binary(scope) and is_function(callback, 1) do
    if String.trim(scope) == "" do
      raise ArgumentError, "within/3 expects a non-empty CSS selector"
    end

    previous_scope = Session.scope(session)
    scoped_session = Session.with_scope(session, compose_scope(previous_scope, scope))
    callback_result = callback.(scoped_session)

    restore_scope(callback_result, previous_scope)
  end

  @spec assert_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def assert_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    call_has_timeout = Keyword.has_key?(opts, :timeout)
    opts = Options.validate_path!(opts, "assert_path/3")
    {validated_timeout, opts} = Keyword.pop(opts, :timeout, 0)
    timeout = resolve_path_timeout(session, call_has_timeout, validated_timeout)

    case session do
      %BrowserSession{} ->
        run_browser_path_assertion!(session, expected, opts, timeout, :assert_path)

      _other ->
        run_non_browser_path_assertion(session, expected, opts, timeout, :assert_path)
    end
  end

  @spec refute_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def refute_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    call_has_timeout = Keyword.has_key?(opts, :timeout)
    opts = Options.validate_path!(opts, "refute_path/3")
    {validated_timeout, opts} = Keyword.pop(opts, :timeout, 0)
    timeout = resolve_path_timeout(session, call_has_timeout, validated_timeout)

    case session do
      %BrowserSession{} ->
        run_browser_path_assertion!(session, expected, opts, timeout, :refute_path)

      _other ->
        run_non_browser_path_assertion(session, expected, opts, timeout, :refute_path)
    end
  end

  @spec click(arg, term(), Options.click_opts()) :: arg when arg: var
  def click(session, locator, opts \\ []) do
    Assertions.click(session, locator, opts)
  end

  @spec click_link(arg, term(), Options.click_opts()) :: arg when arg: var
  def click_link(session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :link))
  end

  @spec click_button(arg, term(), Options.click_opts()) :: arg when arg: var
  def click_button(session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :button))
  end

  @spec fill_in(arg, term(), Options.fill_in_value(), Options.fill_in_opts()) :: arg when arg: var
  def fill_in(session, locator, value, opts \\ []) when is_list(opts) do
    Assertions.fill_in(session, locator, value, opts)
  end

  @spec upload(arg, term(), String.t(), Options.upload_opts()) :: arg when arg: var
  def upload(session, locator, path, opts \\ [])

  def upload(session, locator, path, opts) when is_binary(path) and is_list(opts) do
    Assertions.upload(session, locator, path, opts)
  end

  def upload(_session, _locator, _path, _opts) do
    raise ArgumentError, "upload/4 expects a non-empty path string and keyword options"
  end

  @spec submit(arg, term(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator, opts \\ []) do
    Assertions.submit(session, locator, opts)
  end

  @spec select(arg, term()) :: arg when arg: var
  def select(session, locator), do: select(session, locator, [])

  @spec select(arg, term(), Options.select_opts()) :: arg when arg: var
  def select(session, locator, opts) when is_list(opts) do
    Assertions.select(session, locator, opts)
  end

  @spec choose(arg, term()) :: arg when arg: var
  def choose(session, locator), do: choose(session, locator, [])

  @spec choose(arg, term(), Options.choose_opts()) :: arg when arg: var
  def choose(session, locator, opts) when is_list(opts) do
    Assertions.choose(session, locator, opts)
  end

  @spec check(arg, term()) :: arg when arg: var
  def check(session, locator), do: check(session, locator, [])

  @spec check(arg, term(), Options.check_opts()) :: arg when arg: var
  def check(session, locator, opts) when is_list(opts) do
    Assertions.check(session, locator, opts)
  end

  @spec uncheck(arg, term()) :: arg when arg: var
  def uncheck(session, locator), do: uncheck(session, locator, [])

  @spec uncheck(arg, term(), Options.check_opts()) :: arg when arg: var
  def uncheck(session, locator, opts) when is_list(opts) do
    Assertions.uncheck(session, locator, opts)
  end

  @spec assert_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, locator, opts \\ []) do
    Assertions.assert_has(session, locator, opts)
  end

  @spec refute_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator, opts \\ []) do
    Assertions.refute_has(session, locator, opts)
  end

  defp driver_module_for_session!(%StaticSession{}), do: StaticSession
  defp driver_module_for_session!(%LiveSession{}), do: LiveSession
  defp driver_module_for_session!(%BrowserSession{}), do: BrowserSession

  defp driver_module_for_session!(session) do
    raise ArgumentError,
          "unsupported session #{inspect(session)}; expected a Cerberus session"
  end

  defp restore_scope(%{__struct__: _} = session, previous_scope) do
    Session.with_scope(session, previous_scope)
  end

  defp restore_scope(_value, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp compose_scope(nil, scope), do: scope
  defp compose_scope("", scope), do: scope
  defp compose_scope(previous_scope, scope), do: previous_scope <> " " <> scope

  defp restore_live_child_scope(%{__struct__: _} = callback_result, parent_session, previous_scope) do
    case callback_result do
      %LiveSession{} = live_result ->
        if Session.current_path(live_result) == Session.current_path(parent_session) do
          live_result
          |> Map.put(:view, parent_session.view)
          |> Map.put(:html, Phoenix.LiveViewTest.render(parent_session.view))
          |> Session.with_scope(previous_scope)
        else
          Session.with_scope(live_result, previous_scope)
        end

      _ ->
        Session.with_scope(callback_result, previous_scope)
    end
  end

  defp restore_live_child_scope(_value, _parent_session, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp live_child_view_for_scope(%LiveSession{view: %View{} = view}, scope) when is_binary(scope) do
    if simple_id_selector?(scope) do
      case Phoenix.LiveViewTest.find_live_child(view, String.trim_leading(scope, "#")) do
        %View{} = child_view -> {:ok, child_view}
        _ -> :error
      end
    else
      :error
    end
  end

  defp live_child_view_for_scope(_session, _scope), do: :error

  defp simple_id_selector?(scope), do: String.match?(scope, ~r/^#[A-Za-z_][A-Za-z0-9_-]*$/)

  defp update_last_result(%{last_result: _} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

  defp run_browser_path_assertion!(session, expected, opts, timeout, op) when op in [:assert_path, :refute_path] do
    browser_opts = Keyword.put(opts, :timeout, timeout)
    run_fun = if op == :assert_path, do: &BrowserSession.assert_path/3, else: &BrowserSession.refute_path/3

    case run_fun.(session, expected, browser_opts) do
      {:ok, timed_session, observed} ->
        update_last_result(timed_session, op, observed)

      {:error, _failed_session, observed, _reason} ->
        raise AssertionError, message: format_path_error(Atom.to_string(op), observed)
    end
  end

  defp run_non_browser_path_assertion(session, expected, opts, timeout, op) when op in [:assert_path, :refute_path] do
    LiveViewTimeout.with_timeout(session, timeout, fn timed_session ->
      observed = build_path_observed(timed_session, expected, opts, timeout)
      matches? = observed.path_match? and observed.query_match?
      should_pass? = if op == :assert_path, do: matches?, else: not matches?

      if should_pass? do
        update_last_result(timed_session, op, observed)
      else
        raise AssertionError, message: format_path_error(Atom.to_string(op), observed)
      end
    end)
  end

  defp build_path_observed(session, expected, opts, timeout) do
    refreshed_session = refresh_path_assertion_session(session)
    actual_path = current_path(refreshed_session)
    path_match? = Path.match_path?(actual_path, expected, exact: Keyword.fetch!(opts, :exact))
    query_match? = Path.query_matches?(actual_path, Keyword.get(opts, :query))

    %{
      path: actual_path,
      scope: Session.scope(refreshed_session),
      expected: expected,
      query: Path.normalize_expected_query(Keyword.get(opts, :query)),
      exact: Keyword.fetch!(opts, :exact),
      timeout: timeout,
      path_match?: path_match?,
      query_match?: query_match?
    }
  end

  defp resolve_path_timeout(_session, true, validated_timeout), do: validated_timeout
  defp resolve_path_timeout(%LiveSession{} = session, false, _validated_timeout), do: Session.assert_timeout_ms(session)

  defp resolve_path_timeout(%BrowserSession{} = session, false, _validated_timeout),
    do: Session.assert_timeout_ms(session)

  defp resolve_path_timeout(_session, false, _validated_timeout), do: 0

  defp refresh_path_assertion_session(%BrowserSession{} = session), do: BrowserSession.refresh_path(session)
  defp refresh_path_assertion_session(session), do: session

  defp unwrap_conn_result(%Plug.Conn{} = conn, session, from_driver) when from_driver in [:static, :live] do
    case redirect_target(conn) do
      nil ->
        build_session_from_conn(session, conn, from_driver)

      redirect_path ->
        redirected_session =
          session
          |> static_seed_from_session(conn)
          |> visit(redirect_path)

        transition =
          transition(
            from_driver,
            Session.driver_kind(redirected_session),
            :unwrap,
            session.current_path,
            Session.current_path(redirected_session)
          )

        update_last_result(redirected_session, :unwrap, %{
          path: Session.current_path(redirected_session),
          mode: Session.driver_kind(redirected_session),
          transition: transition
        })
    end
  end

  defp unwrap_conn_result(other, _session, _from_driver) do
    raise ArgumentError,
          "unwrap callback must return a Plug.Conn in static mode, got: #{inspect(other)}"
  end

  defp unwrap_live_result({:ok, %Plug.Conn{} = conn}, %LiveSession{} = session) do
    unwrap_conn_result(conn, session, :live)
  end

  defp unwrap_live_result(%Plug.Conn{} = conn, %LiveSession{} = session) do
    unwrap_conn_result(conn, session, :live)
  end

  defp unwrap_live_result({:ok, %View{} = view, html}, %LiveSession{} = session) when is_binary(html) do
    build_live_session_from_view(session, view, html)
  end

  defp unwrap_live_result({:ok, %View{} = view, _extra}, %LiveSession{} = session) do
    build_live_session_from_view(session, view, Phoenix.LiveViewTest.render(view))
  end

  defp unwrap_live_result(%View{} = view, %LiveSession{} = session) do
    build_live_session_from_view(session, view, Phoenix.LiveViewTest.render(view))
  end

  defp unwrap_live_result({:error, {kind, %{to: to}}}, %LiveSession{} = session)
       when kind in [:redirect, :live_redirect] and is_binary(to) do
    redirected = LiveSession.follow_redirect(session, to)

    transition =
      transition(
        :live,
        Session.driver_kind(redirected),
        kind,
        session.current_path,
        Session.current_path(redirected)
      )

    update_last_result(redirected, :unwrap, %{
      path: Session.current_path(redirected),
      mode: Session.driver_kind(redirected),
      transition: transition
    })
  end

  defp unwrap_live_result({:error, {:live_patch, %{to: to}}}, %LiveSession{} = session) when is_binary(to) do
    path = Path.normalize(to) || session.current_path
    html = Phoenix.LiveViewTest.render(session.view)
    transition = transition(:live, :live, :live_patch, session.current_path, path)

    session
    |> Map.put(:html, html)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, mode: :live, transition: transition})
  end

  defp unwrap_live_result(rendered, %LiveSession{} = session) when is_binary(rendered) do
    path = maybe_live_patch_path(session.view, session.current_path)
    transition = transition(:live, :live, :unwrap, session.current_path, path)

    session
    |> Map.put(:html, rendered)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, mode: :live, transition: transition})
  end

  defp unwrap_live_result(other, _session) do
    raise ArgumentError,
          "unwrap callback in live mode must return render output, redirect tuple, view, or Plug.Conn; got: #{inspect(other)}"
  end

  defp build_session_from_conn(session, conn, from_driver) do
    current_path = DriverConn.current_path(conn, session.current_path)

    case try_live(conn) do
      {:ok, view, html} ->
        transition = transition(from_driver, :live, :unwrap, session.current_path, current_path)

        %LiveSession{
          endpoint: session.endpoint,
          conn: conn,
          view: view,
          html: html,
          form_data: Map.get(session, :form_data),
          scope: session.scope,
          current_path: current_path,
          last_result: %{op: :unwrap, observed: %{path: current_path, mode: :live, transition: transition}}
        }

      :error ->
        transition = transition(from_driver, :static, :unwrap, session.current_path, current_path)

        %StaticSession{
          endpoint: session.endpoint,
          conn: conn,
          html: conn.resp_body || "",
          form_data: Map.get(session, :form_data),
          scope: session.scope,
          current_path: current_path,
          last_result: %{op: :unwrap, observed: %{path: current_path, mode: :static, transition: transition}}
        }
    end
  end

  defp build_live_session_from_view(session, view, html) do
    path = maybe_live_patch_path(view, session.current_path)
    transition = transition(:live, :live, :unwrap, session.current_path, path)

    session
    |> Map.put(:view, view)
    |> Map.put(:html, html)
    |> Map.put(:current_path, path)
    |> update_last_result(:unwrap, %{path: path, mode: :live, transition: transition})
  end

  defp static_seed_from_session(session, conn) do
    %StaticSession{
      endpoint: session.endpoint,
      conn: conn,
      html: conn.resp_body || "",
      form_data: Map.get(session, :form_data),
      scope: session.scope,
      current_path: DriverConn.current_path(conn, session.current_path),
      last_result: session.last_result
    }
  end

  defp redirect_target(%Plug.Conn{status: status} = conn) when status in 300..399 do
    case Plug.Conn.get_resp_header(conn, "location") do
      [location | _] -> Path.normalize(location)
      _ -> nil
    end
  end

  defp redirect_target(_conn), do: nil

  defp try_live(conn) do
    case Phoenix.LiveViewTest.__live__(conn, nil, []) do
      {:ok, view, html} -> {:ok, view, html}
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp maybe_live_patch_path(nil, fallback_path), do: fallback_path

  defp maybe_live_patch_path(view, fallback_path) do
    path = Phoenix.LiveViewTest.assert_patch(view, 0)
    Path.normalize(path) || fallback_path
  rescue
    ArgumentError -> fallback_path
  end

  defp transition(from_driver, to_driver, reason, from_path, to_path) do
    %{
      from_driver: from_driver,
      to_driver: to_driver,
      reason: reason,
      from_path: from_path,
      to_path: to_path
    }
  end

  defp ensure_same_endpoint!(%{endpoint: endpoint}, %{endpoint: endpoint}), do: :ok

  defp ensure_same_endpoint!(_session, _target_session) do
    raise ArgumentError, "cannot switch tab across sessions with different endpoints"
  end

  defp build_text_locator(kind, value, opts) do
    [{kind, value}]
    |> maybe_put_locator_opt(opts, :exact)
    |> maybe_put_locator_opt(opts, :selector)
  end

  defp maybe_put_locator_opt(locator, opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> Keyword.put(locator, key, value)
      :error -> locator
    end
  end

  defp format_path_error(op, observed) do
    """
    #{op} failed: expected path assertion did not hold
    actual_path: #{inspect(observed.path)}
    expected_path: #{inspect(observed.expected)}
    expected_query: #{inspect(observed.query)}
    scope: #{inspect(observed.scope)}
    exact: #{inspect(observed.exact)}
    timeout: #{inspect(observed.timeout)}
    path_match?: #{inspect(observed.path_match?)}
    query_match?: #{inspect(observed.query_match?)}
    """
  end
end
