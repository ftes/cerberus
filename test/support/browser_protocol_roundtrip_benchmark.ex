defmodule Cerberus.TestSupport.BrowserProtocolRoundtripBenchmark do
  @moduledoc false

  alias Cerberus.Driver.Browser.WS

  @default_commands 1_000
  @default_http_timeout_ms 10_000
  @default_wait_attempts 120
  @default_wait_sleep_ms 50

  @type timing :: %{
          commands: pos_integer(),
          total_ms: non_neg_integer(),
          avg_ms: float()
        }

  @type result :: %{
          commands: pos_integer(),
          bidi: timing(),
          cdp: timing()
        }

  @type session :: %{
          session_id: String.t(),
          bidi_web_socket_url: String.t(),
          debugger_address: String.t()
        }

  @type service :: %{
          port: port(),
          os_pid: pos_integer() | nil,
          webdriver_url: String.t()
        }

  @spec run(keyword()) :: result()
  def run(opts \\ []) do
    commands = Keyword.get(opts, :commands, @default_commands)
    webdriver_port = Keyword.get(opts, :webdriver_port, random_port())

    service = start_chromedriver!(webdriver_port)

    try do
      session = create_session!(service.webdriver_url)

      try do
        cdp_browser_socket_url = fetch_cdp_browser_socket_url!(session.debugger_address)
        {:ok, bidi_socket} = start_bidi_socket(session.bidi_web_socket_url)
        {:ok, cdp_socket} = start_cdp_socket(cdp_browser_socket_url)

        try do
          bidi_context = create_bidi_context!(bidi_socket)
          cdp_session_id = create_cdp_runtime_session!(cdp_socket)

          warm_up_bidi!(bidi_socket, bidi_context)
          warm_up_cdp!(cdp_socket, cdp_session_id)

          %{
            commands: commands,
            bidi: measure(commands, fn -> bidi_no_op!(bidi_socket, bidi_context) end),
            cdp: measure(commands, fn -> cdp_no_op!(cdp_socket, cdp_session_id) end)
          }
        after
          _ = WS.close(bidi_socket)
          _ = WS.close(cdp_socket)
        end
      after
        delete_session(service.webdriver_url, session.session_id)
      end
    after
      stop_service(service)
    end
  end

  @spec start_bidi_socket(String.t()) :: {:ok, pid()} | {:error, term()}
  defp start_bidi_socket(url) do
    WS.start_link(url, self(), extra_headers: [{"Sec-WebSocket-Protocol", "webDriverBidi"}])
  end

  @spec start_cdp_socket(String.t()) :: {:ok, pid()} | {:error, term()}
  defp start_cdp_socket(url) do
    WS.start_link(url, self())
  end

  @spec measure(pos_integer(), (-> any())) :: timing()
  defp measure(commands, fun) when is_integer(commands) and commands > 0 do
    started_at = System.monotonic_time(:millisecond)

    Enum.each(1..commands, fn _index ->
      fun.()
    end)

    total_ms = System.monotonic_time(:millisecond) - started_at

    %{
      commands: commands,
      total_ms: total_ms,
      avg_ms: total_ms / commands
    }
  end

  @spec warm_up_bidi!(pid(), String.t()) :: :ok
  defp warm_up_bidi!(socket, context_id) do
    Enum.each(1..10, fn _index -> bidi_no_op!(socket, context_id) end)
  end

  @spec warm_up_cdp!(pid(), String.t()) :: :ok
  defp warm_up_cdp!(socket, cdp_session_id) do
    Enum.each(1..10, fn _index -> cdp_no_op!(socket, cdp_session_id) end)
  end

  @spec bidi_no_op!(pid(), String.t()) :: :ok
  defp bidi_no_op!(socket, context_id) do
    response =
      bidi_command!(socket, "script.evaluate", %{
        "expression" => "1 + 1",
        "awaitPromise" => false,
        "resultOwnership" => "none",
        "target" => %{"context" => context_id}
      })

    case response do
      %{"result" => %{"type" => "number", "value" => 2}} -> :ok
      other -> raise "unexpected BiDi no-op response: #{inspect(other)}"
    end
  end

  @spec cdp_no_op!(pid(), String.t()) :: :ok
  defp cdp_no_op!(socket, cdp_session_id) do
    response =
      cdp_command!(socket, "Runtime.evaluate", %{"expression" => "1 + 1"}, cdp_session_id)

    case response do
      %{"result" => %{"result" => %{"type" => "number", "value" => 2}}} -> :ok
      other -> raise "unexpected CDP no-op response: #{inspect(other)}"
    end
  end

  @spec create_bidi_context!(pid()) :: String.t()
  defp create_bidi_context!(socket) do
    case bidi_command!(socket, "browsingContext.create", %{"type" => "tab"}) do
      %{"context" => context_id} when is_binary(context_id) -> context_id
      other -> raise "unexpected BiDi browsingContext.create response: #{inspect(other)}"
    end
  end

  @spec create_cdp_runtime_session!(pid()) :: String.t()
  defp create_cdp_runtime_session!(socket) do
    %{"result" => %{"targetId" => target_id}} =
      cdp_command!(socket, "Target.createTarget", %{"url" => "about:blank"})

    case cdp_command!(socket, "Target.attachToTarget", %{"targetId" => target_id, "flatten" => true}) do
      %{"result" => %{"sessionId" => session_id}} when is_binary(session_id) -> session_id
      other -> raise "unexpected CDP attachToTarget response: #{inspect(other)}"
    end
  end

  @spec bidi_command!(pid(), String.t(), map()) :: map()
  defp bidi_command!(socket, method, params) do
    id = :erlang.unique_integer([:positive])
    payload = JSON.encode!(%{"id" => id, "method" => method, "params" => params})
    :ok = WS.send_text(socket, payload)

    socket
    |> receive_json_response!(id)
    |> Map.fetch!("result")
  end

  @spec cdp_command!(pid(), String.t(), map(), String.t() | nil) :: map()
  defp cdp_command!(socket, method, params, session_id \\ nil) do
    id = :erlang.unique_integer([:positive])

    payload =
      %{"id" => id, "method" => method, "params" => params}
      |> maybe_put_session_id(session_id)
      |> JSON.encode!()

    :ok = WS.send_text(socket, payload)

    socket
    |> receive_json_response!(id)
    |> Map.delete("id")
  end

  @spec maybe_put_session_id(map(), String.t() | nil) :: map()
  defp maybe_put_session_id(payload, nil), do: payload
  defp maybe_put_session_id(payload, session_id), do: Map.put(payload, "sessionId", session_id)

  @spec receive_json_response!(pid(), pos_integer()) :: map()
  defp receive_json_response!(socket, id) do
    receive do
      {:cerberus_bidi_connected, ^socket} ->
        receive_json_response!(socket, id)

      {:cerberus_bidi_frame, ^socket, payload} ->
        case JSON.decode(payload) do
          {:ok, %{"id" => ^id} = response} ->
            if Map.has_key?(response, "error") do
              raise "protocol command failed: #{inspect(response)}"
            else
              response
            end

          {:ok, _event_or_other} ->
            receive_json_response!(socket, id)

          {:error, reason} ->
            raise "failed to decode websocket payload #{inspect(payload)}: #{inspect(reason)}"
        end

      {:cerberus_bidi_disconnected, ^socket, reason} ->
        raise "websocket disconnected while awaiting response #{id}: #{inspect(reason)}"
    after
      @default_http_timeout_ms ->
        raise "timed out awaiting websocket response #{id}"
    end
  end

  @spec fetch_cdp_browser_socket_url!(String.t()) :: String.t()
  defp fetch_cdp_browser_socket_url!(debugger_address) do
    url = "http://#{debugger_address}/json/version"

    case http_json(:get, url, nil) do
      {:ok, 200, %{"webSocketDebuggerUrl" => socket_url}} when is_binary(socket_url) -> socket_url
      other -> raise "failed to fetch Chrome debugger websocket URL: #{inspect(other)}"
    end
  end

  @spec create_session!(String.t()) :: session()
  defp create_session!(webdriver_url) do
    payload = %{
      "capabilities" => %{
        "alwaysMatch" => %{
          "browserName" => "chrome",
          "webSocketUrl" => true,
          "unhandledPromptBehavior" => "ignore",
          "goog:chromeOptions" => %{
            "args" => ["--headless=new", "--disable-gpu", "--no-sandbox", "--remote-debugging-port=0"],
            "binary" => System.fetch_env!("CHROME")
          }
        }
      }
    }

    case http_json(:post, webdriver_url <> "/session", payload) do
      {:ok, 200, %{"value" => %{"sessionId" => session_id, "capabilities" => capabilities}}}
      when is_binary(session_id) and is_map(capabilities) ->
        validate_session!(%{
          session_id: session_id,
          bidi_web_socket_url: Map.fetch!(capabilities, "webSocketUrl"),
          debugger_address: get_in(capabilities, ["goog:chromeOptions", "debuggerAddress"])
        })

      other ->
        raise "failed to create WebDriver session: #{inspect(other)}"
    end
  end

  @spec validate_session!(session()) :: session()
  defp validate_session!(session) do
    if is_binary(session.bidi_web_socket_url) and is_binary(session.debugger_address) do
      session
    else
      raise "WebDriver session did not expose both BiDi and debuggerAddress: #{inspect(session)}"
    end
  end

  @spec delete_session(String.t(), String.t()) :: :ok
  defp delete_session(webdriver_url, session_id) do
    _ = http_json(:delete, webdriver_url <> "/session/" <> session_id, nil)
    :ok
  end

  @spec start_chromedriver!(pos_integer()) :: service()
  defp start_chromedriver!(webdriver_port) do
    chromedriver = System.fetch_env!("CHROMEDRIVER")

    port =
      Port.open({:spawn_executable, String.to_charlist(chromedriver)}, [
        :binary,
        :hide,
        :exit_status,
        args: [to_charlist("--port=#{webdriver_port}")]
      ])

    service = %{
      port: port,
      os_pid: port_os_pid(port),
      webdriver_url: "http://127.0.0.1:#{webdriver_port}"
    }

    wait_for_service!(service.webdriver_url)
    service
  end

  @spec stop_service(service()) :: :ok
  defp stop_service(%{port: port, os_pid: os_pid}) do
    if is_integer(os_pid) and os_pid > 0 do
      _ = System.cmd("kill", ["-TERM", Integer.to_string(os_pid)], stderr_to_stdout: true)
    end

    if Port.info(port) != nil do
      Port.close(port)
    end

    :ok
  end

  @spec wait_for_service!(String.t()) :: :ok
  defp wait_for_service!(webdriver_url) do
    Enum.reduce_while(1..@default_wait_attempts, nil, fn _attempt, _acc ->
      case http_json(:get, webdriver_url <> "/status", nil) do
        {:ok, 200, _json} ->
          {:halt, :ok}

        _other ->
          Process.sleep(@default_wait_sleep_ms)
          {:cont, nil}
      end
    end) || raise "chromedriver did not become ready at #{webdriver_url}"
  end

  @spec http_json(:get | :post | :delete, String.t(), map() | nil) ::
          {:ok, non_neg_integer(), map()} | {:error, term()}
  defp http_json(method, url, payload) do
    request =
      case method do
        :get ->
          {String.to_charlist(url), []}

        :delete ->
          {String.to_charlist(url), []}

        :post ->
          body = JSON.encode!(payload || %{})
          {String.to_charlist(url), [{~c"content-type", ~c"application/json"}], ~c"application/json", body}
      end

    case :httpc.request(method, request, [timeout: @default_http_timeout_ms], body_format: :binary) do
      {:ok, {{_version, status, _reason}, _headers, response_body}} ->
        decode_http_body(status, response_body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec decode_http_body(non_neg_integer(), binary()) :: {:ok, non_neg_integer(), map()}
  defp decode_http_body(status, ""), do: {:ok, status, %{}}

  defp decode_http_body(status, body) do
    case JSON.decode(body) do
      {:ok, json} when is_map(json) -> {:ok, status, json}
      {:error, reason} -> raise "failed to decode HTTP body #{inspect(body)}: #{inspect(reason)}"
    end
  end

  @spec port_os_pid(port()) :: pos_integer() | nil
  defp port_os_pid(port) do
    case Port.info(port, :os_pid) do
      {:os_pid, os_pid} when is_integer(os_pid) and os_pid > 0 -> os_pid
      _ -> nil
    end
  end

  @spec random_port() :: pos_integer()
  defp random_port do
    40_000 + :rand.uniform(9_000)
  end
end
