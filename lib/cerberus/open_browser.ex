defmodule Cerberus.OpenBrowser do
  @moduledoc false

  alias Cerberus.Html

  @spec write_snapshot!(LazyHTML.t(), String.t() | nil, module() | nil) :: String.t()
  def write_snapshot!(%LazyHTML{} = document, base_url \\ nil, endpoint \\ nil) do
    path = Path.join([System.tmp_dir!(), "cerberus-open-browser#{System.unique_integer([:monotonic])}.html"])

    document
    |> LazyHTML.to_html()
    |> maybe_wrap_snapshot(base_url)
    |> rewrite_static_paths(endpoint)
    |> then(&File.write!(path, &1))

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

  defp rewrite_static_paths(html, nil), do: html

  defp rewrite_static_paths(html, endpoint) when is_atom(endpoint) do
    case static_path(endpoint) do
      nil ->
        html

      static_path ->
        html
        |> Html.parse!()
        |> LazyHTML.to_tree()
        |> LazyHTML.Tree.postwalk(&prefix_static_paths(&1, static_path))
        |> LazyHTML.Tree.to_html()
    end
  end

  defp rewrite_static_paths(html, _endpoint), do: html

  defp static_path(endpoint) do
    static_url = endpoint.config(:static_url) || []

    case endpoint.config(:otp_app) do
      otp_app when is_atom(otp_app) ->
        priv_dir = Application.app_dir(otp_app, "priv")
        if Keyword.get(static_url, :path), do: priv_dir, else: Path.join(priv_dir, "static")

      _ ->
        nil
    end
  end

  defp prefix_static_paths(node, static_path) do
    case node do
      {"script", _, _} ->
        []

      {"a", _, _} = link ->
        link

      {tag, attrs, children} ->
        {tag, maybe_prefix_static_path(attrs, static_path), children}

      other ->
        other
    end
  end

  defp maybe_prefix_static_path(attrs, static_path) when is_list(attrs) and is_binary(static_path) do
    Enum.map(attrs, fn
      {"src", path} -> {"src", prefix_static_path(path, static_path)}
      {"href", path} -> {"href", prefix_static_path(path, static_path)}
      attr -> attr
    end)
  end

  defp prefix_static_path(<<"//" <> _::binary>> = url, _prefix), do: url
  defp prefix_static_path(<<"/" <> _::binary>> = path, prefix), do: "file://#{Path.join([prefix, path])}"
  defp prefix_static_path(url, _prefix), do: url
end
