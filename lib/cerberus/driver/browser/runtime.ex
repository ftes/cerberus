defmodule Cerberus.Driver.Browser.Runtime do
  @moduledoc false

  use GenServer

  @default_browser_name :chrome
  @default_runtime_http_timeout_ms 5_000
  @default_chrome_startup_retries 1
  @default_startup_log_tail_bytes 8_192
  @default_startup_log_tail_lines 40
  @startup_attempts 120
  @startup_sleep_ms 50

  @type service :: %{
          url: String.t(),
          browser_name: :chrome | :firefox,
          managed?: boolean(),
          process: port() | nil,
          startup_log_path: String.t() | nil,
          startup_log_ephemeral?: boolean()
        }

  @type runtime_session :: %{
          service: service(),
          browser_name: :chrome | :firefox,
          session_id: String.t(),
          web_socket_url: String.t(),
          owners: MapSet.t(pid())
        }

  @type state :: %{
          runtime_sessions: %{optional(:chrome | :firefox) => runtime_session()},
          base_url: String.t() | nil,
          opts: keyword(),
          owner_refs: %{optional(reference()) => {:chrome | :firefox, pid()}}
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
    Process.flag(:trap_exit, true)
    ensure_http_stack!()
    {:ok, %{runtime_sessions: %{}, base_url: Keyword.get(opts, :base_url), opts: opts, owner_refs: %{}}}
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

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    {:noreply, release_owner_runtime_session(state, ref, pid)}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp release_owner_runtime_session(state, ref, pid) do
    case Map.pop(state.owner_refs, ref) do
      {nil, _owner_refs} ->
        state

      {{browser_name, ^pid}, owner_refs} ->
        state
        |> Map.put(:owner_refs, owner_refs)
        |> prune_owner_from_runtime_session(browser_name, pid)
    end
  end

  defp prune_owner_from_runtime_session(state, browser_name, pid) do
    case Map.fetch(state.runtime_sessions, browser_name) do
      {:ok, runtime_session} ->
        owners = MapSet.delete(runtime_session.owners, pid)
        update_runtime_session_owners(state, browser_name, runtime_session, owners)

      :error ->
        state
    end
  end

  defp update_runtime_session_owners(state, browser_name, runtime_session, owners) do
    if MapSet.size(owners) == 0 do
      maybe_stop_runtime_session(runtime_session, state.opts)
      runtime_sessions = Map.delete(state.runtime_sessions, browser_name)
      %{state | runtime_sessions: runtime_sessions}
    else
      runtime_session = %{runtime_session | owners: owners}
      runtime_sessions = Map.put(state.runtime_sessions, browser_name, runtime_session)
      %{state | runtime_sessions: runtime_sessions}
    end
  end

  @impl true
  def terminate(_reason, state) do
    maybe_stop_runtime_sessions(state.runtime_sessions, state.opts)
    :ok
  end

  defp ensure_runtime_session(state, opts) do
    merged_opts = merge_runtime_opts(state.opts, opts)
    browser_name = browser_name(merged_opts)
    owner = owner_pid(merged_opts)

    case Map.fetch(state.runtime_sessions, browser_name) do
      {:ok, runtime_session} ->
        {runtime_session, state} = maybe_track_owner(runtime_session, state, browser_name, owner)
        runtime_sessions = Map.put(state.runtime_sessions, browser_name, runtime_session)
        {:ok, runtime_session, %{state | runtime_sessions: runtime_sessions}}

      :error ->
        case start_runtime_session(merged_opts) do
          {:ok, runtime_session} ->
            {runtime_session, state} = maybe_track_owner(runtime_session, state, browser_name, owner)
            runtime_sessions = Map.put(state.runtime_sessions, browser_name, runtime_session)
            {:ok, runtime_session, %{state | runtime_sessions: runtime_sessions}}

          {:error, reason} ->
            {:error, reason, state}
        end
    end
  end

  defp start_runtime_session(opts) do
    with {:ok, service} <- start_service(opts) do
      retries = startup_retry_attempts(service, opts)

      case start_webdriver_session_with_retry(service, opts, retries) do
        {:ok, service, session_id, web_socket_url} ->
          maybe_cleanup_startup_log(service)

          {:ok,
           %{
             service: service,
             browser_name: service.browser_name,
             session_id: session_id,
             web_socket_url: web_socket_url,
             owners: MapSet.new()
           }}

        {:error, service, reason} ->
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

  defp maybe_stop_runtime_sessions(runtime_sessions, opts) when is_map(runtime_sessions) do
    Enum.each(runtime_sessions, fn {_browser_name, runtime_session} ->
      maybe_stop_runtime_session(runtime_session, opts)
    end)
  end

  defp maybe_track_owner(runtime_session, state, _browser_name, nil), do: {runtime_session, state}

  defp maybe_track_owner(runtime_session, state, browser_name, owner) when is_pid(owner) do
    owners = Map.get(runtime_session, :owners, MapSet.new())

    if MapSet.member?(owners, owner) do
      {runtime_session, state}
    else
      monitor_ref = Process.monitor(owner)
      owner_refs = Map.put(state.owner_refs, monitor_ref, {browser_name, owner})
      runtime_session = %{runtime_session | owners: MapSet.put(owners, owner)}
      {runtime_session, %{state | owner_refs: owner_refs}}
    end
  end

  defp owner_pid(opts) when is_list(opts) do
    case Keyword.get(opts, :owner) do
      owner when is_pid(owner) -> owner
      _ -> nil
    end
  end

  defp start_service(opts) do
    browser_name = browser_name(opts)
    webdriver_url = remote_webdriver_url(opts)

    if is_binary(webdriver_url) do
      {:ok,
       %{
         url: webdriver_url,
         browser_name: browser_name,
         managed?: false,
         process: nil,
         startup_log_path: nil,
         startup_log_ephemeral?: false
       }}
    else
      start_managed_service(opts, browser_name)
    end
  end

  defp start_managed_service(opts, browser_name) do
    binary = opts |> webdriver_binary!(browser_name) |> Path.expand()
    port = Keyword.get(opts, :chromedriver_port) || random_port!()
    {startup_log_path, startup_log_ephemeral?} = startup_log_path(opts, browser_name)
    args = webdriver_service_args(browser_name, port, startup_log_path)

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
        {:ok,
         %{
           url: url,
           browser_name: browser_name,
           managed?: true,
           process: process,
           startup_log_path: startup_log_path,
           startup_log_ephemeral?: startup_log_ephemeral?
         }}

      {:error, reason} ->
        Port.close(process)
        {:error, reason}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  defp webdriver_service_args(:chrome, port, startup_log_path) do
    [to_charlist("--port=#{port}"), ~c"--verbose"] ++ maybe_log_path_arg(startup_log_path)
  end

  defp webdriver_service_args(:firefox, port, _startup_log_path) do
    [to_charlist("--port=#{port}"), ~c"--websocket-port=0"]
  end

  defp maybe_log_path_arg(path) when is_binary(path), do: [to_charlist("--log-path=#{path}")]
  defp maybe_log_path_arg(_path), do: []

  defp start_webdriver_session_with_retry(service, opts, retries_left)
       when is_integer(retries_left) and retries_left >= 0 do
    case start_webdriver_session(service, opts) do
      {:ok, session_id, web_socket_url} ->
        {:ok, service, session_id, web_socket_url}

      {:error, reason} ->
        handle_startup_session_failure(service, opts, retries_left, reason)
    end
  end

  defp handle_startup_session_failure(service, opts, retries_left, reason) do
    if retries_left > 0 and retryable_startup_error?(service, reason) do
      retry_start_webdriver_session(service, opts, retries_left - 1, reason)
    else
      {:error, service, append_startup_log(reason, service.startup_log_path, opts)}
    end
  end

  defp retry_start_webdriver_session(service, opts, retries_left, reason) do
    maybe_stop_service(service)
    maybe_cleanup_startup_log(service)

    case start_service(opts) do
      {:ok, replacement_service} ->
        start_webdriver_session_with_retry(replacement_service, opts, retries_left)

      {:error, restart_reason} ->
        reason = append_startup_log(reason, service.startup_log_path, opts)
        {:error, service, "#{reason}; webdriver restart failed: #{restart_reason}"}
    end
  end

  defp startup_retry_attempts(%{managed?: true, browser_name: :chrome}, opts) do
    chrome_startup_retries(opts)
  end

  defp startup_retry_attempts(_service, _opts), do: 0

  @doc false
  @spec chrome_startup_retries(keyword()) :: non_neg_integer()
  def chrome_startup_retries(opts) when is_list(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:chrome_startup_retries, browser_opts[:chrome_startup_retries])
    |> normalize_non_neg_integer(@default_chrome_startup_retries)
  end

  defp retryable_startup_error?(%{managed?: true, browser_name: :chrome}, reason) do
    chrome_startup_retryable_error?(reason)
  end

  defp retryable_startup_error?(_service, _reason), do: false

  @doc false
  @spec chrome_startup_retryable_error?(term()) :: boolean()
  def chrome_startup_retryable_error?(reason) when is_binary(reason) do
    downcased = String.downcase(reason)
    String.contains?(downcased, "session not created") and String.contains?(downcased, "chrome instance exited")
  end

  def chrome_startup_retryable_error?(_reason), do: false

  defp startup_log_path(opts, :chrome) do
    browser_opts = browser_opts(opts)

    case normalize_non_empty_string(Keyword.get(opts, :chromedriver_log_path, browser_opts[:chromedriver_log_path]), nil) do
      path when is_binary(path) ->
        case ensure_log_dir(path) do
          {:ok, expanded_path} -> {expanded_path, false}
          _ -> {nil, false}
        end

      _ ->
        autogenerated_path =
          Path.join(System.tmp_dir!(), "cerberus-chromedriver-#{:erlang.unique_integer([:positive])}.log")

        case ensure_log_dir(autogenerated_path) do
          {:ok, expanded_path} -> {expanded_path, true}
          _ -> {nil, false}
        end
    end
  end

  defp startup_log_path(_opts, _browser_name), do: {nil, false}

  defp ensure_log_dir(path) when is_binary(path) do
    expanded_path = Path.expand(path)

    case File.mkdir_p(Path.dirname(expanded_path)) do
      :ok -> {:ok, expanded_path}
      {:error, _reason} -> {:error, :mkdir_failed}
    end
  end

  defp maybe_cleanup_startup_log(%{startup_log_path: path, startup_log_ephemeral?: true}) when is_binary(path) do
    _ = File.rm(path)
    :ok
  end

  defp maybe_cleanup_startup_log(_service), do: :ok

  @doc false
  @spec append_startup_log(String.t(), String.t() | nil, keyword()) :: String.t()
  def append_startup_log(reason, startup_log_path, opts \\ []) when is_binary(reason) and is_list(opts) do
    case startup_log_tail(startup_log_path, opts) do
      nil ->
        reason

      {path, tail} when tail == "" ->
        reason <> " (chromedriver startup log: " <> path <> ")"

      {path, tail} ->
        reason <>
          " (chromedriver startup log: " <>
          path <> ")\nchromedriver startup log tail:\n" <> tail
    end
  end

  defp startup_log_tail(path, opts) when is_binary(path) and is_list(opts) do
    expanded_path = Path.expand(path)
    max_bytes = startup_log_tail_bytes(opts)
    max_lines = startup_log_tail_lines(opts)

    case File.read(expanded_path) do
      {:ok, contents} ->
        tail =
          contents
          |> trim_leading_bytes(max_bytes)
          |> String.split("\n", trim: true)
          |> Enum.take(-max_lines)
          |> Enum.join("\n")
          |> String.trim()

        {expanded_path, tail}

      _ ->
        nil
    end
  end

  defp startup_log_tail(_path, _opts), do: nil

  defp startup_log_tail_bytes(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:startup_log_tail_bytes, browser_opts[:startup_log_tail_bytes])
    |> normalize_positive_integer(@default_startup_log_tail_bytes)
  end

  defp startup_log_tail_lines(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:startup_log_tail_lines, browser_opts[:startup_log_tail_lines])
    |> normalize_positive_integer(@default_startup_log_tail_lines)
  end

  defp trim_leading_bytes(contents, max_bytes) when is_binary(contents) and is_integer(max_bytes) and max_bytes > 0 do
    size = byte_size(contents)

    if size <= max_bytes do
      contents
    else
      binary_part(contents, size - max_bytes, max_bytes)
    end
  end

  defp start_webdriver_session(service, opts) do
    payload = webdriver_session_payload(opts, service.managed?, service.browser_name)

    with {:ok, 200, body} <- http_json(:post, service.url <> "/session", payload, opts),
         {:ok, session_id, web_socket_url} <- parse_session_response(body, service.url) do
      {:ok, session_id, web_socket_url}
    else
      {:ok, status, body} ->
        {:error, "webdriver session request failed with status #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_session_response(%{"value" => %{"error" => error} = value}, _service_url) do
    message = value["message"] || error
    {:error, message}
  end

  defp parse_session_response(%{"value" => %{"sessionId" => session_id, "capabilities" => caps}}, service_url)
       when is_binary(session_id) and is_map(caps) do
    web_socket_url = normalize_web_socket_url(caps["webSocketUrl"], service_url)

    if is_binary(web_socket_url) and byte_size(web_socket_url) > 0 do
      {:ok, session_id, web_socket_url}
    else
      {:error, "webdriver session created without capabilities.webSocketUrl"}
    end
  end

  defp parse_session_response(response, _service_url) do
    {:error, "unexpected webdriver session response: #{inspect(response)}"}
  end

  @doc false
  @spec normalize_web_socket_url(String.t() | nil, String.t() | nil) :: String.t() | nil
  def normalize_web_socket_url(web_socket_url, service_url) when is_binary(web_socket_url) and is_binary(service_url) do
    with %URI{scheme: scheme, host: ws_host, port: ws_port} = ws_uri <- URI.parse(web_socket_url),
         true <- scheme in ["ws", "wss"],
         true <- is_binary(ws_host),
         true <- is_integer(ws_port),
         %URI{host: service_host, port: service_port} <- URI.parse(service_url),
         true <- is_binary(service_host),
         true <- is_integer(service_port),
         true <- rewrite_web_socket_url?(ws_uri, ws_host, service_host, ws_port, service_port) do
      ws_uri
      |> Map.put(:host, service_host)
      |> Map.put(:port, service_port)
      |> URI.to_string()
    else
      _ -> web_socket_url
    end
  end

  def normalize_web_socket_url(web_socket_url, _service_url), do: web_socket_url

  defp rewrite_web_socket_url?(ws_uri, ws_host, service_host, ws_port, service_port) do
    selenium_bidi_endpoint?(ws_uri) and
      (ws_host != service_host or ws_port != service_port) and
      (local_or_private_host?(ws_host) or ws_host == "localhost")
  end

  defp selenium_bidi_endpoint?(%URI{path: path}) when is_binary(path) do
    String.contains?(path, "/se/bidi")
  end

  defp selenium_bidi_endpoint?(_uri), do: false

  defp local_or_private_host?(host) when host in ["localhost", "127.0.0.1"], do: true

  defp local_or_private_host?(host) when is_binary(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, {10, _, _, _}} -> true
      {:ok, {127, _, _, _}} -> true
      {:ok, {172, second, _, _}} when second in 16..31 -> true
      {:ok, {192, 168, _, _}} -> true
      _ -> false
    end
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
    os_pid = process_os_pid(process)
    kill_target = local_service_kill_target(os_pid)

    signal_local_service(kill_target, "TERM")
    if Port.info(process) != nil, do: Port.close(process)

    Process.sleep(50)

    if local_service_alive?(kill_target) do
      signal_local_service(kill_target, "KILL")
    end

    :ok
  end

  defp maybe_stop_service(_), do: :ok

  defp process_os_pid(process) when is_port(process) do
    case Port.info(process, :os_pid) do
      {:os_pid, os_pid} when is_integer(os_pid) and os_pid > 0 -> os_pid
      _ -> nil
    end
  end

  defp local_service_kill_target(os_pid) when is_integer(os_pid) and os_pid > 0 do
    service_pgid = process_group_id(os_pid)
    runtime_pgid = current_process_group_id()

    if is_integer(service_pgid) and service_pgid > 0 and service_pgid != runtime_pgid do
      {:process_group, service_pgid}
    else
      {:process_tree, process_tree_pids(os_pid)}
    end
  end

  defp local_service_kill_target(_), do: :none

  defp local_service_alive?({:process_group, pgid}) do
    process_group_alive?(pgid)
  end

  defp local_service_alive?({:process_tree, pids}) when is_list(pids) do
    Enum.any?(pids, &pid_alive?/1)
  end

  defp local_service_alive?(:none), do: false

  defp signal_local_service({:process_group, pgid}, signal) do
    signal_process_group(pgid, signal)
  end

  defp signal_local_service({:process_tree, pids}, signal) when is_list(pids) do
    signal_process_tree(pids, signal)
  end

  defp signal_local_service(:none, _signal), do: :ok

  defp process_group_id(os_pid) when is_integer(os_pid) and os_pid > 0 do
    case System.cmd("ps", ["-o", "pgid=", "-p", Integer.to_string(os_pid)], stderr_to_stdout: true) do
      {output, 0} -> parse_positive_integer(output)
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp process_group_id(_), do: nil

  defp current_process_group_id do
    case parse_positive_integer(:os.getpid()) do
      nil -> nil
      os_pid -> process_group_id(os_pid)
    end
  end

  defp process_tree_pids(root_pid) when is_integer(root_pid) and root_pid > 0 do
    [root_pid]
    |> MapSet.new()
    |> process_tree_pids([root_pid])
    |> MapSet.to_list()
  end

  defp process_tree_pids(_), do: []

  defp process_tree_pids(visited, []), do: visited

  defp process_tree_pids(visited, [parent_pid | rest]) do
    children =
      parent_pid
      |> child_pids()
      |> Enum.reject(&MapSet.member?(visited, &1))

    visited = Enum.reduce(children, visited, &MapSet.put(&2, &1))
    process_tree_pids(visited, rest ++ children)
  end

  defp child_pids(parent_pid) when is_integer(parent_pid) and parent_pid > 0 do
    case System.cmd("pgrep", ["-P", Integer.to_string(parent_pid)], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split("\n", trim: true)
        |> Enum.map(&parse_positive_integer/1)
        |> Enum.reject(&is_nil/1)

      _ ->
        []
    end
  rescue
    _ -> []
  end

  defp child_pids(_), do: []

  defp signal_process_tree(pids, signal) when signal in ["TERM", "KILL"] and is_list(pids) do
    pids =
      pids
      |> Enum.filter(&(is_integer(&1) and &1 > 0))
      |> Enum.uniq()
      |> Enum.map(&Integer.to_string/1)

    case pids do
      [] ->
        :ok

      _ ->
        _ = System.cmd("kill", ["-#{signal}" | pids], stderr_to_stdout: true)
        :ok
    end
  rescue
    _ -> :ok
  end

  defp pid_alive?(os_pid) when is_integer(os_pid) and os_pid > 0 do
    case System.cmd("kill", ["-0", Integer.to_string(os_pid)], stderr_to_stdout: true) do
      {_output, 0} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp pid_alive?(_), do: false

  defp parse_positive_integer(value) when is_integer(value) and value > 0, do: value

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} when integer > 0 -> integer
      _ -> nil
    end
  end

  defp parse_positive_integer(_), do: nil

  defp process_group_alive?(os_pid) when is_integer(os_pid) and os_pid > 0 do
    case System.cmd("kill", ["-0", "--", "-#{os_pid}"], stderr_to_stdout: true) do
      {_output, 0} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp signal_process_group(os_pid, signal) when is_integer(os_pid) and os_pid > 0 and signal in ["TERM", "KILL"] do
    _ = System.cmd("kill", ["-#{signal}", "--", "-#{os_pid}"], stderr_to_stdout: true)
    :ok
  rescue
    _ -> :ok
  end

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
    browser_name = browser_name(opts)
    browser_opts = browser_opts(opts)
    browser_webdriver_url = browser_specific_webdriver_url(opts, browser_opts, browser_name)

    webdriver_urls =
      opts
      |> Keyword.get(:webdriver_urls, browser_opts[:webdriver_urls])
      |> normalize_webdriver_urls(browser_name)

    opts
    |> Keyword.get(
      :webdriver_url,
      browser_webdriver_url ||
        webdriver_urls ||
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
    defaults ++ ["--disable-gpu", "--no-sandbox", "--remote-debugging-port=0"] ++ custom_args
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

  defp normalize_webdriver_urls(urls, browser_name) when is_list(urls) and is_atom(browser_name) do
    if Keyword.keyword?(urls), do: urls[browser_name]
  end

  defp normalize_webdriver_urls(urls, browser_name) when is_map(urls) and is_atom(browser_name) do
    Map.get(urls, browser_name) || Map.get(urls, Atom.to_string(browser_name))
  end

  defp normalize_webdriver_urls(_urls, _browser_name), do: nil

  defp browser_specific_webdriver_url(opts, browser_opts, :chrome) when is_list(opts) and is_list(browser_opts) do
    normalize_non_empty_string(opts[:chrome_webdriver_url], nil) ||
      normalize_non_empty_string(browser_opts[:chrome_webdriver_url], nil)
  end

  defp browser_specific_webdriver_url(opts, browser_opts, :firefox) when is_list(opts) and is_list(browser_opts) do
    normalize_non_empty_string(opts[:firefox_webdriver_url], nil) ||
      normalize_non_empty_string(browser_opts[:firefox_webdriver_url], nil)
  end

  defp browser_specific_webdriver_url(_opts, _browser_opts, _browser_name), do: nil

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

  defp normalize_non_neg_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_neg_integer(_value, default), do: default

  defp normalize_positive_integer(value, _default) when is_integer(value) and value > 0, do: value
  defp normalize_positive_integer(_value, default), do: default
end
