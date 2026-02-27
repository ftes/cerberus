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

  @type session_t :: Session.t()
  @type observed :: map()
  @type op_ok :: {:ok, session_t(), observed()}
  @type op_error :: {:error, session_t(), observed(), String.t()}
  @type click_opts :: Options.click_opts()
  @type fill_in_value :: String.t()
  @type fill_in_opts :: Options.fill_in_opts()
  @type submit_opts :: Options.submit_opts()
  @type assert_opts :: Options.assert_opts()

  @callback new_session(keyword()) :: session_t()
  @callback visit(session_t(), String.t(), keyword()) :: session_t()
  @callback click(session_t(), Locator.t(), click_opts()) :: op_ok() | op_error()
  @callback fill_in(session_t(), Locator.t(), fill_in_value(), fill_in_opts()) ::
              op_ok() | op_error()
  @callback submit(session_t(), Locator.t(), submit_opts()) :: op_ok() | op_error()
  @callback assert_has(session_t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
  @callback refute_has(session_t(), Locator.t(), assert_opts()) :: op_ok() | op_error()
end
