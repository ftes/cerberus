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
      dialyzer: [plt_add_apps: [:ex_unit]],
      deps: deps(),
      description: description(),
      docs: docs(),
      package: package()
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
      {:phoenix_ecto, "~> 4.6", only: :test},
      {:ecto_sql, "~> 3.13", only: :test},
      {:ecto_sqlite3, "~> 0.22", only: :test},
      {:websockex, "~> 0.4.3"},
      {:lazy_html, ">= 0.1.0"},
      {:nimble_options, "~> 1.1"},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      precommit: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end

  defp cli do
    [
      preferred_envs: [dialyzer: :test, precommit: :test]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp description do
    "Experimental Phoenix test harness with one API across static, LiveView, and browser drivers."
  end

  defp package do
    [
      name: "fluffy",
      licenses: ["MIT"],
      files: ~w(lib priv mix.exs README* LICENSE* docs)
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
