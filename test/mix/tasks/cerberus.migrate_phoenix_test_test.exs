defmodule Mix.Tasks.Cerberus.MigratePhoenixTestTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @task "cerberus.migrate_phoenix_test"
  @moduletag :tmp_dir
  @project_root Path.expand("../../../", __DIR__)
  @fixture_project_dir Path.join(@project_root, "fixtures/migration_project")

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
    assert rewritten =~ ~s{Cerberus.assert_has(session, Cerberus.and_(Cerberus.css("#main"), ~l"Articles"i))}
    assert rewritten =~ ~s{Cerberus.refute_has(session, Cerberus.and_(Cerberus.css("#missing"), ~l"Nope"i))}
    assert rewritten =~ ~s{Cerberus.fill_in(session, ~l"Search term"i, "phoenix")}
    assert rewritten =~ ~s{Cerberus.select(session, ~l"Role"i, option: ~l"admin"e)}
    refute output =~ "visit(conn, ...)"
    refute output =~ "Direct PhoenixTest.<function> call detected"
  end

  test "write mode keeps non-literal select option values unchanged", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_select_option_variable_test.exs")

    File.write!(
      file,
      """
      defmodule SampleSelectOptionVariableTest do
        import PhoenixTest

        defp apply_action(session, opacity), do: select(session, "Watermark opacity", option: opacity)
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

    assert rewritten =~
             ~s{defp apply_action(session, opacity), do: select(session, ~l"Watermark opacity"i, option: opacity)}

    refute rewritten =~ ~s{option: text(opacity)}
  end

  test "write mode rewrites local select option strings without rewrite failures", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_select_option_string_test.exs")

    File.write!(
      file,
      """
      defmodule SampleSelectOptionStringTest do
        import PhoenixTest

        defp apply_action(conn), do: select(conn, "Unit", option: "Main")
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
    assert rewritten =~ ~s{defp apply_action(conn), do: select(conn, ~l"Unit"i, option: ~l"Main"e)}
    refute output =~ "File rewrite failed and was skipped"
  end

  test "write mode rewrites select text option locators to sigils", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_select_option_text_test.exs")

    File.write!(
      file,
      """
      defmodule SampleSelectOptionTextTest do
        import PhoenixTest

        defp apply_action(conn), do: select(conn, "Unit", option: text("Main", exact: false))
      end
      """
    )

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ ~s{defp apply_action(conn), do: select(conn, ~l"Unit"i, option: ~l"Main"i)}
    refute rewritten =~ ~s{option: text("Main", exact: false)}
  end

  test "write mode rewrites piped select locator and option literals", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_piped_select_test.exs")

    File.write!(
      file,
      """
      defmodule SamplePipedSelectTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/offers/new")
          |> select("Status", option: "complete")
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

    assert rewritten =~ ~r/\|> select\(\s*~l"Status"i,\s*option: ~l"complete"e\s*\)/s
    refute rewritten =~ ~s{|> select("Status", option: ~l"complete"e)}
  end

  test "write mode rewrites action exact options into locator sigils", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_action_exact_test.exs")

    File.write!(
      file,
      """
      defmodule SampleActionExactTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/choose")
          |> choose("Test A", exact: false)
          |> choose("Test B", exact: true)
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

    assert rewritten =~ ~r/\|> choose\(\s*~l"Test A"e\s*\)/s
    assert rewritten =~ ~r/\|> choose\(\s*~l"Test B"i\s*\)/s
    refute rewritten =~ "exact:"
  end

  test "write mode rewrites assertion exact options into locator sigils", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_assert_exact_test.exs")

    File.write!(
      file,
      """
      defmodule SampleAssertExactTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/articles")
          |> assert_has("#main", text: "Articles", exact: true)
          |> refute_has("#main", text: "Nope", exact: false)
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

    assert rewritten =~ ~r/\|> assert_has\(\s*and_\(\s*css\("#main"\),\s*~l"Articles"e\s*\)\s*\)/s
    assert rewritten =~ ~r/\|> refute_has\(\s*and_\(\s*css\("#main"\),\s*~l"Nope"i\s*\)\s*\)/s
    refute rewritten =~ "exact:"
  end

  test "write mode rewrites click_link/click_button calls to click", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_click_aliases_test.exs")

    File.write!(
      file,
      """
      defmodule SampleClickAliasesTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/articles")
          |> click_link("Counter")
          |> click_button("Increment")
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

    assert rewritten =~ ~s{|> click(link: "Counter")}
    assert rewritten =~ ~s{|> click(button: "Increment")}
    refute rewritten =~ ~s{|> click(~l"Counter"i)}
    refute rewritten =~ ~s{|> click(~l"Increment"i)}
    refute rewritten =~ "click_link("
    refute rewritten =~ "click_button("
  end

  test "write mode rewrites remote click aliases to click with clickable locators", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_remote_click_aliases_test.exs")

    File.write!(
      file,
      """
      defmodule SampleRemoteClickAliasesTest do
        test "example", %{conn: conn} do
          session = PhoenixTest.visit(conn, "/articles")
          session = PhoenixTest.click_link(session, "Counter")
          PhoenixTest.click_button(session, ~r/Increment/i)
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

    assert rewritten =~ ~s{Cerberus.click(session, link: "Counter")}
    assert rewritten =~ ~s{Cerberus.click(session, button: ~r/Increment/i)}
    refute rewritten =~ ~s{Cerberus.click(session, ~l"Counter"i)}
    refute rewritten =~ "click_link("
    refute rewritten =~ "click_button("
  end

  test "write mode collapses scoped click aliases into single-locator click calls", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_scoped_click_aliases_test.exs")

    File.write!(
      file,
      """
      defmodule SampleScopedClickAliasesTest do
        test "example", %{conn: conn} do
          session = PhoenixTest.visit(conn, "/articles")
          session = PhoenixTest.click_link(session, "#actions", "Counter")
          PhoenixTest.click_button(session, "#actions", "Increment", timeout: 50)
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

    assert rewritten =~ ~s{Cerberus.click(session, Cerberus.link("#actions", "Counter"))}
    assert rewritten =~ ~s{Cerberus.click(session, Cerberus.button("#actions", "Increment"), timeout: 50)}
    refute rewritten =~ ~s{Cerberus.click(session, "#actions", "Counter")}
    refute rewritten =~ ~s{Cerberus.click(session, "#actions", "Increment", timeout: 50)}
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

  test "write mode preserves phoenix_test config and appends cerberus endpoint config", %{
    tmp_dir: tmp_dir
  } do
    config_dir = Path.join(tmp_dir, "config")
    File.mkdir_p!(config_dir)
    file = Path.join(config_dir, "test.exs")

    File.write!(
      file,
      """
      import Config

      config :phoenix_test,
        endpoint: MyAppWeb.Endpoint,
        otp_app: :my_app,
        playwright: [
          headless: true
        ]
      """
    )

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten =~ "config :phoenix_test,"
    assert rewritten =~ "endpoint: MyAppWeb.Endpoint"
    assert rewritten =~ "otp_app: :my_app"
    assert rewritten =~ "playwright:"
    assert rewritten =~ "headless: true"
    assert rewritten =~ "config :cerberus, endpoint: MyAppWeb.Endpoint"
    refute rewritten =~ "config :phoenix_test, endpoint: MyAppWeb.Endpoint"
    assert output =~ "updated #{file}"
  end

  test "write mode appends test helper endpoint bootstrap inferred from neighboring config/test.exs", %{tmp_dir: tmp_dir} do
    config_dir = Path.join(tmp_dir, "config")
    test_dir = Path.join(tmp_dir, "test")
    File.mkdir_p!(config_dir)
    File.mkdir_p!(test_dir)

    File.write!(
      Path.join(config_dir, "test.exs"),
      """
      import Config
      config :phoenix_test, endpoint: MyAppWeb.Endpoint
      """
    )

    helper = Path.join(test_dir, "test_helper.exs")
    File.write!(helper, "ExUnit.start()\n")

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", helper])
      end)

    rewritten = File.read!(helper)

    assert rewritten =~ "ExUnit.start()"
    assert rewritten =~ "Application.put_env(:cerberus, :endpoint, MyAppWeb.Endpoint)"
    refute output =~ "WARNING"
    assert output =~ "updated #{helper}"
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
    assert rewritten =~ ~s{Assertions.assert_has(conn, Assertions.and_(Assertions.css("#main"), ~l"Articles"i))}
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
    assert rewritten =~ ~s{PTA.refute_has(conn, PTA.and_(PTA.css("#missing"), ~l"Nope"i))}
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

    assert rewritten =~ ~r/\|> fill_in\(\s*~l"Search term"i,\s*"phoenix"\s*\)/s
    assert rewritten =~ ~r/\|> assert_has\(\s*and_\(\s*css\("body"\),\s*~l"Search query: phoenix"i\s*\)\s*\)/s
  end

  test "write mode wraps choose locator variables with label/1", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_choose_variable_test.exs")

    File.write!(
      file,
      """
      defmodule SampleChooseVariableTest do
        import PhoenixTest

        test "example", %{conn: conn} do
          conn
          |> visit("/choose")
          |> choose_contact("Phone")
        end

        defp choose_contact(session, choice_label) do
          choose(session, choice_label)
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

    assert rewritten =~ "choose(session, label(choice_label))"
  end

  test "write mode does not rewrite unrelated select/submit calls", %{tmp_dir: tmp_dir} do
    file = Path.join(tmp_dir, "sample_non_phoenix_select_submit_test.exs")

    original = """
    defmodule SampleNonPhoenixSelectSubmitTest do
      use ExUnit.Case, async: true

      alias MyApp.Timecards

      test "keeps non-phoenix calls untouched" do
        _query = select([pra], count(pra.id))
        tc = :timecard
        project = :project
        _result = Timecards.submit(tc, project)
      end
    end
    """

    File.write!(file, original)

    _output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--write", file])
      end)

    rewritten = File.read!(file)

    assert rewritten == original
    refute rewritten =~ "import Cerberus"
    refute rewritten =~ "text:"
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
    assert rewritten =~ ~r/\|> upload\(\s*~l"Avatar"i,\s*"\/tmp\/avatar\.jpg"\s*\)/s
    assert rewritten =~ "|> submit()"
    refute rewritten =~ "import PhoenixTest"
    refute output =~ "Direct PhoenixTest.<function> call detected"
    assert output =~ "updated #{file}"
    assert output =~ "Mode: write"
  end

  @tag :slow
  test "can run against committed nested Phoenix fixture project tests", %{tmp_dir: tmp_dir} do
    fixture_dir = @fixture_project_dir
    project_copy = Path.join(tmp_dir, "migration_project")
    test_root = Path.join(project_copy, "test")
    test_dir = Path.join(project_copy, "test/features")
    static_copy = Path.join(test_dir, "phoenix_test_baseline_test.exs")
    migration_ready_copy = Path.join(test_dir, "migration_ready_test.exs")
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
    rewritten_migration_ready = File.read!(migration_ready_copy)
    rewritten_feature_case = File.read!(feature_case_copy)
    rewritten_form_fill = File.read!(form_fill_copy)
    rewritten_support_feature_case = File.read!(support_feature_case_copy)

    assert rewritten_static =~ "import Cerberus"
    assert rewritten_static =~ ~s{|> click(link: "Counter")}
    assert rewritten_static =~ ~s{|> click(button: "Increment")}
    refute rewritten_static =~ ~s{|> click(~l"Counter"i)}
    refute rewritten_static =~ "click_link("
    refute rewritten_static =~ "click_button("
    assert rewritten_migration_ready =~ ~s{|> click(link: "Counter")}
    assert rewritten_migration_ready =~ ~s{|> click(button: "Increment")}
    refute rewritten_migration_ready =~ "click_link("
    refute rewritten_migration_ready =~ "click_button("
    assert rewritten_feature_case =~ "|> session()"

    assert rewritten_feature_case =~
             ~r/\|> assert_has\(\s*and_\(\s*css\("h1"\),\s*text\(expected,\s*exact:\s*false\)\s*\)\s*\)/s

    assert rewritten_form_fill =~ ~s{Cerberus.fill_in(session, ~l"Search term"i, value)}

    assert rewritten_form_fill =~
             ~r/Cerberus\.assert_has\(\s*session,\s*Cerberus\.and_\(\s*Cerberus\.css\("body"\),\s*(?:Cerberus\.)?text\(expected,\s*exact:\s*false\)\s*\)\s*\)/s

    assert rewritten_support_feature_case =~ "import Cerberus"
    refute rewritten_support_feature_case =~ "import PhoenixTest"
  end

  @tag :slow
  test "runs full sample suite before migration and applies migration task", %{tmp_dir: tmp_dir} do
    fixture_dir = @fixture_project_dir
    work_dir = Path.join(tmp_dir, "work")
    test_glob = "test/features/pt_*_test.exs"
    support_glob = "test/support/**/*.ex"

    File.cp_r!(fixture_dir, work_dir)

    assert {_output, 0} = run_mix(work_dir, ["deps.get"])

    test_paths = expand_test_paths(work_dir, test_glob)
    assert test_paths != [], "no test files matched #{test_glob}"

    pre_args = ["test" | test_paths]
    {pre_output, pre_status} = run_mix(work_dir, pre_args)
    assert pre_status == 0, "pre-migration suite failed:\n#{pre_output}"

    {migrate_output, migrate_status} =
      run_mix(work_dir, ["cerberus.migrate_phoenix_test", "--write", test_glob, support_glob])

    assert migrate_status == 0, "migration failed:\n#{migrate_output}"

    Enum.each(test_paths, fn test_path ->
      rewritten = File.read!(Path.join(work_dir, test_path))
      refute rewritten =~ "click_link("
      refute rewritten =~ "click_button("
    end)

    post_args = ["test" | test_paths]
    {post_output, post_status} = run_mix(work_dir, post_args)
    assert post_status == 0, "post-migration suite failed:\n#{post_output}"
  end

  defp run_mix(work_dir, args) do
    base_env = [{"MIX_ENV", "test"}, {"CERBERUS_PATH", @project_root}]

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
