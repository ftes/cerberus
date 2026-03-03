defmodule Mix.Tasks.Cerberus.InstallTasksTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Cerberus.Browser.Install

  @chrome_task "cerberus.install.chrome"
  @firefox_task "cerberus.install.firefox"

  setup do
    Install.put_command_runner(nil)

    on_exit(fn ->
      Install.put_command_runner(nil)
    end)

    :ok
  end

  test "mix cerberus.install.chrome --format json emits machine-readable payload" do
    install_output = """
    Chrome runtime ready
    chrome_binary=/tmp/chrome-146/chrome
    chrome_version=146.0.7680.31
    chromedriver_binary=/tmp/chromedriver-146/chromedriver
    chromedriver_version=146.0.7680.31
    """

    Install.put_command_runner(fn script, args, _opts ->
      send(self(), {:runner_invocation, script, args})
      {install_output, 0}
    end)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@chrome_task)
        Mix.Task.run(@chrome_task, ["--format", "json"])
      end)

    assert_receive {:runner_invocation, script, []}
    assert script =~ "/bin/chrome.sh"

    payload = output |> String.trim() |> JSON.decode!()

    assert payload["browser"] == "chrome"
    assert payload["binaries"]["chrome_binary"] == "/tmp/chrome-146/chrome"
    assert payload["binaries"]["chromedriver_binary"] == "/tmp/chromedriver-146/chromedriver"
    assert payload["versions"]["chrome_version"] == "146.0.7680.31"
    assert payload["versions"]["chromedriver_version"] == "146.0.7680.31"
    assert payload["env"]["CHROME"] == "/tmp/chrome-146/chrome"
    assert payload["env"]["CHROMEDRIVER"] == "/tmp/chromedriver-146/chromedriver"
    assert payload["env"]["CERBERUS_CHROME_VERSION"] == "146.0.7680.31"
  end

  test "mix cerberus.install.firefox forwards version flags and renders env" do
    install_output = """
    Firefox runtime ready
    firefox_binary=/tmp/firefox-148/firefox
    firefox_version=148.0
    geckodriver_binary=/tmp/geckodriver-0.36.0/geckodriver
    geckodriver_version=0.36.0
    """

    Install.put_command_runner(fn _script, args, _opts ->
      send(self(), {:runner_args, args})
      {install_output, 0}
    end)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@firefox_task)

        Mix.Task.run(@firefox_task, [
          "--firefox-version",
          "148.0",
          "--geckodriver-version",
          "0.36.0",
          "--format",
          "env"
        ])
      end)

    assert_receive {:runner_args, ["--firefox-version", "148.0", "--geckodriver-version", "0.36.0"]}

    lines = output |> String.trim() |> String.split("\n", trim: true)

    assert "FIREFOX=/tmp/firefox-148/firefox" in lines
    assert "GECKODRIVER=/tmp/geckodriver-0.36.0/geckodriver" in lines
    assert "CERBERUS_FIREFOX_VERSION=148.0" in lines
    assert "CERBERUS_GECKODRIVER_VERSION=0.36.0" in lines
  end

  test "mix cerberus.install.chrome rejects unsupported format" do
    Install.put_command_runner(fn _script, _args, _opts ->
      flunk("runner should not be called on option validation failure")
    end)

    assert_raise Mix.Error, ~r/unsupported format/, fn ->
      capture_io(fn ->
        Mix.Task.reenable(@chrome_task)
        Mix.Task.run(@chrome_task, ["--format", "yaml"])
      end)
    end
  end

  test "browser_config returns runtime config keyword pairs from install payload" do
    payload = %{
      browser: :firefox,
      binaries: %{firefox_binary: "/tmp/firefox-bin", geckodriver_binary: "/tmp/gecko-bin"},
      versions: %{firefox_version: "148.0", geckodriver_version: "0.36.0"},
      raw: %{}
    }

    assert Install.browser_config(payload) == [
             firefox_binary: "/tmp/firefox-bin",
             geckodriver_binary: "/tmp/gecko-bin"
           ]
  end
end
