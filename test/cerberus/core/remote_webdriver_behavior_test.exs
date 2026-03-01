defmodule Cerberus.CoreRemoteWebdriverBehaviorTest do
  use ExUnit.Case, async: false

  import Cerberus

  alias Cerberus.Driver.Browser.BiDiSupervisor
  alias Cerberus.Driver.Browser.Runtime

  @moduletag :browser

  setup_all do
    case remote_webdriver_skip_reason() do
      nil ->
        reset_browser_runtime!()

        {container_id, webdriver_url} = selenium_runtime()
        browser_config = Application.get_env(:cerberus, :browser, [])
        base_url_config = Application.get_env(:cerberus, :base_url)

        Application.put_env(
          :cerberus,
          :browser,
          Keyword.merge(browser_config, webdriver_url: webdriver_url, chromedriver_binary: "/missing/chromedriver")
        )

        if container_id != nil do
          Application.put_env(:cerberus, :base_url, container_reachable_base_url(base_url_config))
        end

        on_exit(fn ->
          Application.put_env(:cerberus, :browser, browser_config)
          Application.put_env(:cerberus, :base_url, base_url_config)
          if container_id != nil, do: _ = docker_rm_force(container_id)
          reset_browser_runtime!()
        end)

        {:ok, webdriver_url: webdriver_url}

      reason ->
        {:ok, skip: reason}
    end
  end

  test "connects through webdriver_url to a containerized remote browser", context do
    case context[:skip] do
      nil ->
        :browser
        |> session()
        |> visit("/articles")
        |> assert_has(text("Articles", exact: true))

        assert {:ok, session_id} = Runtime.session_id()
        assert is_binary(session_id)

      _reason ->
        :ok
    end
  end

  defp remote_webdriver_enabled? do
    System.get_env("CERBERUS_REMOTE_WEBDRIVER") in ["1", "true", "TRUE", "yes", "YES"]
  end

  defp remote_webdriver_skip_reason do
    cond do
      not remote_webdriver_enabled?() ->
        "set CERBERUS_REMOTE_WEBDRIVER=1 to run remote webdriver integration coverage"

      not docker_available?() ->
        "docker daemon is unavailable; start docker and re-run this test"

      true ->
        nil
    end
  end

  defp docker_available? do
    case System.find_executable("docker") do
      nil ->
        false

      docker_path ->
        match?({_, 0}, System.cmd(docker_path, ["info"], stderr_to_stdout: true))
    end
  end

  defp start_selenium_container! do
    image = System.get_env("CERBERUS_REMOTE_SELENIUM_IMAGE", "selenium/standalone-chromium:126.0")
    {container_id, 0} = System.cmd("docker", ["run", "--rm", "-d", "-p", "127.0.0.1::4444", image])
    container_id = String.trim(container_id)
    port = mapped_port!(container_id)
    webdriver_url = "http://127.0.0.1:#{port}"
    wait_for_webdriver_ready!(webdriver_url)

    {container_id, webdriver_url}
  end

  defp selenium_runtime do
    case System.get_env("WEBDRIVER_URL") do
      webdriver_url when is_binary(webdriver_url) and webdriver_url != "" ->
        {nil, webdriver_url}

      _ ->
        start_selenium_container!()
    end
  end

  defp mapped_port!(container_id) do
    {output, 0} = System.cmd("docker", ["port", container_id, "4444/tcp"])

    output
    |> String.trim()
    |> String.split(":")
    |> List.last()
  end

  defp docker_rm_force(container_id) do
    System.cmd("docker", ["rm", "-f", container_id], stderr_to_stdout: true)
  end

  defp container_reachable_base_url(base_url) when is_binary(base_url) do
    uri = URI.parse(base_url)
    URI.to_string(%{uri | host: docker_host_address()})
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

  defp wait_for_webdriver_ready!(webdriver_url) do
    _ = :inets.start()
    _ = :ssl.start()
    wait_for_webdriver_ready!(webdriver_url, 30)
  end

  defp wait_for_webdriver_ready!(_webdriver_url, 0) do
    raise "webdriver service did not become ready in time"
  end

  defp wait_for_webdriver_ready!(webdriver_url, attempts_left) do
    status_url = webdriver_url <> "/status"

    case :httpc.request(:get, {String.to_charlist(status_url), []}, [timeout: 1_000], body_format: :binary) do
      {:ok, {{_version, 200, _reason}, _headers, _body}} ->
        :ok

      _ ->
        Process.sleep(500)
        wait_for_webdriver_ready!(webdriver_url, attempts_left - 1)
    end
  end

  defp reset_browser_runtime! do
    supervisor = Process.whereis(Cerberus.Driver.Browser.Supervisor)

    if is_pid(supervisor) do
      _ = Supervisor.terminate_child(supervisor, BiDiSupervisor)
      _ = Supervisor.terminate_child(supervisor, Runtime)
      _ = Supervisor.restart_child(supervisor, Runtime)
      _ = Supervisor.restart_child(supervisor, BiDiSupervisor)
    end

    :ok
  end
end
