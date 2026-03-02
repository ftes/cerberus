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
    assert rewritten =~ "Cerberus.visit(session(conn), \"/articles\")"
    refute rewritten =~ "import PhoenixTest"
    assert output =~ "updated #{file}"
    assert output =~ "Mode: write"
  end

  test "write mode preserves comments in rewritten files", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_comments_test.exs")

    File.write!(
      file,
      """
      defmodule SampleCommentsTest do
        # import comment
        import PhoenixTest

        test "example", %{conn: conn} do
          # pipeline comment
          conn
          # visit comment
          |> visit("/articles")
          |> assert_has("#main", text: "Articles") # trailing comment
        end
      end
      """
    )

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "# import comment"
    assert rewritten =~ "# pipeline comment"
    assert rewritten =~ "# visit comment"
    assert rewritten =~ "# trailing comment"
    assert rewritten =~ "import Cerberus"
    assert rewritten =~ ~r/session\(conn\)|\|> session\(\)/
    refute rewritten =~ "import PhoenixTest"
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
          session = PhoenixTest.fill_in(session, "Search term", with: "phoenix")
          PhoenixTest.select(session, "Role", option: "admin")
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

    assert rewritten =~ "Cerberus.visit(session(conn), \"/articles\")"
    assert rewritten =~ ~s{Cerberus.assert_has(session, "#main", "Articles")}
    assert rewritten =~ ~s{Cerberus.refute_has(session, "#missing", "Nope")}
    assert rewritten =~ ~s{Cerberus.fill_in(session, "Search term", "phoenix")}
    assert rewritten =~ ~s{Cerberus.select(session, "Role", "admin")}
    refute output =~ "visit(conn, ...)"
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

  test "write mode inserts import Cerberus when local rewritten calls remain", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_local_calls_no_import_test.exs")

    File.write!(
      file,
      """
      defmodule SampleLocalCallsNoImportTest do
        use MyCase

        test "example", %{conn: conn} do
          conn
          |> visit("/articles")
          |> assert_has("#main", text: "Articles")
        end
      end
      """
    )

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "import Cerberus"
    assert rewritten =~ "|> session()"
    refute rewritten =~ "import PhoenixTest"
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
    assert rewritten =~ ~s{Assertions.assert_has(conn, "#main", "Articles")}
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
    assert rewritten =~ ~s{PTA.refute_has(conn, "#missing", "Nope")}
    refute rewritten =~ "alias PhoenixTest.Assertions, as: PTA"
    assert output =~ "updated #{file}"
  end

  test "write mode canonicalizes local imported assertion and fill_in shorthands", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_local_shorthand_test.exs")

    File.write!(
      file,
      """
      defmodule SampleLocalShorthandTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/search")
          |> fill_in("Search term", with: "phoenix")
          |> assert_has("body", text: "Search query: phoenix")
        end
      end
      """
    )

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ ~s{|> fill_in("Search term", "phoenix")}
    assert rewritten =~ ~s{|> assert_has("body", "Search query: phoenix")}
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
          |> within(css("#upload-form"), fn scoped ->
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
    test_root = Path.join(project_copy, "test")
    test_dir = Path.join(project_copy, "test/features")
    static_copy = Path.join(test_dir, "phoenix_test_baseline_test.exs")
    feature_case_copy = Path.join(test_dir, "pt_feature_case_import_test.exs")
    form_fill_copy = Path.join(test_dir, "pt_form_fill_test.exs")
    support_feature_case_copy = Path.join(project_copy, "test/support/feature_case.ex")

    File.cp_r!(fixture_dir, project_copy)

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", test_root])
      end)

    rewritten_static = File.read!(static_copy)
    rewritten_feature_case = File.read!(feature_case_copy)
    rewritten_form_fill = File.read!(form_fill_copy)
    rewritten_support_feature_case = File.read!(support_feature_case_copy)

    assert rewritten_static =~ "import Cerberus"
    assert rewritten_feature_case =~ "|> session()"
    assert rewritten_feature_case =~ "|> assert_has(\"h1\", expected)"
    assert rewritten_form_fill =~ ~s{Cerberus.fill_in(session, "Search term", value)}
    assert rewritten_form_fill =~ ~s{Cerberus.assert_has(session, "body", expected)}
    assert rewritten_support_feature_case =~ "import Cerberus"
    refute rewritten_support_feature_case =~ "import PhoenixTest"
  end

  @tag timeout: 180_000
  test "runs full sample suite before migration and applies migration task", %{tmp_dir: tmp_dir} do
    fixture_dir = "fixtures/migration_project"
    work_dir = Path.join(tmp_dir, "work")
    test_glob = "test/features/pt_*_test.exs"

    File.cp_r!(fixture_dir, work_dir)

    assert {_output, 0} = run_mix(work_dir, ["deps.get"])

    test_paths = expand_test_paths(work_dir, test_glob)
    assert test_paths != [], "no test files matched #{test_glob}"

    pre_args = ["test" | test_paths]
    {pre_output, pre_status} = run_mix(work_dir, pre_args)
    assert pre_status == 0, "pre-migration suite failed:\n#{pre_output}"

    {migrate_output, migrate_status} =
      run_mix(work_dir, ["cerberus.migrate_phoenix_test", "--write", test_glob])

    assert migrate_status == 0, "migration failed:\n#{migrate_output}"
  end

  defp run_mix(work_dir, args) do
    base_env = [{"MIX_ENV", "test"}, {"CERBERUS_PATH", Path.expand(".")}]

    System.cmd("mix", args, cd: work_dir, env: base_env, stderr_to_stdout: true)
  end

  defp expand_test_paths(work_dir, test_glob) do
    work_dir
    |> Path.join(test_glob)
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, work_dir))
    |> Enum.sort()
  end
end
