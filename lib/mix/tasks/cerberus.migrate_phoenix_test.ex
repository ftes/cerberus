defmodule Mix.Tasks.Cerberus.MigratePhoenixTest do
  @moduledoc """
  Migrates PhoenixTest test files to Cerberus in a preview-first workflow.

  By default this task runs in dry-run mode and prints a diff for each changed file.
  Use `--write` to apply changes.

      mix cerberus.migrate_phoenix_test
      mix cerberus.migrate_phoenix_test --write test/my_app_web/features
  """

  @switches [
    write: :boolean,
    dry_run: :boolean
  ]

  @default_globs [
    "test/**/*_test.exs",
    "test/**/*_test.ex"
  ]

  @warning_test_helpers "PhoenixTest.TestHelpers import has no direct Cerberus equivalent and needs manual migration."

  @warning_submodule_alias "PhoenixTest submodule alias detected; verify Cerberus module equivalents manually."
  @warning_direct_call "Direct PhoenixTest.<function> call detected; migrate to Cerberus session-first flow manually."
  @warning_conn_pipe "conn |> visit(...) PhoenixTest flow needs manual session bootstrap in Cerberus."
  @warning_visit_conn "visit(conn, ...) PhoenixTest flow needs manual session bootstrap in Cerberus."
  @warning_browser_helper "Browser helper call likely needs manual migration to Cerberus browser extensions."
  @browser_helpers [:with_dialog, :screenshot, :press, :type, :drag, :cookie, :session_cookie]
  @rewritable_direct_calls [
    :assert_has,
    :refute_has,
    :click,
    :click_link,
    :click_button,
    :fill_in,
    :select,
    :choose,
    :check,
    :uncheck,
    :submit,
    :upload,
    :assert_path,
    :refute_path,
    :within,
    :unwrap,
    :open_browser
  ]
  @rewritable_assertions_calls [:assert_has, :refute_has, :assert_path, :refute_path]

  defmodule RewriteState do
    @moduledoc false
    defstruct changed?: false, warnings: [], seen: MapSet.new()
  end

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
    {rewritten, warnings} = rewrite_with_ast(original)

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

  defp rewrite_with_ast(content) do
    case Code.string_to_quoted(content, token_metadata: true, columns: true) do
      {:ok, ast} ->
        {rewritten_ast, state} = Macro.prewalk(ast, %RewriteState{}, &rewrite_node/2)

        rewritten =
          if state.changed? do
            rewritten_ast
            |> Macro.to_string()
            |> Code.format_string!()
            |> IO.iodata_to_binary()
          else
            content
          end

        {rewritten, Enum.reverse(state.warnings)}

      {:error, {_line, error, _token}} ->
        {content, ["Could not parse file for AST migration: #{error}"]}
    end
  end

  defp rewrite_node({:import, meta, args} = node, state) do
    case args do
      [module_ast | rest] ->
        case alias_parts(module_ast) do
          [:PhoenixTest] ->
            updated = {:import, meta, [alias_ast(module_ast, [:Cerberus]) | rest]}
            {updated, mark_changed(state)}

          [:PhoenixTest, :Assertions] ->
            updated = {:import, meta, [alias_ast(module_ast, [:Cerberus]) | rest]}
            {updated, mark_changed(state)}

          [:PhoenixTest, :TestHelpers] ->
            {node, add_warning(state, @warning_test_helpers)}

          [:PhoenixTest | _] ->
            {node, add_warning(state, @warning_submodule_alias)}

          _ ->
            {node, state}
        end

      _ ->
        {node, state}
    end
  end

  defp rewrite_node({:use, meta, args} = node, state) do
    case args do
      [module_ast | rest] ->
        case alias_parts(module_ast) do
          [:PhoenixTest] ->
            updated = {:use, meta, [alias_ast(module_ast, [:Cerberus]) | rest]}
            {updated, mark_changed(state)}

          [:PhoenixTest | _] ->
            {node, add_warning(state, @warning_submodule_alias)}

          _ ->
            {node, state}
        end

      _ ->
        {node, state}
    end
  end

  defp rewrite_node({:alias, meta, args} = node, state) do
    case args do
      [module_ast | rest] ->
        case alias_parts(module_ast) do
          [:PhoenixTest] ->
            updated = {:alias, meta, [alias_ast(module_ast, [:Cerberus]) | rest]}
            {updated, mark_changed(state)}

          [:PhoenixTest | _] ->
            {node, add_warning(state, @warning_submodule_alias)}

          _ ->
            {node, state}
        end

      _ ->
        {node, state}
    end
  end

  defp rewrite_node({:|>, _meta, [lhs, rhs]} = node, state) do
    next_state =
      if conn_arg?(lhs) and visit_call?(rhs) do
        add_warning(state, @warning_conn_pipe)
      else
        state
      end

    {node, next_state}
  end

  defp rewrite_node({{:., _dot_meta, [module_ast, fun]}, _call_meta, args} = node, state)
       when is_atom(fun) and is_list(args) do
    state_with_warnings =
      state
      |> maybe_warn_browser_helper(fun)
      |> maybe_warn_visit_conn(fun, args)

    rewrite_remote_call(node, module_ast, fun, args, state_with_warnings)
  end

  defp rewrite_node({fun, _meta, args} = node, state) when is_atom(fun) and is_list(args) do
    next_state =
      state
      |> maybe_warn_browser_helper(fun)
      |> maybe_warn_visit_conn(fun, args)

    {node, next_state}
  end

  defp rewrite_node(node, state), do: {node, state}

  defp alias_parts({:__aliases__, _meta, parts}) when is_list(parts), do: parts
  defp alias_parts(_module_ast), do: :unknown

  defp alias_ast({:__aliases__, meta, _parts}, parts), do: {:__aliases__, meta, parts}
  defp alias_ast(_module_ast, parts), do: {:__aliases__, [], parts}

  defp rewrite_remote_call(node, module_ast, fun, args, state) do
    case alias_parts(module_ast) do
      [:PhoenixTest] ->
        rewrite_phoenix_test_remote_call(node, module_ast, fun, args, state)

      [:PhoenixTest, :Assertions] ->
        rewrite_assertions_remote_call(node, module_ast, fun, state)

      [:PhoenixTest | _] ->
        {node, add_warning(state, @warning_submodule_alias)}

      _ ->
        {node, state}
    end
  end

  defp rewrite_remote_module({{:., dot_meta, [module_ast, fun]}, call_meta, args}, module_ast, parts) do
    {{:., dot_meta, [alias_ast(module_ast, parts), fun]}, call_meta, args}
  end

  defp rewrite_phoenix_test_remote_call(node, module_ast, fun, args, state) do
    cond do
      fun in @browser_helpers ->
        {node, state}

      fun == :visit and conn_first_arg?(args) ->
        {node, state}

      fun in @rewritable_direct_calls ->
        {rewrite_remote_module(node, module_ast, [:Cerberus]), mark_changed(state)}

      true ->
        {node, add_warning(state, @warning_direct_call)}
    end
  end

  defp rewrite_assertions_remote_call(node, module_ast, fun, state) do
    if fun in @rewritable_assertions_calls do
      {rewrite_remote_module(node, module_ast, [:Cerberus]), mark_changed(state)}
    else
      {node, add_warning(state, @warning_submodule_alias)}
    end
  end

  defp maybe_warn_browser_helper(state, fun) when fun in @browser_helpers, do: add_warning(state, @warning_browser_helper)
  defp maybe_warn_browser_helper(state, _fun), do: state

  defp maybe_warn_visit_conn(state, :visit, [first | _rest]) do
    if conn_arg?(first), do: add_warning(state, @warning_visit_conn), else: state
  end

  defp maybe_warn_visit_conn(state, _fun, _args), do: state

  defp conn_first_arg?([first | _rest]), do: conn_arg?(first)
  defp conn_first_arg?(_args), do: false

  defp visit_call?({:visit, _meta, args}) when is_list(args), do: true
  defp visit_call?({{:., _meta, [_module_ast, :visit]}, _call_meta, args}) when is_list(args), do: true
  defp visit_call?(_other), do: false

  defp conn_arg?({:conn, _meta, context}) when is_atom(context) or is_nil(context), do: true
  defp conn_arg?(_other), do: false

  defp mark_changed(%RewriteState{} = state), do: %{state | changed?: true}

  defp add_warning(%RewriteState{} = state, warning) do
    if MapSet.member?(state.seen, warning) do
      state
    else
      %{state | warnings: [warning | state.warnings], seen: MapSet.put(state.seen, warning)}
    end
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
