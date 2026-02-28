defmodule Cerberus.Session do
  @moduledoc "Runtime session shapes used by Cerberus drivers."

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static

  @default_assert_timeout_ms 0

  @type driver_kind :: :auto | :static | :live | :browser
  @type last_result :: %{op: atom(), observed: map()} | nil
  @type t :: Static.t() | Live.t() | Browser.t()

  @spec driver_kind(t()) :: :static | :live | :browser
  def driver_kind(%Static{}), do: :static
  def driver_kind(%Live{}), do: :live
  def driver_kind(%Browser{}), do: :browser

  @spec current_path(t()) :: String.t() | nil
  def current_path(%{current_path: current_path}), do: current_path

  @spec scope(t()) :: String.t() | nil
  def scope(%{scope: scope}), do: scope
  def scope(_session), do: nil

  @spec with_scope(t(), String.t() | nil) :: t()
  def with_scope(session, scope) when is_binary(scope) or is_nil(scope), do: Map.put(session, :scope, scope)

  @spec last_result(t()) :: last_result()
  def last_result(%{last_result: last_result}), do: last_result

  @spec transition(t()) :: map() | nil
  def transition(%{last_result: %{observed: observed}}) when is_map(observed) do
    observed[:transition] || observed["transition"]
  end

  def transition(_session), do: nil

  @spec assert_timeout_ms(t()) :: non_neg_integer()
  def assert_timeout_ms(%{assert_timeout_ms: timeout}) when is_integer(timeout) and timeout >= 0, do: timeout
  def assert_timeout_ms(_session), do: default_assert_timeout_ms()

  @doc false
  @spec assert_timeout_from_opts!(keyword()) :: non_neg_integer()
  def assert_timeout_from_opts!(opts) when is_list(opts) do
    if Keyword.has_key?(opts, :assert_timeout_ms) do
      case Keyword.get(opts, :assert_timeout_ms) do
        timeout when is_integer(timeout) and timeout >= 0 ->
          timeout

        timeout ->
          raise ArgumentError, ":assert_timeout_ms must be a non-negative integer, got: #{inspect(timeout)}"
      end
    else
      default_assert_timeout_ms()
    end
  end

  @spec default_assert_timeout_ms() :: non_neg_integer()
  def default_assert_timeout_ms do
    :cerberus
    |> Application.get_env(:assert_timeout_ms)
    |> normalize_non_negative_integer(@default_assert_timeout_ms)
  end

  defp normalize_non_negative_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_negative_integer(_value, default), do: default
end
