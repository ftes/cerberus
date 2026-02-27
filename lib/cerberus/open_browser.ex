defmodule Cerberus.OpenBrowser do
  @moduledoc false

  @spec write_snapshot!(String.t(), String.t() | nil) :: String.t()
  def write_snapshot!(html, base_url \\ nil) when is_binary(html) do
    path = Path.join([System.tmp_dir!(), "cerberus-open-browser#{System.unique_integer([:monotonic])}.html"])
    File.write!(path, maybe_wrap_snapshot(html, base_url))
    path
  end

  @spec open_with_system_cmd(String.t()) :: :ok
  def open_with_system_cmd(path_or_url) when is_binary(path_or_url) do
    {command, args} =
      case :os.type() do
        {:win32, _} -> {"cmd", ["/c", "start", "", path_or_url]}
        {:unix, :darwin} -> {"open", [path_or_url]}
        _ -> {"xdg-open", [path_or_url]}
      end

    case System.cmd(command, args, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, status} ->
        raise ArgumentError, "open_browser failed (#{command} exit #{status}): #{String.trim(output)}"
    end
  end

  defp maybe_wrap_snapshot(html, nil), do: ensure_html_document(html)

  defp maybe_wrap_snapshot(html, base_url) when is_binary(base_url) do
    html
    |> ensure_html_document()
    |> ensure_base_href(base_url)
  end

  defp ensure_html_document(html) do
    if String.contains?(html, "<html") do
      html
    else
      """
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8" />
        </head>
        <body>
      #{html}
        </body>
      </html>
      """
    end
  end

  defp ensure_base_href(html, base_url) do
    if String.contains?(String.downcase(html), "<base ") do
      html
    else
      base = "<base href=\"#{normalize_base_url(base_url)}\" />"

      cond do
        String.contains?(html, "<head>") ->
          String.replace(html, "<head>", "<head>\n    " <> base, global: false)

        String.contains?(html, "<head ") ->
          Regex.replace(~r/<head[^>]*>/, html, "\\0\n    #{base}", global: false)

        true ->
          """
          <!doctype html>
          <html>
            <head>
              <meta charset="utf-8" />
              #{base}
            </head>
            <body>
          #{html}
            </body>
          </html>
          """
      end
    end
  end

  defp normalize_base_url(base_url) do
    if String.ends_with?(base_url, "/"), do: base_url, else: base_url <> "/"
  end
end
