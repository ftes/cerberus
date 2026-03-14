defmodule Cerberus.MatchRoundContractTest do
  use ExUnit.Case, async: true

  alias Cerberus.TestSupport.MatchRoundContract

  @expected_results %{
    "assert_css_text_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_css_text_failure_candidates" => %{
      ok: false,
      reason: "expected locator not found",
      match_count: 0,
      matched: [],
      candidate_values: ["Apply primary", "Apply secondary"]
    },
    "assert_role_heading_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_filter_has_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_filter_has_not_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_not_composition_failure" => %{
      ok: false,
      reason: "expected locator not found",
      match_count: 0,
      matched: [],
      candidate_values: []
    },
    "assert_or_ambiguous_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: [],
      candidate_values: []
    },
    "assert_count_failure_candidates" => %{
      ok: false,
      reason: "expected locator not found",
      match_count: 2,
      matched: ["Alpha primary", "Alpha secondary"],
      candidate_values: []
    },
    "assert_count_min_max_success" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: [],
      candidate_values: []
    },
    "assert_count_between_tuple_success" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: [],
      candidate_values: []
    },
    "assert_count_between_range_success" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: [],
      candidate_values: []
    },
    "assert_closest_from_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_benchmark_locator_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_refute_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: [],
      candidate_values: []
    },
    "assert_refute_count_failure_candidates" => %{
      ok: false,
      reason: "unexpected matching locator found",
      match_count: 2,
      matched: ["Alpha primary", "Alpha secondary"],
      candidate_values: []
    },
    "assert_submit_has_text_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_submit_has_css_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_submit_has_and_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: [],
      candidate_values: []
    },
    "assert_submit_has_missing_failure_candidates" => %{
      ok: false,
      reason: "expected locator not found",
      match_count: 0,
      matched: [],
      candidate_values: []
    },
    "assert_submit_has_not_failure_candidates" => %{
      ok: false,
      reason: "expected locator not found",
      match_count: 0,
      matched: [],
      candidate_values: []
    },
    "click_locator_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Apply secondary"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_locator_failure_candidates" => %{
      ok: false,
      reason: "no button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Apply primary", "Apply secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "click_second_duplicate_button" => %{
      ok: true,
      reason: "matched",
      match_count: 2,
      matched: ["Apply secondary"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_button_title_last_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Apply secondary title"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_has_testid_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Apply secondary"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_has_not_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Apply primary"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_has_missing_failure" => %{
      ok: false,
      reason: "no button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Apply primary", "Apply secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "click_or_ambiguous_failure" => %{
      ok: false,
      reason: "2 elements matched locator; narrow the locator or use :first, :last, :nth, or :index",
      match_count: 2,
      matched: [],
      candidate_values: ["Apply primary", "Apply secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "click_disabled_false_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Toggle panel"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_disabled_true_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Toggle panel"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_first_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Save first"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_last_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Save third"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_nth_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Save second"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_index_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Save third"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "click_nth_out_of_bounds_failure" => %{
      ok: false,
      reason: "nth=4 is out of bounds for 3 matched element(s)",
      match_count: 3,
      matched: [],
      candidate_values: ["Save first", "Save second", "Save third"],
      target_selector: nil,
      target_kind: nil
    },
    "click_repeated_card_locator_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Review batch-orchid west-lane"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "button"
    },
    "fill_in_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Email"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_placeholder_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Email"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_testid_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Email"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_failure_candidates" => %{
      ok: false,
      reason: "no form field matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Email", "Name"],
      target_selector: nil,
      target_kind: nil
    },
    "fill_in_or_unique_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Email"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_or_ambiguous_failure" => %{
      ok: false,
      reason: "2 elements matched locator; narrow the locator or use :first, :last, :nth, or :index",
      match_count: 2,
      matched: [],
      candidate_values: ["Email", "Name"],
      target_selector: nil,
      target_kind: nil
    },
    "fill_in_readonly_false_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Notes"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_readonly_true_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Notes"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_disabled_true_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Alias"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_first_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Code one"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_last_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Code three"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_nth_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Code two"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_index_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Code three"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_nth_out_of_bounds_failure" => %{
      ok: false,
      reason: "nth=4 is out of bounds for 3 matched element(s)",
      match_count: 3,
      matched: [],
      candidate_values: ["Code one", "Code three", "Code two"],
      target_selector: nil,
      target_kind: nil
    },
    "fill_in_wrapped_label_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Search term *"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_aria_labelledby_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Search term labelledby"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "fill_in_multiple_labels_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Secondary email"],
      candidate_values: [],
      target_selector: :present,
      target_kind: "field"
    },
    "submit_locator_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search secondary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_and_testid_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search secondary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_has_testid_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search secondary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_has_text_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search secondary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_has_css_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search secondary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_has_missing_failure" => %{
      ok: false,
      reason: "no submit button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_has_nested_or_ambiguous_failure" => %{
      ok: false,
      reason: "2 elements matched locator; narrow the locator or use :first, :last, :nth, or :index",
      match_count: 2,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_has_not_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search primary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_has_not_failure" => %{
      ok: false,
      reason: "no submit button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_and_not_success" => %{
      ok: true,
      reason: "matched",
      match_count: 1,
      matched: ["Run Search primary"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_scope_chain_failure" => %{
      ok: false,
      reason: "no submit button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_or_ambiguous_failure" => %{
      ok: false,
      reason: "2 elements matched locator; narrow the locator or use :first, :last, :nth, or :index",
      match_count: 2,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_failure_candidates" => %{
      ok: false,
      reason: "no submit button matched locator",
      match_count: 0,
      matched: [],
      candidate_values: ["Run Search primary", "Run Search secondary"],
      target_selector: nil,
      target_kind: nil
    },
    "submit_first_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Run first"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_last_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Run third"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_nth_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Run second"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_index_count_success" => %{
      ok: true,
      reason: "matched",
      match_count: 3,
      matched: ["Run third"],
      candidate_values: [],
      target_selector: nil,
      target_kind: "submit"
    },
    "submit_nth_out_of_bounds_failure" => %{
      ok: false,
      reason: "nth=4 is out of bounds for 3 matched element(s)",
      match_count: 3,
      matched: [],
      candidate_values: ["Run first", "Run second", "Run third"],
      target_selector: nil,
      target_kind: nil
    }
  }

  test "html one-round assertion and action cases produce stable normalized results" do
    results =
      Map.new(MatchRoundContract.cases(), fn contract_case ->
        {contract_case.id, MatchRoundContract.html_round(contract_case)}
      end)

    assert results |> Map.keys() |> Enum.sort() == @expected_results |> Map.keys() |> Enum.sort()
    assert results == @expected_results
  end

  test "node jsdom one-round assertion and action cases match html results" do
    html_results =
      Map.new(MatchRoundContract.cases(), fn contract_case ->
        {contract_case.id, MatchRoundContract.html_round(contract_case)}
      end)

    browser_results =
      Map.new(MatchRoundContract.cases(), fn contract_case ->
        {contract_case.id, MatchRoundContract.browser_round(contract_case)}
      end)

    assert browser_results == html_results
  end
end
