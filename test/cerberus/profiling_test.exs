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

  @tag :tmp_dir
  test "dump_reports/1 writes snapshot artifacts when output dir env is set", %{tmp_dir: tmp_dir} do
    Profiling.put_enabled_override(true)
    previous_output_dir = System.get_env("CERBERUS_PROFILE_OUTPUT_DIR")
    System.put_env("CERBERUS_PROFILE_OUTPUT_DIR", tmp_dir)

    on_exit(fn ->
      if previous_output_dir do
        System.put_env("CERBERUS_PROFILE_OUTPUT_DIR", previous_output_dir)
      else
        System.delete_env("CERBERUS_PROFILE_OUTPUT_DIR")
      end
    end)

    Profiling.with_context({:browser, :test}, fn ->
      Profiling.measure({:browser_bidi, :roundtrip}, fn -> :ok end)
    end)

    assert :ok = Profiling.dump_reports(limit: 5)

    bucket_snapshot = Path.join(tmp_dir, "profiling-buckets.json")
    context_snapshot = Path.join(tmp_dir, "profiling-context-buckets.json")

    assert File.exists?(bucket_snapshot)
    assert File.exists?(context_snapshot)

    assert {:ok, bucket_payload} = File.read(bucket_snapshot)
    assert {:ok, bucket_json} = JSON.decode(bucket_payload)
    assert is_list(bucket_json["rows"])

    assert Enum.any?(bucket_json["rows"], fn row ->
             row["bucket"] == ["browser_bidi", "roundtrip"]
           end)

    assert {:ok, context_payload} = File.read(context_snapshot)
    assert {:ok, context_json} = JSON.decode(context_payload)

    assert Enum.any?(context_json["rows"], fn row ->
             row["context"] == ["browser", "test"] and
               row["bucket"] == ["browser_bidi", "roundtrip"]
           end)
  end
end
