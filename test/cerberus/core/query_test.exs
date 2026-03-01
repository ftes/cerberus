defmodule Cerberus.QueryTest do
  use ExUnit.Case, async: true

  alias Cerberus.Query

  test "pick_match applies count and position filters" do
    matches = [:one, :two, :three]

    assert {:ok, :one} = Query.pick_match(matches, [])
    assert {:ok, :one} = Query.pick_match(matches, count: 3, first: true)
    assert {:ok, :three} = Query.pick_match(matches, last: true, min: 2)
    assert {:ok, :two} = Query.pick_match(matches, nth: 2, between: {2, 4})
    assert {:ok, :three} = Query.pick_match(matches, index: 2, max: 3)

    assert {:error, _reason} = Query.pick_match(matches, count: 2)
    assert {:error, _reason} = Query.pick_match(matches, nth: 4)
  end

  test "assertion_count_outcome supports default and constrained semantics" do
    assert :ok = Query.assertion_count_outcome(1, [], :assert)
    assert {:error, "expected text not found"} = Query.assertion_count_outcome(0, [], :assert)
    assert :ok = Query.assertion_count_outcome(0, [], :refute)
    assert {:error, "unexpected matching text found"} = Query.assertion_count_outcome(1, [], :refute)

    assert :ok = Query.assertion_count_outcome(2, [count: 2], :assert)
    assert {:error, _reason} = Query.assertion_count_outcome(1, [count: 2], :assert)
    assert :ok = Query.assertion_count_outcome(1, [count: 2], :refute)
    assert {:error, _reason} = Query.assertion_count_outcome(2, [count: 2], :refute)
  end
end
