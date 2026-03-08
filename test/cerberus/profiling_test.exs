defmodule Cerberus.ProfilingTest do
  use ExUnit.Case, async: true

  import Cerberus
  import ExUnit.CaptureIO

  alias Cerberus.Profiling

  setup do
    Profiling.clear()
    Profiling.put_enabled_override(nil)

    on_exit(fn ->
      Profiling.clear()
      Profiling.put_enabled_override(nil)
    end)

    :ok
  end

  test "measure/2 records aggregated samples when profiling is enabled" do
    Profiling.put_enabled_override(true)

    Profiling.measure(:sample_bucket, fn -> Process.sleep(5) end)
    Profiling.measure(:sample_bucket, fn -> :ok end)

    assert [%{bucket: :sample_bucket, count: 2, total_us: total_us}] = Profiling.snapshot()
    assert total_us > 0
  end

  test "measure/2 does not record samples when profiling is disabled" do
    Profiling.put_enabled_override(false)
    Profiling.measure(:sample_bucket, fn -> :ok end)
    assert Profiling.snapshot() == []
  end

  test "driver operations publish profiling buckets" do
    Profiling.put_enabled_override(true)

    _session =
      session()
      |> visit("/search")
      |> click(role(:link, name: "Articles"))
      |> assert_has(text("Articles"))

    buckets = Enum.map(Profiling.snapshot(), & &1.bucket)

    assert {:driver_operation, :static, :visit} in buckets
    assert {:driver_operation, :static, :click} in buckets
    assert {:driver_operation, :static, :assert_has} in buckets
  end

  test "dump_summary/1 prints aggregated rows" do
    Profiling.put_enabled_override(true)

    Profiling.measure(:summary_bucket, fn -> :ok end)

    output =
      capture_io(fn ->
        assert :ok = Profiling.dump_summary(limit: 5)
      end)

    assert output =~ "Cerberus profiling summary"
    assert output =~ ":summary_bucket"
  end

  test "snapshot/1 can keep profiling rows separated by context" do
    Profiling.put_enabled_override(true)

    Profiling.with_context(:first_test, fn ->
      Profiling.measure(:sample_bucket, fn -> :ok end)
    end)

    Profiling.with_context(:second_test, fn ->
      Profiling.measure(:sample_bucket, fn -> :ok end)
    end)

    assert [
             %{context: :first_test, bucket: :sample_bucket, count: 1},
             %{context: :second_test, bucket: :sample_bucket, count: 1}
           ] = Enum.sort_by(Profiling.snapshot(group_by: :context_bucket), & &1.context)
  end
end
