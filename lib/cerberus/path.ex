defmodule Cerberus.Path do
  @moduledoc false

  alias Cerberus.Query

  @spec normalize(String.t() | nil) :: String.t() | nil
  def normalize(nil), do: nil

  def normalize(path_or_url) when is_binary(path_or_url) do
    uri = URI.parse(path_or_url)
    path = if uri.path in [nil, ""], do: "/", else: uri.path
    query = uri.query

    if is_binary(query) and query != "" do
      path <> "?" <> query
    else
      path
    end
  end

  @spec path_only(String.t() | nil) :: String.t() | nil
  def path_only(nil), do: nil

  def path_only(path_or_url) when is_binary(path_or_url) do
    path_or_url
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> "/"
      "" -> "/"
      path -> path
    end
  end

  @spec query_map(String.t() | nil) :: map()
  def query_map(nil), do: %{}

  def query_map(path_or_url) when is_binary(path_or_url) do
    path_or_url
    |> URI.parse()
    |> Map.get(:query)
    |> decode_query()
  end

  @spec match_path?(String.t() | nil, String.t() | Regex.t(), keyword()) :: boolean()
  def match_path?(actual, expected, opts \\ []) when is_binary(expected) or is_struct(expected, Regex) do
    exact = Keyword.get(opts, :exact, true)
    normalized_actual = normalize(actual) || ""

    case expected do
      %Regex{} = expected_regex ->
        Query.match_text?(normalized_actual, expected_regex, exact: exact, normalize_ws: false)

      expected_binary when is_binary(expected_binary) ->
        normalized_expected = normalize(expected_binary) || expected_binary

        actual_target =
          if String.contains?(normalized_expected, "?") do
            normalized_actual
          else
            path_only(normalized_actual) || ""
          end

        Query.match_text?(actual_target, normalized_expected, exact: exact, normalize_ws: false)
    end
  end

  @spec query_matches?(String.t() | nil, map() | keyword() | nil) :: boolean()
  def query_matches?(_actual, nil), do: true

  def query_matches?(actual_path, expected_query) when is_map(expected_query) or is_list(expected_query) do
    actual = query_map(actual_path)
    expected = normalize_expected_query(expected_query)

    Enum.all?(expected, fn {key, value} ->
      Map.get(actual, key) == value
    end)
  end

  @spec normalize_expected_query(map() | keyword() | nil) :: map() | nil
  def normalize_expected_query(nil), do: nil

  def normalize_expected_query(expected) when is_list(expected) do
    expected
    |> Map.new()
    |> normalize_expected_query()
  end

  def normalize_expected_query(expected) when is_map(expected) do
    Map.new(expected, fn {key, value} ->
      {to_string(key), to_string(value)}
    end)
  end

  defp decode_query(nil), do: %{}
  defp decode_query(""), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
