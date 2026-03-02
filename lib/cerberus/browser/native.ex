defmodule Cerberus.Browser.Native do
  @moduledoc """
  Opaque browser unwrap handle returned by `Cerberus.unwrap/2`.

  This is an escape hatch for advanced debugging and migration scenarios.
  It intentionally exposes a minimal surface and is not a stable low-level
  browser driver contract.
  """

  @enforce_keys [:user_context_pid, :tab_id]
  defstruct [:user_context_pid, :tab_id]

  @opaque t :: %__MODULE__{
            user_context_pid: pid(),
            tab_id: String.t()
          }

  @doc "Returns the browser user-context process identifier for this unwrap handle."
  @spec user_context_pid(t()) :: pid()
  def user_context_pid(%__MODULE__{user_context_pid: user_context_pid}), do: user_context_pid

  @doc "Returns the active browser tab id for this unwrap handle."
  @spec tab_id(t()) :: String.t()
  def tab_id(%__MODULE__{tab_id: tab_id}), do: tab_id
end
