Code.require_file("../test/test_helper.exs", __DIR__)

defmodule Cerberus.Bench.BrowserLocatorAssertionPaths do
  @moduledoc false

  import Cerberus
  import Cerberus.Browser, only: [evaluate_js: 2]

  @targets %{
    text: "Bench text target",
    label: "Bench label target",
    link: "Bench link target",
    button: "Bench button target",
    placeholder: "Bench placeholder target",
    title: "Bench title target",
    alt: "Bench alt target",
    testid: "bench-target-testid"
  }

  def run(args \\ []) do
    opts = parse_args(args)

    session =
      :browser
      |> session()
      |> visit("/live/selector-edge")

    Enum.each(opts.sizes, fn size ->
      session = inject_dom!(session, size)

      IO.puts("\nDOM size #{size} (iterations=#{opts.iterations}, warmup=#{opts.warmup})")
      IO.puts("scenario      median(ms)  p95(ms)   mean(ms)")

      Enum.each(scenarios(), fn {name, run_scenario} ->
        metrics = time_scenario(session, run_scenario, opts.iterations, opts.warmup)

        "~-12s ~8.3f    ~8.3f   ~8.3f"
        |> :io_lib.format([
          Atom.to_string(name),
          metrics.median_ms,
          metrics.p95_ms,
          metrics.mean_ms
        ])
        |> to_string()
        |> IO.puts()
      end)
    end)
  end

  defp scenarios do
    [
      {:text, fn session -> assert_has(session, text(@targets.text, exact: true)) end},
      {:label, fn session -> assert_has(session, label(@targets.label, exact: true)) end},
      {:link, fn session -> assert_has(session, link(@targets.link, exact: true)) end},
      {:button, fn session -> assert_has(session, button(@targets.button, exact: true)) end},
      {:placeholder, fn session -> assert_has(session, placeholder(@targets.placeholder, exact: true)) end},
      {:title, fn session -> assert_has(session, title(@targets.title, exact: true)) end},
      {:alt, fn session -> assert_has(session, alt(@targets.alt, exact: true)) end},
      {:testid, fn session -> assert_has(session, testid(@targets.testid)) end}
    ]
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [sizes: :string, iterations: :integer, warmup: :integer]
      )

    %{
      sizes: parse_sizes(parsed[:sizes]),
      iterations: parsed[:iterations] || 20,
      warmup: parsed[:warmup] || 5
    }
  end

  defp parse_sizes(nil), do: [200, 1_000, 3_000]

  defp parse_sizes(value) when is_binary(value) do
    parsed =
      value
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.map(&Integer.parse/1)
      |> Enum.flat_map(fn
        {number, ""} when number > 0 -> [number]
        _ -> []
      end)

    if parsed == [], do: [200, 1_000, 3_000], else: parsed
  end

  defp inject_dom!(session, size) do
    payload = JSON.encode!(%{size: size, targets: @targets})

    expression =
      """
      (() => {
        const data = #{payload};
        const { size, targets } = data;

        const rootId = "__cerberus-bench-root";
        let root = document.getElementById(rootId);

        if (!root) {
          root = document.createElement("section");
          root.id = rootId;
          document.body.appendChild(root);
        }

        const rows = [];

        for (let i = 0; i < size; i++) {
          rows.push(`
            <div class="bench-row" data-row="${i}">
              <span>noise text ${i}</span>
              <label for="bench_input_${i}">noise label ${i}</label>
              <input id="bench_input_${i}" placeholder="noise placeholder ${i}" title="noise title ${i}" />
              <a href="/noise/${i}">noise link ${i}</a>
              <button type="button">noise button ${i}</button>
              <img alt="noise alt ${i}" src="data:image/gif;base64,R0lGODlhAQABAAAAACw=" />
              <div data-testid="noise-testid-${i}">noise testid ${i}</div>
            </div>
          `);
        }

        rows.push(`
          <div class="bench-targets">
            <span>${targets.text}</span>
            <label for="bench_target_input">${targets.label}</label>
            <input id="bench_target_input" placeholder="${targets.placeholder}" title="${targets.title}" />
            <a href="/bench-target-link">${targets.link}</a>
            <button type="button">${targets.button}</button>
            <img alt="${targets.alt}" src="data:image/gif;base64,R0lGODlhAQABAAAAACw=" />
            <div data-testid="${targets.testid}">target testid node</div>
          </div>
        `);

        root.innerHTML = rows.join("");
        return true;
      })()
      """

    case evaluate_js(session, expression) do
      true -> session
      other -> raise "failed to inject benchmark DOM: #{inspect(other)}"
    end
  end

  defp time_scenario(session, run_scenario, iterations, warmup) do
    Enum.each(1..warmup, fn _ ->
      _ = run_scenario.(session)
    end)

    samples =
      Enum.map(1..iterations, fn _ ->
        {us, _} = :timer.tc(fn -> run_scenario.(session) end)
        us / 1_000.0
      end)

    sorted = Enum.sort(samples)

    %{
      median_ms: percentile(sorted, 0.5),
      p95_ms: percentile(sorted, 0.95),
      mean_ms: Enum.sum(samples) / max(length(samples), 1)
    }
  end

  defp percentile([], _pct), do: 0.0

  defp percentile(samples, pct) do
    index =
      samples
      |> length()
      |> Kernel.*(pct)
      |> Float.ceil()
      |> trunc()
      |> max(1)
      |> Kernel.-(1)
      |> min(length(samples) - 1)

    Enum.at(samples, index)
  end
end

Cerberus.Bench.BrowserLocatorAssertionPaths.run(System.argv())
