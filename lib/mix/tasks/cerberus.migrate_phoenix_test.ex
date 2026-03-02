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
  @canonical_labeled_value_keys %{fill_in: :with, select: :option}

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
    |> Enum.filter(&File.regular?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec migration_targets([String.t()]) :: [String.t()]
  defp migration_targets(paths) do
    paths
    |> Enum.flat_map(&expand_target/1)
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
    {rewritten, warnings} = rewrite_with_ast(original)
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
        changed? = state.changed? or canonical_changed?

        rewritten = render_rewritten_content(content, canonical_ast, changed?)
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
    case canonicalize_call_args(fun, args) do
      {:ok, updated_args} ->
        {{{:., dot_meta, [module_ast, fun]}, call_meta, updated_args}, true}

      :no_change ->
        {node, changed}
    end
  end

  defp canonicalize_node({fun, meta, args} = node, changed) when is_atom(fun) and is_list(args) do
    case canonicalize_call_args(fun, args) do
      {:ok, updated_args} ->
        {{fun, meta, updated_args}, true}

      :no_change ->
        {node, changed}
    end
  end

  defp canonicalize_node(node, changed), do: {node, changed}

  @spec canonicalize_call_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_call_args(fun, args) do
    with :no_change <- canonicalize_text_assertion_args(fun, args) do
      canonicalize_labeled_value_call_args(fun, args)
    end
  end

  @spec canonicalize_text_assertion_args(atom(), [Macro.t()]) :: canonicalize_result()
  defp canonicalize_text_assertion_args(fun, args) when fun in @canonical_text_assertions do
    with {:ok, prefix, maybe_opts, trailing_opts} <- split_text_assertion_args(args),
         {:ok, text_value, remaining_opts} <- pop_keyword_ast(maybe_opts, :text),
         {:ok, merged_opts} <- merge_trailing_opts(remaining_opts, trailing_opts) do
      {:ok, build_value_args(prefix, text_value, merged_opts)}
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

  @spec split_text_assertion_args([Macro.t()]) :: split_args_result()
  defp split_text_assertion_args([session, maybe_opts]), do: {:ok, [session], maybe_opts, :none}
  defp split_text_assertion_args([session, scope, maybe_opts]), do: {:ok, [session, scope], maybe_opts, :none}
  defp split_text_assertion_args(_args), do: :error

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
