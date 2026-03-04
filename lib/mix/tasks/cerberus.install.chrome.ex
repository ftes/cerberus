defmodule Mix.Tasks.Cerberus.Install.Chrome do
  @shortdoc "Installs Chrome + ChromeDriver runtime binaries for Cerberus"
  @moduledoc """
  Installs Chrome for Testing and matching ChromeDriver, then prints a stable
  output payload for downstream config handoff.

      mix cerberus.install.chrome
      mix cerberus.install.chrome --version 146.0.7680.31
  """

  use Mix.Task

  alias Cerberus.Browser.Install

  @switches [version: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    install_opts =
      case opts[:version] do
        value when is_binary(value) and value != "" -> [version: value]
        _ -> []
      end

    case Install.install(:chrome, install_opts) do
      {:ok, payload} ->
        payload
        |> Install.render()
        |> Mix.shell().info()

      {:error, reason} ->
        Mix.raise(reason)
    end
  end
end
