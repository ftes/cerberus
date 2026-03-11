defmodule Cerberus.Browser.TestConcurrencyLimiter do
  @moduledoc false

  use GenServer

  defstruct size: nil, in_use: %{}, waiting: :queue.new()

  @type limiter_name :: atom()
  @type token_id :: reference()
  @type state :: %__MODULE__{
          size: pos_integer() | nil,
          in_use: %{token_id() => {pid(), reference()}},
          waiting: :queue.queue(GenServer.from())
        }

  @spec checkout(limiter_name(), pos_integer(), timeout()) ::
          {:ok, token_id()} | {:error, {:size_mismatch, pos_integer()}}
  def checkout(name, size, timeout) when is_atom(name) and is_integer(size) and size > 0 do
    _pid = ensure_started(name)
    GenServer.call(via_name(name), {:checkout, size}, timeout)
  end

  @spec checkin(limiter_name(), token_id()) :: :ok
  def checkin(name, token_id) when is_atom(name) and is_reference(token_id) do
    case :global.whereis_name(global_name(name)) do
      :undefined -> :ok
      _pid -> GenServer.call(via_name(name), {:checkin, token_id})
    end
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: via_name(name))
  end

  @impl GenServer
  @spec init(state()) :: {:ok, state()}
  def init(state), do: {:ok, state}

  @impl GenServer
  @spec handle_call({:checkout, pos_integer()}, GenServer.from(), state()) ::
          {:reply, {:ok, token_id()} | {:error, {:size_mismatch, pos_integer()}}, state()}
          | {:noreply, state()}
  def handle_call({:checkout, size}, from, state) do
    case put_size(state, size) do
      {:ok, state} ->
        if map_size(state.in_use) < state.size do
          {token_id, state} = do_checkout(state, from)
          {:reply, {:ok, token_id}, state}
        else
          {:noreply, enqueue_waiter(state, from)}
        end

      {:error, {:size_mismatch, _configured_size}} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  @spec handle_call({:checkin, token_id()}, GenServer.from(), state()) :: {:reply, :ok, state()}
  def handle_call({:checkin, token_id}, _from, state) do
    {:reply, :ok, maybe_wake_waiter(release_token(state, token_id))}
  end

  @impl GenServer
  @spec handle_info({:DOWN, reference(), :process, pid(), term()}, state()) :: {:noreply, state()}
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {:noreply, maybe_wake_waiter(release_monitor(state, ref))}
  end

  @spec ensure_started(limiter_name()) :: pid()
  defp ensure_started(name) do
    :global.trans({__MODULE__, name}, fn ->
      case :global.whereis_name(global_name(name)) do
        :undefined ->
          case start_link(name: name) do
            {:ok, pid} -> pid
            {:error, {:already_started, pid}} -> pid
          end

        pid when is_pid(pid) ->
          pid
      end
    end)
  end

  @spec put_size(state(), pos_integer()) :: {:ok, state()} | {:error, {:size_mismatch, pos_integer()}}
  defp put_size(%__MODULE__{size: nil} = state, size), do: {:ok, %{state | size: size}}
  defp put_size(%__MODULE__{size: size} = state, size), do: {:ok, state}
  defp put_size(%__MODULE__{size: configured_size}, _size), do: {:error, {:size_mismatch, configured_size}}

  @spec enqueue_waiter(state(), GenServer.from()) :: state()
  defp enqueue_waiter(%__MODULE__{} = state, from) do
    %{state | waiting: :queue.in(from, state.waiting)}
  end

  @spec do_checkout(state(), GenServer.from()) :: {token_id(), state()}
  defp do_checkout(%__MODULE__{} = state, {owner_pid, _tag}) do
    token_id = make_ref()
    monitor_ref = Process.monitor(owner_pid)

    updated_state = %{
      state
      | in_use: Map.put(state.in_use, token_id, {owner_pid, monitor_ref})
    }

    {token_id, updated_state}
  end

  @spec release_token(state(), token_id()) :: state()
  defp release_token(%__MODULE__{} = state, token_id) do
    case Map.pop(state.in_use, token_id) do
      {{_owner_pid, monitor_ref}, in_use} ->
        Process.demonitor(monitor_ref, [:flush])
        %{state | in_use: in_use}

      {nil, _in_use} ->
        state
    end
  end

  @spec release_monitor(state(), reference()) :: state()
  defp release_monitor(%__MODULE__{} = state, monitor_ref) do
    case Enum.find(state.in_use, fn {_token_id, {_owner_pid, ref}} -> ref == monitor_ref end) do
      {token_id, {_owner_pid, _ref}} -> release_token(state, token_id)
      nil -> state
    end
  end

  @spec maybe_wake_waiter(state()) :: state()
  defp maybe_wake_waiter(%__MODULE__{} = state) do
    case :queue.out(state.waiting) do
      {{:value, from}, waiting} ->
        {token_id, updated_state} = do_checkout(%{state | waiting: waiting}, from)
        GenServer.reply(from, {:ok, token_id})
        updated_state

      {:empty, _waiting} ->
        state
    end
  end

  @spec via_name(limiter_name()) :: {:global, {module(), limiter_name()}}
  defp via_name(name), do: {:global, global_name(name)}

  @spec global_name(limiter_name()) :: {module(), limiter_name()}
  defp global_name(name), do: {__MODULE__, name}
end
