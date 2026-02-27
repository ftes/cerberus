defmodule Cerberus.Driver.Browser.UserContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDi
  alias Cerberus.Driver.Browser.BrowsingContextProcess
  alias Cerberus.Driver.Browser.BrowsingContextSupervisor
  alias Cerberus.Driver.Browser.Runtime

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: {__MODULE__, make_ref()},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec base_url(pid()) :: String.t()
  def base_url(pid) when is_pid(pid) do
    GenServer.call(pid, :base_url)
  end

  @spec navigate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def navigate(pid, url) when is_pid(pid) and is_binary(url) do
    GenServer.call(pid, {:navigate, url}, 10_000)
  end

  @spec evaluate(pid(), String.t()) :: {:ok, map()} | {:error, String.t(), map()}
  def evaluate(pid, expression) when is_pid(pid) and is_binary(expression) do
    GenServer.call(pid, {:evaluate, expression}, 10_000)
  end

  @impl true
  def init(opts) do
    owner = Keyword.fetch!(opts, :owner)
    owner_ref = Process.monitor(owner)

    with {:ok, browsing_context_supervisor} <- BrowsingContextSupervisor.start_link(),
         {:ok, user_context_id} <- create_user_context(),
         {:ok, browsing_context_pid} <-
           start_browsing_context(browsing_context_supervisor, user_context_id) do
      browsing_context_ref = Process.monitor(browsing_context_pid)

      {:ok,
       %{
         owner: owner,
         owner_ref: owner_ref,
         base_url: Runtime.base_url(),
         user_context_id: user_context_id,
         browsing_context_supervisor: browsing_context_supervisor,
         active_browsing_context_pid: browsing_context_pid,
         active_browsing_context_ref: browsing_context_ref
       }}
    else
      {:error, reason} ->
        {:stop, reason}

      {:error, reason, details} ->
        {:stop, {reason, details}}
    end
  end

  @impl true
  def handle_call(:base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call({:navigate, url}, _from, state) do
    {:reply, BrowsingContextProcess.navigate(state.active_browsing_context_pid, url), state}
  end

  def handle_call({:evaluate, expression}, _from, state) do
    {:reply, BrowsingContextProcess.evaluate(state.active_browsing_context_pid, expression),
     state}
  end

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _pid, reason},
        %{active_browsing_context_ref: ref} = state
      ) do
    {:stop, {:browsing_context_down, reason}, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{owner_ref: ref} = state) do
    # Owner/test process finished; tear down userContext as a normal shutdown.
    {:stop, :normal, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = remove_user_context(state.user_context_id)

    if is_pid(state.browsing_context_supervisor) and
         Process.alive?(state.browsing_context_supervisor) do
      _ = DynamicSupervisor.stop(state.browsing_context_supervisor)
    end

    :ok
  end

  defp create_user_context do
    with {:ok, result} <- BiDi.command("browser.createUserContext"),
         user_context_id when is_binary(user_context_id) <- result["userContext"] do
      {:ok, user_context_id}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      _ ->
        {:error, "unexpected browser.createUserContext response", %{}}
    end
  end

  defp remove_user_context(user_context_id) when is_binary(user_context_id) do
    BiDi.command("browser.removeUserContext", %{"userContext" => user_context_id})
  end

  defp remove_user_context(_), do: :ok

  defp start_browsing_context(browsing_context_supervisor, user_context_id) do
    DynamicSupervisor.start_child(
      browsing_context_supervisor,
      {BrowsingContextProcess, user_context_id: user_context_id}
    )
  end
end
