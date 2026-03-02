defmodule Mix.Tasks.Test.Websocket do
  @shortdoc "Runs tests against a containerized remote WebDriver endpoint"
  @moduledoc """
  Starts Selenium standalone container(s), configures Cerberus to use remote
  WebDriver endpoint(s), and runs `mix test` with forwarded args in a single
  invocation.

  This gives a global remote-browser invocation similar to websocket-based
  remote test flows in companion projects.

  ## Usage

      mix test.websocket
      mix test.websocket --warnings-as-errors
      mix test.websocket --browsers chrome,firefox

  Optional flag:

  - `--browsers` comma-separated list of `chrome`, `firefox`, or `all`
    (default: `all`)

  Optional env vars:

  - `CERBERUS_REMOTE_SELENIUM_BROWSERS` fallback when `--browsers` is not set
    (default: `all`)
  - `CERBERUS_REMOTE_SELENIUM_IMAGE` fallback image for all browsers
  - `CERBERUS_REMOTE_SELENIUM_IMAGE_CHROME`
    (default: `selenium/standalone-chromium:126.0`)
  - `CERBERUS_REMOTE_SELENIUM_IMAGE_FIREFOX`
    (default: `selenium/standalone-firefox:126.0`)
  """

  use Mix.Task

  @default_selenium_images %{
    chrome: "selenium/standalone-chrome:145.0-20260222",
    firefox: "selenium/standalone-firefox:148.0-20260222"
  }

  @impl Mix.Task
  def run(args) do
    if Mix.env() == :test do
      {browsers, test_args} = extract_task_args!(args)
      ensure_docker!()
      docker_host = docker_host_address()

      browser_containers =
        Map.new(browsers, fn browser ->
          image = selenium_image(browser)
          container_id = start_selenium_container!(image)
          webdriver_url = "http://127.0.0.1:#{mapped_port!(container_id)}"
          wait_for_webdriver_ready!(webdriver_url)
          {browser, %{container_id: container_id, webdriver_url: webdriver_url}}
        end)

      default_browser = default_browser_lane(browsers)
      browser_urls = Map.new(browser_containers, fn {browser, info} -> {browser, info.webdriver_url} end)

      try do
        Mix.shell().info(
          "Running tests with remote websocket browsers=#{Enum.map_join(browsers, ",", &Atom.to_string/1)} " <>
            "(default browser lane=#{default_browser})"
        )

        run_test_suite!(test_args, browser_urls, default_browser, docker_host)
      after
        Enum.each(browser_containers, fn {_browser, %{container_id: container_id}} ->
          _ = docker_rm_force(container_id)
        end)
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

  defp run_test_suite!(test_args, browser_urls, default_browser, docker_host)
       when is_list(test_args) and is_map(browser_urls) and default_browser in [:chrome, :firefox] and
              is_binary(docker_host) do
    mix_executable = System.find_executable("mix") || "mix"
    command_args = ["test" | test_args]
    default_webdriver_url = Map.fetch!(browser_urls, default_browser)

    browser_url_envs =
      Enum.map(browser_urls, fn {browser, webdriver_url} ->
        {"WEBDRIVER_URL_" <> (browser |> Atom.to_string() |> String.upcase()), webdriver_url}
      end)

    env = [
      {"MIX_ENV", "test"},
      {"CERBERUS_REMOTE_WEBDRIVER", "1"},
      {"CERBERUS_BROWSER_NAME", Atom.to_string(default_browser)},
      {"WEBDRIVER_URL", default_webdriver_url},
      {"CERBERUS_BASE_URL_HOST", docker_host}
      | browser_url_envs
    ]

    {_, status} =
      System.cmd(mix_executable, command_args,
        env: env,
        stderr_to_stdout: true,
        into: IO.stream(:stdio, :line)
      )

    if status != 0 do
      Mix.raise("mix test.websocket failed with status #{status}")
    end
  end

  defp default_browser_lane(browsers) when is_list(browsers) do
    env_browser = preferred_default_browser_from_env()

    cond do
      env_browser in browsers ->
        env_browser

      :chrome in browsers ->
        :chrome

      true ->
        List.first(browsers)
    end
  end

  defp preferred_default_browser_from_env do
    case System.get_env("CERBERUS_BROWSER_NAME") do
      "chrome" -> :chrome
      "firefox" -> :firefox
      _ -> nil
    end
  end

  defp extract_task_args!(args) when is_list(args) do
    {browsers_arg, test_args} = take_browsers_arg(args, nil, [])
    browsers = parse_browsers!(browsers_arg || System.get_env("CERBERUS_REMOTE_SELENIUM_BROWSERS", "all"))
    {browsers, test_args}
  end

  defp take_browsers_arg([], browsers, acc), do: {browsers, Enum.reverse(acc)}

  defp take_browsers_arg(["--browsers", value | rest], _browsers, acc), do: take_browsers_arg(rest, value, acc)

  defp take_browsers_arg(["--browsers" | _rest], _browsers, _acc) do
    Mix.raise("missing value for --browsers")
  end

  defp take_browsers_arg([<<"--browsers=", value::binary>> | rest], _browsers, acc),
    do: take_browsers_arg(rest, value, acc)

  defp take_browsers_arg(["-b", value | rest], _browsers, acc), do: take_browsers_arg(rest, value, acc)

  defp take_browsers_arg(["-b" | _rest], _browsers, _acc) do
    Mix.raise("missing value for -b")
  end

  defp take_browsers_arg([arg | rest], browsers, acc), do: take_browsers_arg(rest, browsers, [arg | acc])

  defp parse_browsers!(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.flat_map(&expand_browser_token!/1)
    |> Enum.uniq()
    |> case do
      [] -> Mix.raise("no browsers selected for --browsers")
      browsers -> browsers
    end
  end

  defp expand_browser_token!(token) do
    case token |> String.trim() |> String.downcase() do
      "chrome" -> [:chrome]
      "firefox" -> [:firefox]
      "all" -> [:chrome, :firefox]
      other -> Mix.raise("unsupported browser token #{inspect(other)}; use chrome, firefox, or all")
    end
  end

  defp selenium_image(browser) when browser in [:chrome, :firefox] do
    global_image =
      "CERBERUS_REMOTE_SELENIUM_IMAGE"
      |> System.get_env()
      |> normalize_non_empty_string(nil)

    specific_image =
      case browser do
        :chrome ->
          System.get_env("CERBERUS_REMOTE_SELENIUM_IMAGE_CHROME")

        :firefox ->
          System.get_env("CERBERUS_REMOTE_SELENIUM_IMAGE_FIREFOX")
      end

    normalize_non_empty_string(specific_image, global_image || @default_selenium_images[browser])
  end

  defp normalize_non_empty_string(value, default) when is_binary(value) do
    if value |> String.trim() |> byte_size() > 0, do: value, else: default
  end

  defp normalize_non_empty_string(_value, default), do: default

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
      case parse_container_id(output) do
        {:ok, container_id} ->
          container_id

        :error ->
          Mix.raise("failed to parse selenium container id from docker output: #{String.trim(output)}")
      end
    else
      Mix.raise("failed to start selenium container: #{String.trim(output)}")
    end
  end

  defp parse_container_id(output) when is_binary(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reverse()
    |> Enum.find(&String.match?(&1, ~r/^[a-f0-9]{12,}$/i))
    |> case do
      nil -> :error
      container_id -> {:ok, container_id}
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
