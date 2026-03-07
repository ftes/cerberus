defmodule Cerberus.Phoenix.LiveViewHTML do
  @moduledoc false

  alias Cerberus.Html
  alias Cerberus.Locator
  alias Cerberus.Phoenix.LiveViewBindings
  alias Cerberus.Query

  @spec find_live_clickable_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, map()} | :error
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
    with {:ok, lazy_html} <- parse_document(html),
         {:ok, field} <- find_form_field_with_fallback(lazy_html, expected, opts, scope) do
      {:ok, Map.merge(field, form_field_live_flags(lazy_html, field, scope))}
    else
      _ ->
        :error
    end
  end

  defp find_form_field_with_fallback(lazy_html, expected, opts, scope) do
    case Html.find_form_field(lazy_html, expected, opts, scope) do
      {:ok, field} -> {:ok, field}
      :error -> find_form_field_without_name(lazy_html, expected, opts, scope)
    end
  end

  @spec find_submit_button(String.t(), String.t() | Regex.t(), keyword(), String.t() | nil) ::
          {:ok, map()} | :error
  def find_submit_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        case Html.find_submit_button(lazy_html, expected, opts, scope) do
          {:ok, button} ->
            {:ok, Map.put(button, :form_phx_submit, form_phx_submit?(lazy_html, button, scope))}

          :error ->
            :error
        end

      _ ->
        :error
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

  defp find_live_clickable_button_in_doc(lazy_html, expected, opts, scope) do
    query_selector = selector_opt(opts) || "[phx-click]"

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        root_node
        |> safe_query(query_selector)
        |> Enum.flat_map(&maybe_live_clickable_match_list(root_node, &1, expected, opts))
      end)
      |> Enum.filter(&Query.matches_state_filters?(&1, opts))

    case Query.pick_match(matches, opts) do
      {:ok, match} -> {:ok, match}
      {:error, _reason} -> :error
    end
  end

  defp maybe_live_clickable_match(root_node, node, expected, opts) do
    locator = locator_opt(opts)
    text = node_text(node)

    matches? =
      if is_struct(locator, Locator) do
        live_clickable_locator_match?(root_node, node, locator)
      else
        value = live_clickable_match_value(root_node, node, opts)
        Query.match_text?(value, expected, opts) and Html.node_matches_locator_filters?(node, opts)
      end

    if live_clickable_button_node?(root_node, node) and matches? do
      mapped =
        node
        |> build_live_clickable_button(root_node, text)
        |> maybe_put_unique_selector(root_node, node)
        |> maybe_put_match_selector(node, opts)

      mapped
    end
  end

  defp maybe_live_clickable_match_list(root_node, node, expected, opts) do
    case maybe_live_clickable_match(root_node, node, expected, opts) do
      nil -> []
      mapped -> [mapped]
    end
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: :and, value: members, opts: opts})
       when is_list(members) do
    Enum.all?(members, &live_clickable_locator_match?(root_node, node, &1)) and
      live_clickable_common_opts_match?(root_node, node, opts)
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: :or, value: members, opts: opts})
       when is_list(members) do
    Enum.any?(members, &live_clickable_locator_match?(root_node, node, &1)) and
      live_clickable_common_opts_match?(root_node, node, opts)
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: :scope, value: members, opts: opts})
       when is_list(members) do
    live_clickable_scope_members_match?(root_node, node, members) and
      live_clickable_common_opts_match?(root_node, node, opts)
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: :not, value: [member], opts: opts}) do
    not live_clickable_locator_match?(root_node, node, member) and
      live_clickable_common_opts_match?(root_node, node, opts)
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: :css, value: selector, opts: opts}) do
    node_matches_selector?(root_node, node, selector) and live_clickable_common_opts_match?(root_node, node, opts)
  end

  defp live_clickable_locator_match?(root_node, node, %Locator{kind: kind, value: expected, opts: opts}) do
    resolved_kind = Locator.resolved_kind(%Locator{kind: kind, value: expected, opts: opts})

    with true <- live_clickable_common_opts_match?(root_node, node, opts),
         value when is_binary(value) <- live_clickable_locator_value(root_node, node, resolved_kind),
         true <- Query.match_text?(value, expected, opts) do
      true
    else
      _ -> false
    end
  end

  defp live_clickable_locator_value(_root_node, node, :text), do: node_text(node)

  defp live_clickable_locator_value(_root_node, node, :button) do
    if button_node?(node), do: node_text(node)
  end

  defp live_clickable_locator_value(_root_node, node, :title), do: attr(node, "title") || ""
  defp live_clickable_locator_value(_root_node, node, :aria_label), do: attr(node, "aria-label") || ""
  defp live_clickable_locator_value(_root_node, node, :testid), do: attr(node, "data-testid") || ""
  defp live_clickable_locator_value(root_node, node, :alt), do: button_alt_text(node, root_node)
  defp live_clickable_locator_value(_root_node, _node, :link), do: nil
  defp live_clickable_locator_value(_root_node, _node, :label), do: nil
  defp live_clickable_locator_value(_root_node, _node, :placeholder), do: nil

  defp live_clickable_scope_members_match?(_root_node, _node, members) when length(members) < 2, do: false

  defp live_clickable_scope_members_match?(root_node, node, members) do
    target_locator = List.last(members)
    scope_members = Enum.drop(members, -1)

    scope_locator =
      case scope_members do
        [single] -> single
        _ -> %Locator{kind: :scope, value: scope_members, opts: []}
      end

    live_clickable_locator_match?(root_node, node, target_locator) and
      live_clickable_node_has_scope_chain?(root_node, node, scope_locator)
  end

  defp live_clickable_node_has_scope_chain?(root_node, node, %Locator{} = scope_locator) do
    root_node
    |> safe_query("*")
    |> Enum.any?(fn scope_node ->
      live_clickable_locator_match?(root_node, scope_node, scope_locator) and
        strict_descendant?(scope_node, node)
    end)
  end

  defp live_clickable_common_opts_match?(root_node, node, opts) when is_list(opts) do
    node_matches_selector?(root_node, node, selector_opt(opts)) and
      Html.node_matches_locator_filters?(node, opts) and
      Query.matches_state_filters?(live_clickable_state(root_node, node), opts)
  end

  defp live_clickable_state(root_node, node) do
    %{
      checked: false,
      disabled: phx_boolean_attr?(attr(node, "disabled")),
      readonly: phx_boolean_attr?(attr(node, "readonly")),
      selected: false,
      visible: Html.node_visible_in_root?(root_node, node)
    }
  end

  defp live_clickable_match_value(root_node, node, opts) do
    case match_by_opt(opts) do
      :alt -> if(button_node?(node), do: button_alt_text(node, root_node), else: "")
      :button -> if(button_node?(node), do: node_text(node), else: "")
      other -> clickable_attr_match_value(node, other, node_text(node))
    end
  end

  defp clickable_attr_match_value(node, :title, _fallback), do: attr(node, "title") || ""
  defp clickable_attr_match_value(node, :aria_label, _fallback), do: attr(node, "aria-label") || ""
  defp clickable_attr_match_value(node, :testid, _fallback), do: attr(node, "data-testid") || ""
  defp clickable_attr_match_value(_node, _match_by, fallback), do: fallback

  defp find_form_field_without_name(lazy_html, expected, opts, scope) do
    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(&find_nameless_matches_in_root(&1, expected, opts))
      |> Enum.filter(&Query.matches_state_filters?(&1, opts))

    case Query.pick_match(matches, opts) do
      {:ok, match} -> {:ok, match}
      {:error, _reason} -> :error
    end
  end

  defp find_nameless_matches_in_root(root_node, expected, opts) do
    selector = selector_opt(opts)

    root_node
    |> safe_query("input[type='checkbox'][phx-click],input[type='radio'][phx-click]")
    |> Enum.flat_map(&build_nameless_match_list(root_node, &1, expected, opts, selector))
  end

  defp build_nameless_match_list(root_node, field_node, expected, opts, selector) do
    label_text = field_label_text(root_node, field_node)

    if nameless_field_match?(root_node, field_node, label_text, expected, opts, selector) do
      [build_nameless_field_match(root_node, field_node, label_text)]
    else
      []
    end
  end

  defp nameless_field_match?(root_node, field_node, label_text, expected, opts, selector) do
    nameless_field?(field_node) and
      is_binary(label_text) and
      label_text != "" and
      Query.match_text?(label_text, expected, opts) and
      node_matches_selector?(root_node, field_node, selector) and
      Html.node_matches_locator_filters?(field_node, opts)
  end

  defp nameless_field?(field_node) do
    case attr(field_node, "name") do
      name when is_binary(name) -> name == ""
      _ -> true
    end
  end

  defp build_nameless_field_match(root_node, field_node, label_text) do
    form_node = field_form_node(root_node, field_node)
    form_id = attr_or_nil(form_node, "id")

    %{
      id: attr(field_node, "id"),
      label: label_text,
      name: nil,
      selector: unique_selector(root_node, field_node),
      input_type: field_input_type(field_node),
      input_value: attr(field_node, "value") || "on",
      input_checked: phx_boolean_attr?(attr(field_node, "checked")),
      input_disabled: phx_boolean_attr?(attr(field_node, "disabled")),
      input_readonly: phx_boolean_attr?(attr(field_node, "readonly")),
      visible: Html.node_visible_in_root?(root_node, field_node),
      form: form_id,
      form_selector: form_selector(root_node, form_node, form_id)
    }
  end

  defp field_label_text(root_node, field_node) do
    case attr(field_node, "id") do
      id when is_binary(id) and id != "" ->
        case root_node |> safe_query(~s(label[for="#{css_attr_escape(id)}"])) |> Enum.at(0) do
          nil -> wrapped_field_label_text(root_node, field_node)
          label_node -> node_text(label_node)
        end

      _ ->
        wrapped_field_label_text(root_node, field_node)
    end
  end

  defp wrapped_field_label_text(root_node, field_node) do
    root_node
    |> safe_query("label")
    |> Enum.find_value(fn label_node ->
      if label_node
         |> safe_query("*")
         |> Enum.any?(&same_node?(&1, field_node)) do
        node_text(label_node)
      end
    end)
  end

  defp field_form_node(root_node, field_node) do
    root_node
    |> safe_query("form")
    |> Enum.find(fn form_node ->
      form_node
      |> safe_query("*")
      |> Enum.any?(&same_node?(&1, field_node))
    end)
  end

  defp field_input_type(field_node) do
    case node_tag(field_node) do
      "input" -> String.downcase(attr(field_node, "type") || "text")
      other -> other
    end
  end

  defp form_field_live_flags(lazy_html, field, scope) do
    defaults = %{
      input_phx_change: false,
      form_phx_change: false,
      input_phx_click: false,
      option_phx_click_selectors: %{}
    }

    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(defaults, &field_live_flags_in_root(&1, field))
  end

  defp field_live_flags_in_root(root_node, field) do
    case resolve_field_node(root_node, field) do
      nil ->
        false

      field_node ->
        form_node = resolve_form_node(root_node, field, field_node)

        %{
          input_phx_change: phx_binding?(attr(field_node, "phx-change")),
          form_phx_change: phx_binding?(attr_or_nil(form_node, "phx-change")),
          input_phx_click: phx_binding?(attr(field_node, "phx-click")),
          option_phx_click_selectors: option_phx_click_selectors(root_node, field_node)
        }
    end
  end

  defp option_phx_click_selectors(root_node, field_node) do
    if node_tag(field_node) == "select" do
      field_node
      |> safe_query("option[phx-click]")
      |> Enum.reduce(%{}, &put_option_selector(&2, root_node, &1))
    else
      %{}
    end
  end

  defp put_option_selector(acc, root_node, option_node) do
    case {attr(option_node, "value"), unique_selector(root_node, option_node)} do
      {value, selector} when is_binary(value) and value != "" and is_binary(selector) and selector != "" ->
        Map.put(acc, value, selector)

      _ ->
        acc
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
    safe_query_by_id(root_node, id)
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

  defp form_phx_submit?(lazy_html, button, scope) do
    lazy_html
    |> scoped_nodes(scope)
    |> Enum.find_value(false, &submit_form_phx_submit_in_root(&1, button))
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

  defp trigger_action_forms_in_doc(root_node) do
    root_node
    |> safe_query("form")
    |> Enum.flat_map(fn form_node ->
      if trigger_action_enabled?(attr(form_node, "phx-trigger-action")) do
        form_id = attr(form_node, "id")
        selector = form_selector(root_node, form_node, form_id)
        defaults = trigger_action_defaults(root_node, selector)

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

  defp trigger_action_defaults(_root_node, nil), do: %{}
  defp trigger_action_defaults(root_node, selector), do: Html.form_defaults(root_node, selector)

  defp live_clickable_button_node?(root_node, node) do
    node
    |> attr("phx-click")
    |> LiveViewBindings.phx_click?() or dispatch_change_clickable?(root_node, node)
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
      tag: node_tag(node),
      text: text,
      title: attr(node, "title") || "",
      aria_label: attr(node, "aria-label") || "",
      testid: attr(node, "data-testid") || "",
      disabled: phx_boolean_attr?(attr(node, "disabled")),
      readonly: phx_boolean_attr?(attr(node, "readonly")),
      selected: false,
      checked: false,
      visible: Html.node_visible_in_root?(root_node, node),
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
    |> safe_query_by_id(id)
    |> Enum.find(&(node_tag(&1) == "form"))
  end

  defp maybe_put_unique_selector(%{} = mapped, query_root, node) do
    case unique_selector(query_root, node) do
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
    attr_selector(node_tag(node), "data-testid", attr(node, "data-testid"))
  end

  defp match_selector_for(node, :title) do
    attr_selector(node_tag(node), "title", attr(node, "title"))
  end

  defp match_selector_for(node, :aria_label) do
    attr_selector(node_tag(node), "aria-label", attr(node, "aria-label"))
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
        path_selector(node),
        tag
      ]
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()

    Enum.find(candidates, &selector_unique?(lazy_html, &1))
  end

  defp path_selector(node), do: path_selector(node, [], 0)

  defp path_selector(_node, segments, depth) when depth >= 64 do
    segments_to_selector(segments)
  end

  defp path_selector(node, segments, depth) do
    tag = node_tag(node)

    if is_binary(tag) and tag != "" do
      id = attr(node, "id")
      segment = path_segment(node, tag, id)
      next_segments = [segment | segments]
      path_selector_next(node, next_segments, id, depth)
    else
      segments_to_selector(segments)
    end
  end

  defp path_segment(_node, _tag, id) when is_binary(id) and id != "" do
    ~s([id="#{css_attr_escape(id)}"])
  end

  defp path_segment(node, tag, _id) do
    case List.first(LazyHTML.nth_child(node)) do
      n when is_integer(n) and n > 0 -> "#{tag}:nth-child(#{n})"
      _ -> tag
    end
  end

  defp path_selector_next(node, next_segments, id, depth) do
    parent = LazyHTML.parent_node(node)

    cond do
      parent == node -> segments_to_selector(next_segments)
      is_binary(id) and id != "" -> segments_to_selector(next_segments)
      true -> path_selector(parent, next_segments, depth + 1)
    end
  end

  defp segments_to_selector([]), do: nil
  defp segments_to_selector(segments), do: Enum.join(segments, " > ")

  defp selector_unique?(lazy_html, selector) do
    lazy_html
    |> LazyHTML.query(selector)
    |> Enum.count() == 1
  rescue
    _ -> false
  end

  defp node_tag(node) do
    node
    |> LazyHTML.tag()
    |> List.first() || "*"
  end

  defp node_attrs(node) do
    case LazyHTML.attributes(node) do
      [attrs | _] when is_list(attrs) ->
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

  defp safe_query_by_id(node, id) when is_binary(id) and id != "" do
    LazyHTML.query_by_id(node, id)
  rescue
    _ -> []
  end

  defp safe_query_by_id(_node, _id), do: []

  defp selector_opt(opts) do
    case Keyword.get(opts, :selector) do
      selector when is_binary(selector) and selector != "" -> selector
      _ -> nil
    end
  end

  defp locator_opt(opts) do
    case Keyword.get(opts, :locator) do
      %Locator{} = locator -> locator
      _ -> nil
    end
  end

  defp node_matches_selector?(_root_node, _node, nil), do: true

  defp node_matches_selector?(root_node, node, selector) do
    root_node
    |> safe_query(selector)
    |> Enum.any?(&same_node?(&1, node))
  end

  defp match_by_opt(opts) do
    case Keyword.get(opts, :match_by) do
      value when value in [:button, :title, :aria_label, :testid, :alt] -> value
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
    node_signature(left) == node_signature(right)
  end

  defp strict_descendant?(container, node) do
    not same_node?(container, node) and contains_node_or_same?(container, node)
  end

  defp contains_node_or_same?(container, node) do
    same_node?(container, node) or
      container
      |> safe_query("*")
      |> Enum.any?(&same_node?(&1, node))
  end

  defp node_signature(node), do: node_signature(node, [], 0)

  defp node_signature(_node, acc, depth) when depth >= 64 do
    Enum.reverse(acc)
  end

  defp node_signature(node, acc, depth) do
    tag = node_tag(node)

    if is_binary(tag) and tag != "" do
      signature = {tag, List.first(LazyHTML.nth_child(node)), attr(node, "id"), attr(node, "name")}
      parent = LazyHTML.parent_node(node)

      if parent == node do
        Enum.reverse([signature | acc])
      else
        node_signature(parent, [signature | acc], depth + 1)
      end
    else
      Enum.reverse(acc)
    end
  end
end
