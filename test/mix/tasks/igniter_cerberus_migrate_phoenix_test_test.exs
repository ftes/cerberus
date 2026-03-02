defmodule Mix.Tasks.Igniter.Cerberus.MigratePhoenixTestTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "cerberus.migrate_phoenix_test"
  @moduletag :tmp_dir

  test "dry-run prints diff and keeps files unchanged", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_feature_test.exs")

    original = """
    defmodule SampleFeatureTest do
      use ExUnit.Case, async: true
      import PhoenixTest
      alias PhoenixTest.Assertions

      test "example", %{conn: conn} do
        conn
        |> visit("/articles")
        |> Assertions.assert_has("#main", text: "Articles")
      end
    end
    """

    File.write!(file, original)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, [file])
      end)

    assert output =~ "diff --git"
    assert output =~ "import Cerberus"
    assert output =~ "alias Cerberus, as: Assertions"
    assert output =~ "Mode: dry-run"
    assert File.read!(file) == original
  end

  test "write mode applies AST rewrites only for supported patterns", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_write_test.exs")

    File.write!(
      file,
      """
      defmodule SampleWriteTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          PhoenixTest.visit(conn, "/articles")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "import Cerberus"
    assert rewritten =~ "PhoenixTest.visit(conn, \"/articles\")"
    refute rewritten =~ "import PhoenixTest"
    assert output =~ "updated #{file}"
    assert output =~ "Mode: write"
  end

  test "write mode rewrites safe direct PhoenixTest calls", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_direct_calls_test.exs")

    File.write!(
      file,
      """
      defmodule SampleDirectCallsTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          session = PhoenixTest.visit(conn, "/articles")
          session = PhoenixTest.assert_has(session, "#main", text: "Articles")
          PhoenixTest.Assertions.refute_has(session, "#missing", text: "Nope")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "PhoenixTest.visit(conn, \"/articles\")"
    assert rewritten =~ ~s{Cerberus.assert_has(session, "#main", text: "Articles")}
    assert rewritten =~ ~s{Cerberus.refute_has(session, "#missing", text: "Nope")}
    assert output =~ "WARNING #{file}: visit(conn, ...) PhoenixTest flow needs manual session bootstrap in Cerberus."
    refute output =~ "Direct PhoenixTest.<function> call detected"
  end

  test "write mode rewrites PhoenixTest.visit when first arg is not conn", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_direct_visit_test.exs")

    File.write!(
      file,
      """
      defmodule SampleDirectVisitTest do
        import PhoenixTest

        test "example" do
          session = build_session()
          PhoenixTest.visit(session, "/articles")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "Cerberus.visit(session, \"/articles\")"
    refute rewritten =~ "PhoenixTest.visit(session, \"/articles\")"
    refute output =~ "visit(conn, ...)"
    refute output =~ "Direct PhoenixTest.<function> call detected"
  end

  test "write mode rewrites import PhoenixTest.Assertions", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_import_assertions_test.exs")

    File.write!(
      file,
      """
      defmodule SampleImportAssertionsTest do
        import PhoenixTest.Assertions
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "import Cerberus"
    refute rewritten =~ "import PhoenixTest.Assertions"
    assert output =~ "updated #{file}"
  end

  test "write mode rewrites alias PhoenixTest.Assertions with preserved alias name", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_alias_assertions_test.exs")

    File.write!(
      file,
      """
      defmodule SampleAliasAssertionsTest do
        alias PhoenixTest.Assertions

        test "example", %{conn: conn} do
          Assertions.assert_has(conn, "#main", text: "Articles")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "alias Cerberus, as: Assertions"
    refute rewritten =~ "alias PhoenixTest.Assertions"
    assert output =~ "updated #{file}"
  end

  test "write mode preserves explicit assertions alias name", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_alias_assertions_explicit_test.exs")

    File.write!(
      file,
      """
      defmodule SampleAliasAssertionsExplicitTest do
        alias PhoenixTest.Assertions, as: PTA

        test "example", %{conn: conn} do
          PTA.refute_has(conn, "#missing", text: "Nope")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "alias Cerberus, as: PTA"
    refute rewritten =~ "alias PhoenixTest.Assertions, as: PTA"
    assert output =~ "updated #{file}"
  end

  test "reports warnings for unsupported migration patterns", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_warning_test.exs")

    File.write!(
      file,
      """
      defmodule SampleWarningTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn |> visit("/articles")
          screenshot("preview.png")
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, [file])
      end)

    assert output =~ "WARNING #{file}: conn |> visit(...) PhoenixTest flow needs manual session bootstrap in Cerberus."

    assert output =~
             "WARNING #{file}: Browser helper call likely needs manual migration to Cerberus browser extensions."
  end

  test "reports warning for unsupported direct PhoenixTest call", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_direct_warning_test.exs")

    File.write!(
      file,
      """
      defmodule SampleDirectWarningTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          PhoenixTest.custom_helper(conn)
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, [file])
      end)

    assert output =~
             "WARNING #{file}: Direct PhoenixTest.<function> call detected; migrate to Cerberus session-first flow manually."
  end

  test "reports warning for use PhoenixTest and leaves code unchanged", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_use_phoenix_test.exs")

    original = """
    defmodule SampleUsePhoenixTest do
      use PhoenixTest
    end
    """

    File.write!(file, original)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    assert File.read!(file) == original

    assert output =~
             "WARNING #{file}: use PhoenixTest has no direct Cerberus equivalent and needs manual migration."

    refute output =~ "updated #{file}"
  end

  test "write mode preserves upload pipelines and makes them Cerberus-callable", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_upload_test.exs")

    File.write!(
      file,
      """
      defmodule SampleUploadTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/upload")
          |> within("#upload-form", fn scoped ->
            scoped
            |> upload("Avatar", "/tmp/avatar.jpg")
            |> submit()
          end)
        end
      end
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "import Cerberus"
    assert rewritten =~ ~s{|> upload("Avatar", "/tmp/avatar.jpg")}
    assert rewritten =~ "|> submit()"
    refute rewritten =~ "import PhoenixTest"
    refute output =~ "Direct PhoenixTest.<function> call detected"
    assert output =~ "updated #{file}"
    assert output =~ "Mode: write"
  end

  test "can run against committed nested Phoenix fixture project tests", %{tmp_dir: tmp_dir} do
    fixture_dir = "fixtures/migration_project"
    project_copy = Path.join(tmp_dir, "migration_project")
    test_dir = Path.join(project_copy, "test/features")
    static_copy = Path.join(test_dir, "phoenix_test_baseline_test.exs")

    File.cp_r!(fixture_dir, project_copy)

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", test_dir])
      end)

    rewritten_static = File.read!(static_copy)

    assert rewritten_static =~ "import Cerberus"
  end

  @tag timeout: 180_000
  test "runs full sample suite before and after migration", %{tmp_dir: tmp_dir} do
    fixture_dir = "fixtures/migration_project"
    work_dir = Path.join(tmp_dir, "work")
    test_glob = "test/features/pt_*_test.exs"

    File.cp_r!(fixture_dir, work_dir)

    assert {_output, 0} = run_mix(work_dir, ["deps.get"])

    test_paths = expand_test_paths(work_dir, test_glob)
    assert test_paths != [], "no test files matched #{test_glob}"

    pre_args = ["test" | test_paths]
    {pre_output, pre_status} = run_mix(work_dir, pre_args, mode: "phoenix_test")
    assert pre_status == 0, "pre-migration suite failed:\n#{pre_output}"

    {migrate_output, migrate_status} =
      run_mix(work_dir, ["cerberus.migrate_phoenix_test", "--write", test_glob])

    assert migrate_status == 0, "migration failed:\n#{migrate_output}"

    post_args = ["test" | test_paths]
    {post_output, post_status} = run_mix(work_dir, post_args, mode: "cerberus")
    assert post_status == 0, "post-migration suite failed:\n#{post_output}"
  end

  defp run_mix(work_dir, args, opts \\ []) do
    base_env = [{"MIX_ENV", "test"}, {"CERBERUS_PATH", Path.expand(".")}]

    env =
      case Keyword.fetch(opts, :mode) do
        {:ok, mode} -> [{"CERBERUS_MIGRATION_FIXTURE_MODE", mode} | base_env]
        :error -> base_env
      end

    System.cmd("mix", args, cd: work_dir, env: env, stderr_to_stdout: true)
  end

  defp expand_test_paths(work_dir, test_glob) do
    work_dir
    |> Path.join(test_glob)
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, work_dir))
    |> Enum.sort()
  end
end
