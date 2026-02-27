defmodule Cerberus.Session do
  @moduledoc "Runtime test session passed through Cerberus API calls."

  @type driver_kind :: :static | :live | :browser

  @type t :: %__MODULE__{
          driver: driver_kind(),
          driver_state: term(),
          current_path: String.t() | nil,
          last_result: map() | nil,
          meta: map()
        }

  defstruct driver: nil,
            driver_state: nil,
            current_path: nil,
            last_result: nil,
            meta: %{}
end
