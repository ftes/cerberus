defmodule Cerberus.TestSupport.SharedBrowserSession do
  @moduledoc false

  alias Cerberus.Driver.Browser.Runtime

  @boot_timeout_ms 30_000
  @stop_timeout_ms 5_000

  @spec start!(keyword()) :: {pid(), Cerberus.Session.t()}
  def start!(opts \\ []) when is_list(opts) do
    parent = self()

    owner_pid =
      spawn_link(fn ->
        try do
          browser_session = Cerberus.session(:browser, opts)
          send(parent, {:shared_browser_session_ready, self(), browser_session})

          receive do
            :stop -> :ok
          end
        rescue
          error ->
            send(parent, {:shared_browser_session_failed, self(), error, __STACKTRACE__})
        end
      end)

    receive do
      {:shared_browser_session_ready, ^owner_pid, browser_session} ->
        {owner_pid, browser_session}

      {:shared_browser_session_failed, ^owner_pid, error, stacktrace} ->
        reraise(error, stacktrace)
    after
      @boot_timeout_ms ->
        Process.exit(owner_pid, :kill)

        raise "timed out starting shared browser session after #{@boot_timeout_ms}ms"
    end
  end

  @spec stop(pid()) :: :ok
  def stop(owner_pid) when is_pid(owner_pid) do
    if Process.alive?(owner_pid) do
      ref = Process.monitor(owner_pid)
      send(owner_pid, :stop)

      receive do
        {:DOWN, ^ref, :process, ^owner_pid, _reason} -> :ok
      after
        @stop_timeout_ms ->
          Process.exit(owner_pid, :kill)
      end
    end

    :ok
  end

  @spec driver_session(:phoenix | :browser, map()) :: Cerberus.Session.t()
  def driver_session(:phoenix, _context), do: Cerberus.session(:phoenix)
  def driver_session(:browser, %{shared_browser_session: browser_session}), do: browser_session

  @spec maybe_use_cdp_evaluate(keyword()) :: keyword()
  def maybe_use_cdp_evaluate(opts \\ []) when is_list(opts) do
    if Runtime.browser_name(opts) == :chrome do
      Keyword.put(opts, :use_cdp_evaluate, true)
    else
      Keyword.delete(opts, :use_cdp_evaluate)
    end
  end
end
