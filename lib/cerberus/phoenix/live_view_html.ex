defmodule Cerberus.Phoenix.LiveViewHTML do
  @moduledoc false

  alias Cerberus.Html
  alias Cerberus.Phoenix.LiveViewBindings
  alias Cerberus.Query

  @spec find_live_clickable_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok,
           %{
             text: String.t(),
             selector: String.t() | nil,
             button_name: String.t() | nil,
             button_value: String.t() | nil,
             form: String.t() | nil,
             form_selector: String.t() | nil,
             dispatch_change: boolean()
           }}
          | :error
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
    case Html.find_form_field(html, expected, opts, scope) do
      {:ok, field} ->
        {:ok, Map.merge(field, form_field_live_flags(html, field, scope))}

      :error ->
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
             form_selector: String.t() | nil,
             form_phx_submit: boolean(),
             button_name: String.t() | nil,
             button_value: String.t() | nil
           }}
          | :error
  def find_submit_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case Html.find_submit_button(html, expected, opts, scope) do
      {:ok, button} ->
        {:ok, Map.put(button, :form_phx_submit, form_phx_submit?(html, button, scope))}

      :error ->
        :error
    end
  end

  @spec trigger_action_forms(String.t()) :: [map()]
  def trigger_action_forms(html) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        trigger_action_forms_in_doc(lazy_html, html)

      _ ->
        []
    end
  end

  defp find_live_clickable_button_in_doc(lazy_html, expected, opts, scope) do
    query_selector = selector_opt(opts) || "button[phx-click]"

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        root_node
        |> safe_query(query_selector)
        |> Enum.flat_map(&maybe_live_clickable_match_list(root_node, &1, lazy_html, expected, opts))
      end)
      |> Enum.filter(&Query.matches_state_filters?(&1, opts))

    case Query.pick_match(matches, opts) do
      {:ok, match} -> {:ok, match}
      {:error, _reason} -> :error
    end
  end

  defp maybe_live_clickable_match(root_node, node, lazy_html, expected, opts) do
    text = node_text(node)
    value = live_clickable_match_value(root_node, node, opts)

    if live_clickable_button_node?(root_node, node) and Query.match_text?(value, expected, opts) and
         Html.node_matches_locator_filters?(node, opts) do
      mapped =
        node
        |> build_live_clickable_button(root_node, text)
        |> maybe_put_unique_selector(lazy_html, node)
        |> maybe_put_match_selector(node, opts)

      mapped
    end
  end

  defp maybe_live_clickable_match_list(root_node, node, lazy_html, expected, opts) do
    case maybe_live_clickable_match(root_node, node, lazy_html, expected, opts) do
      nil -> []
      mapped -> [mapped]
    end
  end

  defp live_clickable_match_value(root_node, node, opts) do
    case match_by_opt(opts) do
      :button -> node_text(node)
      :title -> attr(node, "title") || ""
      :testid -> attr(node, "data-testid") || ""
      :alt -> button_alt_text(node, root_node)
      _ -> node_text(node)
    end
  end

  defp form_field_live_flags(html, field, scope) do
    defaults = %{input_phx_change: false, form_phx_change: false}

    case parse_document(html) do
      {:ok, lazy_html} ->
        lazy_html
        |> scoped_nodes(scope)
        |> Enum.find_value(defaults, &field_live_flags_in_root(&1, field))

      _ ->
        defaults
    end
  end

  defp field_live_flags_in_root(root_node, field) do
    case resolve_field_node(root_node, field) do
      nil ->
        false

      field_node ->
        form_node = resolve_form_node(root_node, field, field_node)

        %{
          input_phx_change: phx_binding?(attr(field_node, "phx-change")),
          form_phx_change: phx_binding?(attr_or_nil(form_node, "phx-change"))
        }
    end
  end

  defp resolve_field_node(root_node, field) do
    field
    |> field_candidates(root_node)
    |> Enum.find(&field_node_match?(&1, field))
  end

  defp field_candidates(%{selector: selector}, root_node) when is_binary(selector) and selector != "" do
    safe_query(root_node, selector)
  end

  defp field_candidates(%{id: id}, root_node) when is_binary(id) and id != "" do
    safe_query(root_node, ~s([id="#{css_attr_escape(id)}"]))
  end

  defp field_candidates(%{name: name}, root_node) when is_binary(name) and name != "" do
    safe_query(root_node, ~s([name="#{css_attr_escape(name)}"]))
  end

  defp field_candidates(_field, _root_node), do: []

  defp field_node_match?(node, %{id: id}) when is_binary(id) and id != "" do
    attr(node, "id") == id
  end

  defp field_node_match?(node, %{name: name}) when is_binary(name) and name != "" do
    attr(node, "name") == name
  end

  defp field_node_match?(_node, _field), do: true

  defp resolve_form_node(root_node, %{form: form_id}, _field_node) when is_binary(form_id) and form_id != "" do
    form_by_id(root_node, form_id)
  end

  defp resolve_form_node(root_node, %{form_selector: selector}, _field_node)
       when is_binary(selector) and selector != "" do
    root_node |> safe_query(selector) |> Enum.at(0)
  end

  defp resolve_form_node(root_node, _field, field_node) do
    root_node
    |> safe_query("form")
    |> Enum.find(fn form_node ->
      form_node
      |> safe_query("*")
      |> Enum.any?(&same_node?(&1, field_node))
    end)
  end

  defp form_phx_submit?(html, button, scope) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        lazy_html
        |> scoped_nodes(scope)
        |> Enum.find_value(false, &submit_form_phx_submit_in_root(&1, button))

      _ ->
        false
    end
  end

  defp submit_form_phx_submit_in_root(root_node, button) do
    case resolve_submit_form_node(root_node, button) do
      nil -> false
      form_node -> phx_binding?(attr(form_node, "phx-submit"))
    end
  end

  defp resolve_submit_form_node(root_node, %{form_selector: selector}) when is_binary(selector) and selector != "" do
    root_node |> safe_query(selector) |> Enum.at(0)
  end

  defp resolve_submit_form_node(root_node, %{form: form_id}) when is_binary(form_id) and form_id != "" do
    form_by_id(root_node, form_id)
  end

  defp resolve_submit_form_node(_root_node, _button), do: nil

  defp trigger_action_forms_in_doc(root_node, html) do
    root_node
    |> safe_query("form")
    |> Enum.flat_map(fn form_node ->
      if trigger_action_enabled?(attr(form_node, "phx-trigger-action")) do
        form_id = attr(form_node, "id")
        selector = form_selector(root_node, form_node, form_id)
        defaults = trigger_action_defaults(html, selector)

        [
          %{
            form: form_id,
            form_selector: selector,
            action: attr(form_node, "action"),
            method: attr(form_node, "method"),
            defaults: defaults
          }
        ]
      else
        []
      end
    end)
  end

  defp trigger_action_defaults(_html, nil), do: %{}
  defp trigger_action_defaults(html, selector), do: Html.form_defaults(html, selector)

  defp live_clickable_button_node?(root_node, node) do
    button_node?(node) and
      (node
       |> attr("phx-click")
       |> LiveViewBindings.phx_click?() or dispatch_change_clickable?(root_node, node))
  end

  defp dispatch_change_clickable?(root_node, node) do
    phx_click = attr(node, "phx-click")

    LiveViewBindings.dispatch_change?(phx_click) and
      case button_form_node(root_node, node) do
        nil -> false
        form_node -> phx_binding?(attr(form_node, "phx-change"))
      end
  end

  defp build_live_clickable_button(node, root_node, text) do
    phx_click = attr(node, "phx-click")
    form_node = button_form_node(root_node, node)
    form_id = attr_or_nil(form_node, "id")

    %{
      text: text,
      title: attr(node, "title") || "",
      testid: attr(node, "data-testid") || "",
      disabled: phx_boolean_attr?(attr(node, "disabled")),
      readonly: phx_boolean_attr?(attr(node, "readonly")),
      selected: false,
      checked: false,
      button_name: attr(node, "name"),
      button_value: attr(node, "value"),
      form: form_id,
      form_selector: form_selector(root_node, form_node, form_id),
      dispatch_change: dispatch_change_clickable?(root_node, node) and not LiveViewBindings.phx_click?(phx_click)
    }
  end

  defp button_form_node(root_node, button_node) do
    case attr(button_node, "form") do
      form_id when is_binary(form_id) and form_id != "" ->
        form_by_id(root_node, form_id)

      _ ->
        root_node
        |> safe_query("form")
        |> Enum.find(fn form_node ->
          form_node
          |> safe_query("*")
          |> Enum.any?(&same_node?(&1, button_node))
        end)
    end
  end

  defp button_alt_text(node, root_node) do
    case attr(node, "alt") do
      direct when is_binary(direct) and direct != "" ->
        direct

      _ ->
        nested_button_alt_text(node, root_node)
    end
  end

  defp nested_button_alt_text(node, root_node) do
    node
    |> safe_query("img[alt],input[type='image'][alt]")
    |> Enum.find_value("", &matching_alt_value(&1, root_node))
  end

  defp matching_alt_value(image_node, _root_node), do: attr(image_node, "alt") || ""

  defp form_selector(_root_node, nil, nil), do: nil

  defp form_selector(_root_node, _form_node, form_id) when is_binary(form_id) and form_id != "" do
    ~s(form[id="#{css_attr_escape(form_id)}"])
  end

  defp form_selector(root_node, form_node, _form_id) when not is_nil(form_node) do
    unique_selector(root_node, form_node)
  end

  defp form_selector(_root_node, _form_node, _form_id), do: nil

  defp form_by_id(root_node, id) do
    root_node
    |> safe_query("form")
    |> Enum.find(fn form_node ->
      attr(form_node, "id") == id
    end)
  end

  defp maybe_put_unique_selector(%{} = mapped, lazy_html, node) do
    case unique_selector(lazy_html, node) do
      nil -> mapped
      selector -> Map.put(mapped, :selector, selector)
    end
  end

  defp maybe_put_match_selector(%{selector: selector} = mapped, _node, _opts)
       when is_binary(selector) and selector != "" do
    mapped
  end

  defp maybe_put_match_selector(mapped, node, opts) do
    case match_selector_for(node, match_by_opt(opts)) do
      selector when is_binary(selector) and selector != "" -> Map.put(mapped, :selector, selector)
      _ -> mapped
    end
  end

  defp match_selector_for(node, :testid) do
    attr_selector("button", "data-testid", attr(node, "data-testid"))
  end

  defp match_selector_for(node, :title) do
    attr_selector("button", "title", attr(node, "title"))
  end

  defp match_selector_for(_node, _match_by), do: nil

  defp attr_selector(tag, attr_name, value)
       when is_binary(tag) and is_binary(attr_name) and is_binary(value) and value != "" do
    ~s(#{tag}[#{attr_name}="#{css_attr_escape(value)}"])
  end

  defp attr_selector(_tag, _attr_name, _value), do: nil

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

  defp node_text(node) do
    node
    |> LazyHTML.text()
    |> String.replace("\u00A0", " ")
    |> String.trim()
  end

  defp attr(node, name) do
    node
    |> LazyHTML.attribute(name)
    |> List.wrap()
    |> List.first()
  end

  defp attr_or_nil(nil, _name), do: nil
  defp attr_or_nil(node, name), do: attr(node, name)

  defp button_node?(node), do: node_tag(node) == "button"

  defp parse_document(html) when is_binary(html) do
    {:ok, LazyHTML.from_document(html)}
  rescue
    _ -> :error
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

  defp selector_opt(opts) do
    case Keyword.get(opts, :selector) do
      selector when is_binary(selector) and selector != "" -> selector
      _ -> nil
    end
  end

  defp match_by_opt(opts) do
    case Keyword.get(opts, :match_by) do
      value when value in [:button, :title, :testid, :alt] -> value
      _ -> :text
    end
  end

  defp phx_binding?(value) when is_binary(value) do
    String.trim(value) != ""
  end

  defp phx_binding?(_value), do: false

  defp phx_boolean_attr?(value) when is_binary(value), do: true
  defp phx_boolean_attr?(_value), do: false

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
