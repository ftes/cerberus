defmodule Cerberus.Driver.Html do
  @moduledoc false

  alias Cerberus.Query

  @spec texts(String.t(), true | false | :any) :: [String.t()]
  def texts(html, visibility \\ true) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, nodes} ->
        {visible, hidden} = collect(nodes, false, {[], []})

        case visibility do
          true -> visible
          false -> hidden
          :any -> visible ++ hidden
        end

      _ ->
        []
    end
  end

  @spec find_link(String.t(), String.t() | Regex.t(), keyword()) ::
          {:ok, %{text: String.t(), href: String.t()}} | :error
  def find_link(html, expected, opts) when is_binary(html) do
    with {:ok, nodes} <- Floki.parse_document(html) do
      nodes
      |> Floki.find("a[href]")
      |> Enum.find_value(:error, fn node ->
        text = node_text(node)

        if Query.match_text?(text, expected, opts) do
          href = Floki.attribute(node, "href") |> List.first()
          {:ok, %{text: text, href: href}}
        else
          false
        end
      end)
    else
      _ -> :error
    end
  end

  @spec find_button(String.t(), String.t() | Regex.t(), keyword()) ::
          {:ok, %{text: String.t()}} | :error
  def find_button(html, expected, opts) when is_binary(html) do
    with {:ok, nodes} <- Floki.parse_document(html) do
      nodes
      |> Floki.find("button")
      |> Enum.find_value(:error, fn node ->
        text = node_text(node)

        if Query.match_text?(text, expected, opts) do
          {:ok, %{text: text}}
        else
          false
        end
      end)
    else
      _ -> :error
    end
  end

  defp collect(nodes, hidden_parent?, acc) when is_list(nodes) do
    Enum.reduce(nodes, acc, fn node, acc ->
      case node do
        text when is_binary(text) ->
          append_text(text, hidden_parent?, acc)

        {"script", _attrs, _children} ->
          acc

        {"style", _attrs, _children} ->
          acc

        {_tag, attrs, children} when is_list(attrs) and is_list(children) ->
          hidden? = hidden_parent? or hidden_element?(attrs)
          collect(children, hidden?, acc)

        _ ->
          acc
      end
    end)
  end

  defp append_text(text, hidden?, {visible, hidden}) do
    text =
      text
      |> String.replace("\u00A0", " ")
      |> String.trim()

    if text == "" do
      {visible, hidden}
    else
      if hidden? do
        {visible, hidden ++ [text]}
      else
        {visible ++ [text], hidden}
      end
    end
  end

  defp hidden_element?(attrs) do
    hidden_attr? = Enum.any?(attrs, fn {name, _} -> to_string(name) == "hidden" end)

    style =
      attrs
      |> Enum.find_value("", fn {name, value} ->
        if to_string(name) == "style", do: String.downcase(to_string(value)), else: false
      end)
      |> String.replace(" ", "")

    hidden_attr? or String.contains?(style, "display:none") or
      String.contains?(style, "visibility:hidden")
  end

  defp node_text(node) do
    node
    |> Floki.text()
    |> String.replace("\u00A0", " ")
    |> String.trim()
  end
end
