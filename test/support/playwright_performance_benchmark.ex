defmodule Cerberus.TestSupport.PlaywrightPerformanceBenchmark do
  @moduledoc false

  import Cerberus

  @type scenario :: :churn | :churn_no_delay | :locator_stress

  @flow_path "/phoenix_test/playwright/live/performance"
  @done_path "/phoenix_test/playwright/live/performance/done"
  @locator_stress_scenario "locator_stress"
  @candidate_query "wiz"
  @candidate_name "Wizard Prime"
  @candidate_score "score 98"
  @candidate_id "wizard-prime"
  @target_status "status-ready"
  @target_marker "priority-prime"
  @assignment_name "Queue Cobalt"
  @assignment_id "queue-cobalt"
  @assignment_region "region-central"
  @assignment_lane "lane-27"
  @assignment_window "window-3"
  @assignment_skill "skill-runes"
  @assignment_batch "batch-orchid"
  @assignment_owner "owner-wizard-prime"
  @churn_flow_proof "candidate-modal-opened>candidate-results-loaded>candidate-chosen>results-loaded>review-opened>filters-patched>done-navigated"
  @locator_stress_flow_proof "candidate-modal-opened>candidate-results-loaded>candidate-chosen>results-loaded>assignment-modal-opened>assignment-chosen>filters-patched>done-navigated"

  @spec flow_path() :: String.t()
  def flow_path, do: @flow_path

  @spec done_path() :: String.t()
  def done_path, do: @done_path

  @spec candidate_query() :: String.t()
  def candidate_query, do: @candidate_query

  @spec candidate_id() :: String.t()
  def candidate_id, do: @candidate_id

  @spec run_assignment_modal_probe(Cerberus.Session.t(), keyword()) :: Cerberus.Session.t()
  def run_assignment_modal_probe(session, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)
    assignment_panel = assignment_panel_locator()
    assignment_dialog = css("[role='dialog'][aria-label='Assignment queue']")
    assignment_row = assignment_row_locator()

    session
    |> run_candidate_selection(:locator_stress, timeout_ms)
    |> click(role(:button, name: "Load heavy results", exact: true))
    |> assert_has(target_card_locator(:locator_stress), timeout: timeout_ms)
    |> assert_has(assignment_panel, timeout: timeout_ms)
    |> click(assignment_panel_button_locator())
    |> assert_has(assignment_dialog, timeout: timeout_ms)
    |> assert_has(assignment_row, timeout: timeout_ms)
    |> click(assignment_row_button_locator())
    |> assert_has(text("Selected assignment: #{@assignment_name}", exact: true), timeout: timeout_ms)
  end

  @spec run_cerberus_flow(Cerberus.Session.t(), scenario(), keyword()) :: Cerberus.Session.t()
  def run_cerberus_flow(session, scenario \\ :churn, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)

    session
    |> run_candidate_selection(scenario, timeout_ms)
    |> continue_flow(
      scenario,
      target_card_locator(scenario),
      css("[role='dialog'][aria-label='Review candidate']"),
      timeout_ms
    )
  end

  defp run_candidate_selection(session, scenario, timeout_ms) do
    candidate_dialog = css("[role='dialog'][aria-label='Candidate search']")
    candidate_option = candidate_option_locator()

    session
    |> visit(flow_path_for(scenario))
    |> assert_has(role(:heading, name: "Performance LiveView", exact: true))
    |> assert_has(text("Scenario: #{scenario_name(scenario)}", exact: true))
    |> click(role(:button, name: "Open candidate search", exact: true))
    |> assert_has(candidate_dialog, timeout: timeout_ms)
    |> fill_in(label("Candidate search", exact: true), @candidate_query)
    |> assert_has(candidate_option, timeout: timeout_ms)
    |> click(candidate_choose_button_locator())
    |> assert_has(text("Selected candidate: #{@candidate_name}", exact: true), timeout: timeout_ms)
  end

  defp continue_flow(session, scenario, target_card, review_dialog, timeout_ms)
       when scenario in [:churn, :churn_no_delay] do
    query_scenario = if scenario == :churn_no_delay, do: "churn_no_delay", else: "churn"

    session
    |> click(role(:button, name: "Load heavy results", exact: true))
    |> assert_has(target_card, timeout: timeout_ms)
    |> click(review_card_button_locator())
    |> assert_has(review_dialog, timeout: timeout_ms)
    |> assert_has(text(@candidate_name, exact: true))
    |> click(review_apply_filters_button_locator())
    |> assert_path(@flow_path, query: %{step: "patched", candidate: @candidate_id, scenario: query_scenario})
    |> click(role(:button, name: "Continue workflow", exact: true))
    |> assert_path(@done_path, query: %{candidate: @candidate_id})
    |> assert_has(role(:heading, name: "Performance flow complete", exact: true))
    |> assert_has(text("Flow proof: #{@churn_flow_proof}", exact: true))
    |> assert_has(text("Flow events: 7", exact: true))
  end

  defp continue_flow(session, :locator_stress, target_card, _review_dialog, timeout_ms) do
    assignment_panel = assignment_panel_locator()
    assignment_dialog = css("[role='dialog'][aria-label='Assignment queue']")
    assignment_row = assignment_row_locator()

    session
    |> click(role(:button, name: "Load heavy results", exact: true))
    |> assert_has(target_card, timeout: timeout_ms)
    |> assert_has(assignment_panel, timeout: timeout_ms)
    |> click(assignment_panel_button_locator())
    |> assert_has(assignment_dialog, timeout: timeout_ms)
    |> assert_has(assignment_row, timeout: timeout_ms)
    |> click(assignment_row_button_locator())
    |> assert_has(text("Selected assignment: #{@assignment_name}", exact: true), timeout: timeout_ms)
    |> click(role(:button, name: "Apply locator filters", exact: true))
    |> assert_path(@flow_path,
      query: %{
        step: "patched",
        candidate: @candidate_id,
        scenario: @locator_stress_scenario,
        assignment: @assignment_id
      }
    )
    |> click(role(:button, name: "Continue workflow", exact: true))
    |> assert_path(@done_path, query: %{candidate: @candidate_id, assignment: @assignment_id})
    |> assert_has(role(:heading, name: "Performance flow complete", exact: true))
    |> assert_has(text("Assignment carried forward: #{@assignment_id}", exact: true))
    |> assert_has(text("Flow proof: #{@locator_stress_flow_proof}", exact: true))
    |> assert_has(text("Flow events: 8", exact: true))
  end

  defp flow_path_for(:churn), do: @flow_path
  defp flow_path_for(:churn_no_delay), do: "#{@flow_path}?scenario=churn_no_delay"
  defp flow_path_for(:locator_stress), do: "#{@flow_path}?scenario=#{@locator_stress_scenario}"

  defp scenario_name(:churn), do: "churn"
  defp scenario_name(:churn_no_delay), do: "churn_no_delay"
  defp scenario_name(:locator_stress), do: @locator_stress_scenario

  defp candidate_option_locator do
    "[data-testid='candidate-option']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@candidate_score, exact: true))
  end

  defp candidate_choose_button_locator do
    css(
      "[data-testid='candidate-option'][data-candidate-id='#{@candidate_id}'] button[phx-click='choose-candidate'][phx-value-id='#{@candidate_id}']"
    )
  end

  defp target_card_locator(:churn) do
    "article[data-card-kind='result'][data-slot='120']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@target_status, exact: true))
    |> filter(has: text(@target_marker, exact: true))
  end

  defp target_card_locator(:churn_no_delay), do: target_card_locator(:churn)

  defp target_card_locator(:locator_stress) do
    "article[data-card-kind='result'][data-slot='120']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@target_status, exact: true))
    |> filter(has: text(@target_marker, exact: true))
  end

  defp review_card_button_locator do
    css("article[data-card-kind='result'][data-slot='120'] button[phx-click='review-card'][phx-value-slot='120']")
  end

  defp review_apply_filters_button_locator do
    css("#review-modal button[phx-click='apply-filters']")
  end

  defp assignment_panel_locator do
    "section[data-panel-kind='assignment']"
    |> css()
    |> filter(has: text(@assignment_name, exact: true))
    |> filter(has: text(@assignment_region, exact: true))
    |> filter(has: text(@assignment_lane, exact: true))
    |> filter(has: text(@assignment_window, exact: true))
    |> filter(has: text(@assignment_skill, exact: true))
    |> filter(has: text(@assignment_batch, exact: true))
    |> filter(has_not: text("duplicate-lure", exact: true))
  end

  defp assignment_panel_button_locator do
    css(
      "article[data-card-kind='result'][data-slot='120'] section[data-panel-kind='assignment'][data-panel-id='assignment-target'] button[phx-click='open-assignment-modal'][phx-value-slot='120'][phx-value-panel='assignment-target']"
    )
  end

  defp assignment_row_locator do
    "[data-testid='assignment-row']"
    |> css()
    |> filter(has: text(@assignment_name, exact: true))
    |> filter(has: text("state-ready", exact: true))
    |> filter(has: text(@assignment_region, exact: true))
    |> filter(has: text(@assignment_window, exact: true))
    |> filter(has: text(@assignment_skill, exact: true))
    |> filter(has: text(@assignment_owner, exact: true))
    |> filter(has_not: text("secondary-marker", exact: true))
  end

  defp assignment_row_button_locator do
    css(
      "[data-testid='assignment-row'][data-assignment-id='#{@assignment_id}'] button[phx-click='choose-assignment'][phx-value-id='#{@assignment_id}']"
    )
  end
end
