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
  alias Cerberus.Driver.Live, as: LiveSession
  alias Cerberus.Driver.Static, as: StaticSession
  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Path
  alias Cerberus.Session
  alias ExUnit.AssertionError

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

  @spec select(arg, term(), keyword()) :: arg when arg: var
  def select(session, locator, opts \\ []) do
    Assertions.unsupported(session, :select, [locator: locator] ++ opts)
  end

  @spec choose(arg, term(), keyword()) :: arg when arg: var
  def choose(session, locator, opts \\ []) do
    Assertions.unsupported(session, :choose, [locator: locator] ++ opts)
  end

  @spec check(arg, term(), keyword()) :: arg when arg: var
  def check(session, locator, opts \\ []) do
    Assertions.unsupported(session, :check, [locator: locator] ++ opts)
  end

  @spec uncheck(arg, term(), keyword()) :: arg when arg: var
  def uncheck(session, locator, opts \\ []) do
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
