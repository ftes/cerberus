defmodule Mix.Tasks.Igniter.Cerberus.MigratePhoenixTestTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "igniter.cerberus.migrate_phoenix_test"

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "cerberus-migrate-task-#{System.unique_integer([:positive])}")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    %{tmp_dir: tmp_dir}
  end

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

  test "write mode applies only safe rewrites", %{tmp_dir: tmp_dir} do
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

  test "can run against committed PhoenixTest fixture files", %{tmp_dir: tmp_dir} do
    fixture_dir = Path.expand("../../support/fixtures/migration_source", __DIR__)
    live_source = Path.join(fixture_dir, "live_fixture.exs")
    static_source = Path.join(fixture_dir, "static_fixture.exs")
    live_copy = Path.join(tmp_dir, "live_test.exs")
    static_copy = Path.join(tmp_dir, "static_test.exs")

    File.cp!(live_source, live_copy)
    File.cp!(static_source, static_copy)

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", live_copy, static_copy])
      end)

    rewritten_live = File.read!(live_copy)
    rewritten_static = File.read!(static_copy)

    assert rewritten_live =~ "import Cerberus"
    assert rewritten_static =~ "import Cerberus"
    assert output =~ "WARNING #{live_copy}:"
    assert output =~ "WARNING #{static_copy}:"
  end
end
