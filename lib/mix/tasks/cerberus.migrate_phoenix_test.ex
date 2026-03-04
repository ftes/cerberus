defmodule Mix.Tasks.Cerberus.MigratePhoenixTest do
  @shortdoc "Migrates PhoenixTest test files to Cerberus"
  @example "mix cerberus.migrate_phoenix_test --write test/my_app_web/features"

  @moduledoc """
  #{@shortdoc} in a preview-first workflow.

  By default this task runs in dry-run mode.
  Use `--write` to apply changes.

      mix cerberus.migrate_phoenix_test
      #{@example}
  """

  use Igniter.Mix.Task

  alias Rewrite.Source

  @type run_option :: {:write, boolean()} | {:dry_run, boolean()}
  @type run_opts :: [run_option()]
  @type migration_summary :: %{
          files_scanned: non_neg_integer(),
          files_changed: non_neg_integer(),
          warnings: non_neg_integer()
        }
  @type migration_result :: {term(), boolean(), non_neg_integer()}
  @type warning_messages :: [String.t()]
  @type canonicalize_result :: {:ok, [Macro.t()]} | :no_change
  @type split_args_result :: {:ok, [Macro.t()], term(), keyword() | :none} | :error

  @switches [
    write: :boolean,
    dry_run: :boolean
  ]

  @run_opts_schema [
    write: [type: :boolean],
    dry_run: [type: :boolean]
  ]

  @default_globs [
    "test/**/*_test.exs",
    "test/**/*_test.ex"
  ]
  @default_setup_files ["config/test.exs", "test/test_helper.exs"]
  @relative_setup_files @default_setup_files

  @warning_test_helpers "PhoenixTest.TestHelpers import has no direct Cerberus equivalent and needs manual migration."
  @warning_use_phoenix_test "use PhoenixTest has no direct Cerberus equivalent and needs manual migration."

  @warning_submodule_alias "PhoenixTest submodule alias detected; verify Cerberus module equivalents manually."
  @warning_direct_call "Direct PhoenixTest.<function> call detected; migrate to Cerberus session-first flow manually."
  @warning_browser_helper "Browser helper call likely needs manual migration to Cerberus browser extensions."
  @browser_helpers [:with_dialog, :with_popup, :screenshot, :press, :type, :drag, :cookie, :session_cookie]
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
    :visit,
    :open_browser
  ]
  @rewritable_assertions_calls [:assert_has, :refute_has, :assert_path, :refute_path]
  @canonical_text_assertions [:assert_has, :refute_has]
  @canonical_labeled_value_keys %{fill_in: :with}
  @explicit_locator_calls [
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
    :upload
  ]
  @label_locator_variable_calls [:fill_in, :select, :choose, :check, :uncheck, :upload]
  @locator_helper_funs [
    :text,
    :label,
    :link,
    :button,
    :placeholder,
    :title,
    :alt,
    :aria_label,
    :css,
    :testid,
    :role,
    :and_,
    :or_,
    :not_,
    :has,
    :has_not,
    :closest
  ]
  @locator_kind_keys [
    :text,
    :label,
    :link,
    :button,
    :placeholder,
    :title,
    :alt,
    :aria_label,
    :css,
    :testid,
    :role,
    :and,
    :or,
    :not
  ]

  defmodule RewriteState do
    @moduledoc false
    @type t :: %__MODULE__{changed?: boolean(), warnings: [String.t()], seen: MapSet.t(String.t())}
    defstruct changed?: false, warnings: [], seen: MapSet.new()
  end

  @impl Igniter.Mix.Task
  def info(_argv, _source) do
    %Igniter.Mix.Task.Info{
      group: :cerberus,
      example: @example,
      schema: @switches,
      defaults: [write: false],
      extra_args?: true
    }
  end

  @impl Mix.Task
  @spec run([String.t()]) :: :ok
  def run(args) do
    {opts, positional} = parse_run_opts!(args)

    dry_run = resolve_dry_run(opts)
    files = migration_targets(positional)

    Mix.Task.run("compile")
    Application.ensure_all_started(:rewrite)

    igniter =
      Igniter.new()
      |> Map.put(:task, Mix.Task.task_name(__MODULE__))
      |> Igniter.assign(:cerberus_migration_files, files)
      |> Igniter.assign(:cerberus_migration_dry_run, dry_run)
      |> Igniter.Mix.Task.configure_and_run(__MODULE__, args)

    if !dry_run do
      _ =
        Igniter.do_or_dry_run(
          igniter,
          dry_run: false,
          yes: true,
          quiet_on_no_changes?: true,
          title: "Cerberus migration"
        )
    end

    summary = igniter.assigns[:cerberus_migration_summary]
    print_summary(summary.files_scanned, summary.files_changed, summary.warnings, dry_run)
    :ok
  end

  @spec parse_run_opts!([String.t()]) :: {run_opts(), [String.t()]}
  defp parse_run_opts!(args) do
    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      raise ArgumentError, "invalid options: #{inspect(invalid)}"
    end

    {NimbleOptions.validate!(opts, @run_opts_schema), positional}
  end

  @impl Igniter.Mix.Task
  @spec igniter(term()) :: term()
  def igniter(igniter) do
    files = igniter.assigns[:cerberus_migration_files] || []
    dry_run = Map.get(igniter.assigns, :cerberus_migration_dry_run, true)

    if files == [] do
      IO.puts("No candidate test files found.")
      Igniter.assign(igniter, :cerberus_migration_summary, %{files_scanned: 0, files_changed: 0, warnings: 0})
    else
      {igniter, changed_count, warning_count} =
        Enum.reduce(files, {igniter, 0, 0}, fn file, acc ->
          reduce_migrated_file(file, acc, dry_run)
        end)

      Igniter.assign(igniter, :cerberus_migration_summary, %{
        files_scanned: length(files),
        files_changed: changed_count,
        warnings: warning_count
      })
    end
  end

  @spec reduce_migrated_file(String.t(), {term(), non_neg_integer(), non_neg_integer()}, boolean()) ::
          {term(), non_neg_integer(), non_neg_integer()}
  defp reduce_migrated_file(file, {igniter, changed_acc, warning_acc}, dry_run) do
    {next_igniter, changed?, file_warning_count} = migrate_file(igniter, file, dry_run)

    {next_igniter, changed_acc + changed_to_count(changed?), warning_acc + file_warning_count}
  end

  @spec changed_to_count(boolean()) :: 0 | 1
  defp changed_to_count(true), do: 1
  defp changed_to_count(false), do: 0

  @spec resolve_dry_run(run_opts()) :: boolean()
  defp resolve_dry_run(opts) do
    cond do
      Keyword.get(opts, :write, false) -> false
      Keyword.has_key?(opts, :dry_run) -> require_boolean!(Keyword.fetch!(opts, :dry_run), :dry_run)
      true -> true
    end
  end

  @spec require_boolean!(term(), atom()) :: boolean()
  defp require_boolean!(value, _option_name) when is_boolean(value), do: value

  defp require_boolean!(value, option_name) do
    raise ArgumentError, "expected #{inspect(option_name)} option to be a boolean, got: #{inspect(value)}"
  end

  @spec migration_targets([String.t()]) :: [String.t()]
  defp migration_targets([]) do
    @default_globs
    |> Enum.flat_map(&Path.wildcard/1)
    |> append_default_setup_files()
    |> finalize_targets()
  end

  @spec migration_targets([String.t()]) :: [String.t()]
  defp migration_targets(paths) do
    include_relative_setup? = Enum.any?(paths, &(Path.type(&1) != :absolute))

    paths
    |> Enum.flat_map(&expand_target/1)
    |> maybe_append_relative_setup_files(include_relative_setup?)
    |> finalize_targets()
  end

  @spec maybe_append_relative_setup_files([String.t()], boolean()) :: [String.t()]
  defp maybe_append_relative_setup_files(paths, true), do: paths ++ @relative_setup_files
  defp maybe_append_relative_setup_files(paths, false), do: paths

  @spec append_default_setup_files([String.t()]) :: [String.t()]
  defp append_default_setup_files(paths), do: paths ++ @default_setup_files

  @spec finalize_targets([String.t()]) :: [String.t()]
  defp finalize_targets(paths) do
    paths
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec expand_target(String.t()) :: [String.t()]
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

  @spec migrate_file(term(), String.t(), boolean()) :: migration_result()
  defp migrate_file(igniter, file, dry_run) do
    original = File.read!(file)
    {rewritten, warnings} = rewrite_content(file, original)
    print_warnings(file, warnings)
    warning_count = length(warnings)

    cond do
      rewritten == original ->
        {igniter, false, warning_count}

      dry_run ->
        print_diff(file, original, rewritten)
        {igniter, true, warning_count}

      true ->
        igniter = persist_migrated_file(igniter, file, rewritten)
        IO.puts("updated #{file}")
        {igniter, true, warning_count}
    end
  end

  @spec persist_migrated_file(term(), String.t(), String.t()) :: term()
  defp persist_migrated_file(igniter, file, rewritten) do
    Igniter.update_file(
      igniter,
      file,
      &update_source_content(&1, rewritten),
      source_handler: Rewrite.Source.Ex
    )
  end

  @spec update_source_content(Source.t(), String.t()) :: Source.t()
  defp update_source_content(source, rewritten) do
    Source.update(source, :content, rewritten, by: :cerberus_migrate_phoenix_test)
  end

  @spec rewrite_content(String.t(), String.t()) :: {String.t(), warning_messages()}
  defp rewrite_content(file, content) do
    content
    |> rewrite_with_ast()
    |> maybe_ensure_cerberus_endpoint_config(file)
    |> maybe_ensure_test_helper_endpoint(file)
  end

  @spec maybe_ensure_cerberus_endpoint_config({String.t(), warning_messages()}, String.t()) ::
          {String.t(), warning_messages()}
  defp maybe_ensure_cerberus_endpoint_config({content, warnings}, file) do
    cond do
      not config_test_file?(file) ->
        {content, warnings}

      has_cerberus_endpoint_config?(content) ->
        {content, warnings}

      true ->
        case infer_endpoint_ast_from_content(content) do
          {:ok, endpoint_ast} ->
            updated =
              content
              |> append_cerberus_endpoint_config(endpoint_ast)
              |> Code.format_string!()
              |> IO.iodata_to_binary()

            {updated, warnings}

          :error ->
            {content, warnings}
        end
    end
  end

  @spec maybe_ensure_test_helper_endpoint({String.t(), warning_messages()}, String.t()) ::
          {String.t(), warning_messages()}
  defp maybe_ensure_test_helper_endpoint({content, warnings}, file) do
    cond do
      not test_helper_file?(file) ->
        {content, warnings}

      has_cerberus_endpoint_put_env?(content) ->
        {content, warnings}

      true ->
        ensure_test_helper_endpoint_put_env(file, content, warnings)
    end
  end

  @spec ensure_test_helper_endpoint_put_env(String.t(), String.t(), warning_messages()) ::
          {String.t(), warning_messages()}
  defp ensure_test_helper_endpoint_put_env(file, content, warnings) do
    case infer_endpoint_ast(file) do
      {:ok, endpoint_ast} ->
        updated =
          content
          |> append_test_helper_endpoint_put_env(endpoint_ast)
          |> Code.format_string!()
          |> IO.iodata_to_binary()

        {updated, warnings}

      :error ->
        {content, warnings}
    end
  end

  @spec config_test_file?(String.t()) :: boolean()
  defp config_test_file?(file) when is_binary(file) do
    case file |> Path.split() |> Enum.take(-2) do
      ["config", "test.exs"] -> true
      _ -> false
    end
  end

  @spec test_helper_file?(String.t()) :: boolean()
  defp test_helper_file?(file) when is_binary(file) do
    case file |> Path.split() |> Enum.take(-2) do
      ["test", "test_helper.exs"] -> true
      _ -> false
    end
  end

  @spec has_cerberus_endpoint_put_env?(String.t()) :: boolean()
  defp has_cerberus_endpoint_put_env?(content) when is_binary(content) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        {_ast, found?} =
          Macro.prewalk(ast, false, fn
            {{:., _dot_meta, [{:__aliases__, _alias_meta, [:Application]}, :put_env]}, _call_meta, args} =
                node,
            found? ->
              {node, found? or cerberus_endpoint_put_env_call_args?(args)}

            node, found? ->
              {node, found?}
          end)

        found?

      _ ->
        String.contains?(content, "Application.put_env(:cerberus, :endpoint")
    end
  end

  @spec cerberus_endpoint_put_env_call_args?(list()) :: boolean()
  defp cerberus_endpoint_put_env_call_args?([app_ast, key_ast | _rest]) do
    atom_literal(app_ast) == {:ok, :cerberus} and atom_literal(key_ast) == {:ok, :endpoint}
  end

  defp cerberus_endpoint_put_env_call_args?(_args), do: false

  @spec has_cerberus_endpoint_config?(String.t()) :: boolean()
  defp has_cerberus_endpoint_config?(content) when is_binary(content) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        {_ast, found?} =
          Macro.prewalk(ast, false, fn
            {:config, _meta, args} = node, found? when is_list(args) ->
              {node, found? or cerberus_endpoint_config_args?(args)}

            node, found? ->
              {node, found?}
          end)

        found?

      _ ->
        String.contains?(content, "config :cerberus")
    end
  end

  @spec cerberus_endpoint_config_args?([Macro.t()]) :: boolean()
  defp cerberus_endpoint_config_args?([app_ast | rest]) do
    atom_literal(app_ast) == {:ok, :cerberus} and endpoint_ast_from_config_rest(rest) != :error
  end

  defp cerberus_endpoint_config_args?(_args), do: false

  @spec infer_endpoint_ast(String.t()) :: {:ok, Macro.t()} | :error
  defp infer_endpoint_ast(file) do
    config_path = config_test_path_for(file)

    with true <- File.regular?(config_path),
         {:ok, content} <- File.read(config_path) do
      infer_endpoint_ast_from_content(content)
    else
      _ -> :error
    end
  end

  @spec config_test_path_for(String.t()) :: String.t()
  defp config_test_path_for(file) do
    file
    |> Path.expand()
    |> Path.dirname()
    |> Path.dirname()
    |> Path.join("config/test.exs")
  end

  @spec infer_endpoint_ast_from_content(String.t()) :: {:ok, Macro.t()} | :error
  defp infer_endpoint_ast_from_content(content) when is_binary(content) do
    with {:ok, ast} <- Sourceror.parse_string(content),
         {:ok, endpoint_ast} <- find_endpoint_ast(ast) do
      {:ok, endpoint_ast}
    else
      _ -> :error
    end
  end

  @spec find_endpoint_ast(Macro.t()) :: {:ok, Macro.t()} | :error
  defp find_endpoint_ast(ast) do
    {_ast, endpoint_ast} =
      Macro.prewalk(ast, nil, fn
        {:config, _meta, args} = node, nil when is_list(args) ->
          {node, endpoint_ast_from_config_args(args)}

        node, endpoint_ast ->
          {node, endpoint_ast}
      end)

    if is_nil(endpoint_ast), do: :error, else: {:ok, endpoint_ast}
  end

  @spec endpoint_ast_from_config_args([Macro.t()]) :: Macro.t() | nil
  defp endpoint_ast_from_config_args([app_ast | rest]) do
    with {:ok, app} <- atom_literal(app_ast),
         true <- app in [:cerberus, :phoenix_test],
         {:ok, endpoint_ast} <- endpoint_ast_from_config_rest(rest) do
      endpoint_ast
    else
      _ -> nil
    end
  end

  defp endpoint_ast_from_config_args(_args), do: nil

  @spec endpoint_ast_from_config_rest([Macro.t()]) :: {:ok, Macro.t()} | :error
  defp endpoint_ast_from_config_rest(rest) when is_list(rest) do
    rest
    |> Enum.find(&keyword_ast?/1)
    |> case do
      nil ->
        :error

      keyword_ast ->
        keyword_ast
        |> normalize_keyword_ast()
        |> Keyword.fetch(:endpoint)
    end
  end

  @spec append_test_helper_endpoint_put_env(String.t(), Macro.t()) :: String.t()
  defp append_test_helper_endpoint_put_env(content, endpoint_ast) when is_binary(content) do
    put_env_call = "Application.put_env(:cerberus, :endpoint, #{Macro.to_string(endpoint_ast)})"

    if String.ends_with?(content, "\n") do
      content <> put_env_call <> "\n"
    else
      content <> "\n" <> put_env_call <> "\n"
    end
  end

  @spec append_cerberus_endpoint_config(String.t(), Macro.t()) :: String.t()
  defp append_cerberus_endpoint_config(content, endpoint_ast) when is_binary(content) do
    config_line = "config :cerberus, endpoint: #{Macro.to_string(endpoint_ast)}"

    if String.ends_with?(content, "\n") do
      content <> config_line <> "\n"
    else
      content <> "\n" <> config_line <> "\n"
    end
  end

  @spec print_summary(non_neg_integer(), non_neg_integer(), non_neg_integer(), boolean()) :: :ok
  defp print_summary(files_scanned, changed_count, warning_count, dry_run) do
    IO.puts("\nMigration summary:")
    IO.puts("  Files scanned: #{files_scanned}")
    IO.puts("  Files changed: #{changed_count}")
    IO.puts("  Warnings: #{warning_count}")
    IO.puts("  Mode: #{if dry_run, do: "dry-run", else: "write"}")
    :ok
  end

  @spec rewrite_with_ast(String.t()) :: {String.t(), warning_messages()}
  defp rewrite_with_ast(content) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        {rewritten_ast, state} = Macro.prewalk(ast, %RewriteState{}, &rewrite_node/2)
        {canonical_ast, canonical_changed?} = canonicalize_calls(rewritten_ast)
        {imported_ast, import_changed?} = ensure_cerberus_imports(canonical_ast)
        changed? = state.changed? or canonical_changed? or import_changed?

        rewritten = render_rewritten_content(content, imported_ast, changed?)
        {rewritten, Enum.reverse(state.warnings)}

      {:error, {_line, error, _token}} ->
        {content, ["Could not parse file for AST migration: #{error}"]}

      {:error, reason} ->
        {content, ["Could not parse file for AST migration: #{inspect(reason)}"]}
    end
  end

  @spec render_rewritten_content(String.t(), Macro.t(), boolean()) :: String.t()
  defp render_rewritten_content(content, _canonical_ast, false), do: content

  defp render_rewritten_content(_content, canonical_ast, true) do
    canonical_ast
    |> Sourceror.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  @spec rewrite_node(Macro.t(), RewriteState.t()) :: {Macro.t(), RewriteState.t()}
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

  defp rewrite_node({:use, _meta, args} = node, state) do
    case args do
      [module_ast | _rest] ->
        case alias_parts(module_ast) do
          [:PhoenixTest] ->
            {node, add_warning(state, @warning_use_phoenix_test)}

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
        rewrite_alias_node(node, meta, module_ast, rest, state)

      _ ->
        {node, state}
    end
  end

  defp rewrite_node({:|>, meta, [lhs, rhs]} = node, state) do
    if conn_arg?(lhs) and visit_call?(rhs) do
      updated = {:|>, meta, [session_bootstrap_ast_from(lhs), rhs]}
      {updated, mark_changed(state)}
    else
      {node, state}
    end
  end

  defp rewrite_node({{:., _dot_meta, [module_ast, fun]}, _call_meta, args} = node, state)
       when is_atom(fun) and is_list(args) do
    state_with_warnings = maybe_warn_browser_helper(state, fun)
    rewrite_remote_call(node, module_ast, fun, args, state_with_warnings)
  end

  defp rewrite_node({:visit, meta, args} = node, state) when is_list(args) do
    if conn_first_arg?(args) do
      updated = {:visit, meta, replace_first_arg_with_session_bootstrap(args)}
      {updated, mark_changed(state)}
    else
      {node, state}
    end
  end

  defp rewrite_node({:config, _meta, args} = node, state) when is_list(args), do: {node, state}

  defp rewrite_node({fun, _meta, args} = node, state) when is_atom(fun) and is_list(args) do
    next_state = maybe_warn_browser_helper(state, fun)
    {node, next_state}
  end

  defp rewrite_node(node, state), do: {node, state}

  @spec canonicalize_calls(Macro.t()) :: {Macro.t(), boolean()}
  defp canonicalize_calls(ast) do
    Macro.prewalk(ast, false, &canonicalize_node/2)
  end

  @spec canonicalize_node(Macro.t(), boolean()) :: {Macro.t(), boolean()}
  defp canonicalize_node({{:., dot_meta, [module_ast, fun]}, call_meta, args} = node, changed)
       when is_atom(fun) and is_list(args) do
    scope_builder = &build_remote_css_scope(module_ast, &1)
    assertion_scope_builder = &build_remote_assertion_scope(module_ast, &1, &2)

    case canonicalize_call_args(fun, args, scope_builder, assertion_scope_builder) do
      {:ok, updated_args} ->
        {{{:., dot_meta, [module_ast, fun]}, call_meta, updated_args}, true}

      :no_change ->
        {node, changed}
    end
  end

  defp canonicalize_node({fun, meta, args} = node, changed) when is_atom(fun) and is_list(args) do
    case canonicalize_call_args(fun, args, &build_local_css_scope/1, &build_local_assertion_scope/2) do
      {:ok, updated_args} ->
        {{fun, meta, updated_args}, true}

      :no_change ->
        {node, changed}
    end
  end

  defp canonicalize_node(node, changed), do: {node, changed}

  @spec ensure_cerberus_imports(Macro.t()) :: {Macro.t(), boolean()}
  defp ensure_cerberus_imports(ast) do
    Macro.prewalk(ast, false, &ensure_cerberus_import_node/2)
  end

  @spec ensure_cerberus_import_node(Macro.t(), boolean()) :: {Macro.t(), boolean()}
  defp ensure_cerberus_import_node({:defmodule, meta, [module_name, body_kw]} = node, changed) when is_list(body_kw) do
    {updated_body_kw, inserted?} =
      Enum.map_reduce(body_kw, false, fn
        {key, body} = entry, inserted_acc ->
          cond do
            inserted_acc ->
              {entry, true}

            do_block_key?(key) and module_needs_cerberus_import?(body) and not module_imports_cerberus?(body) ->
              {{key, prepend_cerberus_import(body)}, true}

            true ->
              {entry, inserted_acc}
          end

        entry, inserted_acc ->
          {entry, inserted_acc}
      end)

    if inserted? do
      {{:defmodule, meta, [module_name, updated_body_kw]}, true}
    else
      {node, changed}
    end
  end

  defp ensure_cerberus_import_node(node, changed), do: {node, changed}

  @spec do_block_key?(term()) :: boolean()
  defp do_block_key?(:do), do: true
  defp do_block_key?({:__block__, _meta, [:do]}), do: true
  defp do_block_key?(_), do: false

  @spec module_needs_cerberus_import?(Macro.t()) :: boolean()
  defp module_needs_cerberus_import?(body) do
    {_body, needed?} =
      Macro.prewalk(body, false, fn
        {fun, _meta, args} = node, needed when is_atom(fun) and is_list(args) ->
          import_needed_for_call? =
            fun == :session or
              match?(
                {:ok, _updated_args},
                canonicalize_call_args(fun, args, &build_local_css_scope/1, &build_local_assertion_scope/2)
              )

          {node, needed or import_needed_for_call?}

        node, needed ->
          {node, needed}
      end)

    needed?
  end

  @spec module_imports_cerberus?(Macro.t()) :: boolean()
  defp module_imports_cerberus?(body) do
    {_body, imported?} =
      Macro.prewalk(body, false, fn
        {:import, _meta, [module_ast | _rest]} = node, imported ->
          {node, imported or alias_parts(module_ast) == [:Cerberus]}

        node, imported ->
          {node, imported}
      end)

    imported?
  end

  @spec prepend_cerberus_import(Macro.t()) :: Macro.t()
  defp prepend_cerberus_import({:__block__, meta, nodes}) when is_list(nodes) do
    {:__block__, meta, [cerberus_import_ast() | nodes]}
  end

  defp prepend_cerberus_import(node) do
    {:__block__, [], [cerberus_import_ast(), node]}
  end

  @spec cerberus_import_ast() :: Macro.t()
  defp cerberus_import_ast do
    {:import, [], [{:__aliases__, [], [:Cerberus]}]}
  end

  @spec canonicalize_call_args(
          atom(),
          [Macro.t()],
          (Macro.t() -> Macro.t()),
          (Macro.t(), Macro.t() -> Macro.t())
        ) ::
          canonicalize_result()
  defp canonicalize_call_args(fun, args, scope_builder, assertion_scope_builder)
       when is_function(scope_builder, 1) and is_function(assertion_scope_builder, 2) do
    {args, changed?} =
      Enum.reduce(
        [
          fn acc -> canonicalize_text_assertion_args(fun, acc) end,
          fn acc -> canonicalize_labeled_value_call_args(fun, acc) end,
          fn acc -> canonicalize_scope_locator_args(fun, acc, scope_builder, assertion_scope_builder) end,
          fn acc -> canonicalize_explicit_locator_args(fun, acc) end,
          fn acc -> canonicalize_label_variable_locator_args(fun, acc) end
        ],
        {args, false},
        fn transform, {acc, changed?} ->
          case transform.(acc) do
            {:ok, updated} -> {updated, true}
            :no_change -> {acc, changed?}
          end
        end
      )

    if changed?, do: {:ok, args}, else: :no_change
  end

  @spec canonicalize_text_assertion_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_text_assertion_args(fun, args) when fun in @canonical_text_assertions do
    with {:ok, prefix, maybe_opts, trailing_opts} <- split_text_assertion_args(args),
         {:ok, text_value, remaining_opts} <- pop_keyword_ast(maybe_opts, :text),
         {:ok, merged_opts} <- merge_trailing_opts(remaining_opts, trailing_opts) do
      canonical_text_value =
        case explicit_locator_ast(text_value) do
          {:ok, locator_ast} -> locator_ast
          :no_change -> text_value
        end

      {:ok, build_value_args(prefix, canonical_text_value, merged_opts)}
    else
      _ -> :no_change
    end
  end

  defp canonicalize_text_assertion_args(_fun, _args), do: :no_change

  @spec canonicalize_labeled_value_call_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_labeled_value_call_args(fun, args) do
    case Map.fetch(@canonical_labeled_value_keys, fun) do
      {:ok, key} ->
        canonicalize_labeled_value_call_args_by_key(args, key)

      :error ->
        :no_change
    end
  end

  @spec canonicalize_labeled_value_call_args_by_key([Macro.t()], atom()) :: canonicalize_result()
  defp canonicalize_labeled_value_call_args_by_key(args, key) do
    with {:ok, prefix, maybe_opts, trailing_opts} <- split_labeled_value_args(args),
         {:ok, value, remaining_opts} <- pop_keyword_ast(maybe_opts, key),
         {:ok, merged_opts} <- merge_trailing_opts(remaining_opts, trailing_opts) do
      {:ok, build_value_args(prefix, value, merged_opts)}
    else
      _ -> :no_change
    end
  end

  @spec canonicalize_scope_locator_args(
          atom(),
          [Macro.t()],
          (Macro.t() -> Macro.t()),
          (Macro.t(), Macro.t() -> Macro.t())
        ) ::
          canonicalize_result()
  defp canonicalize_scope_locator_args(fun, args, _scope_builder, assertion_scope_builder)
       when fun in @canonical_text_assertions do
    canonicalize_assertion_scope_args(args, assertion_scope_builder)
  end

  defp canonicalize_scope_locator_args(:within, args, scope_builder, _assertion_scope_builder) do
    canonicalize_within_scope_args(args, scope_builder)
  end

  defp canonicalize_scope_locator_args(_fun, _args, _scope_builder, _assertion_scope_builder), do: :no_change

  @spec canonicalize_explicit_locator_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_explicit_locator_args(fun, args) when fun in @explicit_locator_calls do
    case locator_arg_indexes_for(fun, args) do
      [] ->
        :no_change

      indexes ->
        {updated_args, changed?} =
          Enum.reduce(indexes, {args, false}, &reduce_locator_arg_index/2)

        if changed?, do: {:ok, updated_args}, else: :no_change
    end
  end

  defp canonicalize_explicit_locator_args(_fun, _args), do: :no_change

  @spec canonicalize_label_variable_locator_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_label_variable_locator_args(fun, args) when fun in @label_locator_variable_calls do
    case locator_arg_indexes_for(fun, args) do
      [] ->
        :no_change

      indexes ->
        {updated_args, changed?} =
          Enum.reduce(indexes, {args, false}, &reduce_label_variable_locator_arg_index/2)

        if changed?, do: {:ok, updated_args}, else: :no_change
    end
  end

  defp canonicalize_label_variable_locator_args(_fun, _args), do: :no_change

  @spec reduce_label_variable_locator_arg_index(non_neg_integer(), {[Macro.t()], boolean()}) ::
          {[Macro.t()], boolean()}
  defp reduce_label_variable_locator_arg_index(index, {args, changed?}) do
    case Enum.fetch(args, index) do
      {:ok, arg} ->
        maybe_replace_label_variable_arg(args, index, arg, changed?)

      :error ->
        {args, changed?}
    end
  end

  @spec maybe_replace_label_variable_arg([Macro.t()], non_neg_integer(), Macro.t(), boolean()) ::
          {[Macro.t()], boolean()}
  defp maybe_replace_label_variable_arg(args, index, arg, changed?) do
    if bare_variable_ast?(arg) and not locator_expression_ast?(arg) do
      {List.replace_at(args, index, label_call_ast(arg)), true}
    else
      {args, changed?}
    end
  end

  @spec reduce_locator_arg_index(non_neg_integer(), {[Macro.t()], boolean()}) :: {[Macro.t()], boolean()}
  defp reduce_locator_arg_index(index, {args, changed?}) do
    case locatorized_arg_at(args, index) do
      {:ok, updated_args} -> {updated_args, true}
      :no_change -> {args, changed?}
    end
  end

  @spec locator_arg_indexes_for(atom(), [Macro.t()]) :: [non_neg_integer()]
  defp locator_arg_indexes_for(:fill_in, [_, _]), do: [0]
  defp locator_arg_indexes_for(:fill_in, [_, _, third]), do: if(keyword_ast?(third), do: [0], else: [1])
  defp locator_arg_indexes_for(:fill_in, [_, _, _, _]), do: [1]

  defp locator_arg_indexes_for(:upload, [_, _]), do: [0]
  defp locator_arg_indexes_for(:upload, [_, _, third]), do: if(keyword_ast?(third), do: [0], else: [1])
  defp locator_arg_indexes_for(:upload, [_, _, _, _]), do: [1]

  defp locator_arg_indexes_for(fun, [_, _, third]) when fun in [:assert_has, :refute_has, :click] do
    if keyword_ast?(third), do: [1], else: [2]
  end

  defp locator_arg_indexes_for(fun, [_, _, _, _]) when fun in [:assert_has, :refute_has, :click], do: [2]
  defp locator_arg_indexes_for(fun, [_]) when fun in @explicit_locator_calls, do: [0]
  defp locator_arg_indexes_for(fun, [_, _]) when fun in @explicit_locator_calls, do: [1]
  defp locator_arg_indexes_for(fun, [_, _, _]) when fun in @explicit_locator_calls, do: [1]
  defp locator_arg_indexes_for(_fun, _args), do: []

  @spec locatorized_arg_at([Macro.t()], non_neg_integer()) :: {:ok, [Macro.t()]} | :no_change
  defp locatorized_arg_at(args, index) when is_list(args) and is_integer(index) and index >= 0 do
    case Enum.fetch(args, index) do
      {:ok, arg} ->
        case explicit_locator_ast(arg) do
          {:ok, locator_ast} ->
            {:ok, List.replace_at(args, index, locator_ast)}

          :no_change ->
            :no_change
        end

      :error ->
        :no_change
    end
  end

  @spec explicit_locator_ast(Macro.t()) :: {:ok, Macro.t()} | :no_change
  defp explicit_locator_ast(arg) do
    cond do
      locator_expression_ast?(arg) ->
        :no_change

      binary_literal_ast?(arg) ->
        {:ok, text_sigil_i_ast(binary_literal_value(arg))}

      regex_literal_ast?(arg) ->
        {:ok, [text: arg]}

      keyword_ast?(arg) ->
        :no_change

      true ->
        :no_change
    end
  end

  @spec locator_expression_ast?(Macro.t()) :: boolean()
  defp locator_expression_ast?({:__block__, _meta, [value]}), do: locator_expression_ast?(value)
  defp locator_expression_ast?({:sigil_l, _meta, [_body, _mods]}), do: true

  defp locator_expression_ast?({fun, _meta, args}) when is_atom(fun) and is_list(args) and fun in @locator_helper_funs,
    do: true

  defp locator_expression_ast?({{:., _dot_meta, [_module_ast, fun]}, _meta, args})
       when is_atom(fun) and is_list(args) and fun in @locator_helper_funs, do: true

  defp locator_expression_ast?(value) when is_list(value) do
    keyword_ast?(value) and locator_keyword_ast?(value)
  end

  defp locator_expression_ast?(%{} = value) do
    value
    |> Map.keys()
    |> Enum.any?(fn key ->
      case atom_literal(key) do
        {:ok, key_atom} -> key_atom in @locator_kind_keys
        :error -> false
      end
    end)
  end

  defp locator_expression_ast?(_value), do: false

  @spec bare_variable_ast?(Macro.t()) :: boolean()
  defp bare_variable_ast?({name, meta, context})
       when is_atom(name) and is_list(meta) and (is_atom(context) or is_nil(context)), do: true

  defp bare_variable_ast?(_value), do: false

  @spec label_call_ast(Macro.t()) :: Macro.t()
  defp label_call_ast(value), do: {:label, [], [value]}

  @spec locator_keyword_ast?(keyword()) :: boolean()
  defp locator_keyword_ast?(keyword_ast) when is_list(keyword_ast) do
    keyword_ast
    |> normalize_keyword_ast()
    |> Keyword.keys()
    |> Enum.any?(&(&1 in @locator_kind_keys))
  end

  @spec binary_literal_value(Macro.t()) :: String.t()
  defp binary_literal_value({:__block__, _meta, [value]}) when is_binary(value), do: value
  defp binary_literal_value(value) when is_binary(value), do: value

  @spec text_sigil_i_ast(String.t()) :: Macro.t()
  defp text_sigil_i_ast(value) when is_binary(value) do
    {:sigil_l, [delimiter: "\""], [{:<<>>, [], [value]}, ~c"i"]}
  end

  @spec regex_literal_ast?(Macro.t()) :: boolean()
  defp regex_literal_ast?({:sigil_r, _meta, [_body, _mods]}), do: true
  defp regex_literal_ast?({:__block__, _meta, [value]}), do: regex_literal_ast?(value)
  defp regex_literal_ast?(_value), do: false

  @spec canonicalize_assertion_scope_args([Macro.t()], (Macro.t(), Macro.t() -> Macro.t())) :: canonicalize_result()
  defp canonicalize_assertion_scope_args(args, assertion_scope_builder) when is_function(assertion_scope_builder, 2) do
    case args do
      [scope, locator] ->
        canonicalize_assertion_scope_pair(scope, locator, assertion_scope_builder)

      [first, second, third] ->
        canonicalize_assertion_scope_triple(first, second, third, assertion_scope_builder)

      [session, scope, locator, opts] ->
        canonicalize_assertion_scope_quad(session, scope, locator, opts, assertion_scope_builder)

      _ ->
        :no_change
    end
  end

  @spec canonicalize_assertion_scope_pair(Macro.t(), Macro.t(), (Macro.t(), Macro.t() -> Macro.t())) ::
          canonicalize_result()
  defp canonicalize_assertion_scope_pair(scope, locator, assertion_scope_builder)
       when is_function(assertion_scope_builder, 2) do
    if binary_literal_ast?(scope) and not keyword_ast?(locator) do
      {:ok, [assertion_scope_builder.(scope, locator)]}
    else
      :no_change
    end
  end

  @spec canonicalize_assertion_scope_triple(Macro.t(), Macro.t(), Macro.t(), (Macro.t(), Macro.t() -> Macro.t())) ::
          canonicalize_result()
  defp canonicalize_assertion_scope_triple(first, second, third, assertion_scope_builder)
       when is_function(assertion_scope_builder, 2) do
    cond do
      binary_literal_ast?(second) and not keyword_ast?(third) ->
        {:ok, [first, assertion_scope_builder.(second, third)]}

      binary_literal_ast?(first) and keyword_ast?(third) ->
        {:ok, [assertion_scope_builder.(first, second), third]}

      true ->
        :no_change
    end
  end

  @spec canonicalize_assertion_scope_quad(
          Macro.t(),
          Macro.t(),
          Macro.t(),
          Macro.t(),
          (Macro.t(), Macro.t() -> Macro.t())
        ) ::
          canonicalize_result()
  defp canonicalize_assertion_scope_quad(session, scope, locator, opts, assertion_scope_builder)
       when is_function(assertion_scope_builder, 2) do
    if binary_literal_ast?(scope) and keyword_ast?(opts) do
      {:ok, [session, assertion_scope_builder.(scope, locator), opts]}
    else
      :no_change
    end
  end

  @spec canonicalize_within_scope_args([Macro.t()], (Macro.t() -> Macro.t())) :: canonicalize_result()
  defp canonicalize_within_scope_args(args, scope_builder) when is_function(scope_builder, 1) do
    case args do
      [scope, callback] ->
        if binary_literal_ast?(scope) and callback_ast?(callback) do
          {:ok, [scope_builder.(scope), callback]}
        else
          :no_change
        end

      [session, scope, callback] ->
        if binary_literal_ast?(scope) and callback_ast?(callback) do
          {:ok, [session, scope_builder.(scope), callback]}
        else
          :no_change
        end

      _ ->
        :no_change
    end
  end

  @spec callback_ast?(Macro.t()) :: boolean()
  defp callback_ast?({:fn, _, _}), do: true
  defp callback_ast?({:&, _, _}), do: true
  defp callback_ast?(_), do: false

  @spec binary_literal_ast?(Macro.t()) :: boolean()
  defp binary_literal_ast?(value) when is_binary(value), do: true
  defp binary_literal_ast?({:__block__, _meta, [value]}), do: binary_literal_ast?(value)
  defp binary_literal_ast?(_value), do: false

  @spec build_local_css_scope(Macro.t()) :: Macro.t()
  defp build_local_css_scope(scope_ast), do: {:css, [], [scope_ast]}

  @spec build_local_assertion_scope(Macro.t(), Macro.t()) :: Macro.t()
  defp build_local_assertion_scope(scope_ast, locator_ast),
    do: {:and_, [], [build_local_css_scope(scope_ast), locator_ast]}

  @spec build_remote_css_scope(Macro.t(), Macro.t()) :: Macro.t()
  defp build_remote_css_scope(module_ast, scope_ast) do
    {{:., [], [module_ast, :css]}, [], [scope_ast]}
  end

  @spec build_remote_assertion_scope(Macro.t(), Macro.t(), Macro.t()) :: Macro.t()
  defp build_remote_assertion_scope(module_ast, scope_ast, locator_ast) do
    css_ast = build_remote_css_scope(module_ast, scope_ast)
    {{:., [], [module_ast, :and_]}, [], [css_ast, locator_ast]}
  end

  @spec split_text_assertion_args([Macro.t()]) :: split_args_result()
  defp split_text_assertion_args([session, maybe_opts]), do: {:ok, [session], maybe_opts, :none}
  defp split_text_assertion_args([session, scope, maybe_opts]), do: {:ok, [session, scope], maybe_opts, :none}
  defp split_text_assertion_args(_args), do: :error

  @spec atom_literal(Macro.t()) :: {:ok, atom()} | :error
  defp atom_literal(value) when is_atom(value), do: {:ok, value}
  defp atom_literal({:__block__, _meta, [value]}), do: atom_literal(value)
  defp atom_literal(_value), do: :error

  @spec split_labeled_value_args([Macro.t()]) :: split_args_result()
  defp split_labeled_value_args([locator, maybe_opts]), do: {:ok, [locator], maybe_opts, :none}
  defp split_labeled_value_args([session, locator, maybe_opts]), do: {:ok, [session, locator], maybe_opts, :none}

  defp split_labeled_value_args([session, locator, maybe_opts, trailing_opts]),
    do: {:ok, [session, locator], maybe_opts, trailing_opts}

  defp split_labeled_value_args(_args), do: :error

  @spec merge_trailing_opts(keyword(), keyword() | :none) :: {:ok, keyword()} | :error
  defp merge_trailing_opts(remaining_opts, :none), do: {:ok, remaining_opts}

  defp merge_trailing_opts(remaining_opts, trailing_opts) do
    if keyword_ast?(trailing_opts) do
      {:ok, merge_keyword_opts(remaining_opts, normalize_keyword_ast(trailing_opts))}
    else
      :error
    end
  end

  @spec merge_keyword_opts(keyword(), keyword()) :: keyword()
  defp merge_keyword_opts([], trailing_opts), do: trailing_opts
  defp merge_keyword_opts(remaining_opts, trailing_opts), do: Keyword.merge(remaining_opts, trailing_opts)

  @spec build_value_args([Macro.t()], Macro.t(), keyword()) :: [Macro.t()]
  defp build_value_args(prefix, value, []), do: prefix ++ [value]
  defp build_value_args(prefix, value, merged_opts), do: prefix ++ [value, merged_opts]

  @spec pop_keyword_ast(term(), atom()) :: {:ok, Macro.t(), keyword()} | :no_change
  defp pop_keyword_ast(maybe_keyword, key) when is_atom(key) do
    if keyword_ast?(maybe_keyword) do
      case Keyword.pop(normalize_keyword_ast(maybe_keyword), key, :__not_found__) do
        {:__not_found__, _rest} ->
          :no_change

        {value, rest} ->
          {:ok, value, rest}
      end
    else
      :no_change
    end
  end

  @spec keyword_ast?(term()) :: boolean()
  defp keyword_ast?(value) when is_list(value) do
    Enum.all?(value, fn
      {key, _val} -> keyword_key_atom(key) != :error
      _other -> false
    end)
  end

  defp keyword_ast?(_value), do: false

  @spec normalize_keyword_ast(keyword()) :: keyword()
  defp normalize_keyword_ast(keyword_list) when is_list(keyword_list) do
    Enum.map(keyword_list, fn {key, value} ->
      {unwrap_keyword_key(key), value}
    end)
  end

  @spec keyword_key_atom(term()) :: {:ok, atom()} | :error
  defp keyword_key_atom(key) when is_atom(key), do: {:ok, key}
  defp keyword_key_atom({:__block__, _meta, [key]}) when is_atom(key), do: {:ok, key}
  defp keyword_key_atom(_key), do: :error

  @spec unwrap_keyword_key(term()) :: term()
  defp unwrap_keyword_key(key) do
    case keyword_key_atom(key) do
      {:ok, atom_key} -> atom_key
      :error -> key
    end
  end

  @spec alias_parts(Macro.t()) :: [atom()] | :unknown
  defp alias_parts({:__aliases__, _meta, parts}) when is_list(parts), do: parts
  defp alias_parts(_module_ast), do: :unknown

  @spec alias_ast(Macro.t(), [atom()]) :: Macro.t()
  defp alias_ast({:__aliases__, meta, _parts}, parts), do: {:__aliases__, meta, parts}
  defp alias_ast(_module_ast, parts), do: {:__aliases__, [], parts}

  @spec rewrite_remote_call(Macro.t(), Macro.t(), atom(), [Macro.t()], RewriteState.t()) ::
          {Macro.t(), RewriteState.t()}
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

  @spec rewrite_remote_module(Macro.t(), Macro.t(), [atom()]) :: Macro.t()
  defp rewrite_remote_module({{:., dot_meta, [module_ast, fun]}, call_meta, args}, module_ast, parts) do
    {{:., dot_meta, [alias_ast(module_ast, parts), fun]}, call_meta, args}
  end

  @spec rewrite_remote_module(Macro.t(), Macro.t(), [atom()], [Macro.t()]) :: Macro.t()
  defp rewrite_remote_module({{:., dot_meta, [module_ast, fun]}, call_meta, _args}, module_ast, parts, args) do
    {{:., dot_meta, [alias_ast(module_ast, parts), fun]}, call_meta, args}
  end

  @spec rewrite_phoenix_test_remote_call(Macro.t(), Macro.t(), atom(), [Macro.t()], RewriteState.t()) ::
          {Macro.t(), RewriteState.t()}
  defp rewrite_phoenix_test_remote_call(node, module_ast, fun, args, state) do
    cond do
      fun in @browser_helpers ->
        {node, state}

      fun == :visit and conn_first_arg?(args) ->
        updated_args = replace_first_arg_with_session_bootstrap(args)
        {rewrite_remote_module(node, module_ast, [:Cerberus], updated_args), mark_changed(state)}

      fun in @rewritable_direct_calls ->
        {rewrite_remote_module(node, module_ast, [:Cerberus]), mark_changed(state)}

      true ->
        {node, add_warning(state, @warning_direct_call)}
    end
  end

  @spec rewrite_assertions_remote_call(Macro.t(), Macro.t(), atom(), RewriteState.t()) ::
          {Macro.t(), RewriteState.t()}
  defp rewrite_assertions_remote_call(node, module_ast, fun, state) do
    if fun in @rewritable_assertions_calls do
      {rewrite_remote_module(node, module_ast, [:Cerberus]), mark_changed(state)}
    else
      {node, add_warning(state, @warning_submodule_alias)}
    end
  end

  @spec rewrite_assertions_alias_opts([term()], Macro.t()) :: {:ok, [keyword()]} | :error
  defp rewrite_assertions_alias_opts([], module_ast) do
    {:ok, [[as: alias_ast(module_ast, [:Assertions])]]}
  end

  defp rewrite_assertions_alias_opts([opts], module_ast) when is_list(opts) do
    if keyword_ast?(opts) do
      normalized_opts = normalize_keyword_ast(opts)
      {:ok, [Keyword.put_new(normalized_opts, :as, alias_ast(module_ast, [:Assertions]))]}
    else
      :error
    end
  end

  defp rewrite_assertions_alias_opts(_rest, _module_ast), do: :error

  @spec rewrite_alias_node(Macro.t(), keyword(), Macro.t(), [term()], RewriteState.t()) ::
          {Macro.t(), RewriteState.t()}
  defp rewrite_alias_node(node, meta, module_ast, rest, state) do
    case alias_parts(module_ast) do
      [:PhoenixTest] ->
        updated = {:alias, meta, [alias_ast(module_ast, [:Cerberus]) | rest]}
        {updated, mark_changed(state)}

      [:PhoenixTest, :Assertions] ->
        rewrite_assertions_alias_node(node, meta, module_ast, rest, state)

      [:PhoenixTest | _] ->
        {node, add_warning(state, @warning_submodule_alias)}

      _ ->
        {node, state}
    end
  end

  @spec rewrite_assertions_alias_node(Macro.t(), keyword(), Macro.t(), [term()], RewriteState.t()) ::
          {Macro.t(), RewriteState.t()}
  defp rewrite_assertions_alias_node(node, meta, module_ast, rest, state) do
    case rewrite_assertions_alias_opts(rest, module_ast) do
      {:ok, alias_opts} ->
        updated = {:alias, meta, [alias_ast(module_ast, [:Cerberus]) | alias_opts]}
        {updated, mark_changed(state)}

      :error ->
        {node, add_warning(state, @warning_submodule_alias)}
    end
  end

  @spec maybe_warn_browser_helper(RewriteState.t(), atom()) :: RewriteState.t()
  defp maybe_warn_browser_helper(state, fun) when fun in @browser_helpers, do: add_warning(state, @warning_browser_helper)
  defp maybe_warn_browser_helper(state, _fun), do: state

  @spec conn_first_arg?([Macro.t()]) :: boolean()
  defp conn_first_arg?([first | _rest]), do: conn_arg?(first)
  defp conn_first_arg?(_args), do: false

  @spec visit_call?(Macro.t()) :: boolean()
  defp visit_call?({:visit, _meta, args}) when is_list(args), do: true
  defp visit_call?({{:., _meta, [_module_ast, :visit]}, _call_meta, args}) when is_list(args), do: true
  defp visit_call?(_other), do: false

  @spec conn_arg?(Macro.t()) :: boolean()
  defp conn_arg?({:conn, _meta, context}) when is_atom(context) or is_nil(context), do: true
  defp conn_arg?(_other), do: false

  @spec replace_first_arg_with_session_bootstrap([Macro.t()]) :: [Macro.t()]
  defp replace_first_arg_with_session_bootstrap([first | rest]), do: [session_bootstrap_ast_from(first) | rest]
  defp replace_first_arg_with_session_bootstrap(args), do: args

  @spec session_bootstrap_ast(Macro.t()) :: Macro.t()
  defp session_bootstrap_ast(conn_arg) do
    quote do
      session(unquote(conn_arg))
    end
  end

  @spec session_bootstrap_ast_from(Macro.t()) :: Macro.t()
  defp session_bootstrap_ast_from(original_node) do
    transfer_comment_metadata(session_bootstrap_ast(original_node), original_node)
  end

  @spec transfer_comment_metadata(Macro.t(), Macro.t()) :: Macro.t()
  defp transfer_comment_metadata({name, meta, args}, {_, source_meta, _}) when is_list(meta) and is_list(source_meta) do
    source_leading = Keyword.get(source_meta, :leading_comments, [])
    source_trailing = Keyword.get(source_meta, :trailing_comments, [])

    merged_meta =
      meta
      |> put_comment_metadata(:leading_comments, source_leading)
      |> put_comment_metadata(:trailing_comments, source_trailing)

    {name, merged_meta, args}
  end

  defp transfer_comment_metadata(ast, _source), do: ast

  @spec put_comment_metadata(keyword(), atom(), [term()]) :: keyword()
  defp put_comment_metadata(meta, _key, []), do: meta
  defp put_comment_metadata(meta, key, comments), do: Keyword.put(meta, key, comments)

  @spec mark_changed(RewriteState.t()) :: RewriteState.t()
  defp mark_changed(%RewriteState{} = state), do: %{state | changed?: true}

  @spec add_warning(RewriteState.t(), String.t()) :: RewriteState.t()
  defp add_warning(%RewriteState{} = state, warning) do
    if MapSet.member?(state.seen, warning) do
      state
    else
      %{state | warnings: [warning | state.warnings], seen: MapSet.put(state.seen, warning)}
    end
  end

  @spec print_warnings(String.t(), warning_messages()) :: :ok
  defp print_warnings(_file, []), do: :ok

  defp print_warnings(file, warnings) do
    Enum.each(warnings, fn warning ->
      IO.puts("WARNING #{file}: #{warning}")
    end)
  end

  @spec print_diff(String.t(), String.t(), String.t()) :: :ok
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
