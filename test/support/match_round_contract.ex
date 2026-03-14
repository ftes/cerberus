defmodule Cerberus.TestSupport.MatchRoundContract do
  @moduledoc false

  import Cerberus

  alias Cerberus.Driver.Browser.ActionHelpers
  alias Cerberus.Driver.Browser.AssertionHelpers
  alias Cerberus.Driver.Browser.MatchRoundPayload
  alias Cerberus.Html
  alias Cerberus.Locator

  @type assertion_case :: %{
          required(:id) => String.t(),
          required(:kind) => :assertion,
          required(:html) => String.t(),
          required(:locator) => Locator.t(),
          required(:opts) => keyword()
        }

  @type action_case :: %{
          required(:id) => String.t(),
          required(:kind) => :action,
          required(:html) => String.t(),
          required(:op) => :click | :fill_in | :submit,
          required(:expected) => String.t() | Regex.t(),
          required(:opts) => keyword()
        }

  @type contract_case :: assertion_case() | action_case()

  @spec cases() :: [contract_case()]
  def cases do
    [
      %{
        id: "assert_css_text_success",
        kind: :assertion,
        html: button_html(),
        locator: and_(css("button"), text("Apply primary", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_css_text_failure_candidates",
        kind: :assertion,
        html: button_html(),
        locator: and_(css("button"), text("Definitely Missing Button Text", exact: false)),
        opts: [trace: true]
      },
      %{
        id: "assert_role_heading_success",
        kind: :assertion,
        html: heading_html(),
        locator: role(:heading, name: "Search heading aria", exact: true),
        opts: [trace: false]
      },
      %{
        id: "assert_filter_has_success",
        kind: :assertion,
        html: button_html(),
        locator: "button" |> css() |> filter(has: text("secondary", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_filter_has_not_success",
        kind: :assertion,
        html: button_html(),
        locator: "button" |> css() |> filter(has_not: text("secondary", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_not_composition_failure",
        kind: :assertion,
        html: button_html(),
        locator: and_(role(:button, name: "Apply"), not_(testid("apply-secondary"))),
        opts: [trace: false]
      },
      %{
        id: "assert_or_ambiguous_success",
        kind: :assertion,
        html: button_html(),
        locator: or_(css("#apply-primary"), css("#apply-secondary")),
        opts: [trace: false]
      },
      %{
        id: "assert_count_success",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: false, count: 2]
      },
      %{
        id: "assert_count_failure_candidates",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: true, count: 3]
      },
      %{
        id: "assert_count_min_max_success",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: false, min: 2, max: 2]
      },
      %{
        id: "assert_count_between_tuple_success",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: false, between: {1, 2}]
      },
      %{
        id: "assert_count_between_range_success",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: false, between: 2..3]
      },
      %{
        id: "assert_closest_from_success",
        kind: :assertion,
        html: closest_html(),
        locator: ".card" |> css() |> closest(from: text("Queue Cobalt", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_benchmark_locator_success",
        kind: :assertion,
        html: benchmark_locator_html(),
        locator:
          "section[data-panel-kind='assignment']"
          |> css()
          |> filter(has: text("batch-orchid", exact: true))
          |> filter(has_not: text("duplicate-lure", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_refute_count_success",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: false, mode: :refute, count: 3]
      },
      %{
        id: "assert_refute_count_failure_candidates",
        kind: :assertion,
        html: count_html(),
        locator: title("Alpha", exact: false),
        opts: [trace: true, mode: :refute, count: 2]
      },
      %{
        id: "assert_submit_has_text_success",
        kind: :assertion,
        html: submit_html(),
        locator: filter(role(:button, name: "Run Search", exact: false), has: text("secondary", exact: true)),
        opts: [trace: false]
      },
      %{
        id: "assert_submit_has_css_success",
        kind: :assertion,
        html: submit_html(),
        locator: filter(role(:button, name: "Run Search", exact: false), has: css(".kind-secondary")),
        opts: [trace: false]
      },
      %{
        id: "assert_submit_has_and_success",
        kind: :assertion,
        html: submit_html(),
        locator:
          filter(
            role(:button, name: "Run Search", exact: false),
            has: and_(testid("submit-secondary-marker"), text("secondary", exact: true))
          ),
        opts: [trace: false]
      },
      %{
        id: "assert_submit_has_missing_failure_candidates",
        kind: :assertion,
        html: submit_html(),
        locator: filter(role(:button, name: "Run Search", exact: false), has: testid("missing-marker")),
        opts: [trace: true]
      },
      %{
        id: "assert_submit_has_not_failure_candidates",
        kind: :assertion,
        html: submit_html(),
        locator: filter(role(:button, name: "Run Search", exact: false), has_not: css("span")),
        opts: [trace: true]
      },
      %{
        id: "click_locator_success",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [
          kind: :button,
          trace: false,
          locator: testid("apply-secondary")
        ]
      },
      %{
        id: "click_locator_failure_candidates",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [
          kind: :button,
          trace: true,
          locator: testid("apply-missing")
        ]
      },
      %{
        id: "click_second_duplicate_button",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [kind: :button, trace: false, nth: 2]
      },
      %{
        id: "click_button_title_last_success",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply secondary title",
        opts: [kind: :button, trace: false, match_by: :title, exact: true, last: true]
      },
      %{
        id: "click_has_testid_success",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [
          kind: :button,
          trace: false,
          locator: filter(role(:button, name: "Apply", exact: false), has: testid("apply-secondary-marker"))
        ]
      },
      %{
        id: "click_has_not_success",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [
          kind: :button,
          trace: false,
          locator: filter(role(:button, name: "Apply", exact: false), has_not: testid("apply-secondary-marker"))
        ]
      },
      %{
        id: "click_has_missing_failure",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [
          kind: :button,
          trace: true,
          locator: filter(role(:button, name: "Apply", exact: false), has: testid("missing-marker"))
        ]
      },
      %{
        id: "click_or_ambiguous_failure",
        kind: :action,
        html: button_html(),
        op: :click,
        expected: "Apply",
        opts: [kind: :button, trace: true, locator: or_(css("#apply-primary"), css("#apply-secondary"))]
      },
      %{
        id: "click_disabled_false_success",
        kind: :action,
        html: actionability_html(),
        op: :click,
        expected: "Toggle panel",
        opts: [kind: :button, trace: false, disabled: false]
      },
      %{
        id: "click_disabled_true_success",
        kind: :action,
        html: actionability_html(),
        op: :click,
        expected: "Toggle panel",
        opts: [kind: :button, trace: false, disabled: true]
      },
      %{
        id: "click_first_count_success",
        kind: :action,
        html: click_count_position_html(),
        op: :click,
        expected: ~r/^Save/,
        opts: [kind: :button, trace: false, match_by: :title, first: true, count: 3]
      },
      %{
        id: "click_last_count_success",
        kind: :action,
        html: click_count_position_html(),
        op: :click,
        expected: ~r/^Save/,
        opts: [kind: :button, trace: false, match_by: :title, last: true, between: {2, 3}]
      },
      %{
        id: "click_nth_count_success",
        kind: :action,
        html: click_count_position_html(),
        op: :click,
        expected: ~r/^Save/,
        opts: [kind: :button, trace: false, match_by: :title, nth: 2, min: 3]
      },
      %{
        id: "click_index_count_success",
        kind: :action,
        html: click_count_position_html(),
        op: :click,
        expected: ~r/^Save/,
        opts: [kind: :button, trace: false, match_by: :title, index: 2, max: 3]
      },
      %{
        id: "click_nth_out_of_bounds_failure",
        kind: :action,
        html: click_count_position_html(),
        op: :click,
        expected: ~r/^Save/,
        opts: [kind: :button, trace: true, match_by: :title, nth: 4]
      },
      %{
        id: "click_repeated_card_locator_success",
        kind: :action,
        html: repeated_card_action_html(),
        op: :click,
        expected: "Review",
        opts: [
          kind: :button,
          trace: false,
          locator:
            :button
            |> role(name: "Review", exact: false)
            |> filter(has: text("batch-orchid", exact: true))
            |> filter(has_not: text("duplicate-lure", exact: true))
        ]
      },
      %{
        id: "fill_in_success",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "Email",
        opts: [exact: true, trace: false]
      },
      %{
        id: "fill_in_placeholder_success",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "Email placeholder",
        opts: [match_by: :placeholder, exact: true, trace: false]
      },
      %{
        id: "fill_in_testid_success",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "ignored",
        opts: [trace: false, locator: testid("profile-email")]
      },
      %{
        id: "fill_in_failure_candidates",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "Phone",
        opts: [exact: true, trace: true]
      },
      %{
        id: "fill_in_or_unique_success",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "Email",
        opts: [trace: false, locator: or_(css("#profile_email"), css("#missing-field"))]
      },
      %{
        id: "fill_in_or_ambiguous_failure",
        kind: :action,
        html: form_html(),
        op: :fill_in,
        expected: "Email",
        opts: [trace: true, locator: or_(css("#profile_name"), css("#profile_email"))]
      },
      %{
        id: "fill_in_readonly_false_success",
        kind: :action,
        html: actionability_html(),
        op: :fill_in,
        expected: "Notes",
        opts: [trace: false, readonly: false]
      },
      %{
        id: "fill_in_readonly_true_success",
        kind: :action,
        html: actionability_html(),
        op: :fill_in,
        expected: "Notes",
        opts: [trace: false, readonly: true]
      },
      %{
        id: "fill_in_disabled_true_success",
        kind: :action,
        html: actionability_html(),
        op: :fill_in,
        expected: "Alias",
        opts: [trace: false, disabled: true]
      },
      %{
        id: "fill_in_first_count_success",
        kind: :action,
        html: fill_in_count_position_html(),
        op: :fill_in,
        expected: ~r/^Code/,
        opts: [trace: false, first: true, count: 3]
      },
      %{
        id: "fill_in_last_count_success",
        kind: :action,
        html: fill_in_count_position_html(),
        op: :fill_in,
        expected: ~r/^Code/,
        opts: [trace: false, last: true, between: {2, 3}]
      },
      %{
        id: "fill_in_nth_count_success",
        kind: :action,
        html: fill_in_count_position_html(),
        op: :fill_in,
        expected: ~r/^Code/,
        opts: [trace: false, nth: 2, min: 3]
      },
      %{
        id: "fill_in_index_count_success",
        kind: :action,
        html: fill_in_count_position_html(),
        op: :fill_in,
        expected: ~r/^Code/,
        opts: [trace: false, index: 2, max: 3]
      },
      %{
        id: "fill_in_nth_out_of_bounds_failure",
        kind: :action,
        html: fill_in_count_position_html(),
        op: :fill_in,
        expected: ~r/^Code/,
        opts: [trace: true, nth: 4]
      },
      %{
        id: "fill_in_wrapped_label_success",
        kind: :action,
        html: label_edge_html(),
        op: :fill_in,
        expected: "Search term *",
        opts: [trace: false, exact: true]
      },
      %{
        id: "fill_in_aria_labelledby_success",
        kind: :action,
        html: label_edge_html(),
        op: :fill_in,
        expected: "Search term labelledby",
        opts: [trace: false, exact: true]
      },
      %{
        id: "fill_in_multiple_labels_success",
        kind: :action,
        html: label_edge_html(),
        op: :fill_in,
        expected: "Secondary email",
        opts: [trace: false, exact: true]
      },
      %{
        id: "submit_locator_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [trace: false, locator: testid("submit-secondary-button")]
      },
      %{
        id: "submit_and_testid_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: and_(role(:button, name: "Run Search", exact: false), testid("submit-secondary-button"))
        ]
      },
      %{
        id: "submit_has_testid_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: :button |> role(name: "Run Search", exact: false) |> filter(has: testid("submit-secondary-marker"))
        ]
      },
      %{
        id: "submit_has_text_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: :button |> role(name: "Run Search", exact: false) |> filter(has: text("secondary", exact: true))
        ]
      },
      %{
        id: "submit_has_css_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: :button |> role(name: "Run Search", exact: false) |> filter(has: css(".kind-secondary"))
        ]
      },
      %{
        id: "submit_has_missing_failure",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: true,
          locator: :button |> role(name: "Run Search", exact: false) |> filter(has: testid("missing-marker"))
        ]
      },
      %{
        id: "submit_has_nested_or_ambiguous_failure",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: true,
          locator:
            :button
            |> role(name: "Run Search", exact: false)
            |> filter(has: or_(testid("submit-primary-marker"), testid("submit-secondary-marker")))
        ]
      },
      %{
        id: "submit_has_not_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: :button |> role(name: "Run Search", exact: false) |> filter(has_not: testid("submit-secondary-marker"))
        ]
      },
      %{
        id: "submit_has_not_failure",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [trace: true, locator: :button |> role(name: "Run Search", exact: false) |> filter(has_not: css("span"))]
      },
      %{
        id: "submit_and_not_success",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: false,
          locator: and_(role(:button, name: "Run Search", exact: false), not_(testid("submit-secondary-button")))
        ]
      },
      %{
        id: "submit_scope_chain_failure",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [
          trace: true,
          locator: :button |> role(name: "Run Search", exact: false) |> testid("submit-secondary-marker")
        ]
      },
      %{
        id: "submit_or_ambiguous_failure",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Run Search",
        opts: [trace: true, locator: or_(css("#submit-primary"), css("#submit-secondary"))]
      },
      %{
        id: "submit_failure_candidates",
        kind: :action,
        html: submit_html(),
        op: :submit,
        expected: "Missing submit",
        opts: [trace: true, exact: true]
      },
      %{
        id: "submit_first_count_success",
        kind: :action,
        html: submit_count_position_html(),
        op: :submit,
        expected: ~r/^Run/,
        opts: [trace: false, match_by: :title, first: true, count: 3]
      },
      %{
        id: "submit_last_count_success",
        kind: :action,
        html: submit_count_position_html(),
        op: :submit,
        expected: ~r/^Run/,
        opts: [trace: false, match_by: :title, last: true, between: {2, 3}]
      },
      %{
        id: "submit_nth_count_success",
        kind: :action,
        html: submit_count_position_html(),
        op: :submit,
        expected: ~r/^Run/,
        opts: [trace: false, match_by: :title, nth: 2, min: 3]
      },
      %{
        id: "submit_index_count_success",
        kind: :action,
        html: submit_count_position_html(),
        op: :submit,
        expected: ~r/^Run/,
        opts: [trace: false, match_by: :title, index: 2, max: 3]
      },
      %{
        id: "submit_nth_out_of_bounds_failure",
        kind: :action,
        html: submit_count_position_html(),
        op: :submit,
        expected: ~r/^Run/,
        opts: [trace: true, match_by: :title, nth: 4]
      }
    ]
  end

  @spec html_round(contract_case()) :: map()
  def html_round(%{kind: :assertion, html: html, locator: locator, opts: opts}) do
    html
    |> Html.parse!()
    |> Html.resolve_assertion_round(locator, true, Keyword.put_new(opts, :mode, :assert))
    |> normalize_round_result(%{kind: :assertion})
  end

  def html_round(%{kind: :action, html: html, op: op, expected: expected, opts: opts}) do
    html
    |> Html.parse!()
    |> Html.resolve_action_round(op, expected, opts)
    |> normalize_round_result(%{kind: :action, op: op})
  end

  @spec browser_input(contract_case()) :: map()
  def browser_input(%{kind: :assertion, html: html, locator: locator, opts: opts}) do
    payload =
      locator
      |> MatchRoundPayload.assertion(opts)
      |> contract_payload()
      |> Map.put(:trace, Keyword.get(opts, :trace, false))

    %{
      html: html,
      kind: "assertion",
      payload: payload,
      assertionScript: AssertionHelpers.preload_script(),
      actionScript: ActionHelpers.preload_script()
    }
  end

  def browser_input(%{kind: :action, html: html, op: op, expected: expected, opts: opts}) do
    payload =
      op
      |> MatchRoundPayload.action(expected, opts)
      |> contract_payload()
      |> Map.put(:trace, Keyword.get(opts, :trace, false))

    %{
      html: html,
      kind: "action",
      payload: payload,
      assertionScript: AssertionHelpers.preload_script(),
      actionScript: ActionHelpers.preload_script()
    }
  end

  @spec normalize_round_result(map(), %{kind: :assertion} | %{kind: :action, op: atom()}) :: map()
  def normalize_round_result(result, %{kind: :assertion}) when is_map(result) do
    %{
      ok: result[:ok] == true or result["ok"] == true,
      reason: result[:reason] || result["reason"] || "",
      match_count: result[:match_count] || result["match_count"] || result[:matchCount] || result["matchCount"] || 0,
      matched: normalize_values(result[:matched] || result["matched"] || []),
      candidate_values:
        normalize_values(
          result[:candidate_values] || result["candidate_values"] || result[:candidateValues] || result["candidateValues"] ||
            []
        )
    }
  end

  def normalize_round_result(result, %{kind: :action, op: op}) when is_map(result) do
    %{
      ok: result[:ok] == true or result["ok"] == true,
      reason: result[:reason] || result["reason"] || "",
      match_count: result[:match_count] || result["match_count"] || result[:matchCount] || result["matchCount"] || 0,
      matched: normalize_values(result[:matched] || result["matched"] || []),
      candidate_values:
        normalize_values(
          result[:candidate_values] || result["candidate_values"] || result[:candidateValues] || result["candidateValues"] ||
            []
        ),
      target_selector: normalize_selector(result, op),
      target_kind: normalize_target_kind(result, op)
    }
  end

  defp normalize_values(values) when is_list(values) do
    values
    |> Enum.map(&normalize_value/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.sort()
  end

  defp normalize_value(value) when is_binary(value) do
    value
    |> String.replace("\u00A0", " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp normalize_selector(_result, :submit), do: nil

  defp normalize_selector(result, _op) when is_map(result) do
    case result[:target_selector] || result["target_selector"] || result[:targetSelector] || result["targetSelector"] do
      selector when is_binary(selector) and selector != "" -> :present
      _other -> nil
    end
  end

  defp normalize_target_kind(result, :submit) when is_map(result) do
    if result[:ok] == true or result["ok"] == true, do: "submit"
  end

  defp normalize_target_kind(result, _op) when is_map(result) do
    result[:target_kind] || result["target_kind"] || result[:targetKind] || result["targetKind"]
  end

  defp contract_payload(payload) when is_map(payload) do
    case Map.pop(payload, :between) do
      {nil, nil} ->
        payload

      {between, rest} ->
        {between_min, between_max} = between_bounds(between)

        rest
        |> Map.put(:betweenMin, between_min)
        |> Map.put(:betweenMax, between_max)
    end
  end

  defp between_bounds({min, max}), do: {min, max}
  defp between_bounds(%Range{first: min, last: max}), do: {min, max}
  defp between_bounds(_other), do: {nil, nil}

  defp button_html do
    """
    <main>
      <button id="apply-primary" type="button" data-testid="apply-primary" title="Apply primary title">
        <span>Apply</span>
        <span data-testid="apply-primary-marker">primary</span>
      </button>
      <button id="apply-secondary" type="button" data-testid="apply-secondary" title="Apply secondary title">
        <span>Apply</span>
        <span data-testid="apply-secondary-marker">secondary</span>
      </button>
    </main>
    """
  end

  defp heading_html do
    """
    <main>
      <h1 aria-label="Search heading aria">Ignored visible heading</h1>
    </main>
    """
  end

  defp form_html do
    """
    <main>
      <form id="profile-form">
        <label for="profile_name">Name</label>
        <input id="profile_name" name="profile[name]" type="text" placeholder="Name placeholder" data-testid="profile-name" />

        <label for="profile_email">Email</label>
        <input
          id="profile_email"
          name="profile[email]"
          type="email"
          placeholder="Email placeholder"
          data-testid="profile-email"
        />
      </form>
    </main>
    """
  end

  defp submit_html do
    """
    <main>
      <form id="search-form">
        <button id="submit-primary" data-testid="submit-primary-button" type="submit">
          <span>Run Search</span>
          <span class="kind-primary" data-testid="submit-primary-marker">primary</span>
        </button>
        <button id="submit-secondary" data-testid="submit-secondary-button" type="submit">
          <span>Run Search</span>
          <span class="kind-secondary" data-testid="submit-secondary-marker">secondary</span>
        </button>
      </form>
    </main>
    """
  end

  defp count_html do
    """
    <main>
      <button title="Alpha primary">One</button>
      <button title="Alpha secondary">Two</button>
      <button title="Beta tertiary">Three</button>
    </main>
    """
  end

  defp closest_html do
    """
    <main>
      <section class="card">
        <h2>Queue Amber</h2>
        <p>slot-101</p>
      </section>
      <section class="card">
        <h2>Queue Cobalt</h2>
        <p>slot-120</p>
      </section>
    </main>
    """
  end

  defp benchmark_locator_html do
    """
    <main>
      <article data-card-kind="result" data-slot="120">
        <div class="assignment-panel-stack">
          <section data-panel-kind="assignment" data-panel-id="queue-cobalt">
            <header>
              <h4>Queue Cobalt</h4>
            </header>
            <p>batch-orchid</p>
            <p>west-lane</p>
          </section>
          <section data-panel-kind="assignment" data-panel-id="queue-amber">
            <header>
              <h4>Queue Amber</h4>
            </header>
            <p>batch-orchid</p>
            <p>duplicate-lure</p>
          </section>
        </div>
      </article>
    </main>
    """
  end

  defp actionability_html do
    """
    <main>
      <section>
        <button id="toggle-enabled" type="button">Toggle panel</button>
        <button id="toggle-disabled" type="button" disabled>Toggle panel</button>
      </section>

      <section>
        <button id="drawer-visible" type="button">Open drawer</button>
        <button id="drawer-hidden" type="button" hidden>Open drawer</button>
      </section>

      <form id="actionability-form">
        <label for="notes_editable">Notes</label>
        <textarea id="notes_editable" name="notes_editable"></textarea>

        <label for="notes_readonly">Notes</label>
        <textarea id="notes_readonly" name="notes_readonly" readonly>locked</textarea>

        <label for="alias_disabled">Alias</label>
        <input id="alias_disabled" name="alias_disabled" type="text" disabled />

        <div hidden>
          <label for="secret_code">Secret code</label>
          <input id="secret_code" name="secret_code" type="text" />
        </div>
      </form>
    </main>
    """
  end

  defp click_count_position_html do
    """
    <main>
      <section>
        <button id="save-first" type="button" title="Save first">Save</button>
        <button id="save-second" type="button" title="Save second">Save</button>
        <button id="save-third" type="button" title="Save third">Save</button>
      </section>
    </main>
    """
  end

  defp fill_in_count_position_html do
    """
    <main>
      <form id="code-form">
        <label for="code_1">Code one</label>
        <input id="code_1" name="codes[one]" type="text" value="" />

        <label for="code_2">Code two</label>
        <input id="code_2" name="codes[two]" type="text" value="" />

        <label for="code_3">Code three</label>
        <input id="code_3" name="codes[three]" type="text" value="" />
      </form>
    </main>
    """
  end

  defp submit_count_position_html do
    """
    <main>
      <form id="submit-form">
        <button id="run-first" type="submit" title="Run first">Run Search</button>
        <button id="run-second" type="submit" title="Run second">Run Search</button>
        <button id="run-third" type="submit" title="Run third">Run Search</button>
      </form>
    </main>
    """
  end

  defp label_edge_html do
    """
    <main>
      <form id="label-edge-form">
        <label>
          Search term <span class="required">*</span>
          <input id="wrapped_q" name="wrapped_q" type="text" value="" />
        </label>

        <span id="search-field-label">Search term labelledby</span>
        <input id="labelledby_q" name="labelledby_q" type="text" aria-labelledby="search-field-label" />

        <label for="multi_email">Primary email</label>
        <label for="multi_email">Secondary email</label>
        <input id="multi_email" name="multi_email" type="email" value="" />
      </form>
    </main>
    """
  end

  defp repeated_card_action_html do
    """
    <main>
      <article data-card-kind="result" data-slot="101">
        <button id="review-amber" type="button">
          <span>Review</span>
          <span>batch-orchid</span>
          <span>duplicate-lure</span>
        </button>
      </article>

      <article data-card-kind="result" data-slot="120">
        <button id="review-cobalt" type="button">
          <span>Review</span>
          <span>batch-orchid</span>
          <span>west-lane</span>
        </button>
      </article>
    </main>
    """
  end
end
