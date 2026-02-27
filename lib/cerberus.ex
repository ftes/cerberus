defmodule Cerberus do
  @moduledoc """
  Session-first test API for static, live, and browser execution.

  Architecture contract (ADR-0001 + ADR-0002):
  - The public API is driver-agnostic and session-first.
  - All public operations take a `Cerberus.Session` and return a `Cerberus.Session`.
  - `locator` is the first argument after `session` for locator-based operations.
  - v0 does not expose a public located-element pipeline type.

  Slice 1 provides one-shot operations over deterministic adapters.
  """

  alias Cerberus.Assertions
  alias Cerberus.Driver.Browser, as: BrowserSession
  alias Cerberus.Driver.Conn, as: DriverConn
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.OpenBrowser
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Session
  alias ExUnit.AssertionError
  alias Phoenix.LiveViewTest.View

  @type driver_kind :: Session.driver_kind()

  @spec session(driver_kind(), keyword()) :: Session.t()
  def session(driver, opts \\ []) do
    driver_module!(driver).new_session(opts)
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
    driver_module!(session).open_browser(session, open_fun)
  end

  def open_browser(_session, _open_fun) do
    raise ArgumentError, "open_browser/2 expects a callback with arity 1"
  end

  @spec screenshot(arg) :: arg when arg: var
  def screenshot(session), do: screenshot(session, [])

  @spec screenshot(arg, String.t() | Options.screenshot_opts()) :: arg when arg: var
  def screenshot(%BrowserSession{} = session, path) when is_binary(path) do
    opts = Options.validate_screenshot!(path: path)
    BrowserSession.screenshot(session, opts)
  end

  def screenshot(%BrowserSession{} = session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    BrowserSession.screenshot(session, opts)
  end

  def screenshot(session, path) when is_binary(path) do
    Assertions.unsupported(session, :screenshot, path: path)
  end

  def screenshot(session, opts) when is_list(opts) do
    opts = Options.validate_screenshot!(opts)
    Assertions.unsupported(session, :screenshot, opts)
  end

  def screenshot(_session, _opts) do
    raise ArgumentError, "screenshot/2 expects a path string or keyword options"
  end

  @spec text(String.t() | Regex.t()) :: keyword()
  def text(value), do: [text: value]

  @spec link(String.t() | Regex.t()) :: keyword()
  def link(value), do: [link: value]

  @spec button(String.t() | Regex.t()) :: keyword()
  def button(value), do: [button: value]

  @spec label(String.t() | Regex.t()) :: keyword()
  def label(value), do: [label: value]

  @spec css(String.t()) :: keyword()
  def css(value) when is_binary(value), do: [css: value]

  @spec role(String.t() | atom(), keyword()) :: keyword()
  def role(role, opts \\ []) when is_list(opts) do
    [role: role, name: Keyword.get(opts, :name)]
  end

  @spec testid(String.t()) :: keyword()
  def testid(value) when is_binary(value), do: [testid: value]

  @spec sigil_l(String.t(), charlist()) :: Locator.t()
  def sigil_l(value, modifiers) when is_list(modifiers), do: Locator.sigil(value, modifiers)

  @spec visit(arg, String.t(), keyword()) :: arg when arg: var
  def visit(session, path, opts \\ []) when is_binary(path) do
    driver_module!(session).visit(session, path, opts)
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
  def within(session, scope, callback) when is_binary(scope) and is_function(callback, 1) do
    if String.trim(scope) == "" do
      raise ArgumentError, "within/3 expects a non-empty CSS selector"
    end

    previous_scope = Session.scope(session)
    scoped_session = Session.with_scope(session, scope)
    callback_result = callback.(scoped_session)

    restore_scope(callback_result, previous_scope)
  end

  @spec assert_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def assert_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    opts = Options.validate_path!(opts, "assert_path/3")
    actual_path = current_path(session)
    path_match? = Path.match_path?(actual_path, expected, exact: Keyword.fetch!(opts, :exact))
    query_match? = Path.query_matches?(actual_path, Keyword.get(opts, :query))
    matches? = path_match? and query_match?

    observed = %{
      path: actual_path,
      scope: Session.scope(session),
      expected: expected,
      query: Path.normalize_expected_query(Keyword.get(opts, :query)),
      exact: Keyword.fetch!(opts, :exact),
      path_match?: path_match?,
      query_match?: query_match?
    }

    if matches? do
      update_last_result(session, :assert_path, observed)
    else
      raise AssertionError, message: format_path_error("assert_path", observed)
    end
  end

  @spec refute_path(arg, String.t() | Regex.t(), Options.path_opts()) :: arg when arg: var
  def refute_path(session, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    opts = Options.validate_path!(opts, "refute_path/3")
    actual_path = current_path(session)
    path_match? = Path.match_path?(actual_path, expected, exact: Keyword.fetch!(opts, :exact))
    query_match? = Path.query_matches?(actual_path, Keyword.get(opts, :query))
    matches? = path_match? and query_match?

    observed = %{
      path: actual_path,
      scope: Session.scope(session),
      expected: expected,
      query: Path.normalize_expected_query(Keyword.get(opts, :query)),
      exact: Keyword.fetch!(opts, :exact),
      path_match?: path_match?,
      query_match?: query_match?
    }

    if matches? do
      raise AssertionError, message: format_path_error("refute_path", observed)
    else
      update_last_result(session, :refute_path, observed)
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

  @spec submit(arg, term(), Options.submit_opts()) :: arg when arg: var
  def submit(session, locator, opts \\ []) do
    Assertions.submit(session, locator, opts)
  end

  @spec select(Session.t(), term()) :: no_return()
  def select(session, locator), do: select(session, locator, [])

  @spec select(Session.t(), term(), keyword()) :: no_return()
  def select(session, locator, opts) when is_list(opts) do
    Assertions.unsupported(session, :select, [locator: locator] ++ opts)
  end

  @spec choose(Session.t(), term()) :: no_return()
  def choose(session, locator), do: choose(session, locator, [])

  @spec choose(Session.t(), term(), keyword()) :: no_return()
  def choose(session, locator, opts) when is_list(opts) do
    Assertions.unsupported(session, :choose, [locator: locator] ++ opts)
  end

  @spec check(Session.t(), term()) :: no_return()
  def check(session, locator), do: check(session, locator, [])

  @spec check(Session.t(), term(), keyword()) :: no_return()
  def check(session, locator, opts) when is_list(opts) do
    Assertions.unsupported(session, :check, [locator: locator] ++ opts)
  end

  @spec uncheck(Session.t(), term()) :: no_return()
  def uncheck(session, locator), do: uncheck(session, locator, [])

  @spec uncheck(Session.t(), term(), keyword()) :: no_return()
  def uncheck(session, locator, opts) when is_list(opts) do
    Assertions.unsupported(session, :uncheck, [locator: locator] ++ opts)
  end

  @spec assert_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def assert_has(session, locator, opts \\ []) do
    Assertions.assert_has(session, locator, opts)
  end

  @spec refute_has(arg, term(), Options.assert_opts()) :: arg when arg: var
  def refute_has(session, locator, opts \\ []) do
    Assertions.refute_has(session, locator, opts)
  end

  @spec driver_module!(driver_kind()) :: module()
  def driver_module!(:auto), do: StaticSession
  def driver_module!(:static), do: StaticSession
  def driver_module!(:live), do: LiveSession
  def driver_module!(:browser), do: BrowserSession

  @spec driver_module!(Session.t()) :: module()
  def driver_module!(%StaticSession{}), do: StaticSession
  def driver_module!(%LiveSession{}), do: LiveSession
  def driver_module!(%BrowserSession{}), do: BrowserSession

  def driver_module!(driver) do
    raise ArgumentError,
          "unsupported driver #{inspect(driver)}; expected one of :auto, :static, :live, :browser"
  end

  defp restore_scope(%{__struct__: _} = session, previous_scope) do
    Session.with_scope(session, previous_scope)
  end

  defp restore_scope(_value, _previous_scope) do
    raise ArgumentError, "within/3 callback must return a Cerberus session"
  end

  defp update_last_result(%{last_result: _} = session, op, observed) do
    %{session | last_result: %{op: op, observed: observed}}
  end

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

  defp format_path_error(op, observed) do
    """
    #{op} failed: expected path assertion did not hold
    actual_path: #{inspect(observed.path)}
    expected_path: #{inspect(observed.expected)}
    expected_query: #{inspect(observed.query)}
    scope: #{inspect(observed.scope)}
    exact: #{inspect(observed.exact)}
    path_match?: #{inspect(observed.path_match?)}
    query_match?: #{inspect(observed.query_match?)}
    """
  end
end
