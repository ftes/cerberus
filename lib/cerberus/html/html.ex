defmodule Cerberus.Html do
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

  @spec assertion_values(String.t(), atom(), true | false | :any, String.t() | nil) :: [String.t()]
  def assertion_values(html, match_by, visibility \\ true, scope \\ nil)

  def assertion_values(html, :text, visibility, scope) when is_binary(html) do
    texts(html, visibility, scope)
  end

  def assertion_values(html, match_by, visibility, scope) when is_binary(html) and is_atom(match_by) do
    case parse_document(html) do
      {:ok, lazy_html} -> collect_assertion_values_in_doc(lazy_html, match_by, visibility, scope)
      _ -> []
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

  @spec select_values(String.t(), map(), String.t() | [String.t()], keyword(), String.t() | nil) ::
          {:ok, %{values: [String.t()], multiple?: boolean()}} | {:error, String.t()}
  def select_values(html, field, option, opts, scope \\ nil) when is_binary(html) and is_map(field) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        select_values_in_doc(lazy_html, field, option, opts, scope)

      _ ->
        {:error, "failed to parse html while matching select options"}
    end
  end

  @spec form_defaults(String.t(), String.t(), String.t() | nil) :: map()
  def form_defaults(html, form_selector, scope \\ nil) when is_binary(html) and is_binary(form_selector) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        lazy_html
        |> form_node_from_selector(form_selector, scope)
        |> collect_form_defaults()

      _ ->
        %{}
    end
  end

  @spec form_field_names(String.t(), String.t(), String.t() | nil) :: MapSet.t(String.t())
  def form_field_names(html, form_selector, scope \\ nil) when is_binary(html) and is_binary(form_selector) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        form_field_names_in_doc(lazy_html, form_selector, scope)

      _ ->
        MapSet.new()
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
    match_by = match_by_opt(opts)

    find_matching(
      lazy_html,
      query_selector,
      expected,
      opts,
      scope,
      fn node, text, _root_node ->
        %{
          text: text,
          href: attr(node, "href"),
          title: attr(node, "title") || "",
          testid: attr(node, "data-testid") || ""
        }
      end,
      fn _root_node, node -> link_node?(node) end,
      fn root_node, node -> link_match_value(root_node, node, match_by) end
    )
  end

  defp find_button_in_doc(lazy_html, expected, opts, scope) do
    query_selector = selector_opt(opts) || "button"
    match_by = match_by_opt(opts)

    find_matching(
      lazy_html,
      query_selector,
      expected,
      opts,
      scope,
      fn node, text, _root_node ->
        %{
          text: text,
          title: attr(node, "title") || "",
          testid: attr(node, "data-testid") || "",
          button_name: attr(node, "name"),
          button_value: attr(node, "value")
        }
      end,
      fn _root_node, node -> button_node?(node) end,
      fn root_node, node -> button_match_value(root_node, node, match_by) end
    )
  end

  defp find_form_field_in_doc(lazy_html, expected, opts, scope) do
    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(&find_form_field_in_root(&1, expected, opts))

    pick_match_result(matches, opts)
  end

  defp find_submit_button_in_doc(lazy_html, expected, opts, scope) do
    selector = selector_opt(opts)

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        find_submit_button_in_forms(root_node, expected, opts, selector) ++
          find_submit_button_in_owner_form(root_node, expected, opts, selector)
      end)

    pick_match_result(matches, opts)
  end

  defp select_values_in_doc(lazy_html, field, option, opts, scope) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value({:error, "no select field matched locator"}, fn root_node ->
      case find_select_node(root_node, field) do
        {:ok, select_node} -> select_values_for_node(select_node, option, opts)
        :error -> false
      end
    end)
  end

  defp select_values_for_node(select_node, option, opts) do
    if disabled?(select_node) do
      {:error, "matched select field is disabled"}
    else
      multiple? = is_binary(attr(select_node, "multiple"))
      requested = List.wrap(option)

      cond do
        requested == [] ->
          {:error, "select requires at least one option value"}

        not multiple? and length(requested) > 1 ->
          {:error, "matched select does not support selecting multiple options"}

        true ->
          option_opts = [exact: Keyword.get(opts, :exact_option, true)]
          match_select_values(select_node, requested, option_opts, multiple?)
      end
    end
  end

  defp match_select_values(select_node, requested, option_opts, multiple?) do
    options = safe_query(select_node, "option")

    case collect_select_values(options, requested, option_opts) do
      {:ok, values} ->
        {:ok, %{values: values, multiple?: multiple?}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp collect_select_values(options, requested, option_opts) do
    Enum.reduce_while(requested, {:ok, []}, fn requested_option, {:ok, values} ->
      append_select_value(options, requested_option, option_opts, values)
    end)
  end

  defp append_select_value(options, requested_option, option_opts, values) do
    case match_select_option(options, requested_option, option_opts) do
      {:ok, value} -> {:cont, {:ok, values ++ [value]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp match_select_option(options, requested_option, option_opts) do
    predicate = fn option ->
      Query.match_text?(node_text(option), requested_option, option_opts)
    end

    enabled_match =
      Enum.find(options, fn option ->
        predicate.(option) and not disabled?(option)
      end)

    cond do
      not is_nil(enabled_match) ->
        {:ok, attr(enabled_match, "value") || node_text(enabled_match)}

      Enum.any?(options, predicate) ->
        {:error, "matched select option is disabled"}

      true ->
        {:error, "no select option matched the requested option text"}
    end
  end

  defp find_select_node(root_node, field) do
    selectors =
      []
      |> maybe_add_select_selector(field[:id], &~s([id="#{css_attr_escape(&1)}"]))
      |> maybe_add_select_selector(field[:selector], & &1)
      |> maybe_add_select_selector(field[:name], &~s([name="#{css_attr_escape(&1)}"]))

    Enum.find_value(selectors, :error, fn selector ->
      case root_node |> safe_query(selector) |> Enum.find(&(node_tag(&1) == "select")) do
        nil -> false
        select_node -> {:ok, select_node}
      end
    end)
  end

  defp maybe_add_select_selector(selectors, value, builder) when is_function(builder, 1) do
    case value do
      candidate when is_binary(candidate) ->
        if String.trim(candidate) != "" and candidate != "*" do
          selectors ++ [builder.(candidate)]
        else
          selectors
        end

      _ ->
        selectors
    end
  end

  defp find_submit_button_in_forms(root_node, expected, opts, selector) do
    root_node
    |> safe_query("form")
    |> Enum.flat_map(&find_submit_button_in_form(root_node, &1, expected, opts, selector))
  end

  defp find_submit_button_in_form(root_node, form_node, expected, opts, selector) do
    form_meta = form_meta_from_form_node(root_node, form_node)

    form_node
    |> LazyHTML.query("button")
    |> Enum.flat_map(&maybe_submit_button_match(&1, form_meta, expected, opts, root_node, selector))
  end

  defp find_submit_button_in_owner_form(root_node, expected, opts, selector) do
    root_node
    |> safe_query("button[form]")
    |> Enum.flat_map(&owner_submit_button_matches(&1, root_node, expected, opts, selector))
  end

  defp maybe_submit_button_match(button_node, form_meta, expected, opts, root_node, selector) do
    case build_submit_button(button_node, form_meta, expected, opts, root_node, selector) do
      nil -> []
      button -> [button]
    end
  end

  defp owner_submit_button_matches(button_node, root_node, expected, opts, selector) do
    owner_form = attr(button_node, "form")

    with true <- is_binary(owner_form) and owner_form != "",
         form_node when not is_nil(form_node) <- form_by_id(root_node, owner_form) do
      form_meta = form_meta_from_form_node(root_node, form_node, owner_form)
      maybe_submit_button_match(button_node, form_meta, expected, opts, root_node, selector)
    else
      _ -> []
    end
  end

  defp build_submit_button(button_node, form_meta, expected, opts, root_node, selector) do
    text = node_text(button_node)
    type = attr(button_node, "type") || "submit"
    match_by = match_by_opt(opts)
    match_value = button_match_value(root_node, button_node, match_by)

    if submit_button_match?(type, match_value, expected, opts) and
         node_matches_selector?(root_node, button_node, selector) do
      action = attr(button_node, "formaction") || form_meta.action
      method = attr(button_node, "formmethod") || form_meta.method

      %{
        text: text,
        title: attr(button_node, "title") || "",
        alt: button_alt_text(button_node),
        testid: attr(button_node, "data-testid") || "",
        action: action,
        method: method,
        form: form_meta.form,
        form_selector: form_meta.form_selector,
        button_name: attr(button_node, "name"),
        button_value: attr(button_node, "value")
      }
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
      form_selector: form_selector(root_node, form_node, form_id)
    }
  end

  defp submit_button_match?(type, value, expected, opts) do
    type in ["submit", ""] and is_binary(value) and Query.match_text?(value, expected, opts)
  end

  defp find_matching(lazy_html, selector, expected, opts, scope, build_fun, node_predicate, match_value_fun) do
    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        find_matching_in_root(
          root_node,
          lazy_html,
          selector,
          expected,
          opts,
          build_fun,
          node_predicate,
          match_value_fun
        )
      end)

    pick_match_result(matches, opts)
  end

  defp find_form_field_in_root(root_node, expected, opts) do
    selector = selector_opt(opts)
    match_by = match_by_opt(opts, :label)

    case match_by do
      :label ->
        root_node
        |> safe_query("label")
        |> Enum.flat_map(&maybe_form_field_match_list(&1, root_node, expected, opts, selector))

      kind when kind in [:placeholder, :title, :testid] ->
        find_form_field_by_control_attr(root_node, expected, opts, selector, kind)

      _ ->
        []
    end
  end

  defp maybe_form_field_match(label_node, root_node, expected, opts, selector) do
    label_text = node_text(label_node)

    with true <- Query.match_text?(label_text, expected, opts),
         {:ok, %{name: name, node: field_node} = field} <- field_for_label(root_node, label_node),
         true <- is_binary(name) and name != "",
         true <- field_matches_selector?(root_node, field, selector) do
      build_form_field_match(root_node, label_text, name, field, field_node)
    else
      _ -> nil
    end
  end

  defp maybe_form_field_match_list(label_node, root_node, expected, opts, selector) do
    case maybe_form_field_match(label_node, root_node, expected, opts, selector) do
      nil -> []
      match -> [match]
    end
  end

  defp find_form_field_by_control_attr(root_node, expected, opts, selector, kind) do
    root_node
    |> safe_query("input,textarea,select")
    |> Enum.flat_map(&maybe_form_field_attr_match_list(&1, root_node, expected, opts, selector, kind))
  end

  defp maybe_form_field_attr_match(field_node, root_node, expected, opts, selector, kind) do
    with {:ok, %{name: name} = field} <- field_node_to_map(root_node, field_node),
         true <- is_binary(name) and name != "",
         value when is_binary(value) <- field_match_value(root_node, field_node, kind),
         true <- value != "",
         true <- Query.match_text?(value, expected, opts),
         true <- field_matches_selector?(root_node, field, selector) do
      build_form_field_match(root_node, field_label_for_node(root_node, field_node), name, field, field_node)
    else
      _ -> nil
    end
  end

  defp maybe_form_field_attr_match_list(field_node, root_node, expected, opts, selector, kind) do
    case maybe_form_field_attr_match(field_node, root_node, expected, opts, selector, kind) do
      nil -> []
      match -> [match]
    end
  end

  defp build_form_field_match(root_node, label_text, name, field, field_node) do
    form_node = field_form_node(root_node, field)
    form_id = field_form_id(field, form_node)
    input_type = input_type(field_node)

    %{
      label: label_text,
      name: name,
      id: field.id,
      form: form_id,
      selector: field_selector(root_node, field),
      form_selector: form_selector(root_node, form_node, form_id),
      input_type: input_type,
      placeholder: attr(field_node, "placeholder") || "",
      title: attr(field_node, "title") || "",
      testid: attr(field_node, "data-testid") || "",
      input_value: input_value(field_node, input_type),
      input_checked: checked?(field_node)
    }
  end

  defp field_form_id(%{form: form}, _form_node) when is_binary(form) and form != "", do: form
  defp field_form_id(_field, form_node), do: attr_or_nil(form_node, "id")

  defp find_matching_in_root(root_node, lazy_html, selector, expected, opts, build_fun, node_predicate, match_value_fun) do
    root_node
    |> safe_query(selector)
    |> Enum.flat_map(
      &maybe_matching_node_list(&1, root_node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun)
    )
  end

  defp maybe_matching_node(root_node, node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun) do
    text = node_text(node)
    value = match_value_fun.(root_node, node)

    if node_predicate.(root_node, node) and is_binary(value) and Query.match_text?(value, expected, opts) do
      mapped =
        node
        |> build_fun.(text, root_node)
        |> maybe_put_unique_selector(lazy_html, node)

      mapped
    end
  end

  defp maybe_matching_node_list(node, root_node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun) do
    case maybe_matching_node(root_node, node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun) do
      nil -> []
      match -> [match]
    end
  end

  defp pick_match_result(matches, opts) do
    case Query.pick_match(matches, opts) do
      {:ok, match} -> {:ok, match}
      {:error, _reason} -> :error
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

  defp collect_assertion_values_in_doc(lazy_html, match_by, visibility, scope) do
    {visible, hidden} =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.reduce({[], []}, fn root, acc ->
        root
        |> LazyHTML.to_tree()
        |> collect_assertion_values(match_by, false, acc)
      end)

    visible = Enum.uniq(visible)
    hidden = Enum.uniq(hidden)
    pick_visibility_values(visibility, visible, hidden)
  end

  defp pick_visibility_values(true, visible, _hidden), do: visible
  defp pick_visibility_values(false, _visible, hidden), do: hidden
  defp pick_visibility_values(:any, visible, hidden), do: visible ++ hidden

  defp collect_assertion_values(nodes, match_by, hidden_parent?, acc) when is_list(nodes) do
    Enum.reduce(nodes, acc, fn node, acc ->
      case node do
        {_tag, attrs, children} when is_list(attrs) and is_list(children) ->
          tag = node_tree_tag(node)
          hidden? = hidden_parent? or hidden_element?(attrs)
          acc = maybe_append_assertion_value(node, tag, attrs, children, match_by, hidden?, acc)
          collect_assertion_values(children, match_by, hidden?, acc)

        _ ->
          acc
      end
    end)
  end

  defp maybe_append_assertion_value(_node, tag, attrs, children, match_by, hidden?, acc) do
    value = assertion_value_for(tag, attrs, children, match_by)
    append_text(value || "", hidden?, acc)
  end

  defp assertion_value_for("label", _attrs, children, :label), do: normalize_text(tree_text(children))

  defp assertion_value_for("a", attrs, children, :link) do
    if is_binary(attr_from_attrs(attrs, "href")), do: normalize_text(tree_text(children))
  end

  defp assertion_value_for("button", _attrs, children, :button), do: normalize_text(tree_text(children))
  defp assertion_value_for(_tag, attrs, _children, :title), do: attr_from_attrs(attrs, "title")

  defp assertion_value_for(tag, attrs, _children, :placeholder) when tag in ["input", "textarea", "select"],
    do: attr_from_attrs(attrs, "placeholder")

  defp assertion_value_for(_tag, attrs, _children, :alt), do: attr_from_attrs(attrs, "alt")
  defp assertion_value_for(_tag, attrs, _children, :testid), do: attr_from_attrs(attrs, "data-testid")
  defp assertion_value_for(_tag, _attrs, _children, _match_by), do: nil

  defp tree_text(nodes) when is_list(nodes) do
    Enum.map_join(nodes, " ", fn
      text when is_binary(text) -> text
      {_tag, _attrs, children} when is_list(children) -> tree_text(children)
      _ -> ""
    end)
  end

  defp normalize_text(value) when is_binary(value) do
    value
    |> String.replace("\u00A0", " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp node_tree_tag({tag, _attrs, _children}), do: to_string(tag)

  defp attr_from_attrs(attrs, name) when is_list(attrs) and is_binary(name) do
    Enum.find_value(attrs, nil, fn
      {attr_name, value} ->
        if to_string(attr_name) == name do
          value_to_string(value)
        end

      _ ->
        nil
    end)
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

  defp link_match_value(root_node, node, match_by) do
    case match_by do
      :text -> node_text(node)
      :link -> node_text(node)
      :title -> attr(node, "title") || ""
      :testid -> attr(node, "data-testid") || ""
      :alt -> node_alt_text(root_node, node)
      _ -> node_text(node)
    end
  end

  defp button_match_value(root_node, node, match_by) do
    case match_by do
      :text -> node_text(node)
      :button -> node_text(node)
      :title -> attr(node, "title") || ""
      :testid -> attr(node, "data-testid") || ""
      :alt -> button_alt_text(node, root_node)
      _ -> node_text(node)
    end
  end

  defp field_match_value(_root_node, field_node, :placeholder), do: attr(field_node, "placeholder") || ""
  defp field_match_value(_root_node, field_node, :title), do: attr(field_node, "title") || ""
  defp field_match_value(_root_node, field_node, :testid), do: attr(field_node, "data-testid") || ""

  defp field_label_for_node(root_node, field_node) do
    id = attr(field_node, "id")

    with value when is_binary(value) <- id,
         true <- value != "",
         label when not is_nil(label) <- label_for_id(root_node, value) do
      node_text(label)
    else
      _ ->
        case wrapping_label_for_control(root_node, field_node) do
          nil -> ""
          label -> node_text(label)
        end
    end
  end

  defp label_for_id(root_node, id) when is_binary(id) and id != "" do
    root_node
    |> safe_query("label[for]")
    |> Enum.find(fn label_node -> attr(label_node, "for") == id end)
  end

  defp wrapping_label_for_control(root_node, field_node) do
    root_node
    |> safe_query("label")
    |> Enum.find(fn label_node ->
      label_node
      |> safe_query("input,textarea,select")
      |> Enum.any?(&same_node?(&1, field_node))
    end)
  end

  defp node_alt_text(root_node, node) do
    node
    |> direct_or_nested_alt("img[alt],input[type='image'][alt],[role='img'][alt]")
    |> maybe_filter_alt_by_root(root_node)
  end

  defp button_alt_text(node, root_node \\ nil) do
    node
    |> direct_or_nested_alt("img[alt],input[type='image'][alt]")
    |> maybe_filter_alt_by_root(root_node)
  end

  defp direct_or_nested_alt(node, nested_selector) do
    case attr(node, "alt") do
      direct when is_binary(direct) and direct != "" ->
        {:direct, direct}

      _ ->
        {:nested, safe_query(node, nested_selector)}
    end
  end

  defp maybe_filter_alt_by_root({:direct, value}, _root_node), do: value

  defp maybe_filter_alt_by_root({:nested, nodes}, nil) do
    Enum.find_value(nodes, "", &alt_value/1)
  end

  defp maybe_filter_alt_by_root({:nested, nodes}, root_node) do
    Enum.find_value(nodes, "", fn image_node ->
      if node_matches_selector?(root_node, image_node, nil), do: alt_value(image_node)
    end)
  end

  defp alt_value(node), do: attr(node, "alt") || ""

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
       placeholder: attr(node, "placeholder"),
       title: attr(node, "title"),
       testid: attr(node, "data-testid"),
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

  defp form_field_names_in_doc(root_node, form_selector, scope) do
    case form_node_from_selector(root_node, form_selector, scope) do
      nil ->
        MapSet.new()

      form_node ->
        collect_form_field_names(root_node, form_node)
    end
  end

  defp form_node_from_selector(root_node, form_selector, scope) do
    selector = scope_form_selector(form_selector, scope)

    case root_node |> safe_query(selector) |> Enum.at(0) do
      nil -> form_node_scope_fallback(root_node, form_selector, scope)
      form_node -> form_node
    end
  end

  defp form_node_scope_fallback(root_node, form_selector, scope) do
    with id when is_binary(id) <- form_id_from_selector(form_selector),
         true <- scope_targets_form_id?(scope, id) do
      root_node |> safe_query(form_selector) |> Enum.at(0)
    else
      _ -> nil
    end
  end

  defp form_id_from_selector(form_selector) do
    case Regex.run(~r/^form\[id="([^"]+)"\]$/, form_selector, capture: :all_but_first) do
      [id] -> id
      _ -> nil
    end
  end

  defp scope_targets_form_id?(scope, _id) when scope in [nil, ""], do: false

  defp scope_targets_form_id?(scope, id) when is_binary(scope) and is_binary(id) do
    trimmed = String.trim(scope)

    trimmed == "#" <> id or
      String.ends_with?(trimmed, " #" <> id) or
      String.contains?(trimmed, ~s([id="#{id}"])) or
      String.ends_with?(trimmed, ~s(form[id="#{id}"]))
  end

  defp collect_form_field_names(root_node, form_node) do
    controls =
      form_node
      |> form_controls()
      |> maybe_append_owner_controls(root_node, form_node)

    Enum.reduce(controls, MapSet.new(), fn control, acc ->
      case control_name_for_submission(control) do
        nil -> acc
        name -> MapSet.put(acc, name)
      end
    end)
  end

  defp collect_form_defaults(nil), do: %{}

  defp collect_form_defaults(form_node) do
    inputs =
      form_node
      |> safe_query("input[name]:not([disabled]),textarea[name]:not([disabled]),select[name]:not([disabled])")
      |> Enum.reduce(%{}, &put_control_value(&2, &1))

    owner_controls =
      case attr(form_node, "id") do
        form_id when is_binary(form_id) and form_id != "" ->
          parent = form_node

          parent
          |> safe_query(~s|[form="#{form_id}"][name]:not([disabled])|)
          |> Enum.reduce(inputs, &put_control_value(&2, &1))

        _ ->
          inputs
      end

    owner_controls
  end

  defp form_controls(node) do
    node
    |> safe_query("input[name],textarea[name],select[name]")
    |> Enum.reject(&disabled?/1)
  end

  defp maybe_append_owner_controls(controls, root_node, form_node) do
    case attr(form_node, "id") do
      form_id when is_binary(form_id) and form_id != "" ->
        owner_controls =
          root_node
          |> safe_query(~s([form="#{form_id}"][name]))
          |> Enum.reject(&disabled?/1)

        controls ++ owner_controls

      _ ->
        controls
    end
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

  defp control_name_for_submission(node) do
    case {node_tag(node), attr(node, "name")} do
      {_, nil} ->
        nil

      {"input", name} ->
        type = String.downcase(attr(node, "type") || "text")

        if type in ["submit", "button", "image", "reset"] do
          nil
        else
          name
        end

      {"textarea", name} ->
        name

      {"select", name} ->
        name

      _ ->
        nil
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
    case select_default_values(node) do
      [] -> acc
      [single] -> put_name_value(acc, name, single)
      many -> put_name_value(acc, name, many)
    end
  end

  defp select_default_values(node) do
    multiple? = is_binary(attr(node, "multiple"))
    selected_values = selected_option_values(node)

    resolve_select_default_values(node, multiple?, selected_values)
  end

  defp selected_option_values(node) do
    node
    |> enabled_options()
    |> Enum.filter(&checked?/1)
    |> Enum.map(&option_value/1)
  end

  defp resolve_select_default_values(_node, _multiple?, selected_values) when selected_values != [] do
    selected_values
  end

  defp resolve_select_default_values(_node, true, []), do: []

  defp resolve_select_default_values(node, false, []) do
    case first_enabled_option(node) do
      nil -> []
      option -> [option_value(option)]
    end
  end

  defp enabled_options(node) do
    node
    |> safe_query("option")
    |> Enum.reject(&disabled?/1)
  end

  defp first_enabled_option(node) do
    node
    |> enabled_options()
    |> Enum.at(0)
  end

  defp option_value(node), do: attr(node, "value") || node_text(node)

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

  defp disabled?(node) do
    node
    |> attr("disabled")
    |> is_binary()
  end

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

  defp match_by_opt(opts, default \\ :text) do
    case Keyword.get(opts, :match_by) do
      value when value in [:label, :link, :button, :placeholder, :title, :alt, :testid] -> value
      _ -> default
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
