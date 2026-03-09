defmodule Cerberus.Driver.Browser.Runtime do
  @moduledoc false

  use GenServer

  alias Bibbidi.Browser, as: BibbidiBrowser

  @default_slow_mo_ms 0

  @type browser_process :: %{
          pid: pid(),
          monitor_ref: reference(),
          web_socket_url: String.t()
        }

  @type state :: %{
          browser: browser_process() | nil,
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

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    {:ok, %{browser: nil, base_url: Keyword.get(opts, :base_url), opts: opts}}
  end

  @impl true
  def handle_call(:base_url, _from, state) do
    base_url = state.base_url || base_url!(state.opts)
    {:reply, base_url, %{state | base_url: base_url}}
  end

  def handle_call({:web_socket_url, opts}, _from, state) do
    merged_opts = merge_runtime_opts(state.opts, opts)

    case ensure_browser(state.browser, merged_opts) do
      {:ok, browser} ->
        {:reply, {:ok, browser.web_socket_url}, %{state | browser: browser}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(
        {:DOWN, monitor_ref, :process, pid, reason},
        %{browser: %{pid: pid, monitor_ref: monitor_ref} = browser} = state
      ) do
    next_state = %{state | browser: nil}
    cleanup_browser(browser)
    {:stop, {:firefox_exited, reason}, next_state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    cleanup_browser(state.browser)
    :ok
  end

  @doc false
  @spec resolve_base_url(keyword()) :: String.t() | nil
  def resolve_base_url(opts) when is_list(opts) do
    Keyword.get(opts, :base_url) ||
      browser_opts(opts)[:base_url] ||
      Application.get_env(:cerberus, :base_url) ||
      endpoint_base_url(opts)
  end

  @doc false
  @spec headless?(keyword(), keyword()) :: boolean()
  def headless?(opts, merged) do
    Keyword.get(opts, :headless, Keyword.get(merged, :headless, true))
  end

  @doc false
  @spec slow_mo_ms(keyword()) :: non_neg_integer()
  def slow_mo_ms(opts) when is_list(opts) do
    browser_opts = browser_opts(opts)

    opts
    |> Keyword.get(:slow_mo, browser_opts[:slow_mo])
    |> normalize_non_neg_integer(@default_slow_mo_ms)
  end

  @doc false
  @spec browser_name(keyword()) :: :firefox
  def browser_name(opts \\ []) when is_list(opts) do
    case Keyword.get(opts, :browser_name, browser_opts(opts)[:browser_name]) do
      nil -> :firefox
      :firefox -> :firefox
      "firefox" -> :firefox
      other -> raise ArgumentError, "browser_name must be :firefox, got: #{inspect(other)}"
    end
  end

  defp ensure_browser(%{pid: pid} = browser, _opts) when is_pid(pid) do
    if Process.alive?(pid), do: {:ok, browser}, else: {:error, "firefox runtime is not alive"}
  end

  defp ensure_browser(nil, opts) do
    launch_browser(opts)
  end

  defp launch_browser(opts) do
    launch_opts = [headless: headless?(opts, browser_opts(opts)), browser_path: firefox_binary!(opts)]

    case BibbidiBrowser.start_link(launch_opts) do
      {:ok, pid} ->
        monitor_ref = Process.monitor(pid)
        {:ok, %{pid: pid, monitor_ref: monitor_ref, web_socket_url: BibbidiBrowser.url(pid)}}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  rescue
    error ->
      {:error, Exception.message(error)}
  end

  defp firefox_binary!(opts) do
    binary =
      first_existing_path([
        Keyword.get(opts, :firefox_binary),
        browser_opts(opts)[:firefox_binary],
        System.get_env("FIREFOX"),
        stable_binary_path("firefox-current")
      ])

    if is_binary(binary) and File.exists?(binary) do
      binary
    else
      raise ArgumentError,
            "firefox binary not configured; set :cerberus, :browser firefox_binary (or pass :firefox_binary), set FIREFOX, or run mix cerberus.install.firefox"
    end
  end

  defp first_existing_path(paths) when is_list(paths) do
    Enum.find_value(paths, fn
      path when is_binary(path) ->
        expanded_path = Path.expand(path)

        if File.exists?(expanded_path) do
          resolve_existing_path(expanded_path)
        end

      _ ->
        nil
    end)
  end

  defp resolve_existing_path(path) when is_binary(path) do
    case :file.read_link_all(String.to_charlist(path)) do
      {:ok, resolved} ->
        resolved = List.to_string(resolved)
        if File.exists?(resolved), do: resolved, else: path

      _ ->
        path
    end
  end

  defp cleanup_browser(nil), do: :ok

  defp cleanup_browser(%{pid: pid, monitor_ref: monitor_ref}) do
    if is_reference(monitor_ref) do
      Process.demonitor(monitor_ref, [:flush])
    end

    if is_pid(pid) and Process.alive?(pid) do
      _ = BibbidiBrowser.stop(pid)
    end

    :ok
  end

  defp stable_binary_path(name) when is_binary(name) do
    Path.expand(Path.join("tmp", name))
  end

  defp base_url!(opts) do
    resolve_base_url(opts) ||
      raise(
        ArgumentError,
        "missing base URL for browser driver; set :base_url, configure :cerberus, :base_url, or configure :cerberus, :endpoint"
      )
  end

  defp endpoint_base_url(opts) do
    endpoint = Keyword.get(opts, :endpoint) || Application.get_env(:cerberus, :endpoint)

    if is_atom(endpoint) and function_exported?(endpoint, :url, 0) do
      endpoint.url()
    end
  end

  defp browser_opts(opts) do
    :cerberus
    |> Application.get_env(:browser, [])
    |> Keyword.merge(Keyword.get(opts, :browser, []))
  end

  defp merge_runtime_opts(base, overrides) when is_list(base) and is_list(overrides) do
    merged =
      base
      |> Keyword.delete(:browser)
      |> Keyword.merge(Keyword.delete(overrides, :browser))

    browser_merged =
      base
      |> Keyword.get(:browser, [])
      |> Keyword.merge(Keyword.get(overrides, :browser, []))

    if browser_merged == [] do
      merged
    else
      Keyword.put(merged, :browser, browser_merged)
    end
  end

  defp normalize_non_neg_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_neg_integer(_value, default), do: default
end
