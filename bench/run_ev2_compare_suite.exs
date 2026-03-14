defmodule Cerberus.Bench.RunEv2CompareSuite do
  @moduledoc false

  @header [
    "lane",
    "file",
    "status",
    "tests",
    "failures",
    "exunit_seconds",
    "wall_seconds",
    "note"
  ]

  @default_root "/Users/ftes/src/ev2-copy"
  @default_lanes ["original", "copy"]
  @default_timeout_sec 180

  @type lane :: :original | :copy

  def run(args \\ []) do
    opts = parse_args(args)
    init_output(opts)
    emit_row(opts, Enum.join(@header, ","))

    results = Enum.map(opts.lanes, &run_lane(&1, opts))

    IO.puts("")
    Enum.each(results, &print_lane_summary/1)

    if Enum.any?(results, &Enum.any?(&1.entries, fn entry -> entry.status != :ok end)) do
      raise "EV2 compare suite completed with failing or timed out files"
    end
  end

  defp parse_args(args) do
    {parsed, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          root: :string,
          lanes: :string,
          out: :string,
          max_cases: :integer,
          timeout_sec: :integer,
          search: :string,
          node_bin: :string,
          use_nix: :boolean
        ]
      )

    %{
      root: parsed[:root] || @default_root,
      lanes: parse_csv_list(parsed[:lanes], @default_lanes),
      out: parsed[:out],
      max_cases: max(parsed[:max_cases] || 4, 1),
      timeout_sec: max(parsed[:timeout_sec] || @default_timeout_sec, 1),
      search: parsed[:search],
      node_bin: parsed[:node_bin] || default_node_bin(),
      use_nix: parsed[:use_nix] || auto_use_nix?(parsed[:root] || @default_root)
    }
  end

  defp parse_csv_list(nil, default), do: default

  defp parse_csv_list(value, _default) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp init_output(%{out: nil}), do: :ok

  defp init_output(%{out: out}) do
    File.mkdir_p!(Path.dirname(out))
    File.write!(out, "")
  end

  defp run_lane(lane_name, opts) do
    lane = lane_atom!(lane_name)
    files = lane_files(lane, opts.root, opts.search)

    entries =
      Enum.map(files, fn file ->
        IO.puts("==> #{lane_name}: #{Path.relative_to(file, opts.root)}")
        entry = run_file(lane, file, opts)
        emit_row(opts, csv_row(entry))
        entry
      end)

    %{lane: lane, entries: entries}
  end

  defp lane_atom!("original"), do: :original
  defp lane_atom!("copy"), do: :copy
  defp lane_atom!(value), do: raise(ArgumentError, "unsupported lane #{inspect(value)}")

  defp lane_tag(:original), do: "cerberus_compare_original"
  defp lane_tag(:copy), do: "cerberus_compare_copy"

  defp lane_files(lane, root, search) do
    root
    |> Path.join("test/**/*.{ex,exs}")
    |> Path.wildcard()
    |> Enum.filter(fn path ->
      File.read!(path) =~ "@moduletag :#{lane_tag(lane)}"
    end)
    |> Enum.filter(fn path ->
      is_nil(search) or String.contains?(path, search)
    end)
    |> Enum.sort()
  end

  defp run_file(lane, file, opts) do
    started = System.monotonic_time(:millisecond)

    command = [
      "test",
      file,
      "--only",
      lane_tag(lane),
      "--max-cases",
      Integer.to_string(opts.max_cases)
    ]

    env = build_env(opts)
    result = run_command(opts.root, command, env, opts.timeout_sec * 1000, opts.use_nix)

    finished = System.monotonic_time(:millisecond)
    wall_seconds = (finished - started) / 1000
    relative_file = Path.relative_to(file, opts.root)

    case result do
      {:ok, output, exit_status} ->
        summarize_completed_run(lane, relative_file, output, exit_status, wall_seconds)

      {:timeout, output} ->
        %{
          lane: lane,
          file: relative_file,
          status: :timeout,
          tests: nil,
          failures: nil,
          exunit_seconds: nil,
          wall_seconds: wall_seconds,
          note: summarize_note(output, "timeout")
        }
    end
  end

  defp run_command(root, command, env, timeout_ms, use_nix) do
    {executable, args} =
      if use_nix do
        {System.find_executable("nix") || raise("could not find nix executable"), ["develop", ".", "-c", "mix" | command]}
      else
        {System.find_executable("mix") || raise("could not find mix executable"), command}
      end

    port =
      Port.open({:spawn_executable, executable}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        {:cd, root},
        {:env, env},
        {:args, args}
      ])

    deadline = System.monotonic_time(:millisecond) + timeout_ms
    collect_port_output(port, [], deadline)
  end

  defp collect_port_output(port, chunks, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} ->
        collect_port_output(port, [data | chunks], deadline)

      {^port, {:exit_status, exit_status}} ->
        {:ok, chunks_to_binary(chunks), exit_status}
    after
      timeout ->
        Port.close(port)
        {:timeout, chunks_to_binary(chunks)}
    end
  end

  defp chunks_to_binary(chunks) do
    chunks |> Enum.reverse() |> IO.iodata_to_binary()
  end

  defp build_env(opts) do
    path_entries =
      Enum.reject([opts.node_bin, Path.join(opts.root, "tmp/test-bin"), System.get_env("PATH", "")], &(&1 in [nil, ""]))

    path = Enum.join(path_entries, ":")

    [
      {~c"PATH", String.to_charlist(path)},
      {~c"PORT", Integer.to_charlist(unique_port())}
    ]
  end

  defp unique_port do
    4000 + rem(System.unique_integer([:positive, :monotonic]), 1000)
  end

  defp default_node_bin do
    case "/Users/ftes/src/cerberus/tmp/node-v*/bin" |> Path.wildcard() |> Enum.sort() |> List.last() do
      nil -> nil
      path -> path
    end
  end

  defp auto_use_nix?(root) do
    File.exists?(Path.join(root, "flake.nix")) and not is_nil(System.find_executable("nix"))
  end

  defp summarize_completed_run(lane, file, output, exit_status, wall_seconds) do
    clean_output = strip_ansi(output)

    case parse_exunit_summary(clean_output) do
      nil ->
        %{
          lane: lane,
          file: file,
          status: :no_summary,
          tests: nil,
          failures: nil,
          exunit_seconds: nil,
          wall_seconds: wall_seconds,
          note: summarize_note(clean_output, "missing_summary_exit_#{exit_status}")
        }

      summary ->
        %{
          lane: lane,
          file: file,
          status: if(exit_status == 0 and summary.failures == 0, do: :ok, else: :failed),
          tests: summary.tests,
          failures: summary.failures,
          exunit_seconds: summary.seconds,
          wall_seconds: wall_seconds,
          note: summarize_note(clean_output, "")
        }
    end
  end

  defp parse_exunit_summary(output) do
    regex =
      ~r/Finished in (?<seconds>\d+(?:\.\d+)?) seconds? \([^)]+\)\s+(?<tests>\d+) tests?, (?<failures>\d+) failures?/s

    case Regex.named_captures(regex, output) do
      %{"seconds" => seconds, "tests" => tests, "failures" => failures} ->
        %{
          seconds: String.to_float(seconds),
          tests: String.to_integer(tests),
          failures: String.to_integer(failures)
        }

      _ ->
        nil
    end
  end

  defp strip_ansi(output) do
    Regex.replace(~r/\e\[[\d;]*m/, output, "")
  end

  defp summarize_note(output, prefix) do
    suffix =
      output
      |> String.split("\n", trim: true)
      |> Enum.take(-3)
      |> Enum.join(" | ")
      |> String.replace(",", ";")

    [prefix, suffix]
    |> Enum.reject(&(&1 in ["", nil]))
    |> Enum.join(" ")
  end

  defp csv_row(entry) do
    Enum.map_join(
      [
        Atom.to_string(entry.lane),
        entry.file,
        Atom.to_string(entry.status),
        csv_number(entry.tests),
        csv_number(entry.failures),
        csv_float(entry.exunit_seconds),
        csv_float(entry.wall_seconds),
        entry.note
      ],
      ",",
      &to_string/1
    )
  end

  defp emit_row(%{out: nil}, row), do: IO.puts(row)

  defp emit_row(%{out: out}, row) do
    IO.puts(row)
    File.write!(out, row <> "\n", [:append])
  end

  defp csv_number(nil), do: ""
  defp csv_number(value), do: Integer.to_string(value)

  defp csv_float(nil), do: ""

  defp csv_float(value) do
    "~.3f" |> :io_lib.format([value]) |> IO.iodata_to_binary()
  end

  defp print_lane_summary(%{lane: lane, entries: entries}) do
    exunit_total =
      entries
      |> Enum.map(&(&1.exunit_seconds || 0.0))
      |> Enum.sum()

    wall_total =
      entries
      |> Enum.map(&(&1.wall_seconds || 0.0))
      |> Enum.sum()

    failures =
      Enum.count(entries, fn entry -> entry.status != :ok end)

    IO.puts(
      "#{lane}: files=#{length(entries)} failures=#{failures} exunit_seconds=#{csv_float(exunit_total)} wall_seconds=#{csv_float(wall_total)}"
    )
  end
end

Cerberus.Bench.RunEv2CompareSuite.run(System.argv())
