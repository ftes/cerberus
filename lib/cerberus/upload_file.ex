defmodule Cerberus.UploadFile do
  @moduledoc false

  @spec read!(String.t()) :: %{
          content: binary(),
          file_name: String.t(),
          size: non_neg_integer(),
          mime_type: String.t(),
          last_modified: tuple() | non_neg_integer(),
          last_modified_unix_ms: non_neg_integer()
        }
  def read!(path) when is_binary(path) do
    if String.trim(path) == "" do
      raise ArgumentError, "upload path must be a non-empty string"
    end

    file_stat = File.stat!(path)
    content = File.read!(path)
    file_name = Path.basename(path)

    %{
      content: content,
      file_name: file_name,
      size: file_stat.size,
      mime_type: mime_type(path),
      last_modified: file_stat.mtime,
      last_modified_unix_ms: to_unix_ms(file_stat.mtime)
    }
  end

  @spec mime_type(String.t()) :: String.t()
  def mime_type(path) when is_binary(path) do
    ext = path |> Path.extname() |> String.downcase()
    mime_type_from_ext(ext)
  end

  defp mime_type_from_ext(".jpg"), do: "image/jpeg"
  defp mime_type_from_ext(".jpeg"), do: "image/jpeg"
  defp mime_type_from_ext(".png"), do: "image/png"
  defp mime_type_from_ext(".gif"), do: "image/gif"
  defp mime_type_from_ext(".webp"), do: "image/webp"
  defp mime_type_from_ext(".txt"), do: "text/plain"
  defp mime_type_from_ext(".pdf"), do: "application/pdf"
  defp mime_type_from_ext(_), do: "application/octet-stream"

  defp to_unix_ms({{_, _, _}, {_, _, _}} = datetime) do
    datetime
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix(:millisecond)
  end

  defp to_unix_ms(value) when is_integer(value), do: value * 1000
  defp to_unix_ms(_), do: DateTime.to_unix(DateTime.utc_now(), :millisecond)
end
