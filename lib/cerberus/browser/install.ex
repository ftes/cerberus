defmodule Cerberus.Browser.Install do
  @moduledoc """
  Shared Chrome runtime installer for Cerberus Mix tasks.

  This module executes the Cerberus Chrome installer script and returns a parsed
  payload that can be rendered as JSON, key/value env lines, or shell exports.
  """

  @typedoc "Parsed install payload from installer output"
  @type install_payload :: %{
          required(:browser) => :chrome,
          required(:binaries) => %{
            required(:chrome_binary) => String.t(),
            required(:chromedriver_binary) => String.t()
          },
          required(:versions) => %{
            required(:chrome_version) => String.t(),
            required(:chromedriver_version) => String.t()
          },
          required(:raw) => %{required(String.t()) => String.t()}
        }

  @type install_opt ::
          {:version, String.t()}
          | {:stable_link_dir, String.t()}
          | {:command_runner, (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})}

  @type env_map :: %{required(String.t()) => String.t()}
  @command_runner_override_key {__MODULE__, :command_runner_override}
  @stable_link_dir_override_key {__MODULE__, :stable_link_dir_override}

  @spec install([install_opt()]) :: {:ok, install_payload()} | {:error, String.t()}
  def install(opts \\ []) when is_list(opts) do
    with {:ok, script_path} <- installer_script_path(),
         {:ok, key_values} <- run_script(script_path, script_args(opts), command_runner(opts)),
         {:ok, payload} <- parse_payload(key_values),
         :ok <- ensure_stable_symlinks(payload, opts) do
      {:ok, payload}
    end
  end

  @spec browser_config(install_payload()) :: keyword(chrome_binary: String.t(), chromedriver_binary: String.t())
  def browser_config(%{binaries: binaries}) when is_map(binaries) do
    binaries
    |> Enum.map(fn {key, value} -> {key, value} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  @spec env_vars(install_payload()) :: env_map()
  def env_vars(%{binaries: binaries, versions: versions}) do
    %{
      "CHROME" => binaries.chrome_binary,
      "CHROMEDRIVER" => binaries.chromedriver_binary,
      "CERBERUS_CHROME_VERSION" => versions.chrome_version
    }
  end

  @spec render(install_payload()) :: String.t()
  def render(payload) do
    payload
    |> ordered_pairs()
    |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)
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

  @doc false
  @spec put_stable_link_dir(String.t() | nil) :: :ok
  def put_stable_link_dir(dir) when is_binary(dir) do
    Process.put(@stable_link_dir_override_key, dir)
    :ok
  end

  def put_stable_link_dir(nil) do
    Process.delete(@stable_link_dir_override_key)
    :ok
  end

  defp ordered_pairs(%{raw: raw}) when is_map(raw) do
    raw
    |> Enum.map(fn {key, value} -> {key, value} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  defp command_runner(opts) do
    Keyword.get(opts, :command_runner) ||
      Process.get(@command_runner_override_key) ||
      Application.get_env(:cerberus, :install_command_runner, &System.cmd/3)
  end

  defp stable_link_dir(opts) do
    Keyword.get(opts, :stable_link_dir) ||
      Process.get(@stable_link_dir_override_key) ||
      Application.get_env(:cerberus, :install_stable_link_dir, "tmp")
  end

  defp ensure_stable_symlinks(%{binaries: binaries}, opts) when is_map(binaries) do
    stable_link_dir = stable_link_dir(opts)

    with :ok <- ensure_stable_link_dir(stable_link_dir) do
      ensure_stable_link_targets(binaries, stable_link_dir)
    end
  end

  defp ensure_stable_link_dir(stable_link_dir) when is_binary(stable_link_dir) do
    case File.mkdir_p(stable_link_dir) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "failed to create stable link dir #{stable_link_dir}: #{:file.format_error(reason)}"}
    end
  end

  defp ensure_stable_link_targets(binaries, stable_link_dir) when is_map(binaries) do
    Enum.reduce_while(
      [
        {Path.join(stable_link_dir, "chrome-current"), binaries.chrome_binary},
        {Path.join(stable_link_dir, "chromedriver-current"), binaries.chromedriver_binary}
      ],
      :ok,
      fn {link_path, target_path}, :ok ->
        link_path
        |> replace_stable_symlink(target_path)
        |> stable_link_replace_result()
      end
    )
  end

  defp stable_link_replace_result(:ok), do: {:cont, :ok}
  defp stable_link_replace_result({:error, reason}), do: {:halt, {:error, reason}}

  defp replace_stable_symlink(link_path, target_path) when is_binary(link_path) and is_binary(target_path) do
    expanded_link = Path.expand(link_path)
    expanded_target = Path.expand(target_path)

    _ = File.rm_rf(expanded_link)

    case File.ln_s(expanded_target, expanded_link) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error,
         "failed to create stable browser symlink #{expanded_link} -> #{expanded_target}: #{:file.format_error(reason)}"}
    end
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

  defp parse_payload(values) when is_map(values) do
    required_keys = ["chrome_binary", "chrome_version", "chromedriver_binary", "chromedriver_version"]
    missing = Enum.reject(required_keys, &valid_key_value?(values, &1))

    if missing == [] do
      {:ok,
       %{
         browser: :chrome,
         binaries: %{
           chrome_binary: values["chrome_binary"],
           chromedriver_binary: values["chromedriver_binary"]
         },
         versions: %{
           chrome_version: values["chrome_version"],
           chromedriver_version: values["chromedriver_version"]
         },
         raw: Map.take(values, required_keys)
       }}
    else
      {:error, "installer output missing keys #{inspect(missing)}; received #{inspect(Map.keys(values))}"}
    end
  end

  defp valid_key_value?(values, key) when is_map(values) and is_binary(key) do
    case Map.get(values, key) do
      value when is_binary(value) -> String.trim(value) != ""
      _ -> false
    end
  end

  defp script_args(opts) do
    case Keyword.get(opts, :version) do
      value when is_binary(value) and value != "" -> ["--version", value]
      _ -> []
    end
  end

  defp installer_script_path do
    root = Mix.Project.deps_paths()[:cerberus] || local_project_root()
    candidate = Path.expand("bin/chrome.sh", root)

    if File.exists?(candidate) do
      {:ok, candidate}
    else
      {:error, "installer script not found: #{candidate}"}
    end
  end

  defp local_project_root do
    Path.dirname(Mix.Project.project_file())
  end
end
