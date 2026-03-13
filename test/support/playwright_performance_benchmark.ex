defmodule Cerberus.TestSupport.PlaywrightPerformanceBenchmark do
  @moduledoc false

  import Cerberus

  @type scenario :: :churn | :locator_stress

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

  @spec flow_path() :: String.t()
  def flow_path, do: @flow_path

  @spec done_path() :: String.t()
  def done_path, do: @done_path

  @spec candidate_query() :: String.t()
  def candidate_query, do: @candidate_query

  @spec candidate_id() :: String.t()
  def candidate_id, do: @candidate_id

  @spec run_cerberus_flow(Cerberus.Session.t(), scenario()) :: Cerberus.Session.t()
  def run_cerberus_flow(session, scenario \\ :churn) do
    candidate_dialog = css("[role='dialog'][aria-label='Candidate search']")
    review_dialog = css("[role='dialog'][aria-label='Review candidate']")
    candidate_option = candidate_option_locator()
    target_card = target_card_locator(scenario)

    session
    |> visit(flow_path_for(scenario))
    |> assert_has(role(:heading, name: "Performance LiveView", exact: true))
    |> assert_has(text("Scenario: #{scenario_name(scenario)}", exact: true))
    |> click(role(:button, name: "Open candidate search", exact: true))
    |> assert_has(candidate_dialog, timeout: 5_000)
    |> within(candidate_dialog, fn dialog ->
      dialog
      |> fill_in(label("Candidate search", exact: true), @candidate_query)
      |> assert_has(candidate_option, timeout: 5_000)
      |> within(candidate_option, fn option ->
        click(option, role(:button, name: "Choose", exact: true))
      end)
    end)
    |> assert_has(text("Selected candidate: #{@candidate_name}", exact: true), timeout: 5_000)
    |> continue_flow(scenario, target_card, review_dialog)
  end

  defp continue_flow(session, :churn, target_card, review_dialog) do
    session
    |> click(role(:button, name: "Load heavy results", exact: true))
    |> assert_has(target_card, timeout: 5_000)
    |> within(target_card, fn card ->
      click(card, role(:button, name: "Review", exact: true))
    end)
    |> assert_has(review_dialog, timeout: 5_000)
    |> within(review_dialog, fn dialog ->
      dialog
      |> assert_has(text(@candidate_name, exact: true))
      |> click(role(:button, name: "Apply filters", exact: true))
    end)
    |> assert_path(@flow_path, query: %{step: "patched", candidate: @candidate_id, scenario: "churn"})
    |> click(role(:button, name: "Continue workflow", exact: true))
    |> assert_path(@done_path, query: %{candidate: @candidate_id})
    |> assert_has(role(:heading, name: "Performance flow complete", exact: true))
  end

  defp continue_flow(session, :locator_stress, target_card, _review_dialog) do
    assignment_panel = assignment_panel_locator()
    assignment_dialog = css("[role='dialog'][aria-label='Assignment queue']")
    assignment_row = assignment_row_locator()

    session
    |> click(role(:button, name: "Load heavy results", exact: true))
    |> assert_has(target_card, timeout: 5_000)
    |> within(target_card, fn card ->
      card
      |> assert_has(assignment_panel, timeout: 5_000)
      |> within(assignment_panel, fn panel ->
        click(panel, role(:button, name: "Inspect queue", exact: true))
      end)
    end)
    |> assert_has(assignment_dialog, timeout: 5_000)
    |> within(assignment_dialog, fn dialog ->
      dialog
      |> assert_has(assignment_row, timeout: 5_000)
      |> within(assignment_row, fn row ->
        click(row, role(:button, name: "Select", exact: true))
      end)
    end)
    |> assert_has(text("Selected assignment: #{@assignment_name}", exact: true), timeout: 5_000)
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
  end

  defp flow_path_for(:churn), do: @flow_path
  defp flow_path_for(:locator_stress), do: "#{@flow_path}?scenario=#{@locator_stress_scenario}"

  defp scenario_name(:churn), do: "churn"
  defp scenario_name(:locator_stress), do: @locator_stress_scenario

  defp candidate_option_locator do
    "[data-testid='candidate-option']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@candidate_score, exact: true))
  end

  defp target_card_locator(:churn) do
    "article[data-card-kind='result'][data-slot='120']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@target_status, exact: true))
    |> filter(has: text(@target_marker, exact: true))
  end

  defp target_card_locator(:locator_stress) do
    "article[data-card-kind='result'][data-slot='120']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@target_status, exact: true))
    |> filter(has: text(@target_marker, exact: true))
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
end
