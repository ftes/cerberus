defmodule Cerberus.Bench.PhoenixTestPerformanceBenchmark do
  @moduledoc false

  import PhoenixTest

  alias Cerberus.TestSupport.BenchmarkStepTrace
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

  @spec run_flow(Plug.Conn.t(), scenario(), keyword()) :: term()
  def run_flow(conn, scenario \\ :churn, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, 5_000)
    trace = step_trace_context(opts)

    conn
    |> trace_step(trace, :build_session, &PhoenixTest.put_endpoint(&1, @endpoint))
    |> trace_step(trace, :visit_flow, &visit(&1, flow_path_for(scenario)))
    |> trace_step(trace, :assert_page_ready, fn session ->
      session
      |> assert_has("h1", text: "Performance LiveView")
      |> assert_has("[data-testid='benchmark-scenario']", text: "Scenario: #{scenario_name(scenario)}")
    end)
    |> trace_step(trace, :open_candidate_search, fn session ->
      session
      |> click_button("Open candidate search")
      |> assert_has("#candidate-modal", timeout: timeout_ms)
    end)
    |> trace_step(trace, :search_candidate, fn session ->
      within(session, "#candidate-modal", fn nested_session ->
        nested_session
        |> fill_in("Candidate search", with: @candidate_query)
        |> assert_has("[data-testid='candidate-option'][data-candidate-id='#{@candidate_id}']",
          timeout: timeout_ms
        )
      end)
    end)
    |> trace_step(trace, :choose_candidate, fn session ->
      session
      |> within("#candidate-modal", &click_button(&1, candidate_choose_button_selector(), "Choose"))
      |> assert_has("[data-testid='selected-candidate']",
        text: "Selected candidate: #{@candidate_name}",
        timeout: timeout_ms
      )
    end)
    |> continue_flow(scenario, timeout_ms, trace)
  end

  defp continue_flow(session, scenario, timeout_ms, trace) when scenario in [:churn, :churn_no_delay] do
    query_scenario = if scenario == :churn_no_delay, do: "churn_no_delay", else: "churn"

    session
    |> trace_step(trace, :load_heavy_results, &click_button(&1, "Load heavy results"))
    |> trace_step(
      trace,
      :assert_target_card,
      &assert_has(&1, target_card_selector(), text: @candidate_name, timeout: timeout_ms)
    )
    |> trace_step(trace, :open_review_modal, fn current_session ->
      current_session
      |> click_button(review_button_selector(), "Review")
      |> assert_has("#review-modal", timeout: timeout_ms)
      |> assert_has("#review-modal", text: @candidate_name, timeout: timeout_ms)
    end)
    |> trace_step(
      trace,
      :apply_filters,
      &within(&1, "#review-modal", fn nested_session -> click_button(nested_session, "Apply filters") end)
    )
    |> trace_step(trace, :await_patched_state, fn current_session ->
      current_session
      |> assert_has("[data-testid='flow-step']", text: "Step: patched", timeout: timeout_ms)
      |> maybe_await_live_patch(scenario, timeout_ms, query_scenario)
    end)
    |> trace_step(trace, :continue_workflow, &click_button(&1, "Continue workflow"))
    |> trace_step(trace, :await_done_state, &assert_has(&1, "h1", text: "Performance flow complete", timeout: timeout_ms))
    |> trace_step(trace, :final_assertions, fn current_session ->
      current_session
      |> assert_path(@done_path)
      |> assert_has("[data-testid='done-proof']", text: "Flow proof: #{@churn_flow_proof}")
      |> assert_has("[data-testid='done-event-count']", text: "Flow events: 7")
    end)
  end

  defp continue_flow(session, :locator_stress, timeout_ms, trace) do
    session
    |> trace_step(trace, :load_heavy_results, &click_button(&1, "Load heavy results"))
    |> trace_step(
      trace,
      :assert_target_card,
      &assert_has(&1, target_card_selector(), text: @candidate_name, timeout: timeout_ms)
    )
    |> trace_step(
      trace,
      :assert_assignment_panel,
      &assert_has(&1, target_assignment_panel_selector(), text: @assignment_name, timeout: timeout_ms)
    )
    |> trace_step(trace, :open_assignment_modal, fn current_session ->
      current_session
      |> click_button(assignment_panel_button_selector(), "Inspect queue")
      |> assert_has("#assignment-modal", timeout: timeout_ms)
    end)
    |> trace_step(trace, :assert_assignment_row, fn current_session ->
      assert_has(current_session, "[data-testid='assignment-row'][data-assignment-id='#{@assignment_id}']",
        timeout: timeout_ms
      )
    end)
    |> trace_step(trace, :choose_assignment, fn current_session ->
      current_session
      |> click_button(assignment_row_button_selector(), "Select")
      |> assert_has("[data-testid='selected-assignment']",
        text: "Selected assignment: #{@assignment_name}",
        timeout: timeout_ms
      )
    end)
    |> trace_step(trace, :apply_filters, &click_button(&1, "Apply locator filters"))
    |> trace_step(trace, :await_patched_state, fn current_session ->
      current_session
      |> assert_has("[data-testid='flow-step']", text: "Step: patched", timeout: timeout_ms)
      |> await_live_patch(timeout_ms, @locator_stress_scenario)
    end)
    |> trace_step(trace, :continue_workflow, &click_button(&1, "Continue workflow"))
    |> trace_step(trace, :await_done_state, &assert_has(&1, "h1", text: "Performance flow complete", timeout: timeout_ms))
    |> trace_step(trace, :final_assertions, fn current_session ->
      current_session
      |> assert_path(@done_path)
      |> assert_has("[data-testid='done-assignment']", text: "Assignment carried forward: #{@assignment_id}")
      |> assert_has("[data-testid='done-proof']", text: "Flow proof: #{@locator_stress_flow_proof}")
      |> assert_has("[data-testid='done-event-count']", text: "Flow events: 8")
    end)
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

  defp maybe_await_live_patch(session, :churn_no_delay, _timeout_ms, _scenario), do: session

  defp maybe_await_live_patch(session, _scenario, timeout_ms, scenario_name),
    do: await_live_patch(session, timeout_ms, scenario_name)

  defp step_trace_context(opts) do
    BenchmarkStepTrace.build_context(Keyword.get(opts, :step_trace_metadata), opts)
  end

  defp trace_step(subject, trace, step, fun) do
    BenchmarkStepTrace.step(subject, trace, step, fun)
  end
end
