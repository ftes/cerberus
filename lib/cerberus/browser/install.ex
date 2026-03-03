defmodule Cerberus.Browser.Install do
  @moduledoc """
  Shared browser-runtime installer for Cerberus Mix tasks.

  This module executes Cerberus installer scripts and returns a parsed result
  that can be rendered as JSON, key/value env lines, or shell exports.
  """

  @typedoc "Supported browser runtime lanes"
  @type browser :: :chrome | :firefox

  @typedoc "Parsed install payload from installer output"
  @type install_payload :: %{
          required(:browser) => browser(),
          required(:binaries) => map(),
          required(:versions) => map(),
          required(:raw) => map()
        }

  @type install_opt ::
          {:version, String.t()}
          | {:firefox_version, String.t()}
          | {:geckodriver_version, String.t()}
          | {:command_runner, (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})}

  @type env_map :: %{required(String.t()) => String.t()}
  @command_runner_override_key {__MODULE__, :command_runner_override}

  @spec install(browser(), [install_opt()]) :: {:ok, install_payload()} | {:error, String.t()}
  def install(browser, opts \\ []) when browser in [:chrome, :firefox] and is_list(opts) do
    with {:ok, script_path} <- installer_script_path(browser),
         {:ok, key_values} <- run_script(script_path, script_args(browser, opts), command_runner(opts)) do
      case parse_payload(browser, key_values) do
        {:ok, payload} -> {:ok, payload}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec browser_config(install_payload()) :: keyword()
  def browser_config(%{binaries: binaries}) when is_map(binaries) do
    binaries
    |> Enum.map(fn {key, value} -> {key, value} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  @spec env_vars(install_payload()) :: env_map()
  def env_vars(%{browser: :chrome, binaries: binaries, versions: versions}) do
    %{
      "CHROME" => binaries.chrome_binary,
      "CHROMEDRIVER" => binaries.chromedriver_binary,
      "CERBERUS_CHROME_VERSION" => versions.chrome_version
    }
  end

  def env_vars(%{browser: :firefox, binaries: binaries, versions: versions}) do
    %{
      "FIREFOX" => binaries.firefox_binary,
      "GECKODRIVER" => binaries.geckodriver_binary,
      "CERBERUS_FIREFOX_VERSION" => versions.firefox_version,
      "CERBERUS_GECKODRIVER_VERSION" => versions.geckodriver_version
    }
  end

  @spec render(install_payload(), :plain | :json | :env | :shell) :: String.t()
  def render(payload, :plain) do
    payload
    |> ordered_pairs()
    |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)
  end

  def render(payload, :env) do
    payload
    |> env_vars()
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)
  end

  def render(payload, :shell) do
    payload
    |> env_vars()
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map_join("\n", fn {key, value} -> "export #{key}=#{shell_quote(value)}" end)
  end

  def render(payload, :json) do
    payload
    |> normalize_payload_for_json()
    |> JSON.encode!()
  end

  @doc false
  @spec put_command_runner((String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()}) | nil) :: :ok
  def put_command_runner(command_runner) when is_function(command_runner, 3) do
    Process.put(@command_runner_override_key, command_runner)
    :ok
  end

  def put_command_runner(nil) do
    Process.delete(@command_runner_override_key)
    :ok
  end

  defp normalize_payload_for_json(payload) do
    %{
      browser: payload.browser,
      binaries: Map.new(payload.binaries),
      versions: Map.new(payload.versions),
      env: Map.new(env_vars(payload))
    }
  end

  defp ordered_pairs(%{raw: raw}) when is_map(raw) do
    raw
    |> Enum.map(fn {key, value} -> {key, value} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp shell_quote(value) when is_binary(value) do
    escaped = String.replace(value, "'", "'\\''")
    "'#{escaped}'"
  end

  defp command_runner(opts) do
    Keyword.get(opts, :command_runner) ||
      Process.get(@command_runner_override_key) ||
      Application.get_env(:cerberus, :install_command_runner, &System.cmd/3)
  end

  defp run_script(script_path, args, command_runner) when is_list(args) and is_function(command_runner, 3) do
    {output, status} = command_runner.(script_path, args, stderr_to_stdout: true)

    if status == 0 do
      {:ok, parse_key_values(output)}
    else
      {:error, "installer failed with status #{status}: #{String.trim(output)}"}
    end
  rescue
    error ->
      {:error, "installer execution failed: #{Exception.message(error)}"}
  end

  defp parse_key_values(output) when is_binary(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, "=", parts: 2) do
        [key, value] when key != "" and value != "" -> Map.put(acc, key, value)
        _ -> acc
      end
    end)
  end

  defp parse_payload(:chrome, values) when is_map(values) do
    required_keys = ["chrome_binary", "chrome_version", "chromedriver_binary", "chromedriver_version"]
    parse_required(values, required_keys, :chrome)
  end

  defp parse_payload(:firefox, values) when is_map(values) do
    required_keys = ["firefox_binary", "firefox_version", "geckodriver_binary", "geckodriver_version"]
    parse_required(values, required_keys, :firefox)
  end

  defp parse_required(values, required_keys, browser) do
    missing = Enum.reject(required_keys, &valid_key_value?(values, &1))

    if missing == [] do
      {:ok,
       %{
         browser: browser,
         binaries: binaries_map(browser, values),
         versions: versions_map(browser, values),
         raw: Map.take(values, required_keys)
       }}
    else
      {:error, "installer output missing keys #{inspect(missing)} for #{browser}; received #{inspect(Map.keys(values))}"}
    end
  end

  defp valid_key_value?(values, key) when is_map(values) and is_binary(key) do
    case Map.get(values, key) do
      value when is_binary(value) -> String.trim(value) != ""
      _ -> false
    end
  end

  defp binaries_map(:chrome, values) do
    %{
      chrome_binary: values["chrome_binary"],
      chromedriver_binary: values["chromedriver_binary"]
    }
  end

  defp binaries_map(:firefox, values) do
    %{
      firefox_binary: values["firefox_binary"],
      geckodriver_binary: values["geckodriver_binary"]
    }
  end

  defp versions_map(:chrome, values) do
    %{
      chrome_version: values["chrome_version"],
      chromedriver_version: values["chromedriver_version"]
    }
  end

  defp versions_map(:firefox, values) do
    %{
      firefox_version: values["firefox_version"],
      geckodriver_version: values["geckodriver_version"]
    }
  end

  defp script_args(:chrome, opts) do
    case Keyword.get(opts, :version) do
      value when is_binary(value) and value != "" -> ["--version", value]
      _ -> []
    end
  end

  defp script_args(:firefox, opts) do
    []
    |> maybe_put_flag("--firefox-version", Keyword.get(opts, :firefox_version))
    |> maybe_put_flag("--geckodriver-version", Keyword.get(opts, :geckodriver_version))
  end

  defp maybe_put_flag(args, _flag, nil), do: args

  defp maybe_put_flag(args, flag, value) when is_binary(value) and value != "" do
    args ++ [flag, value]
  end

  defp maybe_put_flag(args, _flag, _value), do: args

  defp installer_script_path(:chrome), do: script_path("chrome.sh")
  defp installer_script_path(:firefox), do: script_path("firefox.sh")

  defp script_path(script_name) do
    candidate = Path.expand("bin/#{script_name}")

    if File.exists?(candidate) do
      {:ok, candidate}
    else
      {:error, "installer script not found: #{candidate}"}
    end
  end
end
