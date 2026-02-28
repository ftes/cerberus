defmodule Cerberus.Driver.Browser.Runtime do
  @moduledoc false

  use GenServer

  @default_browser_name :chrome
  @default_runtime_http_timeout_ms 5_000
  @startup_attempts 120
  @startup_sleep_ms 50

  @type service :: %{
          url: String.t(),
          browser_name: :chrome | :firefox,
          managed?: boolean(),
          process: port() | nil
        }

  @type runtime_session :: %{
          service: service(),
          browser_name: :chrome | :firefox,
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

  @spec web_socket_url(keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def web_socket_url(opts \\ []) when is_list(opts) do
    GenServer.call(__MODULE__, {:web_socket_url, opts}, 20_000)
  end

  @spec session_id(keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def session_id(opts \\ []) when is_list(opts) do
    GenServer.call(__MODULE__, {:session_id, opts}, 20_000)
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

  def handle_call({:web_socket_url, opts}, _from, state) do
    case ensure_runtime_session(state, opts) do
      {:ok, runtime_session, state} ->
        {:reply, {:ok, runtime_session.web_socket_url}, state}

      {:error, reason, state} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:session_id, opts}, _from, state) do
    case ensure_runtime_session(state, opts) do
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

  defp ensure_runtime_session(%{runtime_session: runtime_session} = state, opts) when is_map(runtime_session) do
    case requested_browser_name(opts) do
      nil ->
        {:ok, runtime_session, state}

      requested when requested == runtime_session.browser_name ->
        {:ok, runtime_session, state}

      requested ->
        {:error,
         "browser runtime already started for #{runtime_session.browser_name}; requested #{requested}. " <>
           "Run each browser matrix in a separate test invocation.", state}
    end
  end

  defp ensure_runtime_session(state, opts) do
    case start_runtime_session(merge_runtime_opts(state.opts, opts)) do
      {:ok, runtime_session} ->
        {:ok, runtime_session, %{state | runtime_session: runtime_session}}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  defp start_runtime_session(opts) do
    with {:ok, service} <- start_service(opts) do
      case start_webdriver_session(service, opts) do
        {:ok, session_id, web_socket_url} ->
          {:ok,
           %{
             service: service,
             browser_name: service.browser_name,
             session_id: session_id,
             web_socket_url: web_socket_url
           }}

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
    browser_name = browser_name(opts)
    webdriver_url = remote_webdriver_url(opts)

    if is_binary(webdriver_url) do
      {:ok, %{url: webdriver_url, browser_name: browser_name, managed?: false, process: nil}}
    else
      start_managed_service(opts, browser_name)
    end
  end

  defp start_managed_service(opts, browser_name) do
    binary = opts |> webdriver_binary!(browser_name) |> Path.expand()
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
        {:ok, %{url: url, browser_name: browser_name, managed?: true, process: process}}

      {:error, reason} ->
        Port.close(process)
        {:error, reason}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  defp start_webdriver_session(service, opts) do
    payload = webdriver_session_payload(opts, service.managed?, service.browser_name)

    with {:ok, 200, body} <- http_json(:post, service.url <> "/session", payload, opts),
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

  defp wait_for_service(_url, 0, _opts), do: {:error, "webdriver service did not become ready"}

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

  @doc false
  @spec remote_webdriver_url(keyword()) :: String.t() | nil
  def remote_webdriver_url(opts) when is_list(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(
      :webdriver_url,
      browser_opts[:webdriver_url] || opts[:chromedriver_url] || browser_opts[:chromedriver_url]
    )
    |> normalize_non_empty_string(nil)
  end

  @doc false
  @spec browser_name(keyword()) :: :chrome | :firefox
  def browser_name(opts) when is_list(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:browser_name, browser_opts[:browser_name])
    |> normalize_browser_name(@default_browser_name)
  end

  @doc false
  @spec webdriver_session_payload(keyword(), boolean(), :chrome | :firefox) :: map()
  def webdriver_session_payload(opts, managed?, browser_name) when is_list(opts) and is_boolean(managed?) do
    capabilities =
      maybe_put_browser_options(
        %{"browserName" => Atom.to_string(browser_name), "webSocketUrl" => true},
        browser_options(opts, managed?, browser_name),
        browser_name
      )

    %{
      "capabilities" => %{
        "alwaysMatch" => capabilities
      }
    }
  end

  defp maybe_put_browser_options(capabilities, options, _browser_name) when options == %{}, do: capabilities

  defp maybe_put_browser_options(capabilities, options, :chrome) do
    Map.put(capabilities, "goog:chromeOptions", options)
  end

  defp maybe_put_browser_options(capabilities, options, :firefox) do
    Map.put(capabilities, "moz:firefoxOptions", options)
  end

  defp browser_options(opts, managed?, :chrome), do: chrome_options(opts, managed?)
  defp browser_options(opts, managed?, :firefox), do: firefox_options(opts, managed?)

  defp chrome_options(opts, managed?) do
    merged = browser_opts(opts)
    args = chrome_args(opts, merged, managed?)

    options =
      if is_list(args) and args != [] do
        %{"args" => args}
      else
        %{}
      end

    if managed? do
      Map.put(options, "binary", chrome_binary!(opts, merged))
    else
      options
    end
  end

  defp chrome_args(opts, merged, true) do
    headless? = headless?(opts, merged)
    custom_args = Keyword.get(opts, :chrome_args, Keyword.get(merged, :chrome_args, []))
    defaults = if headless?, do: ["--headless=new"], else: []
    defaults ++ ["--disable-gpu", "--no-sandbox"] ++ custom_args
  end

  defp chrome_args(opts, merged, false) do
    Keyword.get(opts, :chrome_args, Keyword.get(merged, :chrome_args, []))
  end

  defp firefox_options(opts, managed?) do
    merged = browser_opts(opts)
    args = firefox_args(opts, merged, managed?)

    options =
      if is_list(args) and args != [] do
        %{"args" => args}
      else
        %{}
      end

    if managed? do
      Map.put(options, "binary", firefox_binary!(opts, merged))
    else
      options
    end
  end

  defp firefox_args(opts, merged, true) do
    headless? = headless?(opts, merged)
    custom_args = Keyword.get(opts, :firefox_args, Keyword.get(merged, :firefox_args, []))
    defaults = if headless?, do: ["-headless"], else: []
    defaults ++ custom_args
  end

  defp firefox_args(opts, merged, false) do
    Keyword.get(opts, :firefox_args, Keyword.get(merged, :firefox_args, []))
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

  defp firefox_binary!(opts, merged) do
    binary = Keyword.get(opts, :firefox_binary) || Keyword.get(merged, :firefox_binary)

    if is_binary(binary) and File.exists?(binary) do
      binary
    else
      raise ArgumentError,
            "firefox binary not configured; set :cerberus, :browser firefox_binary (or pass :firefox_binary)"
    end
  end

  defp webdriver_binary!(opts, :chrome), do: chromedriver_binary!(opts)
  defp webdriver_binary!(opts, :firefox), do: geckodriver_binary!(opts)

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

  defp geckodriver_binary!(opts) do
    binary =
      Keyword.get(opts, :geckodriver_binary) ||
        browser_opts(opts)[:geckodriver_binary]

    if is_binary(binary) and File.exists?(binary) do
      binary
    else
      raise ArgumentError,
            "geckodriver binary not configured; set :cerberus, :browser geckodriver_binary (or pass :geckodriver_binary)"
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

  defp requested_browser_name(opts) when is_list(opts) do
    with :error <- Keyword.fetch(opts, :browser_name),
         browser_opts when is_list(browser_opts) <- Keyword.get(opts, :browser),
         true <- Keyword.keyword?(browser_opts),
         true <- Keyword.has_key?(browser_opts, :browser_name) do
      browser_opts
      |> Keyword.get(:browser_name)
      |> normalize_browser_name(nil)
    else
      {:ok, value} -> normalize_browser_name(value, nil)
      _ -> nil
    end
  end

  defp merge_runtime_opts(base, overrides) when is_list(base) and is_list(overrides) do
    merged =
      base
      |> Keyword.delete(:browser)
      |> Keyword.merge(Keyword.delete(overrides, :browser))

    browser_merged =
      base
      |> Keyword.get(:browser, [])
      |> merge_browser_opts(Keyword.get(overrides, :browser, []))

    if browser_merged == [] do
      merged
    else
      Keyword.put(merged, :browser, browser_merged)
    end
  end

  defp merge_browser_opts(base, overrides) when is_list(base) and is_list(overrides) do
    if Keyword.keyword?(base) and Keyword.keyword?(overrides) do
      Keyword.merge(base, overrides)
    else
      base
    end
  end

  defp merge_browser_opts(base, _overrides), do: base

  defp normalize_browser_name(value, _default) when value in [:chrome, "chrome"], do: :chrome
  defp normalize_browser_name(value, _default) when value in [:firefox, "firefox"], do: :firefox
  defp normalize_browser_name(nil, default), do: default

  defp normalize_browser_name(value, _default) do
    raise ArgumentError, "browser_name must be :chrome or :firefox, got: #{inspect(value)}"
  end

  defp normalize_non_empty_string(value, default) when is_binary(value) do
    if byte_size(String.trim(value)) > 0, do: value, else: default
  end

  defp normalize_non_empty_string(_value, default), do: default

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default
end
