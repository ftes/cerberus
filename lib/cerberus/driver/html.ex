defmodule Cerberus.Driver.Html do
  @moduledoc false

  alias Cerberus.LiveViewBindings
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
          {:ok,
           %{
             required(:text) => String.t(),
             required(:href) => String.t(),
             optional(:selector) => String.t()
           }}
          | :error
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

  @spec find_live_clickable_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, %{text: String.t(), selector: String.t() | nil}} | :error
  def find_live_clickable_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_live_clickable_button_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec find_form_field(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, map()} | :error
  def find_form_field(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_form_field_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec form_defaults(String.t(), String.t(), String.t() | nil) :: map()
  def form_defaults(html, form_selector, scope \\ nil) when is_binary(html) and is_binary(form_selector) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        selector = scope_form_selector(form_selector, scope)

        lazy_html
        |> safe_query(selector)
        |> Enum.at(0)
        |> collect_form_defaults()

      _ ->
        %{}
    end
  end

  @spec trigger_action_forms(String.t()) :: [map()]
  def trigger_action_forms(html) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        trigger_action_forms_in_doc(lazy_html)

      _ ->
        []
    end
  end

  @spec find_submit_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok,
           %{
             text: String.t(),
             action: String.t() | nil,
             method: String.t() | nil,
             form: String.t() | nil,
             form_selector: String.t() | nil,
             form_phx_submit: boolean(),
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
    query_selector = selector_opt(opts) || "a[href]"

    find_first_matching(
      lazy_html,
      query_selector,
      expected,
      opts,
      scope,
      fn node, text ->
        %{text: text, href: attr(node, "href")}
      end,
      &link_node?/1
    )
  end

  defp find_button_in_doc(lazy_html, expected, opts, scope) do
    query_selector = selector_opt(opts) || "button"

    find_first_matching(
      lazy_html,
      query_selector,
      expected,
      opts,
      scope,
      fn _node, text ->
        %{text: text}
      end,
      &button_node?/1
    )
  end

  defp find_live_clickable_button_in_doc(lazy_html, expected, opts, scope) do
    query_selector = selector_opt(opts) || "button[phx-click]"

    find_first_matching(
      lazy_html,
      query_selector,
      expected,
      opts,
      scope,
      fn _node, text ->
        %{text: text}
      end,
      &live_clickable_button_node?/1
    )
  end

  defp find_form_field_in_doc(lazy_html, expected, opts, scope) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node -> find_form_field_in_root(root_node, expected, opts) end)
  end

  defp find_submit_button_in_doc(lazy_html, expected, opts, scope) do
    selector = selector_opt(opts)

    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node ->
      case find_submit_button_in_forms(root_node, expected, opts, selector) do
        {:ok, _button} = ok -> ok
        :error -> find_submit_button_in_owner_form(root_node, expected, opts, selector)
      end
    end)
  end

  defp find_submit_button_in_forms(root_node, expected, opts, selector) do
    root_node
    |> safe_query("form")
    |> Enum.reduce_while(:error, fn form_node, _acc ->
      case find_submit_button_in_form(root_node, form_node, expected, opts, selector) do
        {:ok, _button} = ok -> {:halt, ok}
        :error -> {:cont, :error}
      end
    end)
  end

  defp find_submit_button_in_form(root_node, form_node, expected, opts, selector) do
    form_meta = form_meta_from_form_node(root_node, form_node)

    form_node
    |> LazyHTML.query("button")
    |> Enum.find_value(:error, fn button_node ->
      build_submit_button(button_node, form_meta, expected, opts, root_node, selector)
    end)
  end

  defp find_submit_button_in_owner_form(root_node, expected, opts, selector) do
    root_node
    |> safe_query("button[form]")
    |> Enum.find_value(:error, fn button_node ->
      owner_form = attr(button_node, "form")

      with true <- is_binary(owner_form) and owner_form != "",
           form_node when not is_nil(form_node) <- form_by_id(root_node, owner_form) do
        form_meta = form_meta_from_form_node(root_node, form_node, owner_form)
        build_submit_button(button_node, form_meta, expected, opts, root_node, selector)
      else
        _ -> false
      end
    end)
  end

  defp build_submit_button(button_node, form_meta, expected, opts, root_node, selector) do
    text = node_text(button_node)
    type = attr(button_node, "type") || "submit"

    if submit_button_match?(type, text, expected, opts) and
         node_matches_selector?(root_node, button_node, selector) do
      action = attr(button_node, "formaction") || form_meta.action
      method = attr(button_node, "formmethod") || form_meta.method

      {:ok,
       %{
         text: text,
         action: action,
         method: method,
         form: form_meta.form,
         form_selector: form_meta.form_selector,
         form_phx_submit: form_meta.form_phx_submit,
         button_name: attr(button_node, "name"),
         button_value: attr(button_node, "value")
       }}
    else
      false
    end
  end

  defp form_meta_from_form_node(root_node, form_node, form_id_override \\ nil) do
    form_id =
      case form_id_override do
        value when is_binary(value) and value != "" -> value
        _ -> attr(form_node, "id")
      end

    %{
      form: form_id,
      action: attr(form_node, "action"),
      method: attr(form_node, "method"),
      form_selector: form_selector(root_node, form_node, form_id),
      form_phx_submit: form_node |> attr("phx-submit") |> phx_submit_binding?()
    }
  end

  defp trigger_action_forms_in_doc(root_node) do
    root_node
    |> safe_query("form")
    |> Enum.flat_map(fn form_node ->
      if form_node |> attr("phx-trigger-action") |> trigger_action_enabled?() do
        form_id = attr(form_node, "id")

        [
          %{
            form: form_id,
            form_selector: form_selector(root_node, form_node, form_id),
            action: attr(form_node, "action"),
            method: attr(form_node, "method"),
            defaults: collect_form_defaults(form_node)
          }
        ]
      else
        []
      end
    end)
  end

  defp submit_button_match?(type, text, expected, opts) do
    type in ["submit", ""] and Query.match_text?(text, expected, opts)
  end

  defp find_first_matching(lazy_html, selector, expected, opts, scope, build_fun, node_predicate) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(:error, fn root_node ->
      find_first_matching_in_root(root_node, lazy_html, selector, expected, opts, build_fun, node_predicate)
    end)
  end

  defp find_form_field_in_root(root_node, expected, opts) do
    selector = selector_opt(opts)

    root_node
    |> safe_query("label")
    |> Enum.find_value(false, fn label_node ->
      maybe_form_field_match(label_node, root_node, expected, opts, selector)
    end)
  end

  defp maybe_form_field_match(label_node, root_node, expected, opts, selector) do
    label_text = node_text(label_node)

    with true <- Query.match_text?(label_text, expected, opts),
         {:ok, %{name: name, node: field_node} = field} <- field_for_label(root_node, label_node),
         true <- is_binary(name) and name != "",
         true <- field_matches_selector?(root_node, field, selector) do
      build_form_field_match(root_node, label_text, name, field, field_node)
    else
      _ -> false
    end
  end

  defp build_form_field_match(root_node, label_text, name, field, field_node) do
    form_node = field_form_node(root_node, field)
    form_id = field_form_id(field, form_node)
    input_type = input_type(field_node)

    {:ok,
     %{
       label: label_text,
       name: name,
       id: field.id,
       form: form_id,
       selector: field_selector(root_node, field),
       form_selector: form_selector(root_node, form_node, form_id),
       input_type: input_type,
       input_value: input_value(field_node, input_type),
       input_checked: checked?(field_node),
       input_phx_change: field_node |> attr("phx-change") |> phx_change_binding?(),
       form_phx_change: form_node |> attr_or_nil("phx-change") |> phx_change_binding?()
     }}
  end

  defp field_form_id(%{form: form}, _form_node) when is_binary(form) and form != "", do: form
  defp field_form_id(_field, form_node), do: attr_or_nil(form_node, "id")

  defp find_first_matching_in_root(root_node, lazy_html, selector, expected, opts, build_fun, node_predicate) do
    root_node
    |> safe_query(selector)
    |> Enum.find_value(false, fn node ->
      maybe_matching_node(node, lazy_html, expected, opts, build_fun, node_predicate)
    end)
  end

  defp maybe_matching_node(node, lazy_html, expected, opts, build_fun, node_predicate) do
    text = node_text(node)

    if node_predicate.(node) and Query.match_text?(text, expected, opts) do
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
    |> String.to_charlist()
    |> Enum.map_join(&css_attr_char_escape/1)
  end

  defp css_attr_char_escape(?\\), do: "\\\\"
  defp css_attr_char_escape(?"), do: "\\\""
  defp css_attr_char_escape(char) when char in [?\n, ?\r, ?\t, ?\f], do: "\\#{Integer.to_string(char, 16)} "

  defp css_attr_char_escape(char), do: <<char::utf8>>

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

  defp input_type(field_node) do
    case node_tag(field_node) do
      "input" -> String.downcase(attr(field_node, "type") || "text")
      other -> other
    end
  end

  defp input_value(field_node, input_type) do
    case attr(field_node, "value") do
      value when is_binary(value) ->
        value

      _ ->
        if input_type in ["checkbox", "radio"], do: "on", else: ""
    end
  end

  defp field_for_label(root_node, label_node) do
    case attr(label_node, "for") do
      nil ->
        label_node
        |> safe_query("input,textarea,select")
        |> Enum.find_value(:error, fn node -> field_node_to_map(root_node, node) end)

      id ->
        root_node
        |> safe_query("[id='#{id}']")
        |> Enum.find_value(:error, fn node -> field_node_to_map(root_node, node) end)
    end
  end

  defp field_node_to_map(root_node, node) do
    name = attr(node, "name")
    id = attr(node, "id")
    form = attr(node, "form")

    {:ok,
     %{
       name: name,
       id: id,
       form: form,
       node: node,
       selector: field_selector(root_node, %{id: id, name: name, node: node})
     }}
  end

  defp attr(node, name) do
    node
    |> LazyHTML.attribute(name)
    |> List.wrap()
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

  defp field_form_node(root_node, %{form: form_id}) when is_binary(form_id) and form_id != "" do
    form_by_id(root_node, form_id)
  end

  defp field_form_node(root_node, %{node: node}) do
    root_node
    |> safe_query("form")
    |> Enum.find(fn form_node ->
      form_node
      |> safe_query("*")
      |> Enum.any?(&same_node?(&1, node))
    end)
  end

  defp field_selector(_root_node, %{selector: selector}) when is_binary(selector), do: selector

  defp field_selector(_root_node, %{id: id}) when is_binary(id) and id != "" do
    ~s([id="#{css_attr_escape(id)}"])
  end

  defp field_selector(_root_node, %{name: name}) when is_binary(name) and name != "" do
    ~s([name="#{css_attr_escape(name)}"])
  end

  defp field_selector(root_node, %{node: node}) do
    unique_selector(root_node, node) || "*"
  end

  defp form_selector(_root_node, nil, nil), do: nil

  defp form_selector(_root_node, _form_node, form_id) when is_binary(form_id) and form_id != "" do
    ~s(form[id="#{css_attr_escape(form_id)}"])
  end

  defp form_selector(root_node, form_node, _form_id) when not is_nil(form_node) do
    unique_selector(root_node, form_node)
  end

  defp form_selector(_root_node, _form_node, _form_id), do: nil

  defp scope_form_selector(form_selector, nil), do: form_selector
  defp scope_form_selector(form_selector, ""), do: form_selector
  defp scope_form_selector(form_selector, scope), do: scope <> " " <> form_selector

  defp collect_form_defaults(nil), do: %{}

  defp collect_form_defaults(form_node) do
    inputs =
      form_node
      |> safe_query("input[name],textarea[name],select[name]")
      |> Enum.reduce(%{}, &put_control_value(&2, &1))

    owner_controls =
      case attr(form_node, "id") do
        form_id when is_binary(form_id) and form_id != "" ->
          parent = form_node

          parent
          |> safe_query(~s([form="#{form_id}"][name]))
          |> Enum.reduce(inputs, &put_control_value(&2, &1))

        _ ->
          inputs
      end

    owner_controls
  end

  defp put_control_value(acc, node) do
    case {node_tag(node), attr(node, "name")} do
      {_, nil} ->
        acc

      {"input", name} ->
        put_input_default(acc, node, name)

      {"textarea", name} ->
        put_name_value(acc, name, node_text(node))

      {"select", name} ->
        put_select_default(acc, node, name)

      _ ->
        acc
    end
  end

  defp put_input_default(acc, node, name) do
    type = String.downcase(attr(node, "type") || "text")

    cond do
      type in ["submit", "button", "image", "file", "reset"] ->
        acc

      type in ["checkbox", "radio"] ->
        if checked?(node) do
          put_name_value(acc, name, attr(node, "value") || "on")
        else
          acc
        end

      true ->
        put_name_value(acc, name, attr(node, "value") || "")
    end
  end

  defp put_select_default(acc, node, name) do
    selected_values =
      node
      |> safe_query("option")
      |> Enum.filter(&checked?/1)
      |> Enum.map(&(attr(&1, "value") || node_text(&1)))

    selected_values =
      if selected_values == [] do
        case node |> safe_query("option") |> Enum.at(0) do
          nil -> []
          option -> [attr(option, "value") || node_text(option)]
        end
      else
        selected_values
      end

    case selected_values do
      [] -> acc
      [single] -> put_name_value(acc, name, single)
      many -> put_name_value(acc, name, many)
    end
  end

  defp put_name_value(acc, name, values) when is_list(values) do
    Enum.reduce(values, acc, &put_name_value(&2, name, &1))
  end

  defp put_name_value(acc, name, value) do
    if String.ends_with?(name, "[]") do
      Map.update(acc, name, [value], fn existing -> existing ++ [value] end)
    else
      Map.put(acc, name, value)
    end
  end

  defp checked?(node) do
    node
    |> attr("checked")
    |> is_binary()
  end

  defp phx_change_binding?(value) when is_binary(value) do
    String.trim(value) != ""
  end

  defp phx_change_binding?(_value), do: false

  defp phx_submit_binding?(value) when is_binary(value) do
    String.trim(value) != ""
  end

  defp phx_submit_binding?(_value), do: false

  defp trigger_action_enabled?(nil), do: false

  defp trigger_action_enabled?(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> true
      "false" -> false
      "0" -> false
      _ -> true
    end
  end

  defp trigger_action_enabled?(_value), do: true

  defp attr_or_nil(nil, _name), do: nil
  defp attr_or_nil(node, name), do: attr(node, name)

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

  defp selector_opt(opts) do
    case Keyword.get(opts, :selector) do
      selector when is_binary(selector) and selector != "" -> selector
      _ -> nil
    end
  end

  defp node_matches_selector?(_root_node, _node, nil), do: true

  defp node_matches_selector?(root_node, node, selector) do
    root_node
    |> safe_query(selector)
    |> Enum.any?(&same_node?(&1, node))
  end

  defp field_matches_selector?(_root_node, _field, nil), do: true

  defp field_matches_selector?(root_node, field, selector) do
    root_node
    |> safe_query(selector)
    |> Enum.any?(fn node ->
      node_id = attr(node, "id")
      node_name = attr(node, "name")

      cond do
        is_binary(field.id) and field.id != "" ->
          node_id == field.id

        is_binary(field.name) and field.name != "" ->
          node_name == field.name

        true ->
          false
      end
    end)
  end

  defp link_node?(node) do
    node_tag(node) == "a" and is_binary(attr(node, "href"))
  end

  defp button_node?(node), do: node_tag(node) == "button"

  defp live_clickable_button_node?(node) do
    button_node?(node) and
      node
      |> attr("phx-click")
      |> LiveViewBindings.phx_click?()
  end

  defp same_node?(left, right) do
    left_id = attr(left, "id")
    right_id = attr(right, "id")

    if is_binary(left_id) and left_id != "" and is_binary(right_id) and right_id != "" do
      left_id == right_id
    else
      node_tag(left) == node_tag(right) and node_text(left) == node_text(right) and
        node_attrs(left) == node_attrs(right)
    end
  end
end
