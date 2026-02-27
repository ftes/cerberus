defmodule Cerberus.Locator do
  @moduledoc "Normalize user input into a single internal locator representation."

  alias Cerberus.InvalidLocatorError

  @regex_modifiers ~c"imsuxfU"

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

  @spec text_sigil(String.t()) :: t()
  def text_sigil(value) when is_binary(value), do: %__MODULE__{kind: :text, value: value}

  @spec regex_sigil(String.t(), charlist(), atom()) :: t()
  def regex_sigil(value, modifiers, sigil) when is_binary(value) and is_list(modifiers) and is_atom(sigil) do
    invalid = Enum.reject(modifiers, &(&1 in @regex_modifiers))

    if invalid != [] do
      raise InvalidLocatorError,
        locator: {sigil, value, modifiers},
        message:
          "invalid locator sigil ~#{sigil}: unsupported modifier(s) #{inspect(List.to_string(invalid))}; allowed modifiers: #{List.to_string(@regex_modifiers)}"
    end

    flags = List.to_string(modifiers)

    case Regex.compile(value, flags) do
      {:ok, regex} ->
        %__MODULE__{kind: :text, value: regex}

      {:error, reason} ->
        raise InvalidLocatorError,
          locator: {sigil, value, modifiers},
          message: "invalid locator sigil ~#{sigil}: #{inspect(reason)}"
    end
  end

  defp normalize_map(locator_map, original) do
    text = Map.get(locator_map, :text, Map.get(locator_map, "text", :__missing__))

    if !(text != :__missing__ and (is_binary(text) or is_struct(text, Regex))) do
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; :text must be a string or regex for slice 1"
    end

    allowed_keys = MapSet.new([:text, "text"])

    case locator_map |> Map.keys() |> Enum.reject(&MapSet.member?(allowed_keys, &1)) do
      [] ->
        %__MODULE__{kind: :text, value: text}

      extra ->
        raise InvalidLocatorError,
          locator: original,
          message: "unsupported locator keys #{inspect(extra)} in #{inspect(original)}"
    end
  end
end
