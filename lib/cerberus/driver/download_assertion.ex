defmodule Cerberus.Driver.DownloadAssertion do
  @moduledoc false

  alias ExUnit.AssertionError

  @spec assert_from_conn!(map(), String.t()) :: map()
  def assert_from_conn!(%{conn: %Plug.Conn{} = conn} = session, expected_filename) when is_binary(expected_filename) do
    filename = non_empty_text!(expected_filename, "assert_download/3 filename")
    observed_filenames = response_download_filenames(conn)

    if filename in observed_filenames do
      session
    else
      raise AssertionError,
        message:
          "assert_download/3 expected #{inspect(filename)} from response content-disposition; observed downloads: #{inspect(observed_filenames)}"
    end
  end

  def assert_from_conn!(_session, _expected_filename) do
    raise AssertionError,
      message: "assert_download/3 requires a response-backed static/live session with an available conn"
  end

  defp response_download_filenames(conn) do
    conn
    |> Plug.Conn.get_resp_header("content-disposition")
    |> Enum.flat_map(&extract_content_disposition_filenames/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_content_disposition_filenames(header) when is_binary(header) do
    segments =
      header
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    filename_star =
      Enum.find_value(segments, &disposition_segment_value(&1, "filename*", :extended))

    filename =
      Enum.find_value(segments, &disposition_segment_value(&1, "filename", :basic))

    Enum.filter([filename_star, filename], &(is_binary(&1) and &1 != ""))
  end

  defp extract_content_disposition_filenames(_header), do: []

  defp disposition_segment_value(segment, expected_key, mode) when is_binary(segment) and is_binary(expected_key) do
    case String.split(segment, "=", parts: 2) do
      [key, value] ->
        if String.downcase(String.trim(key)) == expected_key do
          decode_disposition_param_value(value, mode)
        end

      _ ->
        nil
    end
  end

  defp decode_disposition_param_value(value, mode) when is_binary(value) do
    value
    |> String.trim()
    |> trim_wrapping_quotes()
    |> decode_disposition_value(mode)
    |> String.trim()
  end

  defp decode_disposition_value(value, :extended) when is_binary(value) do
    case String.split(value, "''", parts: 2) do
      [_charset, encoded] -> URI.decode(encoded)
      _ -> URI.decode(value)
    end
  rescue
    _ -> value
  end

  defp decode_disposition_value(value, :basic), do: value

  defp trim_wrapping_quotes(value) when is_binary(value) do
    if String.starts_with?(value, "\"") and String.ends_with?(value, "\"") and byte_size(value) >= 2 do
      value
      |> String.trim_leading("\"")
      |> String.trim_trailing("\"")
    else
      value
    end
  end

  defp non_empty_text!(value, label) when is_binary(value) do
    if String.trim(value) == "" do
      raise ArgumentError, "#{label} must be a non-empty string"
    else
      value
    end
  end
end
