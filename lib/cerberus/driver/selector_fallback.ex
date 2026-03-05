defmodule Cerberus.Driver.SelectorFallback do
  @moduledoc false

  alias Cerberus.Locator

  @selected_option_selector_regex ~r/^select\[name=(['"])(?<name>[^'"]+)\1\]\s+option\[value=(['"])(?<value>[^'"]+)\3\]\[selected\]$/u

  @spec selected_option_assertion_values(map(), Locator.t(), true | false | :any) :: [String.t()] | nil
  def selected_option_assertion_values(form_data, %Locator{kind: :css, value: selector}, visible)
      when is_binary(selector) and visible != :hidden do
    case parse_selected_option_selector(selector) do
      {:ok, name, value} ->
        if selected_in_form_data?(form_data, name, value) do
          [value]
        else
          []
        end

      :error ->
        nil
    end
  end

  def selected_option_assertion_values(_form_data, _locator, _visible), do: nil

  defp parse_selected_option_selector(selector) do
    case Regex.named_captures(@selected_option_selector_regex, selector) do
      %{"name" => name, "value" => value} -> {:ok, name, value}
      _ -> :error
    end
  end

  defp selected_in_form_data?(%{values: values}, name, expected_value) when is_map(values) do
    values
    |> Map.values()
    |> Enum.any?(&selected_in_params?(&1, name, expected_value))
  end

  defp selected_in_form_data?(values, name, expected_value) when is_map(values) do
    selected_in_params?(values, name, expected_value)
  end

  defp selected_in_form_data?(_form_data, _name, _expected_value), do: false

  defp selected_in_params?(params, name, expected_value) when is_map(params) do
    case Map.get(params, name) do
      nil ->
        false

      values when is_list(values) ->
        Enum.any?(values, &value_matches?(&1, expected_value))

      value ->
        value_matches?(value, expected_value)
    end
  end

  defp selected_in_params?(_params, _name, _expected_value), do: false

  defp value_matches?(value, expected_value) when is_binary(value), do: value == expected_value
  defp value_matches?(value, expected_value) when is_integer(value), do: Integer.to_string(value) == expected_value
  defp value_matches?(value, expected_value) when is_float(value), do: Float.to_string(value) == expected_value
  defp value_matches?(value, expected_value) when is_atom(value), do: Atom.to_string(value) == expected_value
  defp value_matches?(_value, _expected_value), do: false
end
