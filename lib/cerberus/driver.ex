defmodule Cerberus.Driver do
  @moduledoc """
  Driver contract for static/live/browser implementations.

  Architectural boundary (ADR-0001):
  - Drivers execute side effects and gather observations.
  - Shared semantics (locator normalization, text matching semantics) live in
    Cerberus core modules, not in individual drivers.
  """

  alias Cerberus.Locator
  alias Cerberus.Session

  @type observed :: map()
  @type op_ok :: {:ok, Session.t(), observed()}
  @type op_error :: {:error, Session.t(), observed(), String.t()}

  @callback new_session(keyword()) :: Session.t()
  @callback visit(Session.t(), String.t(), keyword()) :: Session.t()
  @callback click(Session.t(), Locator.t(), keyword()) :: op_ok() | op_error()
  @callback assert_has(Session.t(), Locator.t(), keyword()) :: op_ok() | op_error()
  @callback refute_has(Session.t(), Locator.t(), keyword()) :: op_ok() | op_error()
end
