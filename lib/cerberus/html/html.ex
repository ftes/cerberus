defmodule Cerberus.Html do
  @moduledoc false

  alias Cerberus.Locator
  alias Cerberus.Options
  alias Cerberus.Query

  @assertion_deadline_key :cerberus_assertion_deadline_ms
  @assertion_deadline_throw :cerberus_assertion_deadline_exceeded

  @spec texts(String.t() | LazyHTML.t(), true | false | :any, String.t() | nil) :: [String.t()]
  def texts(html_or_doc, visibility \\ true, scope \\ nil)

  def texts(%LazyHTML{} = lazy_html, visibility, scope) do
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
  end

  def texts(html, visibility, scope) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} -> texts(lazy_html, visibility, scope)
      _ -> []
    end
  end

  @spec assertion_values(String.t() | LazyHTML.t(), atom(), true | false | :any, String.t() | nil) ::
          [String.t()]
  def assertion_values(html_or_doc, match_by, visibility \\ true, scope \\ nil)

  def assertion_values(%LazyHTML{} = lazy_html, :text, visibility, scope) do
    texts(lazy_html, visibility, scope)
  end

  def assertion_values(%LazyHTML{} = lazy_html, match_by, visibility, scope) when is_atom(match_by) do
    collect_assertion_values_in_doc(lazy_html, match_by, visibility, scope)
  end

  def assertion_values(html, match_by, visibility, scope) when is_binary(html) and is_atom(match_by) do
    case parse_document(html) do
      {:ok, lazy_html} -> assertion_values(lazy_html, match_by, visibility, scope)
      _ -> []
    end
  end

  @spec locator_assertion_values(String.t() | LazyHTML.t(), Locator.t(), true | false | :any, String.t() | nil) ::
          [String.t()]
  def locator_assertion_values(html_or_doc, locator, visibility \\ true, scope \\ nil)

  def locator_assertion_values(%LazyHTML{} = lazy_html, %Locator{} = locator, visibility, scope) do
    assert_deadline!()
    locator = locator_without_from(locator)
    from_locator = Keyword.get(locator.opts, :from)
    selector = selector_opt(locator.opts)
    query_selector = within_query_selector(locator)
    locator_for_filter = locator_for_candidate_filter(locator, query_selector)

    lazy_html
    |> scoped_nodes(scope)
    |> Enum.flat_map(fn root_node ->
      assert_deadline!()
      hidden_nodes = hidden_nodes_in_root(root_node)

      root_node
      |> safe_query(query_selector)
      |> Enum.filter(&scope_target_candidate_matches?(root_node, &1, locator_for_filter, selector))
      |> maybe_filter_scope_target_closest_candidates(root_node, from_locator)
      |> Enum.flat_map(&locator_assertion_values_for_node(root_node, hidden_nodes, &1, locator, visibility))
    end)
  end

  def locator_assertion_values(html, %Locator{} = locator, visibility, scope) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} -> locator_assertion_values(lazy_html, locator, visibility, scope)
      _ -> []
    end
  end

  @spec node_matches_locator_filters?(term(), Options.locator_filter_opts()) :: boolean()
  def node_matches_locator_filters?(node, opts) when is_list(opts) do
    matches_nested_filter?(node, Keyword.get(opts, :has), true) and
      matches_nested_filter?(node, Keyword.get(opts, :has_not), false)
  end

  @spec fragment_matches_locator_filters?(String.t(), Options.locator_filter_opts()) :: boolean()
  def fragment_matches_locator_filters?(fragment_html, opts) when is_binary(fragment_html) and is_list(opts) do
    if Keyword.has_key?(opts, :has) or Keyword.has_key?(opts, :has_not) do
      fragment_matches_locator_filters_in_doc?(fragment_html, opts)
    else
      true
    end
  end

  defp fragment_matches_locator_filters_in_doc?(fragment_html, opts) do
    with {:ok, lazy_html} <- parse_document(fragment_wrapper(fragment_html)),
         root_node when not is_nil(root_node) <- Enum.at(safe_query(lazy_html, "#__cerberus_fragment_root__ > *"), 0) do
      node_matches_locator_filters?(root_node, opts)
    else
      _ -> false
    end
  end

  @spec find_link(String.t(), String.t() | Regex.t(), Options.locator_filter_opts(), String.t() | nil) ::
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

  @spec find_button(String.t(), String.t() | Regex.t(), Options.locator_filter_opts(), String.t() | nil) ::
          {:ok, %{text: String.t(), selector: String.t() | nil}} | :error
  def find_button(html, expected, opts, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_button_in_doc(lazy_html, expected, opts, scope)

      _ ->
        :error
    end
  end

  @spec find_form_field(
          String.t() | LazyHTML.t(),
          String.t() | Regex.t(),
          Options.locator_filter_opts(),
          String.t() | nil
        ) ::
          {:ok, map()} | :error
  def find_form_field(html_or_doc, expected, opts, scope \\ nil)

  def find_form_field(%LazyHTML{} = lazy_html, expected, opts, scope) do
    find_form_field_in_doc(lazy_html, expected, opts, scope)
  end

  def find_form_field(html, expected, opts, scope) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} -> find_form_field(lazy_html, expected, opts, scope)
      _ -> :error
    end
  end

  @spec select_values(String.t(), map(), String.t() | [String.t()], Options.locator_filter_opts(), String.t() | nil) ::
          {:ok, %{values: [String.t()], multiple?: boolean()}} | {:error, String.t()}
  def select_values(html, field, option, opts, scope \\ nil) when is_binary(html) and is_map(field) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        select_values_in_doc(lazy_html, field, option, opts, scope)

      _ ->
        {:error, "failed to parse html while matching select options"}
    end
  end

  @spec form_defaults(String.t() | LazyHTML.t(), String.t(), String.t() | nil) :: map()
  def form_defaults(html_or_doc, form_selector, scope \\ nil)

  def form_defaults(%LazyHTML{} = lazy_html, form_selector, scope) when is_binary(form_selector) do
    lazy_html
    |> form_node_from_selector(form_selector, scope)
    |> collect_form_defaults()
  end

  def form_defaults(html, form_selector, scope) when is_binary(html) and is_binary(form_selector) do
    case parse_document(html) do
      {:ok, lazy_html} -> form_defaults(lazy_html, form_selector, scope)
      _ -> %{}
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

  @spec checkbox_unchecked_value(String.t() | LazyHTML.t(), String.t(), String.t(), String.t() | nil) ::
          String.t() | nil
  def checkbox_unchecked_value(html_or_doc, form_selector, field_name, scope \\ nil)

  def checkbox_unchecked_value(%LazyHTML{} = lazy_html, form_selector, field_name, scope)
      when is_binary(form_selector) and is_binary(field_name) do
    with true <- form_selector != "",
         true <- field_name != "",
         form_node when not is_nil(form_node) <- form_node_from_selector(lazy_html, form_selector, scope) do
      form_hidden_input_value(lazy_html, form_node, field_name)
    else
      _ -> nil
    end
  end

  def checkbox_unchecked_value(html, form_selector, field_name, scope)
      when is_binary(html) and is_binary(form_selector) and is_binary(field_name) do
    case parse_document(html) do
      {:ok, lazy_html} -> checkbox_unchecked_value(lazy_html, form_selector, field_name, scope)
      _ -> nil
    end
  end

  @spec find_submit_button(
          String.t() | LazyHTML.t(),
          String.t() | Regex.t(),
          Options.locator_filter_opts(),
          String.t() | nil
        ) ::
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
  def find_submit_button(html_or_doc, expected, opts, scope \\ nil)

  def find_submit_button(%LazyHTML{} = lazy_html, expected, opts, scope) do
    find_submit_button_in_doc(lazy_html, expected, opts, scope)
  end

  def find_submit_button(html, expected, opts, scope) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} -> find_submit_button(lazy_html, expected, opts, scope)
      _ -> :error
    end
  end

  @spec find_scope_target(String.t(), Locator.t(), String.t() | nil) ::
          {:ok, %{selector: String.t(), tag: String.t(), iframe?: boolean()}} | {:error, String.t()}
  def find_scope_target(html, %Locator{} = locator, scope \\ nil) when is_binary(html) do
    case parse_document(html) do
      {:ok, lazy_html} ->
        find_scope_target_in_doc(lazy_html, locator, scope)

      _ ->
        {:error, "failed to parse html while resolving within locator"}
    end
  end

  defp find_link_in_doc(lazy_html, expected, opts, scope) do
    case locator_opt(opts) do
      %Locator{} = locator ->
        find_link_by_locator(lazy_html, locator, opts, scope)

      nil ->
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
              disabled: false,
              readonly: false,
              selected: false,
              checked: false,
              title: attr(node, "title") || "",
              aria_label: attr(node, "aria-label") || "",
              testid: attr(node, "data-testid") || ""
            }
          end,
          fn _root_node, node -> link_node?(node) end,
          fn root_node, node -> link_match_value(root_node, node, match_by) end
        )
    end
  end

  defp find_button_in_doc(lazy_html, expected, opts, scope) do
    case locator_opt(opts) do
      %Locator{} = locator ->
        find_button_by_locator(lazy_html, locator, opts, scope)

      nil ->
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
              disabled: disabled?(node),
              readonly: readonly?(node),
              selected: false,
              checked: false,
              title: attr(node, "title") || "",
              aria_label: attr(node, "aria-label") || "",
              testid: attr(node, "data-testid") || "",
              button_name: attr(node, "name"),
              button_value: attr(node, "value")
            }
          end,
          fn _root_node, node -> button_node?(node) end,
          fn root_node, node -> button_match_value(root_node, node, match_by) end
        )
    end
  end

  defp find_form_field_in_doc(lazy_html, expected, opts, scope) do
    case_result =
      case locator_opt(opts) do
        %Locator{} = locator ->
          lazy_html
          |> scoped_nodes(scope)
          |> Enum.flat_map(&find_form_field_in_root_by_locator(&1, locator, opts))

        nil ->
          lazy_html
          |> scoped_nodes(scope)
          |> Enum.flat_map(&find_form_field_in_root(&1, expected, opts))
      end

    matches = Enum.filter(case_result, &Query.matches_state_filters?(&1, opts))

    pick_match_result(matches, opts)
  end

  defp find_submit_button_in_doc(lazy_html, expected, opts, scope) do
    selector = selector_opt(opts)

    case_result =
      case locator_opt(opts) do
        %Locator{} = locator ->
          lazy_html
          |> scoped_nodes(scope)
          |> Enum.flat_map(fn root_node ->
            find_submit_button_in_forms_by_locator(root_node, locator, opts, selector) ++
              find_submit_button_in_owner_form_by_locator(root_node, locator, opts, selector)
          end)

        nil ->
          lazy_html
          |> scoped_nodes(scope)
          |> Enum.flat_map(fn root_node ->
            find_submit_button_in_forms(root_node, expected, opts, selector) ++
              find_submit_button_in_owner_form(root_node, expected, opts, selector)
          end)
      end

    matches = Enum.filter(case_result, &Query.matches_state_filters?(&1, opts))

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

  defp find_scope_target_in_doc(lazy_html, %Locator{} = locator, scope) do
    opts = locator.opts
    from_locator = Keyword.get(opts, :from)
    locator = locator_without_from(locator)
    selector = selector_opt(locator.opts)
    query_selector = within_query_selector(locator)

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        root_node
        |> safe_query(query_selector)
        |> Enum.filter(&scope_target_candidate_matches?(root_node, &1, locator, selector))
        |> maybe_filter_scope_target_closest_candidates(root_node, from_locator)
        |> Enum.map(&scope_target_candidate_map(&1, lazy_html))
      end)

    case Query.pick_match(matches, opts) do
      {:ok, %{selector: selector, tag: tag, iframe?: iframe?}}
      when is_binary(selector) and selector != "" and is_binary(tag) ->
        {:ok, %{selector: selector, tag: tag, iframe?: iframe?}}

      {:ok, _match} ->
        {:error, "within locator matched element but a unique selector could not be derived"}

      {:error, _reason} ->
        {:error, "no elements matched within locator"}
    end
  end

  defp scope_target_candidate_matches?(root_node, node, %Locator{} = locator, selector) do
    assert_deadline!()
    opts = locator.opts

    node_matches_within_locator?(root_node, node, locator) and
      node_matches_selector?(root_node, node, selector) and
      node_matches_locator_filters?(node, opts) and
      Query.matches_state_filters?(scope_target_state(node), opts)
  end

  defp maybe_filter_scope_target_closest_candidates(candidates, _root_node, nil), do: candidates

  defp maybe_filter_scope_target_closest_candidates(candidates, root_node, %Locator{} = from_locator) do
    from_selector = selector_opt(from_locator.opts) || within_query_selector(from_locator)

    from_candidates =
      root_node
      |> safe_query(from_selector)
      |> Enum.filter(&scope_target_candidate_matches?(root_node, &1, from_locator, selector_opt(from_locator.opts)))

    Enum.filter(candidates, fn candidate ->
      closest_scope_candidate_for_any_from?(candidate, candidates, from_candidates)
    end)
  end

  defp closest_scope_candidate_for_any_from?(candidate, candidates, from_candidates) do
    Enum.any?(from_candidates, fn from_node ->
      contains_node_or_same?(candidate, from_node) and
        scope_candidate_is_closest_for_from?(candidate, candidates, from_node)
    end)
  end

  defp scope_candidate_is_closest_for_from?(candidate, candidates, from_node) do
    Enum.all?(candidates, fn other_candidate ->
      same_node?(other_candidate, candidate) or
        not contains_node_or_same?(other_candidate, from_node) or
        not contains_node_or_same?(candidate, other_candidate)
    end)
  end

  defp contains_node_or_same?(container, node) do
    assert_deadline!()

    same_node?(container, node) or
      Enum.any?(safe_query(container, "*"), &same_node?(&1, node))
  end

  defp scope_target_candidate_map(node, lazy_html) do
    node
    |> scope_target_state()
    |> Map.merge(%{
      tag: node_tag(node),
      iframe?: node_tag(node) == "iframe"
    })
    |> maybe_put_unique_selector(lazy_html, node)
  end

  defp scope_target_state(node) do
    %{
      checked: checked?(node),
      disabled: disabled?(node),
      readonly: readonly?(node),
      selected: selected?(node, input_type(node))
    }
  end

  defp locator_without_from(%Locator{} = locator) do
    %{locator | opts: Keyword.delete(locator.opts, :from)}
  end

  defp locator_for_candidate_filter(%Locator{kind: :and, value: members} = locator, query_selector)
       when is_list(members) and is_binary(query_selector) do
    {filtered_members, removed?} =
      Enum.reduce(members, {[], false}, fn
        %Locator{kind: :css, value: value}, {acc, false} when value == query_selector ->
          {acc, true}

        member, {acc, removed?} ->
          {[member | acc], removed?}
      end)

    if removed? do
      %{locator | value: Enum.reverse(filtered_members)}
    else
      locator
    end
  end

  defp locator_for_candidate_filter(locator, _query_selector), do: locator

  defp resolve_role_locator(%Locator{kind: :role} = locator) do
    %{locator | kind: Locator.resolved_kind(locator)}
  end

  defp resolve_role_locator(locator), do: locator

  defp node_matches_within_locator?(root_node, node, %Locator{kind: :and, value: members}) when is_list(members) do
    assert_deadline!()
    Enum.all?(members, &node_matches_within_locator?(root_node, node, &1))
  end

  defp node_matches_within_locator?(root_node, node, %Locator{kind: :or, value: members}) when is_list(members) do
    assert_deadline!()
    Enum.any?(members, &node_matches_within_locator?(root_node, node, &1))
  end

  defp node_matches_within_locator?(root_node, node, %Locator{kind: :not, value: [member]}) do
    assert_deadline!()
    not node_matches_within_locator?(root_node, node, member)
  end

  defp node_matches_within_locator?(root_node, node, %Locator{kind: :css, value: value}) do
    assert_deadline!()

    root_node
    |> safe_query(value)
    |> Enum.any?(&same_node?(&1, node))
  end

  defp node_matches_within_locator?(root_node, node, %Locator{} = locator) do
    assert_deadline!()
    resolved_locator = resolve_role_locator(locator)
    value = within_locator_match_value(root_node, node, resolved_locator)

    is_binary(value) and Query.match_text?(value, resolved_locator.value, resolved_locator.opts)
  end

  defp within_locator_match_value(_root_node, node, %Locator{kind: :text}), do: node_text(node)
  defp within_locator_match_value(root_node, node, %Locator{kind: :link}), do: link_match_value(root_node, node, :link)

  defp within_locator_match_value(root_node, node, %Locator{kind: :button}),
    do: button_match_value(root_node, node, :button)

  defp within_locator_match_value(_root_node, node, %Locator{kind: :label}), do: node_text(node)
  defp within_locator_match_value(_root_node, node, %Locator{kind: :placeholder}), do: attr(node, "placeholder") || ""
  defp within_locator_match_value(_root_node, node, %Locator{kind: :title}), do: attr(node, "title") || ""
  defp within_locator_match_value(_root_node, node, %Locator{kind: :aria_label}), do: attr(node, "aria-label") || ""
  defp within_locator_match_value(root_node, node, %Locator{kind: :alt}), do: node_alt_text(root_node, node)
  defp within_locator_match_value(_root_node, node, %Locator{kind: :testid}), do: attr(node, "data-testid") || ""
  defp within_locator_match_value(_root_node, _node, _locator), do: nil

  defp within_query_selector(%Locator{kind: :css, value: value}), do: value

  defp within_query_selector(%Locator{kind: :and, value: members}) when is_list(members) do
    members
    |> Enum.find_value(fn member ->
      selector = within_query_selector(member)
      if selector == "*", do: nil, else: selector
    end)
    |> Kernel.||("*")
  end

  defp within_query_selector(%Locator{kind: :and}), do: "*"
  defp within_query_selector(%Locator{kind: :or}), do: "*"
  defp within_query_selector(%Locator{kind: :not}), do: "*"
  defp within_query_selector(%Locator{kind: :text}), do: "*"
  defp within_query_selector(%Locator{kind: :link}), do: "a[href]"
  defp within_query_selector(%Locator{kind: :button}), do: "button"
  defp within_query_selector(%Locator{kind: :label}), do: "label"

  defp within_query_selector(%Locator{kind: :placeholder}),
    do: "input[placeholder],textarea[placeholder],select[placeholder]"

  defp within_query_selector(%Locator{kind: :title}), do: "[title]"
  defp within_query_selector(%Locator{kind: :aria_label}), do: "[aria-label]"

  defp within_query_selector(%Locator{kind: :alt}),
    do: "[alt],img[alt],input[type='image'][alt],[role='img'][alt],button,a[href]"

  defp within_query_selector(%Locator{kind: :testid}), do: "[data-testid]"

  defp within_query_selector(%Locator{kind: :role} = locator),
    do: locator |> resolve_role_locator() |> within_query_selector()

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
         node_matches_selector?(root_node, button_node, selector) and
         node_matches_locator_filters?(button_node, opts) do
      action = attr(button_node, "formaction") || form_meta.action
      method = attr(button_node, "formmethod") || form_meta.method

      %{
        text: text,
        title: attr(button_node, "title") || "",
        alt: button_alt_text(button_node),
        testid: attr(button_node, "data-testid") || "",
        disabled: disabled?(button_node),
        readonly: readonly?(button_node),
        selected: false,
        checked: false,
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

  defp find_link_by_locator(lazy_html, locator, opts, scope) do
    selector = selector_opt(opts)

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        root_node
        |> safe_query("a[href]")
        |> Enum.flat_map(&maybe_link_by_locator(root_node, &1, lazy_html, locator, selector))
      end)

    pick_match_result(matches, opts)
  end

  defp find_button_by_locator(lazy_html, locator, opts, scope) do
    selector = selector_opt(opts)

    matches =
      lazy_html
      |> scoped_nodes(scope)
      |> Enum.flat_map(fn root_node ->
        root_node
        |> safe_query("button")
        |> Enum.flat_map(&maybe_button_by_locator(root_node, &1, lazy_html, locator, selector))
      end)

    pick_match_result(matches, opts)
  end

  defp find_form_field_in_root_by_locator(root_node, locator, opts) do
    selector = selector_opt(opts)

    root_node
    |> safe_query("input,textarea,select")
    |> Enum.flat_map(fn field_node ->
      with true <- form_field_candidate_node?(field_node),
           {:ok, %{name: name} = field} <- field_node_to_map(root_node, field_node),
           true <- is_binary(name) and name != "",
           true <- field_matches_selector?(root_node, field, selector),
           true <- locator_matches_action_node?(root_node, field_node, locator, :form_field) do
        [
          build_form_field_match(
            root_node,
            field_label_for_node(root_node, field_node),
            name,
            field,
            field_node
          )
        ]
      else
        _ -> []
      end
    end)
  end

  defp form_field_candidate_node?(field_node) do
    input_type = input_type(field_node)
    input_type not in ["hidden", "submit", "button"]
  end

  defp find_submit_button_in_forms_by_locator(root_node, locator, opts, selector) do
    root_node
    |> safe_query("form")
    |> Enum.flat_map(fn form_node ->
      form_meta = form_meta_from_form_node(root_node, form_node)
      find_submit_button_in_form_by_locator(root_node, form_node, form_meta, locator, opts, selector)
    end)
  end

  defp find_submit_button_in_form_by_locator(root_node, form_node, form_meta, locator, opts, selector) do
    form_node
    |> LazyHTML.query("button")
    |> Enum.flat_map(fn button_node ->
      case build_submit_button_by_locator(button_node, form_meta, locator, opts, root_node, selector) do
        nil -> []
        button -> [button]
      end
    end)
  end

  defp find_submit_button_in_owner_form_by_locator(root_node, locator, opts, selector) do
    root_node
    |> safe_query("button[form]")
    |> Enum.flat_map(&owner_form_submit_by_locator(root_node, &1, locator, opts, selector))
  end

  defp build_submit_button_by_locator(button_node, form_meta, locator, _opts, root_node, selector) do
    if submit_button_by_locator_candidate?(root_node, button_node, locator, selector) do
      submit_button_map(button_node, form_meta, root_node)
    end
  end

  defp submit_button_by_locator_candidate?(root_node, button_node, locator, selector) do
    type = attr(button_node, "type") || "submit"

    type in ["submit", ""] and
      node_matches_selector?(root_node, button_node, selector) and
      locator_matches_action_node?(root_node, button_node, locator, :submit_button)
  end

  defp submit_button_map(button_node, form_meta, root_node) do
    action = attr(button_node, "formaction") || form_meta.action
    method = attr(button_node, "formmethod") || form_meta.method

    %{
      text: node_text(button_node),
      title: attr(button_node, "title") || "",
      aria_label: attr(button_node, "aria-label") || "",
      alt: button_alt_text(button_node, root_node),
      testid: attr(button_node, "data-testid") || "",
      disabled: disabled?(button_node),
      readonly: readonly?(button_node),
      selected: false,
      checked: false,
      action: action,
      method: method,
      form: form_meta.form,
      form_selector: form_meta.form_selector,
      button_name: attr(button_node, "name"),
      button_value: attr(button_node, "value")
    }
  end

  defp maybe_link_by_locator(root_node, node, lazy_html, locator, selector) do
    if link_node?(node) and node_matches_selector?(root_node, node, selector) and
         locator_matches_action_node?(root_node, node, locator, :link) do
      mapped =
        maybe_put_unique_selector(
          %{
            text: node_text(node),
            href: attr(node, "href"),
            disabled: false,
            readonly: false,
            selected: false,
            checked: false,
            title: attr(node, "title") || "",
            aria_label: attr(node, "aria-label") || "",
            alt: node_alt_text(root_node, node),
            testid: attr(node, "data-testid") || ""
          },
          lazy_html,
          node
        )

      [mapped]
    else
      []
    end
  end

  defp maybe_button_by_locator(root_node, node, lazy_html, locator, selector) do
    if button_node?(node) and node_matches_selector?(root_node, node, selector) and
         locator_matches_action_node?(root_node, node, locator, :button) do
      mapped =
        maybe_put_unique_selector(
          %{
            text: node_text(node),
            disabled: disabled?(node),
            readonly: readonly?(node),
            selected: false,
            checked: false,
            title: attr(node, "title") || "",
            aria_label: attr(node, "aria-label") || "",
            alt: button_alt_text(node, root_node),
            testid: attr(node, "data-testid") || "",
            button_name: attr(node, "name"),
            button_value: attr(node, "value")
          },
          lazy_html,
          node
        )

      [mapped]
    else
      []
    end
  end

  defp owner_form_submit_by_locator(root_node, button_node, locator, opts, selector) do
    case resolve_owner_form_meta(root_node, button_node) do
      {:ok, form_meta} ->
        case build_submit_button_by_locator(button_node, form_meta, locator, opts, root_node, selector) do
          nil -> []
          button -> [button]
        end

      :error ->
        []
    end
  end

  defp resolve_owner_form_meta(root_node, button_node) do
    owner_form = attr(button_node, "form")

    with true <- is_binary(owner_form) and owner_form != "",
         form_node when not is_nil(form_node) <- form_by_id(root_node, owner_form) do
      {:ok, form_meta_from_form_node(root_node, form_node, owner_form)}
    else
      _ -> :error
    end
  end

  defp find_form_field_in_root(root_node, expected, opts) do
    selector = selector_opt(opts)
    match_by = match_by_opt(opts, :label)

    case match_by do
      :label ->
        root_node
        |> safe_query("label")
        |> Enum.flat_map(&maybe_form_field_match_list(&1, root_node, expected, opts, selector))

      kind when kind in [:placeholder, :title, :aria_label, :testid] ->
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
         true <- field_matches_selector?(root_node, field, selector),
         true <- node_matches_locator_filters?(field_node, opts) do
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
         true <- field_matches_selector?(root_node, field, selector),
         true <- node_matches_locator_filters?(field_node, opts) do
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
      aria_label: attr(field_node, "aria-label") || "",
      testid: attr(field_node, "data-testid") || "",
      input_value: input_value(field_node, input_type),
      input_checked: checked?(field_node),
      input_disabled: disabled?(field_node),
      input_readonly: readonly?(field_node),
      input_selected: selected?(field_node, input_type)
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

    if node_predicate.(root_node, node) and is_binary(value) and Query.match_text?(value, expected, opts) and
         node_matches_locator_filters?(node, opts) do
      mapped =
        node
        |> build_fun.(text, root_node)
        |> maybe_put_unique_selector(lazy_html, node)

      if Query.matches_state_filters?(mapped, opts), do: mapped
    end
  end

  defp maybe_matching_node_list(node, root_node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun) do
    case maybe_matching_node(root_node, node, lazy_html, expected, opts, build_fun, node_predicate, match_value_fun) do
      nil -> []
      match -> [match]
    end
  end

  defp locator_matches_action_node?(root_node, node, %Locator{kind: :and, value: members, opts: opts}, context)
       when is_list(members) do
    Enum.all?(members, &locator_matches_action_node?(root_node, node, &1, context)) and
      action_node_matches_common_opts?(root_node, node, opts)
  end

  defp locator_matches_action_node?(root_node, node, %Locator{kind: :or, value: members, opts: opts}, context)
       when is_list(members) do
    Enum.any?(members, &locator_matches_action_node?(root_node, node, &1, context)) and
      action_node_matches_common_opts?(root_node, node, opts)
  end

  defp locator_matches_action_node?(root_node, node, %Locator{kind: :not, value: [member], opts: opts}, context) do
    not locator_matches_action_node?(root_node, node, member, context) and
      action_node_matches_common_opts?(root_node, node, opts)
  end

  defp locator_matches_action_node?(root_node, node, %Locator{kind: :css, value: selector, opts: opts}, _context) do
    node_matches_selector?(root_node, node, selector) and action_node_matches_common_opts?(root_node, node, opts)
  end

  defp locator_matches_action_node?(root_node, node, %Locator{kind: kind, value: expected, opts: opts}, context) do
    resolved_kind = Locator.resolved_kind(%Locator{kind: kind, value: expected, opts: opts})

    with true <- action_node_matches_common_opts?(root_node, node, opts),
         value when is_binary(value) <- action_locator_match_value(root_node, node, resolved_kind, context),
         true <- Query.match_text?(value, expected, opts) do
      true
    else
      _ -> false
    end
  end

  defp action_locator_match_value(root_node, node, :text, :form_field) do
    field_label_for_node(root_node, node)
  end

  defp action_locator_match_value(_root_node, node, :text, _context), do: node_text(node)

  defp action_locator_match_value(root_node, node, :link, :link), do: link_match_value(root_node, node, :link)
  defp action_locator_match_value(_root_node, _node, :link, _context), do: nil

  defp action_locator_match_value(root_node, node, :button, context) when context in [:button, :submit_button] do
    button_match_value(root_node, node, :button)
  end

  defp action_locator_match_value(_root_node, _node, :button, _context), do: nil

  defp action_locator_match_value(root_node, node, :label, :form_field) do
    field_label_for_node(root_node, node)
  end

  defp action_locator_match_value(_root_node, node, :label, _context), do: node_text(node)

  defp action_locator_match_value(_root_node, node, :placeholder, _context), do: attr(node, "placeholder") || ""
  defp action_locator_match_value(_root_node, node, :title, _context), do: attr(node, "title") || ""
  defp action_locator_match_value(_root_node, node, :aria_label, _context), do: attr(node, "aria-label") || ""
  defp action_locator_match_value(_root_node, node, :testid, _context), do: attr(node, "data-testid") || ""

  defp action_locator_match_value(root_node, node, :alt, :link), do: node_alt_text(root_node, node)

  defp action_locator_match_value(root_node, node, :alt, context) when context in [:button, :submit_button] do
    button_alt_text(node, root_node)
  end

  defp action_locator_match_value(_root_node, _node, :alt, _context), do: nil

  defp action_node_matches_common_opts?(root_node, node, opts) when is_list(opts) do
    node_matches_selector?(root_node, node, selector_opt(opts)) and
      node_matches_locator_filters?(node, opts) and
      Query.matches_state_filters?(scope_target_state(node), opts)
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

  defp locator_assertion_values_for_node(root_node, hidden_nodes, node, locator, visibility) do
    hidden? = node_hidden_in_root?(hidden_nodes, node)
    maybe_locator_assertion_value(selected_visibility?(visibility, hidden?), root_node, node, locator)
  end

  defp maybe_locator_assertion_value(true, root_node, node, locator) do
    [locator_assertion_value(root_node, node, locator)]
  end

  defp maybe_locator_assertion_value(false, _root_node, _node, _locator), do: []

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
  defp assertion_value_for(_tag, attrs, _children, :aria_label), do: attr_from_attrs(attrs, "aria-label")
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

  defp selected_visibility?(true, hidden?), do: not hidden?
  defp selected_visibility?(false, hidden?), do: hidden?
  defp selected_visibility?(:any, _hidden?), do: true
  defp selected_visibility?(_other, hidden?), do: not hidden?

  defp hidden_nodes_in_root(root_node) do
    root_node
    |> safe_query("*")
    |> Enum.filter(&hidden_node?/1)
  end

  defp node_hidden_in_root?(hidden_nodes, node) do
    assert_deadline!()

    hidden_node?(node) or
      Enum.any?(hidden_nodes, &contains_node_or_same?(&1, node))
  end

  defp hidden_node?(node) do
    hidden_attr? = is_binary(attr(node, "hidden"))

    style =
      node
      |> attr("style")
      |> to_string()
      |> String.downcase()
      |> String.replace(" ", "")

    hidden_attr? or String.contains?(style, "display:none") or
      String.contains?(style, "visibility:hidden")
  end

  defp locator_assertion_value(root_node, node, locator) do
    case within_locator_match_value(root_node, node, locator) do
      value when is_binary(value) and value != "" -> value
      _ -> node_text(node)
    end
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

  defp link_match_value(root_node, node, :alt), do: node_alt_text(root_node, node)
  defp link_match_value(_root_node, node, match_by) when match_by in [:text, :link], do: node_text(node)
  defp link_match_value(_root_node, node, match_by), do: action_match_attr_value(node, match_by, node_text(node))

  defp button_match_value(root_node, node, :alt), do: button_alt_text(node, root_node)
  defp button_match_value(_root_node, node, match_by) when match_by in [:text, :button], do: node_text(node)
  defp button_match_value(_root_node, node, match_by), do: action_match_attr_value(node, match_by, node_text(node))

  defp field_match_value(_root_node, field_node, :placeholder), do: attr(field_node, "placeholder") || ""
  defp field_match_value(_root_node, field_node, :title), do: attr(field_node, "title") || ""
  defp field_match_value(_root_node, field_node, :aria_label), do: attr(field_node, "aria-label") || ""
  defp field_match_value(_root_node, field_node, :testid), do: attr(field_node, "data-testid") || ""

  defp action_match_attr_value(node, :title, _fallback), do: attr(node, "title") || ""
  defp action_match_attr_value(node, :aria_label, _fallback), do: attr(node, "aria-label") || ""
  defp action_match_attr_value(node, :testid, _fallback), do: attr(node, "data-testid") || ""
  defp action_match_attr_value(_node, _match_by, fallback), do: fallback

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

  defp node_has_locator?(node, %Locator{} = has_locator) do
    selector = selector_opt(has_locator.opts) || within_query_selector(has_locator)
    has_locator = locator_without_from(has_locator)

    selector
    |> safe_query_in_node(node)
    |> Enum.any?(fn candidate_node ->
      node_matches_within_locator?(node, candidate_node, has_locator) and
        node_matches_locator_filters?(candidate_node, has_locator.opts) and
        Query.matches_state_filters?(scope_target_state(candidate_node), has_locator.opts)
    end)
  end

  defp matches_nested_filter?(_node, nil, _expected), do: true

  defp matches_nested_filter?(node, %Locator{} = nested_locator, true) do
    node_has_locator?(node, nested_locator)
  end

  defp matches_nested_filter?(node, %Locator{} = nested_locator, false) do
    not node_has_locator?(node, nested_locator)
  end

  defp matches_nested_filter?(_node, _invalid, _expected), do: false

  defp safe_query_in_node(selector, node) when is_binary(selector) do
    safe_query(node, selector)
  end

  defp safe_query_in_node(_selector, _node), do: []

  defp fragment_wrapper(fragment_html) do
    """
    <!doctype html>
    <html>
      <head><meta charset="utf-8" /></head>
      <body>
        <div id="__cerberus_fragment_root__">#{fragment_html}</div>
      </body>
    </html>
    """
  end

  defp field_for_label(root_node, label_node) do
    case attr(label_node, "for") do
      nil ->
        label_node
        |> safe_query("input,textarea,select")
        |> Enum.find_value(:error, fn node -> field_node_to_map(root_node, node) end)

      id ->
        root_node
        |> safe_query_by_id(id)
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
       aria_label: attr(node, "aria-label"),
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
    |> safe_query_by_id(id)
    |> Enum.find(&(node_tag(&1) == "form"))
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

  defp form_hidden_input_value(root_node, form_node, field_name) do
    case form_node |> hidden_inputs_with_name(field_name) |> Enum.find_value(&hidden_input_value/1) do
      nil ->
        case attr(form_node, "id") do
          form_id when is_binary(form_id) and form_id != "" ->
            root_node
            |> owner_hidden_inputs(form_id, field_name)
            |> Enum.find_value(&hidden_input_value/1)

          _ ->
            nil
        end

      value ->
        value
    end
  end

  defp hidden_inputs_with_name(node, field_name) do
    selector = ~s|input[type="hidden"][name="#{css_attr_escape(field_name)}"]:not([disabled])|
    safe_query(node, selector)
  end

  defp owner_hidden_inputs(root_node, form_id, field_name) do
    selector =
      ~s|input[type="hidden"][form="#{css_attr_escape(form_id)}"][name="#{css_attr_escape(field_name)}"]:not([disabled])|

    safe_query(root_node, selector)
  end

  defp hidden_input_value(node) do
    case attr(node, "value") do
      value when is_binary(value) -> value
      _ -> ""
    end
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
    |> Enum.filter(&selected_option?/1)
    |> Enum.map(&option_value/1)
  end

  defp selected_option?(node) do
    node
    |> attr("selected")
    |> is_binary()
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

  defp selected?(field_node, input_type) when input_type in ["checkbox", "radio"], do: checked?(field_node)

  defp selected?(field_node, input_type) when input_type in ["select-one", "select-multiple"],
    do: selected_option_values(field_node) != []

  defp selected?(_field_node, _input_type), do: false

  defp disabled?(node) do
    node
    |> attr("disabled")
    |> is_binary()
  end

  defp readonly?(node) do
    node
    |> attr("readonly")
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

  defp match_by_opt(opts, default \\ :text) do
    case Keyword.get(opts, :match_by) do
      value when value in [:label, :link, :button, :placeholder, :title, :alt, :aria_label, :testid] -> value
      _ -> default
    end
  end

  defp node_matches_selector?(_root_node, _node, nil), do: true

  defp node_matches_selector?(root_node, node, selector) do
    assert_deadline!()

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
    assert_deadline!()
    left_id = attr(left, "id")
    right_id = attr(right, "id")

    if is_binary(left_id) and left_id != "" and is_binary(right_id) and right_id != "" do
      left_id == right_id
    else
      node_tag(left) == node_tag(right) and node_text(left) == node_text(right) and
        node_attrs(left) == node_attrs(right)
    end
  end

  @spec current_assertion_deadline_ms() :: integer() | nil
  def current_assertion_deadline_ms do
    Process.get(@assertion_deadline_key)
  end

  @spec put_assertion_deadline_ms(integer() | nil) :: integer() | nil
  def put_assertion_deadline_ms(deadline_ms) when is_integer(deadline_ms) do
    Process.put(@assertion_deadline_key, deadline_ms)
  end

  def put_assertion_deadline_ms(nil) do
    Process.delete(@assertion_deadline_key)
  end

  @spec assertion_deadline_throw() :: atom()
  def assertion_deadline_throw, do: @assertion_deadline_throw

  defp assert_deadline! do
    case current_assertion_deadline_ms() do
      deadline_ms when is_integer(deadline_ms) ->
        if System.monotonic_time(:millisecond) > deadline_ms do
          throw({@assertion_deadline_throw, deadline_ms})
        end

      _ ->
        :ok
    end
  end
end
