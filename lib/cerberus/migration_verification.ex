defmodule Cerberus.MigrationVerification do
  @moduledoc false

  @migration_task "igniter.cerberus.migrate_phoenix_test"
  @default_fixture_dir "fixtures/migration_project"
  @default_test_file "test/features/migration_ready_test.exs"
  @default_rows [
    %{id: "pt_migration_ready", test_file: @default_test_file}
  ]

  @type cmd_fun :: (String.t(), [String.t()], keyword() -> {String.t(), non_neg_integer()})
  @type row_result :: %{
          id: String.t(),
          test_file: String.t(),
          pre_status: :pass | :fail | :not_run,
          post_status: :pass | :fail | :not_run,
          parity: boolean()
        }

  @spec run(keyword(), cmd_fun()) :: {:ok, map()} | {:error, map()}
  def run(opts \\ [], cmd_fun \\ &System.cmd/3) when is_list(opts) do
    root_dir = opts |> Keyword.get(:root_dir, File.cwd!()) |> Path.expand()
    fixture_dir = opts |> Keyword.get(:fixture_dir, @default_fixture_dir) |> Path.expand(root_dir)
    rows = resolve_rows(opts)

    work_dir =
      opts
      |> Keyword.get_lazy(:work_dir, fn ->
        Path.join(System.tmp_dir!(), "cerberus-migration-verify-#{System.unique_integer([:positive])}")
      end)
      |> Path.expand(root_dir)

    keep? = Keyword.get(opts, :keep, false)

    result =
      with :ok <- prepare_workspace(fixture_dir, work_dir),
           :ok <- run_deps_get(cmd_fun, work_dir, root_dir),
           {:ok, row_results} <- run_rows(rows, cmd_fun, work_dir, root_dir) do
        report = build_report(rows, row_results)

        {:ok,
         %{
           fixture_dir: fixture_dir,
           work_dir: work_dir,
           rows: rows,
           test_file: first_row_test_file(rows),
           report: report
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

  defp run_rows(rows, cmd_fun, work_dir, root_dir) do
    rows
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, acc} ->
      case run_row(row, cmd_fun, work_dir, root_dir) do
        {:ok, row_result} ->
          {:cont, {:ok, [row_result | acc]}}

        {:error, failure, row_result} ->
          current_results = Enum.reverse([row_result | acc])
          report = build_report(rows, current_results)
          {:halt, {:error, Map.put(failure, :report, report)}}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      {:error, failure} -> {:error, failure}
    end
  end

  defp run_row(%{id: row_id, test_file: test_file}, cmd_fun, work_dir, root_dir) do
    case run_mix_test(cmd_fun, work_dir, test_file, "phoenix_test", root_dir) do
      {:ok, pre_result} ->
        run_row_after_pre(row_id, test_file, pre_result, cmd_fun, work_dir, root_dir)

      {:error, failure} ->
        row_result = %{
          id: row_id,
          test_file: test_file,
          pre_status: :fail,
          post_status: :not_run,
          pre: %{status: Map.get(failure, :status), output: Map.get(failure, :output)},
          post: nil,
          parity: false
        }

        {:error, Map.merge(failure, %{row_id: row_id, test_file: test_file}), row_result}
    end
  end

  defp run_row_after_pre(row_id, test_file, pre_result, cmd_fun, work_dir, root_dir) do
    with :ok <- run_migration(work_dir, test_file),
         {:ok, post_result} <- run_mix_test(cmd_fun, work_dir, test_file, "cerberus", root_dir) do
      {:ok,
       %{
         id: row_id,
         test_file: test_file,
         pre_status: :pass,
         post_status: :pass,
         pre: pre_result,
         post: post_result,
         parity: true
       }}
    else
      {:error, %{stage: :post_test} = failure} ->
        row_result = %{
          id: row_id,
          test_file: test_file,
          pre_status: :pass,
          post_status: :fail,
          pre: pre_result,
          post: %{status: Map.get(failure, :status), output: Map.get(failure, :output)},
          parity: false
        }

        {:error, Map.merge(failure, %{row_id: row_id, test_file: test_file}), row_result}

      {:error, failure} ->
        row_result = %{
          id: row_id,
          test_file: test_file,
          pre_status: :pass,
          post_status: :not_run,
          pre: pre_result,
          post: nil,
          parity: false
        }

        {:error, Map.merge(failure, %{row_id: row_id, test_file: test_file}), row_result}
    end
  end

  defp build_report(rows, current_results) do
    results_by_id = Map.new(current_results, &{&1.id, &1})

    report_rows =
      Enum.map(rows, fn row ->
        Map.get(results_by_id, row.id, %{
          id: row.id,
          test_file: row.test_file,
          pre_status: :not_run,
          post_status: :not_run,
          pre: nil,
          post: nil,
          parity: false
        })
      end)

    parity_pass_rows = Enum.count(report_rows, & &1.parity)
    pre_pass_rows = Enum.count(report_rows, &(&1.pre_status == :pass))
    post_pass_rows = Enum.count(report_rows, &(&1.post_status == :pass))
    total_rows = length(report_rows)

    %{
      rows: report_rows,
      summary: %{
        total_rows: total_rows,
        pre_pass_rows: pre_pass_rows,
        post_pass_rows: post_pass_rows,
        parity_pass_rows: parity_pass_rows,
        all_parity_pass?: parity_pass_rows == total_rows
      }
    }
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

  defp resolve_rows(opts) do
    cond do
      rows = Keyword.get(opts, :rows) ->
        Enum.map(rows, &normalize_row!/1)

      test_file = Keyword.get(opts, :test_file) ->
        [%{id: row_id_from_test_file(test_file), test_file: test_file}]

      true ->
        @default_rows
    end
  end

  defp normalize_row!(%{id: id, test_file: test_file}) when is_binary(id) and is_binary(test_file) do
    %{id: id, test_file: test_file}
  end

  defp normalize_row!(row) do
    raise ArgumentError,
          "invalid :rows entry #{inspect(row)}; expected %{id: binary(), test_file: binary()}"
  end

  defp row_id_from_test_file(test_file) when is_binary(test_file) do
    test_file
    |> Path.basename()
    |> String.replace(~r/\.(exs|ex)\z/, "")
    |> then(&"row_#{&1}")
  end

  defp first_row_test_file([%{test_file: test_file} | _]), do: test_file
  defp first_row_test_file([]), do: @default_test_file
end
