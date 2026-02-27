defmodule Cerberus.Driver do
  @moduledoc """
  Driver contract for static/live/browser implementations.

  Architectural boundary (ADR-0001):
  - Drivers execute side effects and gather observations.
  - Shared semantics (locator normalization, text matching semantics) live in
    Cerberus core modules, not in individual drivers.
  """

  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Session

  @type observed :: map()
  @type op_ok :: {:ok, Session.t(), observed()}
  @type op_error :: {:error, Session.t(), observed(), String.t()}
  @type click_opts :: Options.click_opts()
  @type fill_in_value :: String.t()
  @type fill_in_opts :: Options.fill_in_opts()
  @type submit_opts :: Options.submit_opts()
  @type assert_opts :: Options.assert_opts()

  @callback new_session(keyword()) :: Session.t()
  @callback visit(Session.t(), String.t(), keyword()) :: Session.t()
  @callback click(Session.t(), Locator.t(), click_opts()) :: op_ok() | op_error()
  @callback fill_in(Session.t(), Locator.t(), fill_in_value(), fill_in_opts()) ::
              op_ok() | op_error()
  @callback submit(Session.t(), Locator.t(), submit_opts()) :: op_ok() | op_error()
  @callback assert_has(Session.t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
  @callback refute_has(Session.t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
end
