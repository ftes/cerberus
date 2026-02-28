defmodule Cerberus.Query do
  @moduledoc """
  Shared query semantics reused by all drivers.

  Per ADR-0001, this module is the semantic source of truth for text matching
  behavior (`exact`, regex/string matching, and string whitespace normalization),
  so driver adapters do not diverge in assertion behavior.
  """

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
