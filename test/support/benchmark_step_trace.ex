defmodule Cerberus.TestSupport.BenchmarkStepTrace do
  @moduledoc false

  @type metadata :: %{
          runner: String.t(),
          scenario: atom(),
          worker: pos_integer()
        }

  @type context :: %{
          path: String.t(),
          runner: String.t(),
          scenario: String.t(),
          worker: pos_integer()
        }

  @spec build_context(metadata() | nil, keyword()) :: context() | nil
  def build_context(nil, _opts), do: nil

  def build_context(%{runner: runner, scenario: scenario, worker: worker}, opts)
      when is_binary(runner) and is_atom(scenario) and is_integer(worker) and worker > 0 do
    path = Keyword.get(opts, :path, System.get_env("CERBERUS_BENCH_STEP_TRACE_PATH"))

    if is_binary(path) and path != "" do
      File.mkdir_p!(Path.dirname(path))

      %{
        path: path,
        runner: runner,
        scenario: Atom.to_string(scenario),
        worker: worker
      }
    end
  end

  @spec step(subject, context() | nil, atom(), (subject -> subject)) :: subject when subject: var
  def step(subject, nil, _step, fun), do: fun.(subject)

  def step(subject, context, step, fun) when is_atom(step) do
    started = System.monotonic_time(:microsecond)
    result = fun.(subject)
    duration_ms = duration_ms(started, System.monotonic_time(:microsecond))

    record_step(context, step, duration_ms)
    result
  end

  defp duration_ms(started, finished) when finished >= started do
    Float.round((finished - started) / 1_000, 3)
  end

  defp record_step(context, step, duration_ms) do
    line =
      [
        context.runner,
        context.scenario,
        Integer.to_string(context.worker),
        Atom.to_string(step),
        :erlang.float_to_binary(duration_ms, decimals: 3)
      ]
      |> Enum.join(",")
      |> Kernel.<>("\n")

    File.write!(context.path, line, [:append])
  end
end
