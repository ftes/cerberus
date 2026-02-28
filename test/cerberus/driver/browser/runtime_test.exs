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

  describe "browser_name/1" do
    test "defaults to chrome and accepts browser config/session overrides" do
      assert Runtime.browser_name([]) == :chrome

      Application.put_env(:cerberus, :browser, browser_name: :firefox)
      assert Runtime.browser_name([]) == :firefox
      assert Runtime.browser_name(browser_name: :chrome) == :chrome
    end
  end

  describe "webdriver_session_payload/3" do
    test "remote payload does not require local browser binary" do
      payload = Runtime.webdriver_session_payload([chrome_args: ["--remote-flag"]], false, :chrome)
      always_match = payload["capabilities"]["alwaysMatch"]
      chrome_opts = always_match["goog:chromeOptions"]

      assert always_match["browserName"] == "chrome"
      assert always_match["webSocketUrl"] == true
      assert chrome_opts["args"] == ["--remote-flag"]
      refute Map.has_key?(chrome_opts, "binary")
    end

    @tag :tmp_dir
    test "managed payload includes local browser binary", %{tmp_dir: tmp_dir} do
      chrome_path = Path.join(tmp_dir, "cerberus-fake-chrome")
      File.write!(chrome_path, "")

      payload = Runtime.webdriver_session_payload([chrome_binary: chrome_path], true, :chrome)
      chrome_opts = payload["capabilities"]["alwaysMatch"]["goog:chromeOptions"]

      assert chrome_opts["binary"] == chrome_path
      assert is_list(chrome_opts["args"])
    end

    test "firefox payload uses moz:firefoxOptions and browserName firefox" do
      payload = Runtime.webdriver_session_payload([firefox_args: ["-private"]], false, :firefox)
      always_match = payload["capabilities"]["alwaysMatch"]

      assert always_match["browserName"] == "firefox"
      assert always_match["webSocketUrl"] == true
      assert always_match["moz:firefoxOptions"]["args"] == ["-private"]
      refute Map.has_key?(always_match, "goog:chromeOptions")
    end
  end

  describe "normalize_web_socket_url/2" do
    test "rewrites private selenium websocket endpoint to service host/port" do
      web_socket_url = "ws://172.17.0.2:4444/session/abc/se/bidi"
      service_url = "http://127.0.0.1:61532"

      assert Runtime.normalize_web_socket_url(web_socket_url, service_url) ==
               "ws://127.0.0.1:61532/session/abc/se/bidi"
    end

    test "keeps websocket url when host/port are already routable" do
      web_socket_url = "ws://127.0.0.1:4444/session/abc/se/bidi"
      service_url = "http://127.0.0.1:4444"

      assert Runtime.normalize_web_socket_url(web_socket_url, service_url) == web_socket_url
    end
  end
end
