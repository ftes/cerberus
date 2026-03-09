defmodule Mix.Tasks.Cerberus.InstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Cerberus.Browser.Install

  @chrome_task "cerberus.install.chrome"
  @moduletag :tmp_dir

  setup %{tmp_dir: tmp_dir} do
    Install.put_command_runner(nil)
    Install.put_stable_link_dir(tmp_dir)

    on_exit(fn ->
      Install.put_command_runner(nil)
      Install.put_stable_link_dir(nil)
    end)

    :ok
  end

  test "mix cerberus.install.chrome resolves script from cerberus app path, not cwd", %{tmp_dir: tmp_dir} do
    install_output = """
    Chrome runtime ready
    chrome_binary=/tmp/chrome-146/chrome
    chrome_version=146.0.7680.31
    chromedriver_binary=/tmp/chromedriver-146/chromedriver
    chromedriver_version=146.0.7680.31
    """

    cwd_script_path = Path.join([tmp_dir, "bin", "chrome.sh"])
    File.mkdir_p!(Path.dirname(cwd_script_path))
    File.write!(cwd_script_path, "#!/bin/sh\n")

    Install.put_command_runner(fn script, args, _opts ->
      send(self(), {:runner_invocation, script, args})
      {install_output, 0}
    end)

    previous_cwd = File.cwd!()

    try do
      File.cd!(tmp_dir)

      capture_io(fn ->
        Mix.Task.reenable(@chrome_task)
        Mix.Task.run(@chrome_task, [])
      end)
    after
      File.cd!(previous_cwd)
    end

    assert_receive {:runner_invocation, script, []}
    refute script == cwd_script_path
    assert script =~ "/bin/chrome.sh"
  end

  test "browser_config returns runtime config keyword pairs from install payload" do
    payload = %{
      browser: :chrome,
      binaries: %{chrome_binary: "/tmp/chrome-bin", chromedriver_binary: "/tmp/chromedriver-bin"},
      versions: %{chrome_version: "146.0.7680.31", chromedriver_version: "146.0.7680.31"},
      raw: %{}
    }

    assert Install.browser_config(payload) == [
             chrome_binary: "/tmp/chrome-bin",
             chromedriver_binary: "/tmp/chromedriver-bin"
           ]
  end
end
