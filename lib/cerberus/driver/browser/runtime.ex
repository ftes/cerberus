defmodule Cerberus.Driver.Browser.Runtime do
  @moduledoc false

  use GenServer

  @default_runtime_http_timeout_ms 5_000
  @startup_attempts 120
  @startup_sleep_ms 50

  @type service :: %{
          url: String.t(),
          managed?: boolean(),
          process: port() | nil
        }

  @type runtime_session :: %{
          service: service(),
          session_id: String.t(),
          web_socket_url: String.t()
        }

  @type state :: %{
          runtime_session: runtime_session() | nil,
          base_url: String.t() | nil,
          opts: keyword()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec base_url() :: String.t()
  def base_url do
    GenServer.call(__MODULE__, :base_url)
  end

  @spec web_socket_url() :: {:ok, String.t()} | {:error, String.t()}
  def web_socket_url do
    GenServer.call(__MODULE__, :web_socket_url, 20_000)
  end

  @spec session_id() :: {:ok, String.t()} | {:error, String.t()}
  def session_id do
    GenServer.call(__MODULE__, :session_id, 20_000)
  end

  @impl true
  def init(opts) do
    ensure_http_stack!()
    {:ok, %{runtime_session: nil, base_url: Keyword.get(opts, :base_url), opts: opts}}
  end

  @impl true
  def handle_call(:base_url, _from, state) do
    base_url = state.base_url || base_url!(state.opts)
    {:reply, base_url, %{state | base_url: base_url}}
  end

  def handle_call(:web_socket_url, _from, state) do
    case ensure_runtime_session(state) do
      {:ok, runtime_session, state} ->
        {:reply, {:ok, runtime_session.web_socket_url}, state}

      {:error, reason, state} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:session_id, _from, state) do
    case ensure_runtime_session(state) do
      {:ok, runtime_session, state} ->
        {:reply, {:ok, runtime_session.session_id}, state}

      {:error, reason, state} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info({_port, {:data, _data}}, state) do
    {:noreply, state}
  end

  def handle_info({_port, {:exit_status, _status}}, state) do
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    maybe_stop_runtime_session(state.runtime_session, state.opts)
    :ok
  end

  defp ensure_runtime_session(%{runtime_session: runtime_session} = state) when is_map(runtime_session) do
    {:ok, runtime_session, state}
  end

  defp ensure_runtime_session(state) do
    case start_runtime_session(state.opts) do
      {:ok, runtime_session} ->
        {:ok, runtime_session, %{state | runtime_session: runtime_session}}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  defp start_runtime_session(opts) do
    with {:ok, service} <- start_service(opts) do
      case start_webdriver_session(service.url, opts) do
        {:ok, session_id, web_socket_url} ->
          {:ok, %{service: service, session_id: session_id, web_socket_url: web_socket_url}}

        {:error, reason} ->
          maybe_stop_service(service)
          {:error, reason}
      end
    end
  end

  defp maybe_stop_runtime_session(%{service: service, session_id: session_id}, opts) do
    maybe_delete_session(service, session_id, opts)
    maybe_stop_service(service)
    :ok
  end

  defp maybe_stop_runtime_session(_, _), do: :ok

  defp start_service(opts) do
    chromedriver_url =
      Keyword.get_lazy(opts, :chromedriver_url, fn ->
        browser_opts(opts)[:chromedriver_url]
      end)

    if is_binary(chromedriver_url) do
      {:ok, %{url: chromedriver_url, managed?: false, process: nil}}
    else
      start_managed_service(opts)
    end
  end

  defp start_managed_service(opts) do
    binary = opts |> chromedriver_binary!() |> Path.expand()
    port = Keyword.get(opts, :chromedriver_port) || random_port!()
    args = [to_charlist("--port=#{port}")]

    process =
      Port.open({:spawn_executable, to_charlist(binary)}, [
        :binary,
        :hide,
        :exit_status,
        args: args
      ])

    url = "http://127.0.0.1:#{port}"

    case wait_for_service(url, @startup_attempts, opts) do
      :ok ->
        {:ok, %{url: url, managed?: true, process: process}}

      {:error, reason} ->
        Port.close(process)
        {:error, reason}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  defp start_webdriver_session(service_url, opts) do
    chrome_opts = chrome_options(opts)

    payload = %{
      "capabilities" => %{
        "alwaysMatch" => %{
          "browserName" => "chrome",
          "webSocketUrl" => true,
          "goog:chromeOptions" => chrome_opts
        }
      }
    }

    with {:ok, 200, body} <- http_json(:post, service_url <> "/session", payload, opts),
         {:ok, session_id, web_socket_url} <- parse_session_response(body) do
      {:ok, session_id, web_socket_url}
    else
      {:ok, status, body} ->
        {:error, "webdriver session request failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_session_response(%{"value" => %{"error" => error} = value}) do
    message = value["message"] || error
    {:error, message}
  end

  defp parse_session_response(%{"value" => %{"sessionId" => session_id, "capabilities" => caps}})
       when is_binary(session_id) and is_map(caps) do
    web_socket_url = caps["webSocketUrl"]

    if is_binary(web_socket_url) and byte_size(web_socket_url) > 0 do
      {:ok, session_id, web_socket_url}
    else
      {:error, "webdriver session created without capabilities.webSocketUrl"}
    end
  end

  defp parse_session_response(response) do
    {:error, "unexpected webdriver session response: #{inspect(response)}"}
  end

  defp wait_for_service(_url, 0, _opts), do: {:error, "chromedriver did not become ready"}

  defp wait_for_service(url, attempts_left, opts) do
    case http_json(:get, url <> "/status", nil, opts) do
      {:ok, 200, _} ->
        :ok

      _ ->
        Process.sleep(@startup_sleep_ms)
        wait_for_service(url, attempts_left - 1, opts)
    end
  end

  defp http_json(method, url, payload, opts) do
    request =
      case method do
        :get ->
          {to_charlist(url), []}

        :delete ->
          {to_charlist(url), []}

        :post ->
          body = JSON.encode!(payload || %{})

          {to_charlist(url), [{~c"content-type", ~c"application/json"}], ~c"application/json", body}
      end

    timeout = runtime_http_timeout_ms(opts)

    case :httpc.request(method, request, [timeout: timeout], body_format: :binary) do
      {:ok, {{_version, status, _reason}, _headers, response_body}} ->
        decode_body(status, response_body)

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp decode_body(status, ""), do: {:ok, status, %{}}

  defp decode_body(status, body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, json} -> {:ok, status, json}
      {:error, _} -> {:ok, status, %{"raw" => body}}
    end
  end

  defp maybe_delete_session(%{url: service_url}, session_id, opts)
       when is_binary(service_url) and is_binary(session_id) do
    _ = http_json(:delete, service_url <> "/session/" <> session_id, nil, opts)
    :ok
  end

  defp maybe_delete_session(_, _, _), do: :ok

  defp maybe_stop_service(%{managed?: true, process: process}) when is_port(process) do
    if Port.info(process) != nil, do: Port.close(process)
    :ok
  end

  defp maybe_stop_service(_), do: :ok

  defp base_url!(opts) do
    Keyword.get(opts, :base_url) ||
      browser_opts(opts)[:base_url] ||
      Application.get_env(:cerberus, :base_url) ||
      raise(ArgumentError, "missing :cerberus, :base_url for browser driver")
  end

  defp browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  @doc false
  @spec runtime_http_timeout_ms(keyword()) :: pos_integer()
  def runtime_http_timeout_ms(opts) when is_list(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:runtime_http_timeout_ms, browser_opts[:runtime_http_timeout_ms])
    |> normalize_positive_integer(@default_runtime_http_timeout_ms)
  end

  defp chrome_options(opts) do
    merged = browser_opts(opts)
    args = chrome_args(opts, merged)
    binary = chrome_binary!(opts, merged)
    %{"args" => args, "binary" => binary}
  end

  defp chrome_args(opts, merged) do
    headless? = headless?(opts, merged)
    custom_args = Keyword.get(opts, :chrome_args, Keyword.get(merged, :chrome_args, []))
    defaults = if headless?, do: ["--headless=new"], else: []
    defaults ++ ["--disable-gpu", "--no-sandbox"] ++ custom_args
  end

  @doc false
  @spec headless?(keyword(), keyword()) :: boolean()
  def headless?(opts, merged) do
    show_browser? = Keyword.get(opts, :show_browser, Keyword.get(merged, :show_browser, false))
    Keyword.get(opts, :headless, Keyword.get(merged, :headless, not show_browser?))
  end

  defp chrome_binary!(opts, merged) do
    binary = Keyword.get(opts, :chrome_binary) || Keyword.get(merged, :chrome_binary)

    if is_binary(binary) and File.exists?(binary) do
      binary
    else
      raise ArgumentError,
            "chrome binary not configured; set :cerberus, :browser chrome_binary (or pass :chrome_binary)"
    end
  end

  defp chromedriver_binary!(opts) do
    binary =
      Keyword.get(opts, :chromedriver_binary) ||
        browser_opts(opts)[:chromedriver_binary]

    if is_binary(binary) and File.exists?(binary) do
      binary
    else
      raise ArgumentError,
            "chromedriver binary not configured; set :cerberus, :browser chromedriver_binary (or pass :chromedriver_binary)"
    end
  end

  defp random_port! do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, {:active, false}, {:reuseaddr, true}])
    {:ok, port} = :inet.port(socket)
    :gen_tcp.close(socket)
    port
  end

  defp ensure_http_stack! do
    _ = :inets.start()
    _ = :ssl.start()
    :ok
  end

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default
end
