defmodule Cerberus.Driver.Browser.RuntimeTest do
  use ExUnit.Case, async: true

  alias Cerberus.Driver.Browser.Runtime
  alias Cerberus.Fixtures.Endpoint

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

    test "headless=false disables headless mode" do
      assert Runtime.headless?([], headless: false) == false
    end

    test "explicit headless option overrides merged config" do
      assert Runtime.headless?([headless: true], headless: false) == true
      assert Runtime.headless?([headless: false], headless: true) == false
    end
  end

  describe "slow_mo_ms/1" do
    test "defaults to zero and supports top-level/session overrides" do
      Application.put_env(:cerberus, :browser, slow_mo: 40)

      assert Runtime.slow_mo_ms([]) == 40
      assert Runtime.slow_mo_ms(slow_mo: 120) == 120
    end

    test "supports nested browser overrides" do
      Application.put_env(:cerberus, :browser, slow_mo: 40)

      assert Runtime.slow_mo_ms(browser: [slow_mo: 75]) == 75
    end
  end

  describe "remote_webdriver_url/1" do
    test "prefers explicit webdriver_url override then browser config" do
      Application.put_env(:cerberus, :browser, webdriver_url: "http://remote-from-config:4444")

      assert Runtime.remote_webdriver_url([]) == "http://remote-from-config:4444"
      assert Runtime.remote_webdriver_url(webdriver_url: "http://session-override:5555") == "http://session-override:5555"
    end

    test "supports chrome webdriver url override keys" do
      Application.put_env(:cerberus, :browser, chrome_webdriver_url: "http://config-chrome:4444")

      assert Runtime.remote_webdriver_url([]) == "http://config-chrome:4444"

      assert Runtime.remote_webdriver_url(chrome_webdriver_url: "http://override-chrome:4444") ==
               "http://override-chrome:4444"
    end
  end

  describe "resolve_base_url/1" do
    test "prefers explicit base_url option over configured values" do
      assert Runtime.resolve_base_url(base_url: "http://session-override:7777") == "http://session-override:7777"
    end

    test "falls back to endpoint url when :base_url is unset" do
      previous_base_url = Application.get_env(:cerberus, :base_url)
      previous_endpoint = Application.get_env(:cerberus, :endpoint)

      on_exit(fn ->
        if is_nil(previous_base_url) do
          Application.delete_env(:cerberus, :base_url)
        else
          Application.put_env(:cerberus, :base_url, previous_base_url)
        end

        if is_nil(previous_endpoint) do
          Application.delete_env(:cerberus, :endpoint)
        else
          Application.put_env(:cerberus, :endpoint, previous_endpoint)
        end
      end)

      Application.delete_env(:cerberus, :base_url)
      Application.put_env(:cerberus, :endpoint, Endpoint)

      assert Runtime.resolve_base_url([]) == Endpoint.url()
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

    @tag :tmp_dir
    test "managed payload includes local browser binary", %{tmp_dir: tmp_dir} do
      chrome_path = Path.join(tmp_dir, "cerberus-fake-chrome")
      File.write!(chrome_path, "")

      payload = Runtime.webdriver_session_payload([chrome_binary: chrome_path], true)
      chrome_opts = payload["capabilities"]["alwaysMatch"]["goog:chromeOptions"]

      assert chrome_opts["binary"] == chrome_path
      assert is_list(chrome_opts["args"])
      assert "--remote-debugging-port=0" in chrome_opts["args"]
      assert "--disable-background-networking" in chrome_opts["args"]
      assert "--disable-popup-blocking" in chrome_opts["args"]
      assert "--enable-automation" in chrome_opts["args"]
      assert "--headless" in chrome_opts["args"]
      assert "--hide-scrollbars" in chrome_opts["args"]
      assert "--mute-audio" in chrome_opts["args"]
      assert Enum.any?(chrome_opts["args"], &String.starts_with?(&1, "--disable-features="))
      assert Enum.any?(chrome_opts["args"], &String.starts_with?(&1, "--blink-settings="))
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
