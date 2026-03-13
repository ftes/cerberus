defmodule Cerberus.PhoenixTestPerformanceBenchmarkSupportTest do
  use ExUnit.Case, async: true

  alias Cerberus.TestSupport.PhoenixTestPerformanceBenchmark

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "real PhoenixTest benchmark flow completes for churn", %{conn: conn} do
    _session = PhoenixTestPerformanceBenchmark.run_flow(conn, :churn, timeout_ms: 20_000)
  end

  test "real PhoenixTest benchmark flow completes for locator stress", %{conn: conn} do
    _session = PhoenixTestPerformanceBenchmark.run_flow(conn, :locator_stress, timeout_ms: 20_000)
  end
end
