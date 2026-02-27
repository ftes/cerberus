defmodule Cerberus do
  @moduledoc """
  Session-first test API for static, live, and browser execution.

  Architecture contract (ADR-0001 + ADR-0002):
  - The public API is driver-agnostic and session-first.
  - All public operations take a `Cerberus.Session` and return a `Cerberus.Session`.
  - `locator` is the first argument after `session` for locator-based operations.
  - v0 does not expose a public located-element pipeline type.

  Slice 1 currently provides one-shot operations over deterministic adapters.
  """

  alias Cerberus.Assertions
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

  @spec click(Session.t(), term(), keyword()) :: Session.t()
  def click(%Session{} = session, locator, opts \\ []) do
    Assertions.click(session, locator, opts)
  end

  @spec assert_has(Session.t(), term(), keyword()) :: Session.t()
  def assert_has(%Session{} = session, locator, opts \\ []) do
    Assertions.assert_has(session, locator, opts)
  end

  @spec refute_has(Session.t(), term(), keyword()) :: Session.t()
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
