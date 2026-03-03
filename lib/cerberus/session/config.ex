defmodule Cerberus.Session.Config do
  @moduledoc false

  @default_assert_timeout_ms 0
  @default_live_browser_assert_timeout_ms 500

  @spec assert_timeout_from_opts!(keyword()) :: non_neg_integer()
  def assert_timeout_from_opts!(opts) when is_list(opts) do
    assert_timeout_from_opts!(opts, @default_assert_timeout_ms)
  end

  @spec assert_timeout_from_opts!(keyword(), non_neg_integer()) :: non_neg_integer()
  def assert_timeout_from_opts!(opts, fallback_default)
      when is_list(opts) and is_integer(fallback_default) and fallback_default >= 0 do
    if Keyword.has_key?(opts, :assert_timeout_ms) do
      case Keyword.get(opts, :assert_timeout_ms) do
        timeout when is_integer(timeout) and timeout >= 0 ->
          timeout

        timeout ->
          raise ArgumentError, ":assert_timeout_ms must be a non-negative integer, got: #{inspect(timeout)}"
      end
    else
      default_assert_timeout_ms(fallback_default)
    end
  end

  @spec default_assert_timeout_ms() :: non_neg_integer()
  def default_assert_timeout_ms do
    default_assert_timeout_ms(@default_assert_timeout_ms)
  end

  @spec default_assert_timeout_ms(non_neg_integer()) :: non_neg_integer()
  def default_assert_timeout_ms(fallback_default) when is_integer(fallback_default) and fallback_default >= 0 do
    :cerberus
    |> Application.get_env(:assert_timeout_ms)
    |> normalize_non_negative_integer(fallback_default)
  end

  @spec live_browser_assert_timeout_default_ms() :: non_neg_integer()
  def live_browser_assert_timeout_default_ms do
    default_assert_timeout_ms(@default_live_browser_assert_timeout_ms)
  end

  defp normalize_non_negative_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_negative_integer(_value, default), do: default
end
