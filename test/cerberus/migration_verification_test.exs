defmodule Cerberus.MigrationVerificationTest do
  use ExUnit.Case, async: false

  alias Cerberus.MigrationVerification

  @moduletag :tmp_dir

  test "runs pre-test, migration, and post-test in order", %{tmp_dir: tmp_dir} do
    fixture_dir = build_fixture_project(tmp_dir)
    work_dir = Path.join(tmp_dir, "work")

    cmd_fun = fn cmd, args, opts ->
      send(self(), {:cmd, cmd, args, opts})
      {"ok", 0}
    end

    assert {:ok, result} =
             MigrationVerification.run(
               [
                 fixture_dir: fixture_dir,
                 work_dir: work_dir,
                 root_dir: "/repo/root",
                 keep: true
               ],
               cmd_fun
             )

    assert result.work_dir == work_dir
    assert result.test_file == "test/features/migration_ready_test.exs"
    assert result.report.summary.all_parity_pass?
    assert result.report.summary.total_rows == 1
    assert result.report.summary.pre_pass_rows == 1
    assert result.report.summary.post_pass_rows == 1
    assert result.report.summary.parity_pass_rows == 1
    assert [%{id: "pt_migration_ready", parity: true}] = result.report.rows

    assert_receive {:cmd, "mix", ["deps.get"], deps_opts}
    assert_receive {:cmd, "mix", ["test", "test/features/migration_ready_test.exs"], pre_opts}
    assert_receive {:cmd, "mix", ["test", "test/features/migration_ready_test.exs"], post_opts}

    assert cerberus_path(deps_opts) == "/repo/root"
    assert mode(pre_opts) == "phoenix_test"
    assert mode(post_opts) == "cerberus"

    assert File.read!(Path.join(work_dir, "test/features/migration_ready_test.exs")) =~ "import Cerberus"
  end

  test "records row-level parity for multiple rows", %{tmp_dir: tmp_dir} do
    fixture_dir = build_fixture_project(tmp_dir)

    File.write!(
      Path.join(fixture_dir, "test/features/migration_ready_second_test.exs"),
      """
      defmodule FixtureMigrationReadySecondTest do
        use ExUnit.Case, async: true

        import PhoenixTest

        test "placeholder second" do
          assert true
        end
      end
      """
    )

    rows = [
      %{id: "row_1", test_file: "test/features/migration_ready_test.exs"},
      %{id: "row_2", test_file: "test/features/migration_ready_second_test.exs"}
    ]

    assert {:ok, result} =
             MigrationVerification.run(
               [
                 fixture_dir: fixture_dir,
                 work_dir: Path.join(tmp_dir, "work"),
                 rows: rows,
                 keep: true
               ],
               fn _cmd, _args, _opts -> {"ok", 0} end
             )

    assert result.report.summary.total_rows == 2
    assert result.report.summary.pre_pass_rows == 2
    assert result.report.summary.post_pass_rows == 2
    assert result.report.summary.parity_pass_rows == 2
    assert result.report.summary.all_parity_pass?
    assert Enum.all?(result.report.rows, & &1.parity)
    assert Enum.map(result.report.rows, & &1.id) == ["row_1", "row_2"]
  end

  test "returns detailed failure for post-test failures", %{tmp_dir: tmp_dir} do
    fixture_dir = build_fixture_project(tmp_dir)
    work_dir = Path.join(tmp_dir, "work")

    cmd_fun = fn _cmd, args, opts ->
      case args do
        ["deps.get"] ->
          {"ok", 0}

        ["test", _file] ->
          if mode(opts) == "cerberus" do
            {"post failed", 1}
          else
            {"ok", 0}
          end
      end
    end

    assert {:error, failure} =
             MigrationVerification.run(
               [
                 fixture_dir: fixture_dir,
                 work_dir: work_dir,
                 keep: true
               ],
               cmd_fun
             )

    assert failure.stage == :post_test
    assert failure.row_id == "pt_migration_ready"
    assert failure.test_file == "test/features/migration_ready_test.exs"
    assert failure.status == 1
    assert failure.work_dir == work_dir
    assert failure.output == "post failed"
    assert failure.report.summary.total_rows == 1
    assert failure.report.summary.pre_pass_rows == 1
    assert failure.report.summary.post_pass_rows == 0
    assert failure.report.summary.parity_pass_rows == 0
    refute failure.report.summary.all_parity_pass?

    assert [%{id: "pt_migration_ready", pre_status: :pass, post_status: :fail, parity: false}] =
             failure.report.rows
  end

  test "returns prepare error when fixture directory is missing", %{tmp_dir: tmp_dir} do
    missing_fixture_dir = Path.join(tmp_dir, "missing")

    assert {:error, failure} =
             MigrationVerification.run(
               fixture_dir: missing_fixture_dir,
               work_dir: Path.join(tmp_dir, "work")
             )

    assert failure.stage == :prepare
    assert failure.message =~ "fixture directory not found"
  end

  test "runs end-to-end against committed migration fixture", %{tmp_dir: tmp_dir} do
    root_dir = Path.expand("../..", __DIR__)
    fixture_dir = Path.join(root_dir, "fixtures/migration_project")
    work_dir = Path.join(tmp_dir, "work")

    rows = [
      %{id: "pt_migration_ready", test_file: "test/features/migration_ready_test.exs"},
      %{id: "pt_static_nav", test_file: "test/features/pt_static_nav_test.exs"},
      %{id: "pt_text_assert", test_file: "test/features/pt_text_assert_test.exs"},
      %{id: "pt_text_refute", test_file: "test/features/pt_text_refute_test.exs"},
      %{id: "pt_click_navigation", test_file: "test/features/pt_click_navigation_test.exs"},
      %{id: "pt_form_fill", test_file: "test/features/pt_form_fill_test.exs"},
      %{id: "pt_select", test_file: "test/features/pt_select_test.exs"},
      %{id: "pt_choose", test_file: "test/features/pt_choose_test.exs"},
      %{id: "pt_checkbox_array", test_file: "test/features/pt_checkbox_array_test.exs"},
      %{id: "pt_submit_action", test_file: "test/features/pt_submit_action_test.exs"},
      %{id: "pt_upload", test_file: "test/features/pt_upload_test.exs"},
      %{id: "pt_path_assert", test_file: "test/features/pt_path_assert_test.exs"},
      %{id: "pt_path_refute", test_file: "test/features/pt_path_refute_test.exs"},
      %{id: "pt_live_click", test_file: "test/features/pt_live_click_test.exs"},
      %{id: "pt_live_change", test_file: "test/features/pt_live_change_test.exs"},
      %{id: "pt_live_nav", test_file: "test/features/pt_live_nav_test.exs"},
      %{id: "pt_live_async_timeout", test_file: "test/features/pt_live_async_timeout_test.exs"},
      %{id: "pt_unwrap", test_file: "test/features/pt_unwrap_test.exs"},
      %{id: "pt_scope_nested", test_file: "test/features/pt_scope_nested_test.exs"}
    ]

    assert {:ok, result} =
             MigrationVerification.run(
               [
                 root_dir: root_dir,
                 fixture_dir: fixture_dir,
                 work_dir: work_dir,
                 rows: rows,
                 keep: false
               ],
               &System.cmd/3
             )

    assert result.report.summary.total_rows == length(rows)
    assert result.report.summary.pre_pass_rows == length(rows)
    assert result.report.summary.post_pass_rows == length(rows)
    assert result.report.summary.parity_pass_rows == length(rows)
    assert result.report.summary.all_parity_pass?
    assert Enum.map(result.report.rows, & &1.id) == Enum.map(rows, & &1.id)
    assert Enum.all?(result.report.rows, & &1.parity)
    refute File.exists?(work_dir)
  end

  defp build_fixture_project(tmp_dir) do
    fixture_dir = Path.join(tmp_dir, "fixture")
    test_dir = Path.join(fixture_dir, "test/features")

    File.mkdir_p!(test_dir)

    File.write!(
      Path.join(test_dir, "migration_ready_test.exs"),
      """
      defmodule FixtureMigrationReadyTest do
        use ExUnit.Case, async: true

        import PhoenixTest

        test \"placeholder\" do
          assert true
        end
      end
      """
    )

    fixture_dir
  end

  defp mode(opts) do
    opts
    |> Keyword.fetch!(:env)
    |> Map.new()
    |> Map.fetch!("CERBERUS_MIGRATION_FIXTURE_MODE")
  end

  defp cerberus_path(opts) do
    opts
    |> Keyword.fetch!(:env)
    |> Map.new()
    |> Map.fetch!("CERBERUS_PATH")
  end
end
