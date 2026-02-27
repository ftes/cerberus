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
  alias Cerberus.Session

  @type driver_kind :: Session.driver_kind()

  @spec session(driver_kind(), keyword()) :: Session.t()
  def session(driver, opts \\ []) do
    driver_module!(driver).new_session(opts)
  end

  @spec sigil_t(String.t(), charlist()) :: Locator.t()
  def sigil_t(value, []), do: Locator.text_sigil(value)
  def sigil_t(value, modifiers), do: Locator.regex_sigil(value, modifiers, :t)

  @spec sigil_l(String.t(), charlist()) :: Locator.t()
  def sigil_l(value, modifiers), do: sigil_t(value, modifiers)

  @spec sigil_L(String.t(), charlist()) :: Locator.t()
  def sigil_L(value, modifiers), do: Locator.regex_sigil(value, modifiers, :L)

  @spec visit(arg, String.t(), keyword()) :: arg when arg: var
  def visit(session, path, opts \\ []) when is_binary(path) do
    driver_module!(session).visit(session, path, opts)
  end

  @spec reload_page(arg, keyword()) :: arg when arg: var
  def reload_page(session, opts \\ []) do
    visit(session, Session.current_path(session) || "/", opts)
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
end
