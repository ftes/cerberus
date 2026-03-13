defmodule Cerberus.TestSupport.PhoenixTestPerformanceBenchmark do
  @moduledoc false

  import PhoenixTest

  alias Cerberus.TestSupport.PlaywrightPerformanceBenchmark

  @type scenario :: :churn | :churn_no_delay | :locator_stress

  @endpoint Cerberus.Fixtures.Endpoint
  @flow_path PlaywrightPerformanceBenchmark.flow_path()
  @done_path PlaywrightPerformanceBenchmark.done_path()
  @locator_stress_scenario "locator_stress"
  @candidate_query "wiz"
  @candidate_name "Wizard Prime"
  @candidate_id "wizard-prime"
  @assignment_name "Queue Cobalt"
  @assignment_id "queue-cobalt"
  @churn_flow_proof "candidate-modal-opened>candidate-results-loaded>candidate-chosen>results-loaded>review-opened>filters-patched>done-navigated"
  @locator_stress_flow_proof "candidate-modal-opened>candidate-results-loaded>candidate-chosen>results-loaded>assignment-modal-opened>assignment-chosen>filters-patched>done-navigated"

  @spec run_flow(Plug.Conn.t(), scenario(), keyword()) :: PhoenixTest.Live.t() | PhoenixTest.Static.t()
  def run_flow(conn, scenario \\ :churn, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)

    conn
    |> PhoenixTest.put_endpoint(@endpoint)
    |> visit(flow_path_for(scenario))
    |> assert_has("h1", text: "Performance LiveView")
    |> assert_has("[data-testid='benchmark-scenario']", text: "Scenario: #{scenario_name(scenario)}")
    |> click_button("Open candidate search")
    |> assert_has("#candidate-modal", timeout: timeout_ms)
    |> within("#candidate-modal", fn session ->
      session
      |> fill_in("Candidate search", with: @candidate_query)
      |> assert_has("[data-testid='candidate-option'][data-candidate-id='#{@candidate_id}']", timeout: timeout_ms)
      |> click_button(candidate_choose_button_selector(), "Choose")
    end)
    |> assert_has("[data-testid='selected-candidate']",
      text: "Selected candidate: #{@candidate_name}",
      timeout: timeout_ms
    )
    |> continue_flow(scenario, timeout_ms)
  end

  defp continue_flow(session, scenario, timeout_ms) when scenario in [:churn, :churn_no_delay] do
    query_scenario = if scenario == :churn_no_delay, do: "churn_no_delay", else: "churn"

    session
    |> click_button("Load heavy results")
    |> assert_has(target_card_selector(), text: @candidate_name, timeout: timeout_ms)
    |> click_button(review_button_selector(), "Review")
    |> assert_has("#review-modal", timeout: timeout_ms)
    |> assert_has("#review-modal", text: @candidate_name, timeout: timeout_ms)
    |> within("#review-modal", &click_button(&1, "Apply filters"))
    |> assert_has("[data-testid='flow-step']", text: "Step: patched", timeout: timeout_ms)
    |> await_live_patch(timeout_ms, query_scenario)
    |> click_button("Continue workflow")
    |> assert_has("h1", text: "Performance flow complete", timeout: timeout_ms)
    |> assert_path(@done_path)
    |> assert_has("[data-testid='done-proof']", text: "Flow proof: #{@churn_flow_proof}")
    |> assert_has("[data-testid='done-event-count']", text: "Flow events: 7")
  end

  defp continue_flow(session, :locator_stress, timeout_ms) do
    session
    |> click_button("Load heavy results")
    |> assert_has(target_card_selector(), text: @candidate_name, timeout: timeout_ms)
    |> assert_has(target_assignment_panel_selector(), text: @assignment_name, timeout: timeout_ms)
    |> click_button(assignment_panel_button_selector(), "Inspect queue")
    |> assert_has("#assignment-modal", timeout: timeout_ms)
    |> assert_has("[data-testid='assignment-row'][data-assignment-id='#{@assignment_id}']", timeout: timeout_ms)
    |> click_button(assignment_row_button_selector(), "Select")
    |> assert_has("[data-testid='selected-assignment']",
      text: "Selected assignment: #{@assignment_name}",
      timeout: timeout_ms
    )
    |> click_button("Apply locator filters")
    |> assert_has("[data-testid='flow-step']", text: "Step: patched", timeout: timeout_ms)
    |> await_live_patch(timeout_ms, @locator_stress_scenario)
    |> click_button("Continue workflow")
    |> assert_has("h1", text: "Performance flow complete", timeout: timeout_ms)
    |> assert_path(@done_path)
    |> assert_has("[data-testid='done-assignment']", text: "Assignment carried forward: #{@assignment_id}")
    |> assert_has("[data-testid='done-proof']", text: "Flow proof: #{@locator_stress_flow_proof}")
    |> assert_has("[data-testid='done-event-count']", text: "Flow events: 8")
  end

  defp flow_path_for(:churn), do: @flow_path
  defp flow_path_for(:churn_no_delay), do: "#{@flow_path}?scenario=churn_no_delay"
  defp flow_path_for(:locator_stress), do: "#{@flow_path}?scenario=#{@locator_stress_scenario}"

  defp scenario_name(:churn), do: "churn"
  defp scenario_name(:churn_no_delay), do: "churn_no_delay"
  defp scenario_name(:locator_stress), do: @locator_stress_scenario

  defp target_card_selector, do: "article[data-card-kind='result'][data-slot='120']"

  defp candidate_choose_button_selector do
    "[data-testid='candidate-option'][data-candidate-id='#{@candidate_id}'] button[phx-click='choose-candidate'][phx-value-id='#{@candidate_id}']"
  end

  defp review_button_selector do
    "article[data-card-kind='result'][data-slot='120'] button[phx-click='review-card'][phx-value-slot='120']"
  end

  defp target_assignment_panel_selector do
    "article[data-card-kind='result'][data-slot='120'] section[data-panel-kind='assignment'][data-panel-id='assignment-target']"
  end

  defp assignment_panel_button_selector do
    "article[data-card-kind='result'][data-slot='120'] section[data-panel-kind='assignment'][data-panel-id='assignment-target'] button[phx-click='open-assignment-modal'][phx-value-slot='120'][phx-value-panel='assignment-target']"
  end

  defp assignment_row_button_selector do
    "[data-testid='assignment-row'][data-assignment-id='#{@assignment_id}'] button[phx-click='choose-assignment'][phx-value-id='#{@assignment_id}']"
  end

  defp await_live_patch(session, timeout_ms, scenario) do
    session
    |> unwrap(fn view ->
      _ = Phoenix.LiveViewTest.assert_patch(view, timeout_ms)
      Phoenix.LiveViewTest.render(view)
    end)
    |> assert_has("[data-testid='benchmark-scenario']", text: "Scenario: #{scenario}", timeout: timeout_ms)
  end
end
