defmodule Mix.Tasks.Cerberus.Install.Firefox do
  @shortdoc "Installs Firefox + GeckoDriver runtime binaries for Cerberus"
  @moduledoc """
  Installs Firefox and GeckoDriver runtime binaries, then prints a stable
  output payload for downstream config handoff.

      mix cerberus.install.firefox
      mix cerberus.install.firefox --firefox-version 148.0 --geckodriver-version 0.36.0
      mix cerberus.install.firefox --format json
      mix cerberus.install.firefox --format env
      mix cerberus.install.firefox --format shell
  """

  use Mix.Task

  alias Cerberus.Browser.Install

  @switches [firefox_version: :string, geckodriver_version: :string, format: :string]
  @formats ["plain", "json", "env", "shell"]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    format = normalize_format(opts[:format] || "plain")

    install_opts =
      []
      |> maybe_put_opt(:firefox_version, opts[:firefox_version])
      |> maybe_put_opt(:geckodriver_version, opts[:geckodriver_version])

    case Install.install(:firefox, install_opts) do
      {:ok, payload} ->
        payload
        |> Install.render(format)
        |> Mix.shell().info()

      {:error, reason} ->
        Mix.raise(reason)
    end
  end

  defp maybe_put_opt(opts, _key, nil), do: opts

  defp maybe_put_opt(opts, key, value) when is_binary(value) and value != "" do
    Keyword.put(opts, key, value)
  end

  defp maybe_put_opt(opts, _key, _value), do: opts

  defp normalize_format(format) when is_binary(format) do
    normalized = format |> String.trim() |> String.downcase()

    case normalized do
      "plain" -> :plain
      "json" -> :json
      "env" -> :env
      "shell" -> :shell
      _ -> Mix.raise("unsupported format #{inspect(format)}; expected one of: #{Enum.join(@formats, ", ")}")
    end
  end
end
