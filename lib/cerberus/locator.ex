defmodule Cerberus.Locator do
  @moduledoc "Normalize user input into a single internal locator representation."

  alias Cerberus.InvalidLocatorError

  @enforce_keys [:kind, :value]
  defstruct [:kind, :value]

  @type t :: %__MODULE__{kind: :text, value: String.t() | Regex.t()}

  @spec normalize(term()) :: t()
  def normalize(%__MODULE__{} = locator), do: locator
  def normalize(locator) when is_binary(locator), do: %__MODULE__{kind: :text, value: locator}
  def normalize(%Regex{} = locator), do: %__MODULE__{kind: :text, value: locator}

  def normalize(locator) when is_list(locator) do
    if Keyword.keyword?(locator) do
      locator
      |> Map.new()
      |> normalize_map(locator)
    else
      raise InvalidLocatorError, locator: locator
    end
  end

  def normalize(locator) when is_map(locator) do
    normalize_map(locator, locator)
  end

  def normalize(locator), do: raise(InvalidLocatorError, locator: locator)

  defp normalize_map(locator_map, original) do
    text = Map.get(locator_map, :text, Map.get(locator_map, "text", :__missing__))

    unless text != :__missing__ and (is_binary(text) or is_struct(text, Regex)) do
      raise InvalidLocatorError,
        locator: original,
        message:
          "invalid locator #{inspect(original)}; :text must be a string or regex for slice 1"
    end

    allowed_keys = MapSet.new([:text, "text"])

    case Map.keys(locator_map) |> Enum.reject(&MapSet.member?(allowed_keys, &1)) do
      [] ->
        %__MODULE__{kind: :text, value: text}

      extra ->
        raise InvalidLocatorError,
          locator: original,
          message: "unsupported locator keys #{inspect(extra)} in #{inspect(original)}"
    end
  end
end
