defmodule Cerberus.MixProject do
  use Mix.Project

  @version "0.1.4"
  @source_url "https://github.com/ftes/cerberus"

  def project do
    [
      app: :cerberus,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      cli: cli(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:ex_unit, :mix]],
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
      {:phoenix_ecto, "~> 4.6", optional: true},
      {:ecto_sql, "~> 3.13", optional: true},
      {:postgrex, "~> 0.19", optional: true},
      {:lazy_html, ">= 0.1.0"},
      {:nimble_options, "~> 1.1"},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --warnings-as-errors"],
      precommit: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer",
        "docs --warnings-as-errors --formatter html"
      ]
    ]
  end

  defp cli do
    [
      preferred_envs: [
        "test.websocket": :test,
        test: :test,
        dialyzer: :test,
        precommit: :test
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "docs/getting-started.md",
        "docs/cheatsheet.md",
        "docs/architecture.md",
        "docs/browser-support-policy.md"
      ],
      groups_for_extras: [
        Guides: [
          "docs/getting-started.md",
          "docs/architecture.md",
          "docs/browser-support-policy.md"
        ],
        Reference: ["docs/cheatsheet.md"]
      ],
      source_url: @source_url,
      source_ref: "v#{@version}",
      homepage_url: @source_url,
      assets: %{"docs" => "docs"},
      logo: "docs/icon.png",
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(:epub), do: ""

  defp description do
    "Phoenix test harness with one API across static, LiveView, and browser drivers"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      },
      files: ~w(lib bin mix.exs README* LICENSE*)
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
