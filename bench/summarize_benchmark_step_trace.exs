path =
  case System.argv() do
    [value] -> value
    _ -> raise ArgumentError, "usage: mix run bench/summarize_benchmark_step_trace.exs <trace-path>"
  end

lines =
  path
  |> File.read!()
  |> String.split("\n", trim: true)

entries =
  Enum.map(lines, fn line ->
    case String.split(line, ",", parts: 5) do
      [runner, scenario, worker, step, duration_ms] ->
        %{
          runner: runner,
          scenario: scenario,
          worker: String.to_integer(worker),
          step: step,
          duration_ms: String.to_float(duration_ms)
        }

      _ ->
        raise ArgumentError, "invalid trace line #{inspect(line)}"
    end
  end)

grouped =
  Enum.group_by(entries, fn entry -> {entry.runner, entry.scenario, entry.step} end)

IO.puts("runner,scenario,step,count,mean_ms,max_ms")

grouped
|> Enum.sort_by(fn {{runner, scenario, step}, _entries} -> {runner, scenario, step} end)
|> Enum.each(fn {{runner, scenario, step}, step_entries} ->
  durations = Enum.map(step_entries, & &1.duration_ms)
  count = length(durations)
  mean_ms = Enum.sum(durations) / count
  max_ms = Enum.max(durations)

  IO.puts(
    Enum.join(
      [
        runner,
        scenario,
        step,
        Integer.to_string(count),
        :erlang.float_to_binary(mean_ms, decimals: 3),
        :erlang.float_to_binary(max_ms, decimals: 3)
      ],
      ","
    )
  )
end)
