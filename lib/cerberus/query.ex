defmodule Cerberus.Query do
  @moduledoc false

  @spec match_text?(String.t(), String.t() | Regex.t(), keyword()) :: boolean()
  def match_text?(actual, expected, opts \\ []) when is_binary(actual) do
    actual = maybe_normalize_ws(actual, opts)

    case expected do
      expected when is_binary(expected) ->
        expected = maybe_normalize_ws(expected, opts)

        if Keyword.get(opts, :exact, false) do
          actual == expected
        else
          String.contains?(actual, expected)
        end

      %Regex{} = expected ->
        Regex.match?(expected, actual)
    end
  end

  defp maybe_normalize_ws(value, opts) do
    if Keyword.get(opts, :normalize_ws, true) do
      value
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    else
      value
    end
  end
end
