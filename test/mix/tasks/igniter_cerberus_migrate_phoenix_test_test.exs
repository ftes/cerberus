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
    assert output =~ "alias PhoenixTest.Assertions"
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

  test "ast rewrite updates use PhoenixTest.Playwright.Case and warns once", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_playwright_case_test.exs")

    File.write!(
      file,
      """
      defmodule SamplePlaywrightCaseTest do
        use PhoenixTest.Playwright.Case, async: true

        test "example", %{conn: conn} do
          conn |> visit("/")
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

    assert rewritten =~ "use Cerberus.Playwright.Case"

    assert output =~
             "WARNING #{file}: PhoenixTest.Playwright calls need manual migration to browser-only Cerberus APIs."

    assert output =~
             "WARNING #{file}: conn |> visit(...) PhoenixTest flow needs manual session bootstrap in Cerberus."
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
          PhoenixTest.Playwright.screenshot("preview.png")
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
             "WARNING #{file}: PhoenixTest.Playwright calls need manual migration to browser-only Cerberus APIs."
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
    playwright_copy = Path.join(test_dir, "phoenix_test_playwright_baseline_test.exs")

    File.cp_r!(fixture_dir, project_copy)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", test_dir])
      end)

    rewritten_static = File.read!(static_copy)
    rewritten_playwright = File.read!(playwright_copy)

    assert rewritten_static =~ "import Cerberus"
    assert rewritten_playwright =~ "use Cerberus.Playwright.Case"
    assert output =~ "WARNING #{playwright_copy}:"
  end

  @tag timeout: 180_000
  test "runs full sample suite before and after migration", %{tmp_dir: tmp_dir} do
    fixture_dir = "fixtures/migration_project"
    work_dir = Path.join(tmp_dir, "work")
    test_glob = "test/features/pt_*_test.exs"

    File.rm_rf!(work_dir)
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
