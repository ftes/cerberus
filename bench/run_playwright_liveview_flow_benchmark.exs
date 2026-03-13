Code.require_file("../test/test_helper.exs", __DIR__)

defmodule Cerberus.Bench.RunPlaywrightLiveViewFlow do
  @moduledoc false

  alias Cerberus.Fixtures.Endpoint

  def run(args \\ []) do
    opts = parse_args(args)

    env = [
      {"BASE_URL", Endpoint.url()},
      {"CHROME", System.fetch_env!("CHROME")},
      {"ITERATIONS", Integer.to_string(opts.iterations)},
      {"WARMUP", Integer.to_string(opts.warmup)}
    ]

    {_, exit_code} =
      System.cmd(
        "mise",
        [
          "exec",
          "nodejs@24.13.0",
          "--",
          "node",
          Path.expand("playwright_liveview_flow_benchmark.js", __DIR__)
        ],
        env: env,
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    if exit_code != 0 do
      raise "Playwright benchmark failed with exit code #{exit_code}"
    end
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [iterations: :integer, warmup: :integer]
      )

    %{
      iterations: parsed[:iterations] || 10,
      warmup: parsed[:warmup] || 2
    }
  end
end

Cerberus.Bench.RunPlaywrightLiveViewFlow.run(System.argv())
