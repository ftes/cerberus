defmodule Cerberus.OpenBrowserBehaviorTest do
  use ExUnit.Case, async: true

  import Cerberus

  alias Cerberus.TestSupport.SharedBrowserSession

  setup_all do
    {owner_pid, browser_session} = SharedBrowserSession.start!()

    on_exit(fn ->
      SharedBrowserSession.stop(owner_pid)
    end)

    {:ok, shared_browser_session: browser_session}
  end

  for driver <- [:phoenix, :browser] do
    test "open_browser snapshots static pages consistently in static and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/articles")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Articles"
        File.rm(path)
      end)
    end

    test "open_browser snapshots live pages consistently in live and browser drivers (#{driver})", context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/live/counter")
      |> open_browser(fn path ->
        assert File.exists?(path)
        assert File.read!(path) =~ "Count: 0"
        File.rm(path)
      end)
    end

    test "open_browser rewrites stylesheet paths to local static assets and strips scripts (#{driver})",
         context do
      unquote(driver)
      |> driver_session(context)
      |> visit("/styled-snapshot")
      |> open_browser(fn path ->
        content = File.read!(path)
        html = LazyHTML.from_document(content)
        [css_href] = html |> LazyHTML.query("link[rel=stylesheet]") |> LazyHTML.attribute("href")

        assert String.starts_with?(css_href, "file://")
        css_path = String.replace_prefix(css_href, "file://", "")
        assert css_path =~ "/cerberus/priv/static/assets/app.css"
        assert File.exists?(css_path)

        refute content =~ "<script"
        File.rm(path)
      end)
    end
  end

  test "open_browser on live phoenix sessions keeps head stylesheet links via LiveViewTest delegation" do
    :phoenix
    |> session()
    |> visit("/live/counter")
    |> open_browser(fn path ->
      content = File.read!(path)
      html = LazyHTML.from_document(content)

      [css_href] =
        html
        |> LazyHTML.query(~s(link[rel="stylesheet"][phx-track-static]))
        |> LazyHTML.attribute("href")

      assert String.starts_with?(css_href, "file://")
      css_path = String.replace_prefix(css_href, "file://", "")
      assert css_path =~ "/cerberus/priv/static/assets/app.css"
      assert File.exists?(css_path)

      File.rm(path)
    end)
  end

  defp driver_session(driver, context), do: SharedBrowserSession.driver_session(driver, context)
end
