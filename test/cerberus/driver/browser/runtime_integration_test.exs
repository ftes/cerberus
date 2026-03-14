defmodule Cerberus.Driver.Browser.RuntimeIntegrationTest do
  use ExUnit.Case, async: false

  alias Cerberus.Driver.Browser.Runtime

  @tag :tmp_dir
  test "direct firefox runtime cleans up the browser process when runtime exits", %{tmp_dir: tmp_dir} do
    fake_firefox = Path.join(tmp_dir, "fake_firefox.sh")
    File.cp!(Path.expand("../../../support/bin/fake_firefox.sh", __DIR__), fake_firefox)
    File.chmod!(fake_firefox, 0o755)

    runtime_pid = Process.whereis(Runtime)
    runtime_ref = Process.monitor(runtime_pid)

    on_exit(fn ->
      kill_matching_processes(fake_firefox)
    end)

    assert {:ok, web_socket_url} =
             Runtime.web_socket_url(browser_name: :firefox, firefox_binary: fake_firefox)

    assert web_socket_url =~ "ws://127.0.0.1:"
    assert_process_running(fake_firefox)

    GenServer.stop(Runtime, :shutdown, 5_000)

    assert_receive {:DOWN, ^runtime_ref, :process, ^runtime_pid, :shutdown}, 5_000
    assert_process_stopped(fake_firefox)
    assert_runtime_restarted(runtime_pid)
  end

  @tag :tmp_dir
  test "watchdog cleans up direct firefox when shutdown is interrupted", %{tmp_dir: tmp_dir} do
    fake_firefox = Path.join(tmp_dir, "fake_firefox.sh")
    File.cp!(Path.expand("../../../support/bin/fake_firefox.sh", __DIR__), fake_firefox)
    File.chmod!(fake_firefox, 0o755)

    on_exit(fn ->
      kill_matching_processes(fake_firefox)
    end)

    script = """
    alias Cerberus.Driver.Browser.Runtime

    {:ok, _} = Runtime.start_link(base_url: "http://127.0.0.1")
    {:ok, _url} = Runtime.web_socket_url(browser_name: :firefox, firefox_binary: #{inspect(fake_firefox)})
    spawn(fn -> GenServer.stop(Runtime, :shutdown, 5_000) end)
    Process.sleep(10)
    System.halt(0)
    """

    assert {_, 0} =
             System.cmd("mix", ["run", "--no-compile", "-e", script],
               cd: File.cwd!(),
               env: [{"MIX_ENV", "test"}],
               stderr_to_stdout: true
             )

    assert_process_stopped(fake_firefox)
  end

  defp assert_runtime_restarted(previous_pid, attempts \\ 50)

  defp assert_runtime_restarted(previous_pid, attempts) when attempts > 0 do
    case Process.whereis(Runtime) do
      pid when is_pid(pid) and pid != previous_pid ->
        :ok

      _ ->
        Process.sleep(100)
        assert_runtime_restarted(previous_pid, attempts - 1)
    end
  end

  defp assert_runtime_restarted(previous_pid, 0) do
    flunk("expected #{inspect(Runtime)} to restart after #{inspect(previous_pid)} exited")
  end

  defp assert_process_running(command_path, attempts \\ 50)

  defp assert_process_running(command_path, attempts) when attempts > 0 do
    if process_running?(command_path) do
      :ok
    else
      Process.sleep(100)
      assert_process_running(command_path, attempts - 1)
    end
  end

  defp assert_process_running(command_path, 0) do
    flunk("expected process to be running for #{command_path}")
  end

  defp assert_process_stopped(command_path, attempts \\ 50)

  defp assert_process_stopped(command_path, attempts) when attempts > 0 do
    if process_running?(command_path) do
      Process.sleep(100)
      assert_process_stopped(command_path, attempts - 1)
    else
      :ok
    end
  end

  defp assert_process_stopped(command_path, 0) do
    flunk("expected process to stop for #{command_path}")
  end

  defp process_running?(command_path) do
    case System.cmd("pgrep", ["-fal", command_path], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.any?(&String.contains?(&1, command_path))

      _ ->
        false
    end
  end

  defp kill_matching_processes(command_path) do
    _ = System.cmd("pkill", ["-f", command_path], stderr_to_stdout: true)
    :ok
  end
end
