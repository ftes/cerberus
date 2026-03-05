defmodule Cerberus.TestSupport.PhoenixTestPlaywright.Driver do
  @moduledoc false

  @prefix "/phoenix_test/playwright"

  def current_path(session) do
    session
    |> Cerberus.current_path(return_result: true)
    |> strip_prefix()
  end

  def render_page_title(session) do
    live_title =
      case session do
        %{view: view} when not is_nil(view) ->
          if function_exported?(Phoenix.LiveViewTest, :page_title, 1) do
            Phoenix.LiveViewTest.page_title(view)
          end

        _ ->
          nil
      end

    if is_binary(live_title) and live_title != "" do
      normalize_title(live_title)
    else
      render_page_title_from_html(session)
    end
  end

  defp render_page_title_from_html(session) do
    html = render_html(session)

    case Regex.run(~r/<title[^>]*>(.*?)<\/title>/si, html, capture: :all_but_first) do
      [title] -> normalize_title(title)
      _ -> nil
    end
  end

  defp normalize_title(title), do: title |> String.replace(~r/\s+/, " ") |> String.trim()

  def render_html(%{html: html}) when is_binary(html), do: html

  def render_html(session) do
    rendered = :erlang.make_ref()
    caller = self()

    _ =
      Cerberus.render_html(session, fn lazy_html ->
        send(caller, {rendered, inspect(lazy_html)})
      end)

    receive do
      {^rendered, html} -> html
    after
      1000 -> ""
    end
  end

  defp strip_prefix(nil), do: nil

  defp strip_prefix(path) when is_binary(path) do
    cond do
      String.starts_with?(path, @prefix <> "/") -> String.replace_prefix(path, @prefix, "")
      path == @prefix -> "/"
      true -> path
    end
  end
end
