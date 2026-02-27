defmodule Cerberus.Driver.Html do
  @moduledoc false

  alias Cerberus.Query

  @spec texts(String.t(), true | false | :any, String.t() | nil) :: [String.t()]
  def texts(html, visibility \\ true, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        {visible, hidden} =
          lazy_html
          |> scoped_nodes(scope)
          |> Enum.reduce({[], []}, fn root, acc ->
            root
            |> LazyHTML.to_tree()
            |> collect(false, acc)
          end)

        visible = Enum.uniq(visible)
        hidden = Enum.uniq(hidden)

        case visibility do
          true -> visible
          false -> hidden
          :any -> visible ++ hidden
        end

      _ ->
        []
    end
  end

  @spec find_link(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, %{text: String.t(), href: String.t()}} | :error
  def find_link(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_link_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec find_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, %{text: String.t(), selector: String.t() | nil}} | :error
  def find_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_button_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec find_form_field(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, %{label: String.t(), name: String.t(), id: String.t() | nil, form: String.t() | nil}} | :error
  def find_form_field(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_form_field_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec find_submit_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok,
           %{
             text: String.t(),
             action: String.t() | nil,
             method: String.t() | nil,
             form: String.t() | nil,
             button_name: String.t() | nil,
             button_value: String.t() | nil
           }}
          | :error
  def find_submit_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_submit_button_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  defp find_link_in_doc(lazy_html, expected, opts, scope) do
    find_first_matching(lazy_html, "a[href]", expected, opts, scope, fn node, text ->
      %{text: text, href: attr(node, "href")}
    end)
  end

  defp find_button_in_doc(lazy_html, expected, opts, scope) do
    find_first_matching(lazy_html, "button", expected, opts, scope, fn _node, text ->
      %{text: text}
    end)
  end

  defp find_form_field_in_doc(lazy_html, expected, opts, scope) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node -> find_form_field_in_root(root_node, expected, opts) end)
  end

  defp find_submit_button_in_doc(lazy_html, expected, opts, scope) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node ->
      case find_submit_button_in_forms(root_node, expected, opts) do
        {:ok, _button} = ok -> ok
        :error -> find_submit_button_in_owner_form(root_node, expected, opts)
      end
    end)
  end

  defp find_submit_button_in_forms(root_node, expected, opts) do
    root_node
    |> safe_query("form")
    |> Enum.reduce_while(:error, fn form_node, _acc ->
      case find_submit_button_in_form(form_node, expected, opts) do
        {:ok, _button} = ok -> {:halt, ok}
        :error -> {:cont, :error}
      end
    end)
  end

  defp find_submit_button_in_form(form_node, expected, opts) do
    form = attr(form_node, "id")
    action = attr(form_node, "action")
    method = attr(form_node, "method")
    form_meta = %{form: form, action: action, method: method}

    form_node
    |> LazyHTML.query("button")
    |> Enum.find_value(:error, fn button_node ->
      build_submit_button(button_node, form_meta, expected, opts)
    end)
  end

  defp find_submit_button_in_owner_form(root_node, expected, opts) do
    root_node
    |> safe_query("button[form]")
    |> Enum.find_value(:error, fn button_node ->
      owner_form = attr(button_node, "form")

      with true <- is_binary(owner_form) and owner_form != "",
           form_node when not is_nil(form_node) <- form_by_id(root_node, owner_form) do
        action = attr(form_node, "action")
        method = attr(form_node, "method")
        form_meta = %{form: owner_form, action: action, method: method}
        build_submit_button(button_node, form_meta, expected, opts)
      else
        _ -> false
      end
    end)
  end

  defp build_submit_button(button_node, form_meta, expected, opts) do
    text = node_text(button_node)
    type = attr(button_node, "type") || "submit"

    if submit_button_match?(type, text, expected, opts) do
      action = attr(button_node, "formaction") || form_meta.action
      method = attr(button_node, "formmethod") || form_meta.method

      {:ok,
       %{
         text: text,
         action: action,
         method: method,
         form: form_meta.form,
         button_name: attr(button_node, "name"),
         button_value: attr(button_node, "value")
       }}
    else
      false
    end
  end

  defp submit_button_match?(type, text, expected, opts) do
    type in ["submit", ""] and Query.match_text?(text, expected, opts)
  end

  defp find_first_matching(lazy_html, selector, expected, opts, scope, build_fun) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node ->
      find_first_matching_in_root(root_node, lazy_html, selector, expected, opts, build_fun)
    end)
  end

  defp find_form_field_in_root(root_node, expected, opts) do
    root_node
    |> safe_query("label")
    |> Enum.find_value(false, fn label_node -> maybe_form_field_match(label_node, root_node, expected, opts) end)
  end

  defp maybe_form_field_match(label_node, root_node, expected, opts) do
    label_text = node_text(label_node)

    with true <- Query.match_text?(label_text, expected, opts),
         {:ok, %{name: name} = field} <- field_for_label(root_node, label_node),
         true <- is_binary(name) and name != "" do
      {:ok, %{label: label_text, name: name, id: field.id, form: field.form}}
    else
      _ -> false
    end
  end

  defp find_first_matching_in_root(root_node, lazy_html, selector, expected, opts, build_fun) do
    root_node
    |> safe_query(selector)
    |> Enum.find_value(false, fn node ->
      maybe_matching_node(node, lazy_html, expected, opts, build_fun)
    end)
  end

  defp maybe_matching_node(node, lazy_html, expected, opts, build_fun) do
    text = node_text(node)

    if Query.match_text?(text, expected, opts) do
      mapped =
        node
        |> build_fun.(text)
        |> maybe_put_unique_selector(lazy_html, node)

      {:ok, mapped}
    else
      false
    end
  end

  defp maybe_put_unique_selector(%{} = mapped, lazy_html, node) do
    case unique_selector(lazy_html, node) do
      nil -> mapped
      selector -> Map.put(mapped, :selector, selector)
    end
  end

  defp unique_selector(lazy_html, node) do
    tag = node_tag(node)
    attrs = node_attrs(node)
    id = attrs["id"]
    attr_selector = attrs_selector(attrs)

    candidates =
      [
        if(is_binary(id) and id != "", do: ~s([id="#{css_attr_escape(id)}"])),
        if(attr_selector != "", do: "#{tag}#{attr_selector}"),
        tag
      ]
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    Enum.find(candidates, &selector_unique?(lazy_html, &1))
  end

  defp selector_unique?(lazy_html, selector) do
    lazy_html
    |> LazyHTML.query(selector)
    |> Enum.count() == 1
  rescue
    _ -> false
  end

  defp node_tag(node) do
    case LazyHTML.to_tree(node) do
      [{tag, _attrs, _children} | _] -> to_string(tag)
      _ -> "*"
    end
  end

  defp node_attrs(node) do
    case LazyHTML.to_tree(node) do
      [{_tag, attrs, _children} | _] when is_list(attrs) ->
        Enum.reduce(attrs, %{}, fn
          {name, value}, acc ->
            Map.put(acc, to_string(name), value_to_string(value))

          _, acc ->
            acc
        end)

      _ ->
        %{}
    end
  end

  defp value_to_string(nil), do: ""
  defp value_to_string(true), do: ""
  defp value_to_string(value), do: to_string(value)

  defp attrs_selector(attrs) when map_size(attrs) == 0, do: ""

  defp attrs_selector(attrs) do
    attrs
    |> Enum.sort_by(fn {name, _value} -> name end)
    |> Enum.map_join("", fn
      {name, ""} -> "[#{name}]"
      {name, value} -> ~s([#{name}="#{css_attr_escape(value)}"])
    end)
  end

  defp css_attr_escape(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
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
    |> LazyHTML.text()
    |> String.replace("\u00A0", " ")
    |> String.trim()
  end

  defp field_for_label(root_node, label_node) do
    case attr(label_node, "for") do
      nil ->
        label_node
        |> safe_query("input,textarea,select")
        |> Enum.find_value(:error, fn node -> field_node_to_map(node) end)

      id ->
        root_node
        |> safe_query("[id='#{id}']")
        |> Enum.find_value(:error, fn node -> field_node_to_map(node) end)
    end
  end

  defp field_node_to_map(node) do
    name = attr(node, "name")
    id = attr(node, "id")
    form = attr(node, "form")
    {:ok, %{name: name, id: id, form: form}}
  end

  defp attr(node, name) do
    node
    |> LazyHTML.attribute(name)
    |> List.first()
  end

  defp parse_document(html) when is_binary(html) do
    {:ok, LazyHTML.from_document(html)}
  rescue
    _ -> :error
  end

  defp form_by_id(root_node, id) do
    root_node
    |> safe_query("form")
    |> Enum.find(fn form_node ->
      attr(form_node, "id") == id
    end)
  end

  defp scoped_nodes(lazy_html, nil), do: [lazy_html]
  defp scoped_nodes(lazy_html, ""), do: [lazy_html]

  defp scoped_nodes(lazy_html, scope) when is_binary(scope) do
    safe_query(lazy_html, scope)
  end

  defp safe_query(node, selector) do
    LazyHTML.query(node, selector)
  rescue
    _ -> []
  end
end
