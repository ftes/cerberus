defmodule Cerberus.Driver.Browser.RuntimeTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.Runtime

  setup do
    browser_config = Application.get_env(:cerberus, :browser, [])

    on_exit(fn ->
      Application.put_env(:cerberus, :browser, browser_config)
    end)

    :ok
  end

  describe "headless?/2" do
    test "defaults to headless" do
      assert Runtime.headless?([], []) == true
    end

    test "show_browser=true disables headless by default" do
      assert Runtime.headless?([], show_browser: true) == false
    end

    test "explicit headless option overrides show_browser" do
      assert Runtime.headless?([headless: true], show_browser: true) == true
      assert Runtime.headless?([headless: false], show_browser: false) == false
    end
  end

  describe "remote_webdriver_url/1" do
    test "prefers explicit webdriver_url override then browser config" do
      Application.put_env(:cerberus, :browser, webdriver_url: "http://remote-from-config:4444")

      assert Runtime.remote_webdriver_url([]) == "http://remote-from-config:4444"
      assert Runtime.remote_webdriver_url(webdriver_url: "http://session-override:5555") == "http://session-override:5555"
    end

    test "supports legacy chromedriver_url as fallback" do
      assert Runtime.remote_webdriver_url(chromedriver_url: "http://legacy:9515") == "http://legacy:9515"
    end
  end

  describe "webdriver_session_payload/2" do
    test "remote payload does not require local browser binary" do
      payload = Runtime.webdriver_session_payload([chrome_args: ["--remote-flag"]], false)
      always_match = payload["capabilities"]["alwaysMatch"]
      chrome_opts = always_match["goog:chromeOptions"]

      assert always_match["browserName"] == "chrome"
      assert always_match["webSocketUrl"] == true
      assert chrome_opts["args"] == ["--remote-flag"]
      refute Map.has_key?(chrome_opts, "binary")
    end

    test "managed payload includes local browser binary" do
      chrome_path = Path.join(System.tmp_dir!(), "cerberus-fake-chrome-#{System.unique_integer([:positive])}")
      File.write!(chrome_path, "")

      on_exit(fn ->
        File.rm(chrome_path)
      end)

      payload = Runtime.webdriver_session_payload([chrome_binary: chrome_path], true)
      chrome_opts = payload["capabilities"]["alwaysMatch"]["goog:chromeOptions"]

      assert chrome_opts["binary"] == chrome_path
      assert is_list(chrome_opts["args"])
    end
  end
end
