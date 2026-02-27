defmodule Cerberus.HarnessTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.Harness

  test "run executes one scenario per tagged driver" do
    context = %{drivers: [:browser, :static, :live]}

    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "Articles")
      end)

    assert Enum.map(results, & &1.driver) == [:browser, :live, :static]
    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.all?(results, &(&1.operation == :assert_has))
  end

  test "run captures failures with common result shape" do
    context = %{drivers: [:static, :live]}

    results =
      Harness.run(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "DOES NOT EXIST")
      end)

    assert Enum.all?(results, &(&1.status == :error))
    assert Enum.all?(results, &is_binary(&1.message))
    assert Enum.all?(results, &match?(%ExUnit.AssertionError{}, &1.error))
  end

  test "run! raises one aggregated error when any driver fails" do
    context = %{drivers: [:static, :browser]}

    assert_raise ExUnit.AssertionError, ~r/driver conformance failures/, fn ->
      Harness.run!(context, fn session ->
        session
        |> visit("/articles")
        |> assert_has(text: "DOES NOT EXIST")
      end)
    end
  end

  test "run rejects drivers opt override and requires tag/context selection" do
    context = %{drivers: [:static]}

    assert_raise ArgumentError, ~r/no longer supports :drivers opt/, fn ->
      Harness.run(
        context,
        fn session ->
          session
          |> visit("/articles")
          |> assert_has(text: "Articles")
        end,
        drivers: [:browser]
      )
    end
  end

  test "sort_results sorts by operation and driver" do
    unsorted = [
      %{driver: :live, operation: :refute_has},
      %{driver: :browser, operation: :assert_has},
      %{driver: :static, operation: :assert_has}
    ]

    assert [
             %{driver: :browser, operation: :assert_has},
             %{driver: :static, operation: :assert_has},
             %{driver: :live, operation: :refute_has}
           ] = Harness.sort_results(unsorted)
  end
end
