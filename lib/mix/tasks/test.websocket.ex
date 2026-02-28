defmodule Mix.Tasks.Test.Websocket do
  @shortdoc "Runs tests against a containerized remote WebDriver endpoint"
  @moduledoc """
  Starts a Selenium standalone container, configures Cerberus to use remote
  WebDriver (`webdriver_url`), and runs `mix test` with forwarded args.

  This gives a global remote-browser invocation similar to websocket-based
  remote test flows in companion projects.

  ## Usage

      mix test.websocket
      mix test.websocket --warnings-as-errors
      mix test.websocket test/core/remote_webdriver_behavior_test.exs

  Optional env vars:

  - `CERBERUS_REMOTE_SELENIUM_IMAGE` (default: `selenium/standalone-chromium:126.0`)
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    if Mix.env() == :test do
      ensure_docker!()

      image = System.get_env("CERBERUS_REMOTE_SELENIUM_IMAGE", "selenium/standalone-chromium:126.0")
      container_id = start_selenium_container!(image)

      try do
        webdriver_url = "http://127.0.0.1:#{mapped_port!(container_id)}"
        wait_for_webdriver_ready!(webdriver_url)

        System.put_env("CERBERUS_REMOTE_WEBDRIVER", "1")
        System.put_env("WEBDRIVER_URL", webdriver_url)
        System.put_env("CERBERUS_BASE_URL_HOST", docker_host_address())
        apply_runtime_browser_config(webdriver_url)

        Mix.shell().info("Running tests with remote webdriver_url=#{webdriver_url}")
        Mix.Task.run("test", args)
      after
        _ = docker_rm_force(container_id)
      end
    else
      rerun_in_test_env!(args)
    end
  end

  defp rerun_in_test_env!(args) do
    mix_executable = System.find_executable("mix") || "mix"
    command_args = ["test.websocket" | args]

    {_, status} =
      System.cmd(mix_executable, command_args,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true,
        into: IO.stream(:stdio, :line)
      )

    if status != 0 do
      Mix.raise("mix test.websocket failed in test env with status #{status}")
    end
  end

  defp ensure_docker! do
    case System.find_executable("docker") do
      nil ->
        Mix.raise("docker executable not found in PATH")

      docker_path ->
        case System.cmd(docker_path, ["info"], stderr_to_stdout: true) do
          {_, 0} ->
            :ok

          {output, status} ->
            Mix.raise("docker info failed with status #{status}: #{String.trim(output)}")
        end
    end
  end

  defp start_selenium_container!(image) do
    {output, status} = System.cmd("docker", ["run", "--rm", "-d", "-p", "127.0.0.1::4444", image], stderr_to_stdout: true)

    if status == 0 do
      String.trim(output)
    else
      Mix.raise("failed to start selenium container: #{String.trim(output)}")
    end
  end

  defp mapped_port!(container_id) do
    {output, status} = System.cmd("docker", ["port", container_id, "4444/tcp"], stderr_to_stdout: true)

    if status == 0 do
      output
      |> String.trim()
      |> String.split(":")
      |> List.last()
    else
      Mix.raise("failed to resolve selenium container port: #{String.trim(output)}")
    end
  end

  defp docker_rm_force(container_id) do
    System.cmd("docker", ["rm", "-f", container_id], stderr_to_stdout: true)
  end

  defp docker_host_address do
    case :os.type() do
      {:unix, :darwin} ->
        "host.docker.internal"

      {:unix, :linux} ->
        case System.cmd("docker", [
               "network",
               "inspect",
               "bridge",
               "--format",
               "{{range .IPAM.Config}}{{.Gateway}}{{end}}"
             ]) do
          {gateway, 0} when gateway != "" -> String.trim(gateway)
          _ -> "172.17.0.1"
        end

      _ ->
        "host.docker.internal"
    end
  end

  defp apply_runtime_browser_config(webdriver_url) do
    browser_config =
      :cerberus
      |> Application.get_env(:browser, [])
      |> Keyword.put(:webdriver_url, webdriver_url)

    Application.put_env(:cerberus, :browser, browser_config)
  end

  defp wait_for_webdriver_ready!(webdriver_url) do
    _ = :inets.start()
    _ = :ssl.start()
    do_wait_for_webdriver_ready!(webdriver_url, 30)
  end

  defp do_wait_for_webdriver_ready!(_webdriver_url, 0) do
    Mix.raise("webdriver service did not become ready in time")
  end

  defp do_wait_for_webdriver_ready!(webdriver_url, attempts_left) do
    status_url = webdriver_url <> "/status"

    case :httpc.request(:get, {String.to_charlist(status_url), []}, [timeout: 1_000], body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, _body}} ->
        :ok

      _ ->
        Process.sleep(500)
        do_wait_for_webdriver_ready!(webdriver_url, attempts_left - 1)
    end
  end
end
