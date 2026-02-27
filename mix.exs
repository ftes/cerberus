defmodule Cerberus.MixProject do
  use Mix.Project

  def project do
    [
      app: :cerberus,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      cli: cli(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:websockex, "~> 0.4.3"},
      {:floki, "~> 0.38"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test}
    ]
  end

  defp aliases do
    [
      precommit: ["format --check-formatted", "test"]
    ]
  end

  defp cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
