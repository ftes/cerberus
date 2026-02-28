defmodule Cerberus.MigrationVerification do
  @moduledoc false

  @migration_task "igniter.cerberus.migrate_phoenix_test"
  @default_fixture_dir "fixtures/migration_project"
  @default_test_file "test/features/migration_ready_test.exs"

  @type cmd_fun :: (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})

  @spec run(keyword(), cmd_fun()) :: {:ok, map()} | {:error, map()}
  def run(opts \\ [], cmd_fun \\ &System.cmd/3) when is_list(opts) do
    root_dir = opts |> Keyword.get(:root_dir, File.cwd!()) |> Path.expand()
    fixture_dir = opts |> Keyword.get(:fixture_dir, @default_fixture_dir) |> Path.expand(root_dir)

    work_dir =
      opts
      |> Keyword.get_lazy(:work_dir, fn ->
        Path.join(System.tmp_dir!(), "cerberus-migration-verify-#{System.unique_integer([:positive])}")
      end)
      |> Path.expand(root_dir)

    keep? = Keyword.get(opts, :keep, false)
    test_file = Keyword.get(opts, :test_file, @default_test_file)

    result =
      with :ok <- prepare_workspace(fixture_dir, work_dir),
           :ok <- run_deps_get(cmd_fun, work_dir, root_dir),
           {:ok, pre_result} <- run_mix_test(cmd_fun, work_dir, test_file, "phoenix_test", root_dir),
           :ok <- run_migration(work_dir, test_file),
           {:ok, post_result} <- run_mix_test(cmd_fun, work_dir, test_file, "cerberus", root_dir) do
        {:ok,
         %{
           fixture_dir: fixture_dir,
           work_dir: work_dir,
           test_file: test_file,
           pre: pre_result,
           post: post_result
         }}
      end

    maybe_cleanup(result, work_dir, keep?)
  end

  defp maybe_cleanup({:ok, _} = result, _work_dir, true), do: result

  defp maybe_cleanup({:ok, _} = result, work_dir, false) do
    File.rm_rf!(work_dir)
    result
  end

  defp maybe_cleanup({:error, error}, _work_dir, _keep?) do
    {:error, error}
  end

  defp prepare_workspace(fixture_dir, work_dir) do
    if File.dir?(fixture_dir) do
      File.rm_rf!(work_dir)
      File.mkdir_p!(Path.dirname(work_dir))
      File.cp_r!(fixture_dir, work_dir)
      :ok
    else
      {:error, %{stage: :prepare, message: "fixture directory not found: #{fixture_dir}", work_dir: work_dir}}
    end
  end

  defp run_mix_test(cmd_fun, work_dir, test_file, mode, root_dir) do
    args = ["test", test_file]

    env = [
      {"CERBERUS_MIGRATION_FIXTURE_MODE", mode},
      {"CERBERUS_PATH", root_dir}
    ]

    {output, status} =
      cmd_fun.("mix", args,
        cd: work_dir,
        env: env,
        stderr_to_stdout: true
      )

    if status == 0 do
      {:ok, %{status: status, output: output}}
    else
      {:error,
       %{
         stage: stage_for_mode(mode),
         status: status,
         command: ["mix" | args],
         output: output,
         work_dir: work_dir
       }}
    end
  end

  defp run_deps_get(cmd_fun, work_dir, root_dir) do
    {output, status} =
      cmd_fun.("mix", ["deps.get"],
        cd: work_dir,
        env: [{"CERBERUS_PATH", root_dir}],
        stderr_to_stdout: true
      )

    if status == 0 do
      :ok
    else
      {:error,
       %{
         stage: :deps_get,
         status: status,
         command: ["mix", "deps.get"],
         output: output,
         work_dir: work_dir
       }}
    end
  end

  defp run_migration(work_dir, test_file) do
    target = Path.join(work_dir, test_file)

    if File.regular?(target) do
      Mix.Task.reenable(@migration_task)
      Mix.Task.run(@migration_task, ["--write", target])
      :ok
    else
      {:error, %{stage: :migrate, message: "migration target not found: #{target}", work_dir: work_dir}}
    end
  rescue
    error ->
      {:error, %{stage: :migrate, message: Exception.message(error), work_dir: work_dir}}
  end

  defp stage_for_mode("phoenix_test"), do: :pre_test
  defp stage_for_mode("cerberus"), do: :post_test
end
