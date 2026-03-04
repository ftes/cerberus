defmodule Mix.Tasks.Cerberus.Install.Firefox do
  @shortdoc "Installs Firefox + GeckoDriver runtime binaries for Cerberus"
  @moduledoc """
  Installs Firefox and GeckoDriver runtime binaries, then prints a stable
  output payload for downstream config handoff.

      mix cerberus.install.firefox
      mix cerberus.install.firefox --firefox-version 148.0 --geckodriver-version 0.36.0
  """

  use Mix.Task

  alias Cerberus.Browser.Install

  @switches [firefox_version: :string, geckodriver_version: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    install_opts =
      []
      |> maybe_put_opt(:firefox_version, opts[:firefox_version])
      |> maybe_put_opt(:geckodriver_version, opts[:geckodriver_version])

    case Install.install(:firefox, install_opts) do
      {:ok, payload} ->
        payload
        |> Install.render()
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
end
