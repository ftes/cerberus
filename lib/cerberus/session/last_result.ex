defmodule Cerberus.Session.LastResult do
  @moduledoc false
  alias Cerberus.Session

  @enforce_keys [:op]
  defstruct op: nil, observed: nil, transition: nil

  @type t :: %__MODULE__{
          op: Session.operation(),
          observed: map() | nil,
          transition: map() | nil
        }

  @spec new(Session.operation(), map()) :: t()
  def new(op, observed) when is_atom(op) and is_map(observed), do: new(op, observed, nil)

  @spec new(Session.operation(), term()) :: t()
  def new(op, _observed) when is_atom(op) do
    %__MODULE__{op: op}
  end

  @spec new(Session.operation(), map(), struct() | module() | nil) :: t()
  def new(op, observed, source) when is_atom(op) and is_map(observed) do
    normalized_observed = put_driver(observed, source)

    %__MODULE__{
      op: op,
      observed: normalized_observed,
      transition: normalized_observed[:transition] || normalized_observed["transition"]
    }
  end

  @spec new(Session.operation(), term(), struct() | module() | nil) :: t()
  def new(op, _observed, _source) when is_atom(op) do
    %__MODULE__{op: op}
  end

  defp put_driver(observed, source) when is_map(observed) do
    driver =
      case source do
        %_{} = session -> session.__struct__
        module when is_atom(module) -> module
        _ -> nil
      end

    cond do
      is_nil(driver) ->
        observed

      Map.has_key?(observed, :driver) or Map.has_key?(observed, "driver") ->
        observed

      true ->
        Map.put(observed, :driver, driver)
    end
  end
end
