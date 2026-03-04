defmodule Cerberus.HelperLocatorBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  @shared_browser_session_boot_timeout_ms 30_000
  @shared_browser_session_stop_timeout_ms 5_000

  setup_all do
    {owner_pid, browser_session} = start_shared_browser_session!()

    on_exit(fn ->
      stop_shared_browser_session(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "helper locators are consistent across static and browser for forms and navigation (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> fill_in(label("Search term"), "phoenix")
      |> submit(button("Run Search"))
      |> assert_has(text("Search query: phoenix", exact: true))
      |> visit("/search")
      |> fill_in(role(:textbox, name: "Search term"), "elixir")
      |> submit(role(:button, name: "Run Search"))
      |> assert_has(text("Search query: elixir", exact: true))
      |> visit("/articles")
      |> click(role(:link, name: "Counter"))
      |> assert_has(role(:button, name: "Increment", exact: true))
      |> click(link("Articles"))
      |> assert_has(text("Articles", exact: true))
    end

    test "sigil modifiers are consistent across static and browser for role/css/testid/exact flows (#{driver})",
         context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(~l"articles-title"t)
      |> click(~l"link:Counter"r)
      |> assert_has(~l"button:Increment"re)
      |> visit("/search")
      |> fill_in(~l"search-input"t, "elixir")
      |> submit(~l"search-submit"t)
      |> assert_has(~l"Search query: elixir"e)
    end

    test "duplicate live button labels are disambiguated for render_click conversion (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(button("Apply"))
      |> assert_has(text("Selected: primary", exact: true))
      |> click(role(:button, name: "Apply"))
      |> assert_has(text("Selected: primary", exact: true))
    end

    test "css sigil selector disambiguates duplicate live button labels (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(~l"#secondary-actions button"c)
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "click_button handles multiline data-confirm attributes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click_button(button("Create", exact: true))
      |> assert_has(text("Selected: confirmed", exact: true))
    end

    test "role link helper navigates from live route consistently (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(role(:link, name: "Articles"))
      |> assert_has(text("Articles", exact: true))
    end

    test "expanded role helpers tab/menuitem map to clickable controls (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(role(:tab, name: "Tab Primary"))
      |> assert_has(text("Selected: primary", exact: true))
      |> click(role(:menuitem, name: "Menu Secondary"))
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "testid helper works across drivers for assertions and form actions (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(testid("articles-title"))
      |> visit("/search")
      |> fill_in(testid("search-input"), "gandalf")
      |> submit(testid("search-submit"))
      |> assert_has(text("Search query: gandalf", exact: true))
    end

    test "testid helper supports click targets on live routes (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> click(testid("articles-counter-link"))
      |> click(testid("counter-increment-button"))
      |> assert_has(text("Count: 1", exact: true))
    end

    test "testid click disambiguates duplicate live button text without relying on text fallback (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(testid("apply-secondary"))
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "has locator option disambiguates duplicate live buttons with nested marker elements (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click("Apply" |> button() |> has(testid("apply-secondary-marker")))
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "has_not locator option disambiguates duplicate live buttons with nested marker elements (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click("Apply" |> button() |> has_not(testid("apply-secondary-marker")))
      |> assert_has(text("Selected: primary", exact: true))
    end

    test "pipe-composed and vs nesting semantics are consistent across static and browser (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/no (elements|clickable)/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/selector-edge")
        |> click("Apply" |> button() |> testid("apply-secondary-marker"), timeout: 0)
      end

      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click("Apply" |> button() |> has(testid("apply-secondary-marker")))
      |> assert_has(text("Selected: secondary", exact: true))
    end

    test "boolean locator algebra supports A and not B semantics (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(and_(button("Apply"), not_(testid("apply-secondary"))))
      |> assert_has(text("Selected: primary", exact: true))
    end

    test "boolean locator algebra supports not(A and B) semantics (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/selector-edge")
      |> click(
        and_(
          button("Apply"),
          not_(and_(button("Apply"), testid("apply-secondary")))
        )
      )
      |> assert_has(text("Selected: primary", exact: true))
    end

    test "or composition enforces strict uniqueness for actions (#{driver})", context do
      assert_raise ExUnit.AssertionError,
                   ~r/(expected exactly 1 matched element|no clickable element matched locator)/,
                   fn ->
                     unquote(driver)
                     |> driver_session(context)
                     |> visit("/live/selector-edge")
                     |> click(or_(css("#primary-actions button"), css("#secondary-actions button")), timeout: 0)
                   end
    end

    test "count-position filters pick deterministic action targets across fill_in and submit (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/search")
      |> submit(button(~r/^Run/))
      |> assert_path("/search/results")
      |> visit("/search")
      |> fill_in(label("Search term"), "shire", first: true)
      |> submit(button(~r/^Run/), first: true)
      |> assert_path("/search/results", query: [q: "shire"])
      |> visit("/search")
      |> fill_in(label("Search term"), "gondor", last: true)
      |> submit(button(~r/^Run/), last: true)
      |> assert_path("/search/nested/results", query: [nested_q: "gondor"])
    end

    test "placeholder/title/alt/aria_label helpers behave consistently in static and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> assert_has(title("Articles heading", exact: true))
      |> assert_has(aria_label("Articles heading aria", exact: true))
      |> assert_has(alt("Articles hero image", exact: true))
      |> visit("/search")
      |> assert_has(aria_label("Search heading aria", exact: true))
      |> assert_has(testid("search-title"))
      |> assert_has(placeholder("Search by term", exact: true))
      |> fill_in(aria_label("Search term aria"), "boromir")
      |> submit(aria_label("Run search aria", exact: true))
      |> assert_has(text("Search query: boromir", exact: true))
    end

    test "placeholder/title/testid/aria_label helpers behave consistently in live and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/form-change")
      |> assert_has(title("Live name input", exact: true))
      |> assert_has(placeholder("Live name", exact: true))
      |> assert_has(aria_label("Live name aria", exact: true))
      |> fill_in(aria_label("Live name aria"), "Eowyn")
      |> assert_has(testid("live-change-name"))
      |> assert_has(text("name: Eowyn", exact: true))
    end

    test "state filters can target selected radios in live and browser (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/controls")
      |> choose(label("Mail Choice"), selected: true)
      |> assert_has(text("contact: mail", exact: true))
    end

    test "state filters reject non-matching radio state in live and browser (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/no (elements|form field) matched locator/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> choose(label("Email Choice"), selected: true, timeout: 0)
      end
    end

    test "state filters apply before disabled select checks in live and browser (#{driver})", context do
      assert_raise ExUnit.AssertionError, ~r/no (elements|form field) matched locator/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> select(label("Disabled select"), option: "Cannot submit", disabled: false, timeout: 0)
      end

      assert_raise ExUnit.AssertionError, ~r/matched select field is disabled/, fn ->
        unquote(driver)
        |> driver_session(context)
        |> visit("/live/controls")
        |> select(label("Disabled select"), option: "Cannot submit", disabled: true, timeout: 0)
      end
    end
  end

  defp driver_session(:phoenix, _context), do: session(:phoenix)
  defp driver_session(:browser, context), do: context.shared_browser_session

  defp start_shared_browser_session! do
    parent = self()

    owner_pid =
      spawn_link(fn ->
        try do
          browser_session = session(:browser)
          send(parent, {:shared_browser_session_ready, self(), browser_session})

          receive do
            :stop -> :ok
          end
        rescue
          error ->
            send(parent, {:shared_browser_session_failed, self(), error, __STACKTRACE__})
        end
      end)

    receive do
      {:shared_browser_session_ready, ^owner_pid, browser_session} ->
        {owner_pid, browser_session}

      {:shared_browser_session_failed, ^owner_pid, error, stacktrace} ->
        reraise(error, stacktrace)
    after
      @shared_browser_session_boot_timeout_ms ->
        Process.exit(owner_pid, :kill)

        raise "timed out starting shared browser session after #{@shared_browser_session_boot_timeout_ms}ms"
    end
  end

  defp stop_shared_browser_session(owner_pid) when is_pid(owner_pid) do
    if Process.alive?(owner_pid) do
      ref = Process.monitor(owner_pid)
      send(owner_pid, :stop)

      receive do
        {:DOWN, ^ref, :process, ^owner_pid, _reason} -> :ok
      after
        @shared_browser_session_stop_timeout_ms ->
          Process.exit(owner_pid, :kill)
      end
    end

    :ok
  end
end
