defmodule Cerberus.ProfilingTest do
  use ExUnit.Case, async: false

  import Cerberus
  import ExUnit.CaptureIO

  alias Cerberus.Profiling

  @env_name "CERBERUS_PROFILE"

  setup do
    previous = System.get_env(@env_name)
    Profiling.clear()

    on_exit(fn ->
      Profiling.clear()

      if is_nil(previous) do
        System.delete_env(@env_name)
      else
        System.put_env(@env_name, previous)
      end
    end)

    :ok
  end

  test "measure/2 records aggregated samples when profiling is enabled" do
    System.put_env(@env_name, "1")

    Profiling.measure(:sample_bucket, fn -> Process.sleep(5) end)
    Profiling.measure(:sample_bucket, fn -> :ok end)

    assert [%{bucket: :sample_bucket, count: 2, total_us: total_us}] = Profiling.snapshot()
    assert total_us > 0
  end

  test "measure/2 does not record samples when profiling is disabled" do
    System.put_env(@env_name, "0")
    Profiling.measure(:sample_bucket, fn -> :ok end)
    assert Profiling.snapshot() == []
  end

  test "driver operations publish profiling buckets" do
    System.put_env(@env_name, "1")

    _session =
      session()
      |> visit("/search")
      |> click_link("Articles")
      |> assert_has("Articles")

    buckets = Enum.map(Profiling.snapshot(), & &1.bucket)

    assert {:driver_operation, :static, :visit} in buckets
    assert {:driver_operation, :static, :click} in buckets
    assert {:driver_operation, :static, :assert_has} in buckets
  end

  test "dump_summary/1 prints aggregated rows" do
    System.put_env(@env_name, "1")

    Profiling.measure(:summary_bucket, fn -> :ok end)

    output =
      capture_io(fn ->
        assert :ok = Profiling.dump_summary(limit: 5)
      end)

    assert output =~ "Cerberus profiling summary"
    assert output =~ ":summary_bucket"
  end
end
