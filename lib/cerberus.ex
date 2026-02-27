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
  alias Cerberus.Options
  alias Cerberus.Session

  @type driver_kind :: Session.driver_kind()

  @spec session(driver_kind(), keyword()) :: Session.t()
  def session(driver, opts \\ []) do
    driver_module!(driver).new_session(opts)
  end

  @spec visit(Session.t(), String.t(), keyword()) :: Session.t()
  def visit(%Session{} = session, path, opts \\ []) when is_binary(path) do
    driver_module!(session.driver).visit(session, path, opts)
  end

  @spec reload_page(Session.t(), keyword()) :: Session.t()
  def reload_page(%Session{} = session, opts \\ []) do
    visit(session, session.current_path || "/", opts)
  end

  @spec click(Session.t(), term(), Options.click_opts()) :: Session.t()
  def click(%Session{} = session, locator, opts \\ []) do
    Assertions.click(session, locator, opts)
  end

  @spec click_link(Session.t(), term(), Options.click_opts()) :: Session.t()
  def click_link(%Session{} = session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :link))
  end

  @spec click_button(Session.t(), term(), Options.click_opts()) :: Session.t()
  def click_button(%Session{} = session, locator, opts \\ []) do
    click(session, locator, Keyword.put(opts, :kind, :button))
  end

  @spec fill_in(Session.t(), term(), Options.fill_in_value(), Options.fill_in_opts()) ::
          Session.t()
  def fill_in(%Session{} = session, locator, value, opts \\ []) when is_list(opts) do
    Assertions.fill_in(session, locator, value, opts)
  end

  @spec submit(Session.t(), term(), Options.submit_opts()) :: Session.t()
  def submit(%Session{} = session, locator, opts \\ []) do
    Assertions.submit(session, locator, opts)
  end

  @spec select(Session.t(), term(), keyword()) :: Session.t()
  def select(%Session{} = session, locator, opts \\ []) do
    Assertions.unsupported(session, :select, [locator: locator] ++ opts)
  end

  @spec choose(Session.t(), term(), keyword()) :: Session.t()
  def choose(%Session{} = session, locator, opts \\ []) do
    Assertions.unsupported(session, :choose, [locator: locator] ++ opts)
  end

  @spec check(Session.t(), term(), keyword()) :: Session.t()
  def check(%Session{} = session, locator, opts \\ []) do
    Assertions.unsupported(session, :check, [locator: locator] ++ opts)
  end

  @spec uncheck(Session.t(), term(), keyword()) :: Session.t()
  def uncheck(%Session{} = session, locator, opts \\ []) do
    Assertions.unsupported(session, :uncheck, [locator: locator] ++ opts)
  end

  @spec assert_has(Session.t(), term(), Options.assert_opts()) :: Session.t()
  def assert_has(%Session{} = session, locator, opts \\ []) do
    Assertions.assert_has(session, locator, opts)
  end

  @spec refute_has(Session.t(), term(), Options.assert_opts()) :: Session.t()
  def refute_has(%Session{} = session, locator, opts \\ []) do
    Assertions.refute_has(session, locator, opts)
  end

  @spec driver_module!(driver_kind()) :: module()
  def driver_module!(:static), do: Cerberus.Driver.Static
  def driver_module!(:live), do: Cerberus.Driver.Live
  def driver_module!(:browser), do: Cerberus.Driver.Browser

  def driver_module!(driver) do
    raise ArgumentError,
          "unsupported driver #{inspect(driver)}; expected one of :static, :live, :browser"
  end
end
