defmodule Cerberus.Locator do
  @moduledoc "Normalize user input into a single internal locator representation."

  alias Cerberus.InvalidLocatorError

  @enforce_keys [:kind, :value]
  defstruct [:kind, :value]

  @type locator_kind :: :text | :label | :link | :button | :testid
  @type t :: %__MODULE__{kind: locator_kind(), value: String.t() | Regex.t()}

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

  defp normalize_map(locator_map, original) do
    kinds = [
      {:text, key_value(locator_map, :text)},
      {:label, key_value(locator_map, :label)},
      {:link, key_value(locator_map, :link)},
      {:button, key_value(locator_map, :button)},
      {:role, key_value(locator_map, :role)},
      {:testid, key_value(locator_map, :testid)}
    ]

    present =
      kinds
      |> Enum.filter(fn {_kind, value} -> value != :__missing__ end)
      |> Enum.map(fn {kind, _value} -> kind end)

    case present do
      [] ->
        raise InvalidLocatorError,
          locator: original,
          message:
            "invalid locator #{inspect(original)}; expected one of :text, :label, :link, :button, :role, or :testid"

      [kind] ->
        normalize_kind(kind, locator_map, original)

      many ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; expected exactly one locator kind key, got #{inspect(many)}"
    end
  end

  defp normalize_kind(:text, locator_map, original) do
    text = key_value(locator_map, :text)
    ensure_text_value!(:text, text, original)
    ensure_only_keys!(locator_map, original, [:text])
    %__MODULE__{kind: :text, value: text}
  end

  defp normalize_kind(:label, locator_map, original) do
    label = key_value(locator_map, :label)
    ensure_text_value!(:label, label, original)
    ensure_only_keys!(locator_map, original, [:label])
    %__MODULE__{kind: :label, value: label}
  end

  defp normalize_kind(:link, locator_map, original) do
    link = key_value(locator_map, :link)
    ensure_text_value!(:link, link, original)
    ensure_only_keys!(locator_map, original, [:link])
    %__MODULE__{kind: :link, value: link}
  end

  defp normalize_kind(:button, locator_map, original) do
    button = key_value(locator_map, :button)
    ensure_text_value!(:button, button, original)
    ensure_only_keys!(locator_map, original, [:button])
    %__MODULE__{kind: :button, value: button}
  end

  defp normalize_kind(:testid, locator_map, original) do
    testid = key_value(locator_map, :testid)

    if is_binary(testid) and testid != "" do
      ensure_only_keys!(locator_map, original, [:testid])
      %__MODULE__{kind: :testid, value: testid}
    else
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; :testid must be a non-empty string"
    end
  end

  defp normalize_kind(:role, locator_map, original) do
    role = key_value(locator_map, :role)
    name = key_value(locator_map, :name)

    ensure_only_keys!(locator_map, original, [:role, :name])
    ensure_text_value!(:name, name, original)
    role_name = normalize_role_name!(role, original)
    role_kind = role_to_kind!(role_name, original)
    %__MODULE__{kind: role_kind, value: name}
  end

  defp key_value(locator_map, key) when is_atom(key) do
    Map.get(locator_map, key, Map.get(locator_map, Atom.to_string(key), :__missing__))
  end

  defp ensure_text_value!(name, value, original) do
    if is_binary(value) or is_struct(value, Regex) do
      :ok
    else
      raise InvalidLocatorError,
        locator: original,
        message: "invalid locator #{inspect(original)}; #{inspect(name)} must be a string or regex"
    end
  end

  defp ensure_only_keys!(locator_map, original, allowed_atom_keys) do
    allowed =
      allowed_atom_keys
      |> Enum.flat_map(fn key -> [key, Atom.to_string(key)] end)
      |> MapSet.new()

    case locator_map |> Map.keys() |> Enum.reject(&MapSet.member?(allowed, &1)) do
      [] ->
        :ok

      extra ->
        raise InvalidLocatorError,
          locator: original,
          message: "unsupported locator keys #{inspect(extra)} in #{inspect(original)}"
    end
  end

  defp normalize_role_name!(role, original) do
    case role do
      value when is_atom(value) ->
        value |> Atom.to_string() |> String.downcase()

      value when is_binary(value) and value != "" ->
        String.downcase(value)

      _ ->
        raise InvalidLocatorError,
          locator: original,
          message: "invalid locator #{inspect(original)}; :role must be an atom or string"
    end
  end

  defp role_to_kind!("button", _original), do: :button
  defp role_to_kind!("link", _original), do: :link
  defp role_to_kind!("textbox", _original), do: :label
  defp role_to_kind!("searchbox", _original), do: :label
  defp role_to_kind!("combobox", _original), do: :label

  defp role_to_kind!(role_name, original) do
    raise InvalidLocatorError,
      locator: original,
      message: "unsupported :role #{inspect(role_name)} in #{inspect(original)}"
  end
end
