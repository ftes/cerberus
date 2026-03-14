defmodule Cerberus.Driver.Browser.RuntimeIntegrationTest do
  use ExUnit.Case, async: false

  alias Cerberus.Driver.Browser.Runtime

  @browser_name Application.compile_env(:cerberus, [:browser, :browser_name], :chrome)
  @tag :tmp_dir
  @tag skip: @browser_name != :firefox
  test "direct firefox runtime cleans up the browser process when runtime exits", %{tmp_dir: tmp_dir} do
    fake_firefox = Path.join(tmp_dir, "fake_firefox.sh")
    File.cp!(Path.expand("../../../support/bin/fake_firefox.sh", __DIR__), fake_firefox)
    File.chmod!(fake_firefox, 0o755)

    runtime_pid = restart_runtime!()
    runtime_ref = Process.monitor(runtime_pid)

    on_exit(fn ->
      kill_matching_processes(fake_firefox)
    end)

    assert {:ok, web_socket_url} =
             Runtime.web_socket_url(browser_name: :firefox, firefox_binary: fake_firefox)

    assert web_socket_url =~ "ws://127.0.0.1:"
    fake_firefox_pid = assert_process_running(fake_firefox)

    GenServer.stop(Runtime, :shutdown, 5_000)

    assert_receive {:DOWN, ^runtime_ref, :process, ^runtime_pid, :shutdown}, 5_000
    assert_process_stopped(fake_firefox_pid, fake_firefox)
    assert_runtime_restarted(runtime_pid)
  end

  @tag :tmp_dir
  @tag skip: @browser_name != :chrome
  test "watchdog cleans up chromedriver and chrome when the runtime VM exits abruptly", %{
    tmp_dir: _tmp_dir
  } do
    chrome_binary = configured_binary!("CHROME", :chrome_binary, "chrome-current")
    chromedriver_binary = configured_binary!("CHROMEDRIVER", :chromedriver_binary, "chromedriver-current")

    {port, os_pid} =
      start_runtime_subprocess!("""
      alias Cerberus.Driver.Browser.Runtime

      {:ok, _} = Runtime.start_link(base_url: "http://127.0.0.1")

      {:ok, _url} =
        Runtime.web_socket_url(
          browser_name: :chrome,
          chrome_binary: #{inspect(chrome_binary)},
          chromedriver_binary: #{inspect(chromedriver_binary)}
        )

      IO.puts("RUNTIME_READY")
      Process.sleep(:infinity)
      """)

    on_exit(fn ->
      kill_os_pid(os_pid, "KILL")
      kill_matching_processes(chrome_binary)
      kill_matching_processes(chromedriver_binary)
      close_port_safe(port)
    end)

    await_runtime_ready!(port)

    chromedriver_pid = assert_process_running(chromedriver_binary)
    chrome_pid = assert_process_running(chrome_binary)

    kill_os_pid(os_pid, "KILL")
    await_subprocess_exit!(port)

    assert_process_stopped(chromedriver_pid, chromedriver_binary)
    assert_process_stopped(chrome_pid, chrome_binary)
  end

  @tag :tmp_dir
  @tag skip: @browser_name != :firefox
  test "watchdog cleans up direct firefox when the runtime VM exits abruptly", %{tmp_dir: tmp_dir} do
    fake_firefox = Path.join(tmp_dir, "fake_firefox.sh")
    File.cp!(Path.expand("../../../support/bin/fake_firefox.sh", __DIR__), fake_firefox)
    File.chmod!(fake_firefox, 0o755)

    {port, os_pid} =
      start_runtime_subprocess!("""
      alias Cerberus.Driver.Browser.Runtime

      {:ok, _} = Runtime.start_link(base_url: "http://127.0.0.1")
      {:ok, _url} = Runtime.web_socket_url(browser_name: :firefox, firefox_binary: #{inspect(fake_firefox)})

      IO.puts("RUNTIME_READY")
      Process.sleep(:infinity)
      """)

    on_exit(fn ->
      kill_os_pid(os_pid, "KILL")
      kill_matching_processes(fake_firefox)
      close_port_safe(port)
    end)

    await_runtime_ready!(port)

    fake_firefox_pid = assert_process_running(fake_firefox)

    kill_os_pid(os_pid, "KILL")
    await_subprocess_exit!(port)

    assert_process_stopped(fake_firefox_pid, fake_firefox)
  end

  defp restart_runtime! do
    previous_pid = Process.whereis(Runtime)

    if is_pid(previous_pid) do
      runtime_ref = Process.monitor(previous_pid)
      GenServer.stop(Runtime, :shutdown, 5_000)
      assert_receive {:DOWN, ^runtime_ref, :process, ^previous_pid, :shutdown}, 5_000
    end

    wait_for_runtime_pid(previous_pid)
  end

  defp wait_for_runtime_pid(previous_pid, attempts \\ 50)

  defp wait_for_runtime_pid(previous_pid, attempts) when attempts > 0 do
    case Process.whereis(Runtime) do
      pid when is_pid(pid) and pid != previous_pid ->
        pid

      _ ->
        Process.sleep(100)
        wait_for_runtime_pid(previous_pid, attempts - 1)
    end
  end

  defp wait_for_runtime_pid(previous_pid, 0) do
    flunk("expected #{inspect(Runtime)} to restart after #{inspect(previous_pid)} exited")
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
    case process_pid(command_path) do
      pid when is_integer(pid) and pid > 0 ->
        pid

      _ ->
        Process.sleep(100)
        assert_process_running(command_path, attempts - 1)
    end
  end

  defp assert_process_running(command_path, 0) do
    flunk("expected process to be running for #{command_path}")
  end

  defp assert_process_stopped(process_pid, label, attempts \\ 50)

  defp assert_process_stopped(process_pid, label, attempts)
       when is_integer(process_pid) and process_pid > 0 and attempts > 0 do
    if pid_alive?(process_pid) do
      Process.sleep(100)
      assert_process_stopped(process_pid, label, attempts - 1)
    else
      :ok
    end
  end

  defp assert_process_stopped(_process_pid, label, 0) do
    flunk("expected process to stop for #{label}")
  end

  defp start_runtime_subprocess!(script) when is_binary(script) do
    elixir = System.find_executable("elixir") || flunk("expected elixir executable in PATH")

    port =
      Port.open({:spawn_executable, elixir}, [
        :binary,
        :exit_status,
        :hide,
        :stderr_to_stdout,
        args: ["-S", "mix", "run", "--no-compile", "-e", script]
      ])

    os_pid =
      case Port.info(port, :os_pid) do
        {:os_pid, pid} when is_integer(pid) and pid > 0 -> pid
        _ -> flunk("expected spawned mix subprocess OS pid")
      end

    {port, os_pid}
  end

  defp await_runtime_ready!(port, timeout_ms \\ 15_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_await_runtime_ready(port, "", deadline)
  end

  defp do_await_runtime_ready(port, output, deadline) when is_port(port) and is_binary(output) do
    remaining_ms = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} ->
        output = output <> data

        if String.contains?(output, "RUNTIME_READY") do
          :ok
        else
          do_await_runtime_ready(port, output, deadline)
        end

      {^port, {:exit_status, status}} ->
        flunk("expected runtime subprocess to become ready, exited with status #{status}: #{output}")
    after
      remaining_ms ->
        flunk("timed out waiting for runtime subprocess readiness: #{output}")
    end
  end

  defp await_subprocess_exit!(port, timeout_ms \\ 10_000) when is_port(port) do
    receive do
      {^port, {:exit_status, _status}} ->
        :ok
    after
      timeout_ms ->
        flunk("timed out waiting for runtime subprocess to exit")
    end
  end

  defp configured_binary!(env_name, config_key, stable_name)
       when is_binary(env_name) and is_atom(config_key) and is_binary(stable_name) do
    binary =
      first_existing_path([
        System.get_env(env_name),
        Application.get_env(:cerberus, :browser, [])[config_key],
        stable_binary_path(stable_name)
      ])

    if is_binary(binary) do
      binary
    else
      flunk(
        "expected #{env_name}, :cerberus browser #{inspect(config_key)}, or #{stable_name} to point to an installed browser binary"
      )
    end
  end

  defp first_existing_path(paths) when is_list(paths) do
    Enum.find_value(paths, fn
      path when is_binary(path) and path != "" ->
        path = Path.expand(path)
        if File.exists?(path), do: resolve_existing_path(path)

      _ ->
        nil
    end)
  end

  defp resolve_existing_path(path) when is_binary(path) do
    case :file.read_link_all(String.to_charlist(path)) do
      {:ok, resolved} ->
        resolved = List.to_string(resolved)
        if File.exists?(resolved), do: resolved, else: path

      _ ->
        path
    end
  end

  defp stable_binary_path(name) when is_binary(name) do
    Path.expand(Path.join("tmp", name))
  end

  defp process_pid(command_path) do
    command_path
    |> command_path_variants()
    |> Enum.find_value(fn path ->
      case System.cmd("pgrep", ["-fal", path], stderr_to_stdout: true) do
        {output, 0} ->
          output
          |> String.split("\n", trim: true)
          |> Enum.find_value(fn line ->
            if String.contains?(line, path) do
              line
              |> String.split(~r/\s+/, parts: 2, trim: true)
              |> List.first()
              |> parse_positive_integer()
            end
          end)

        _ ->
          nil
      end
    end)
  end

  defp kill_matching_processes(command_path) do
    command_path
    |> command_path_variants()
    |> Enum.each(fn path ->
      _ = System.cmd("pkill", ["-f", path], stderr_to_stdout: true)
    end)

    :ok
  end

  defp command_path_variants(command_path) when is_binary(command_path) do
    expanded = Path.expand(command_path)

    Enum.uniq([expanded | symlink_target_variants(expanded)])
  end

  defp kill_os_pid(os_pid, signal) when is_integer(os_pid) and os_pid > 0 do
    _ = System.cmd("kill", ["-#{signal}", Integer.to_string(os_pid)], stderr_to_stdout: true)
    :ok
  end

  defp close_port_safe(port) when is_port(port) do
    if Port.info(port) != nil, do: Port.close(port)
    :ok
  rescue
    _ -> :ok
  end

  defp pid_alive?(process_pid) when is_integer(process_pid) and process_pid > 0 do
    match?({_output, 0}, System.cmd("kill", ["-0", Integer.to_string(process_pid)], stderr_to_stdout: true))
  end

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp symlink_target_variants(path) when is_binary(path) do
    case File.read_link(path) do
      {:ok, target} ->
        resolved =
          if Path.type(target) == :absolute do
            target
          else
            Path.expand(target, Path.dirname(path))
          end

        [resolved | symlink_target_variants(resolved)]

      _ ->
        []
    end
  end
end
