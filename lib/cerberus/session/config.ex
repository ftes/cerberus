defmodule Cerberus.Session.Config do
  @moduledoc false

  @default_timeout_ms 0
  @default_live_timeout_ms 500
  @default_browser_timeout_ms 500

  @type driver_kind :: :static | :live | :browser

  @spec timeout_from_opts!(keyword(), driver_kind()) :: {non_neg_integer(), boolean()}
  def timeout_from_opts!(opts, driver) when is_list(opts) and driver in [:static, :live, :browser] do
    if Keyword.has_key?(opts, :timeout_ms) do
      {normalize_timeout_ms!(Keyword.get(opts, :timeout_ms)), true}
    else
      {default_timeout_ms(driver), false}
    end
  end

  @spec default_timeout_ms(driver_kind()) :: non_neg_integer()
  def default_timeout_ms(driver) when driver in [:static, :live, :browser] do
    fallback =
      case driver do
        :static -> @default_timeout_ms
        :live -> @default_live_timeout_ms
        :browser -> @default_browser_timeout_ms
      end

    global_timeout =
      :cerberus
      |> Application.get_env(:timeout_ms)
      |> normalize_non_negative_integer(fallback)

    driver_timeout =
      :cerberus
      |> Application.get_env(driver, [])
      |> Keyword.get(:timeout_ms)

    normalize_non_negative_integer(driver_timeout, global_timeout)
  end

  @spec normalize_timeout_ms!(term()) :: non_neg_integer()
  def normalize_timeout_ms!(timeout) when is_integer(timeout) and timeout >= 0, do: timeout

  def normalize_timeout_ms!(timeout) do
    raise ArgumentError, ":timeout_ms must be a non-negative integer, got: #{inspect(timeout)}"
  end

  defp normalize_non_negative_integer(value, _default) when is_integer(value) and value >= 0, do: value
  defp normalize_non_negative_integer(_value, default), do: default
end
