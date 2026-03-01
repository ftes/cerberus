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

    test "supports per-browser webdriver_urls map/keyword selection" do
      Application.put_env(:cerberus, :browser,
        webdriver_urls: [chrome: "http://chrome:4444", firefox: "http://firefox:4444"]
      )

      assert Runtime.remote_webdriver_url(browser_name: :chrome) == "http://chrome:4444"
      assert Runtime.remote_webdriver_url(browser_name: :firefox) == "http://firefox:4444"

      assert Runtime.remote_webdriver_url(
               browser_name: :firefox,
               webdriver_urls: %{firefox: "http://override-firefox:4444"}
             ) ==
               "http://override-firefox:4444"
    end

    test "supports top-level per-browser webdriver url keys" do
      Application.put_env(:cerberus, :browser,
        chrome_webdriver_url: "http://config-chrome:4444",
        firefox_webdriver_url: "http://config-firefox:4444"
      )

      assert Runtime.remote_webdriver_url(browser_name: :chrome) == "http://config-chrome:4444"
      assert Runtime.remote_webdriver_url(browser_name: :firefox) == "http://config-firefox:4444"

      assert Runtime.remote_webdriver_url(browser_name: :chrome, chrome_webdriver_url: "http://override-chrome:4444") ==
               "http://override-chrome:4444"

      assert Runtime.remote_webdriver_url(
               browser_name: :firefox,
               firefox_webdriver_url: "http://override-firefox:4444"
             ) ==
               "http://override-firefox:4444"
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
      assert "--remote-debugging-port=0" in chrome_opts["args"]
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

  describe "chrome startup hardening helpers" do
    test "chrome_startup_retries/1 defaults to one retry and accepts overrides" do
      Application.put_env(:cerberus, :browser, chrome_startup_retries: 3)
      assert Runtime.chrome_startup_retries([]) == 3
      assert Runtime.chrome_startup_retries(chrome_startup_retries: 0) == 0
      assert Runtime.chrome_startup_retries(chrome_startup_retries: 2) == 2
    end

    test "chrome_startup_retryable_error?/1 only matches transient chrome startup failures" do
      assert Runtime.chrome_startup_retryable_error?(
               ~s(webdriver session request failed with status 500: %{\\"message\\" => \\"session not created: Chrome instance exited\\"})
             )

      refute Runtime.chrome_startup_retryable_error?("webdriver timed out")
      refute Runtime.chrome_startup_retryable_error?(nil)
    end

    @tag :tmp_dir
    test "append_startup_log/3 appends path and tail", %{tmp_dir: tmp_dir} do
      log_path = Path.join(tmp_dir, "chromedriver.log")

      File.write!(log_path, """
      one
      two
      three
      four
      """)

      message =
        Runtime.append_startup_log("startup failed", log_path,
          startup_log_tail_lines: 2,
          startup_log_tail_bytes: 200
        )

      assert message =~ "startup failed"
      assert message =~ log_path
      assert message =~ "three"
      assert message =~ "four"
      refute message =~ "one"
    end

    test "append_startup_log/3 leaves reason unchanged when log is missing" do
      reason = "startup failed"
      assert Runtime.append_startup_log(reason, "/tmp/does-not-exist.log") == reason
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

    test "keeps non-selenium websocket endpoint even when service host/port differ" do
      web_socket_url = "ws://127.0.0.1:9222/session/abc"
      service_url = "http://127.0.0.1:4545"

      assert Runtime.normalize_web_socket_url(web_socket_url, service_url) == web_socket_url
    end

    test "keeps non-selenium private-host websocket endpoint" do
      web_socket_url = "ws://172.17.0.2:9222/session/abc"
      service_url = "http://127.0.0.1:4545"

      assert Runtime.normalize_web_socket_url(web_socket_url, service_url) == web_socket_url
    end
  end
end
