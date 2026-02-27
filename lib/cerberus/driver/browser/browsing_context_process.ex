defmodule Cerberus.Driver.Browser.BrowsingContextProcess do
  @moduledoc false

  use GenServer

  alias Cerberus.Driver.Browser.BiDi

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

  @spec id(pid()) :: String.t()
  def id(pid) when is_pid(pid) do
    GenServer.call(pid, :id)
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
    user_context_id = Keyword.fetch!(opts, :user_context_id)

    case create_browsing_context(user_context_id) do
      {:ok, browsing_context_id} ->
        {:ok, %{id: browsing_context_id, user_context_id: user_context_id}}

      {:error, reason, details} ->
        {:stop, {:create_browsing_context_failed, reason, details}}
    end
  end

  @impl true
  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_call({:navigate, url}, _from, state) do
    result =
      BiDi.command("browsingContext.navigate", %{
        "context" => state.id,
        "url" => url,
        "wait" => "complete"
      })

    {:reply, result, state}
  end

  def handle_call({:evaluate, expression}, _from, state) do
    result =
      BiDi.command("script.evaluate", %{
        "target" => %{"context" => state.id},
        "expression" => expression,
        "awaitPromise" => true,
        "resultOwnership" => "none"
      })

    {:reply, result, state}
  end

  @impl true
  def terminate(_reason, state) do
    _ = BiDi.command("browsingContext.close", %{"context" => state.id})
    :ok
  end

  defp create_browsing_context(user_context_id) do
    with {:ok, result} <-
           BiDi.command("browsingContext.create", %{
             "type" => "tab",
             "userContext" => user_context_id
           }),
         browsing_context_id when is_binary(browsing_context_id) <- result["context"] do
      {:ok, browsing_context_id}
    else
      {:error, reason, details} ->
        {:error, reason, details}

      _ ->
        {:error, "unexpected browsingContext.create response", %{}}
    end
  end
end
