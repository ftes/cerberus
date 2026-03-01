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

  @spec apply_count_constraints(non_neg_integer(), keyword()) :: :ok | {:error, String.t()}
  def apply_count_constraints(match_count, opts) when is_integer(match_count) and match_count >= 0 do
    with :ok <- check_count_opt(match_count, Keyword.get(opts, :count)),
         :ok <- check_min_opt(match_count, Keyword.get(opts, :min)),
         :ok <- check_max_opt(match_count, Keyword.get(opts, :max)) do
      check_between_opt(match_count, Keyword.get(opts, :between))
    end
  end

  @spec has_count_constraints?(keyword()) :: boolean()
  def has_count_constraints?(opts) when is_list(opts) do
    not is_nil(Keyword.get(opts, :count)) or
      not is_nil(Keyword.get(opts, :min)) or
      not is_nil(Keyword.get(opts, :max)) or
      not is_nil(Keyword.get(opts, :between))
  end

  @spec assertion_count_outcome(non_neg_integer(), keyword(), :assert | :refute) ::
          :ok | {:error, String.t()}
  def assertion_count_outcome(match_count, opts, :assert) when is_integer(match_count) and match_count >= 0 do
    if has_count_constraints?(opts) do
      apply_count_constraints(match_count, opts)
    else
      assert_default_count_outcome(match_count)
    end
  end

  def assertion_count_outcome(match_count, opts, :refute) when is_integer(match_count) and match_count >= 0 do
    if has_count_constraints?(opts) do
      refute_constraint_count_outcome(match_count, opts)
    else
      refute_default_count_outcome(match_count)
    end
  end

  defp assert_default_count_outcome(match_count) do
    if match_count > 0, do: :ok, else: {:error, "expected text not found"}
  end

  defp refute_default_count_outcome(match_count) do
    if match_count == 0, do: :ok, else: {:error, "unexpected matching text found"}
  end

  defp refute_constraint_count_outcome(match_count, opts) do
    case apply_count_constraints(match_count, opts) do
      :ok -> {:error, "unexpected matching text count satisfied constraints"}
      {:error, _reason} -> :ok
    end
  end

  @spec pick_match([term()], keyword()) :: {:ok, term()} | {:error, String.t()}
  def pick_match(matches, opts) when is_list(matches) do
    match_count = length(matches)

    with :ok <- apply_count_constraints(match_count, opts),
         :ok <- ensure_non_empty(matches),
         {:ok, index} <- resolve_position_index(match_count, opts) do
      {:ok, Enum.at(matches, index)}
    end
  end

  defp ensure_non_empty([]), do: {:error, "no elements matched locator"}
  defp ensure_non_empty(_matches), do: :ok

  defp resolve_position_index(match_count, opts) when is_integer(match_count) and match_count > 0 do
    case position_target(opts) do
      {:error, reason} ->
        {:error, reason}

      {:first, _value} ->
        {:ok, 0}

      {:last, _value} ->
        {:ok, match_count - 1}

      {:nth, nth} ->
        nth_index = nth - 1
        ensure_index_in_bounds(nth_index, match_count, "nth=#{nth}")

      {:index, index} ->
        ensure_index_in_bounds(index, match_count, "index=#{index}")

      :none ->
        {:ok, 0}
    end
  end

  defp position_target(opts) do
    candidates =
      []
      |> maybe_add_position(:first, Keyword.get(opts, :first))
      |> maybe_add_position(:last, Keyword.get(opts, :last))
      |> maybe_add_position(:nth, Keyword.get(opts, :nth))
      |> maybe_add_position(:index, Keyword.get(opts, :index))

    case candidates do
      [] -> :none
      [single] -> single
      _many -> {:error, "position options are mutually exclusive; use only one of :first, :last, :nth, or :index"}
    end
  end

  defp maybe_add_position(acc, _key, false), do: acc
  defp maybe_add_position(acc, _key, nil), do: acc
  defp maybe_add_position(acc, key, value), do: acc ++ [{key, value}]

  defp ensure_index_in_bounds(index, match_count, label) when index < 0 or index >= match_count do
    {:error, "#{label} is out of bounds for #{match_count} matched element(s)"}
  end

  defp ensure_index_in_bounds(index, _match_count, _label), do: {:ok, index}

  defp check_count_opt(_match_count, nil), do: :ok

  defp check_count_opt(match_count, expected) do
    if match_count == expected do
      :ok
    else
      {:error, "expected exactly #{expected} matched element(s), got #{match_count}"}
    end
  end

  defp check_min_opt(_match_count, nil), do: :ok

  defp check_min_opt(match_count, min) do
    if match_count >= min do
      :ok
    else
      {:error, "expected at least #{min} matched element(s), got #{match_count}"}
    end
  end

  defp check_max_opt(_match_count, nil), do: :ok

  defp check_max_opt(match_count, max) do
    if match_count <= max do
      :ok
    else
      {:error, "expected at most #{max} matched element(s), got #{match_count}"}
    end
  end

  defp check_between_opt(_match_count, nil), do: :ok

  defp check_between_opt(match_count, {min, max}) do
    if match_count >= min and match_count <= max do
      :ok
    else
      {:error, "expected matched element count between #{min} and #{max}, got #{match_count}"}
    end
  end
end
