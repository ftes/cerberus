defmodule Cerberus.TestSupport.PlaywrightPerformanceBenchmark do
  @moduledoc false

  import Cerberus

  @flow_path "/phoenix_test/playwright/live/performance"
  @done_path "/phoenix_test/playwright/live/performance/done"
  @candidate_query "wiz"
  @candidate_name "Wizard Prime"
  @candidate_score "score 98"
  @candidate_id "wizard-prime"
  @target_slot "slot-120"
  @target_status "status-ready"
  @target_marker "priority-prime"

  @spec flow_path() :: String.t()
  def flow_path, do: @flow_path

  @spec done_path() :: String.t()
  def done_path, do: @done_path

  @spec candidate_query() :: String.t()
  def candidate_query, do: @candidate_query

  @spec candidate_id() :: String.t()
  def candidate_id, do: @candidate_id

  @spec run_cerberus_flow(Cerberus.Session.t()) :: Cerberus.Session.t()
  def run_cerberus_flow(session) do
    candidate_dialog = css("[role='dialog'][aria-label='Candidate search']")
    review_dialog = css("[role='dialog'][aria-label='Review candidate']")
    candidate_option = candidate_option_locator()
    target_card = target_card_locator()

    session
    |> visit(@flow_path)
    |> assert_has(role(:heading, name: "Performance LiveView", exact: true))
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
    |> assert_path(@flow_path, query: %{step: "patched", candidate: @candidate_id})
    |> click(role(:button, name: "Continue workflow", exact: true))
    |> assert_path(@done_path, query: %{candidate: @candidate_id})
    |> assert_has(role(:heading, name: "Performance flow complete", exact: true))
  end

  defp candidate_option_locator do
    "[data-testid='candidate-option']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@candidate_score, exact: true))
  end

  defp target_card_locator do
    "article[data-card-kind='result']"
    |> css()
    |> filter(has: text(@candidate_name, exact: true))
    |> filter(has: text(@target_status, exact: true))
    |> filter(has: text(@target_slot, exact: true))
    |> filter(has: text(@target_marker, exact: true))
  end
end
