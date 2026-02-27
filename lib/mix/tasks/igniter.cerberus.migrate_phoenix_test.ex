defmodule Mix.Tasks.Igniter.Cerberus.MigratePhoenixTest do
  @moduledoc """
  Migrates PhoenixTest test files to Cerberus in a safe, preview-first workflow.

  By default this task runs in dry-run mode and prints a diff for each changed file.
  Use `--write` to apply changes.

      mix igniter.cerberus.migrate_phoenix_test
      mix igniter.cerberus.migrate_phoenix_test --write test/my_app_web/features
  """

  @switches [
    write: :boolean,
    dry_run: :boolean
  ]

  @default_globs [
    "test/**/*_test.exs",
    "test/**/*_test.ex"
  ]

  @safe_rewrites [
    {~r/\bimport\s+PhoenixTest\b/, "import Cerberus"},
    {~r/\buse\s+PhoenixTest\b/, "use Cerberus"},
    {~r/\balias\s+PhoenixTest\b(?!\.)/, "alias Cerberus"}
  ]

  @unsupported_patterns [
    {~r/\bPhoenixTest\.Playwright\b/,
     "PhoenixTest.Playwright calls need manual migration to browser-only Cerberus APIs."},
    {~r/\bimport\s+PhoenixTest\.TestHelpers\b/,
     "PhoenixTest.TestHelpers import has no direct Cerberus equivalent and needs manual migration."},
    {~r/\balias\s+PhoenixTest\.[A-Z][\w.]*/,
     "PhoenixTest submodule alias detected; verify Cerberus module equivalents manually."},
    {~r/\bPhoenixTest\.[a-z_]+\s*\(/,
     "Direct PhoenixTest.<function> call detected; migrate to Cerberus session-first flow manually."},
    {~r/\bconn\s*\|>\s*visit\s*\(/, "conn |> visit(...) PhoenixTest flow needs manual session bootstrap in Cerberus."},
    {~r/\bvisit\s*\(\s*conn\b/, "visit(conn, ...) PhoenixTest flow needs manual session bootstrap in Cerberus."},
    {~r/\b(with_dialog|screenshot|press|type|drag|cookie|session_cookie)\s*\(/,
     "Browser helper call likely needs manual migration to Cerberus browser extensions."}
  ]

  def run(args) do
    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      raise ArgumentError, "invalid options: #{inspect(invalid)}"
    end

    dry_run = resolve_dry_run(opts)
    files = migration_targets(positional)

    if files == [] do
      IO.puts("No candidate test files found.")
    else
      {changed_count, warning_count} =
        Enum.reduce(files, {0, 0}, fn file, {changed_acc, warning_acc} ->
          migrate_file(file, dry_run, changed_acc, warning_acc)
        end)

      IO.puts("\nMigration summary:")
      IO.puts("  Files scanned: #{length(files)}")
      IO.puts("  Files changed: #{changed_count}")
      IO.puts("  Warnings: #{warning_count}")
      IO.puts("  Mode: #{if dry_run, do: "dry-run", else: "write"}")
    end
  end

  defp resolve_dry_run(opts) do
    cond do
      Keyword.get(opts, :write, false) -> false
      Keyword.has_key?(opts, :dry_run) -> Keyword.fetch!(opts, :dry_run)
      true -> true
    end
  end

  defp migration_targets([]) do
    @default_globs
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp migration_targets(paths) do
    paths
    |> Enum.flat_map(&expand_target/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expand_target(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        Path.wildcard(Path.join(path, "**/*.{ex,exs}"))

      true ->
        Path.wildcard(path)
    end
  end

  defp migrate_file(file, dry_run, changed_acc, warning_acc) do
    original = File.read!(file)
    rewritten = rewrite_safe(original)
    warnings = collect_warnings(original)

    warning_count = warning_acc + length(warnings)
    print_warnings(file, warnings)

    if rewritten == original do
      {changed_acc, warning_count}
    else
      if dry_run do
        print_diff(file, original, rewritten)
      else
        File.write!(file, rewritten)
        IO.puts("updated #{file}")
      end

      {changed_acc + 1, warning_count}
    end
  end

  defp rewrite_safe(content) do
    Enum.reduce(@safe_rewrites, content, fn {pattern, replacement}, acc ->
      Regex.replace(pattern, acc, replacement)
    end)
  end

  defp collect_warnings(content) do
    Enum.flat_map(@unsupported_patterns, fn {pattern, message} ->
      if Regex.match?(pattern, content) do
        [message]
      else
        []
      end
    end)
  end

  defp print_warnings(_file, []), do: :ok

  defp print_warnings(file, warnings) do
    Enum.each(warnings, fn warning ->
      IO.puts("WARNING #{file}: #{warning}")
    end)
  end

  defp print_diff(file, _original, rewritten) do
    tmp = Path.join(System.tmp_dir!(), "cerberus-migrate-#{System.unique_integer([:positive])}.tmp")
    File.write!(tmp, rewritten)

    {output, _status} =
      System.cmd("git", ["diff", "--no-index", "--", file, tmp], stderr_to_stdout: true)

    output |> String.replace(tmp, file <> ".migrated") |> IO.write()
    File.rm(tmp)

    :ok
  end
end
