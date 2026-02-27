defmodule Cerberus.Session do
  @moduledoc "Runtime session shapes used by Cerberus drivers."

  alias Cerberus.Driver.Browser
  alias Cerberus.Driver.Live
  alias Cerberus.Driver.Static

  @type driver_kind :: :auto | :static | :live | :browser
  @type last_result :: %{op: atom(), observed: map()} | nil
  @type t :: Static.t() | Live.t() | Browser.t()

  @spec driver_kind(t()) :: :static | :live | :browser
  def driver_kind(%Static{}), do: :static
  def driver_kind(%Live{}), do: :live
  def driver_kind(%Browser{}), do: :browser

  @spec current_path(t()) :: String.t() | nil
  def current_path(%{current_path: current_path}), do: current_path

  @spec last_result(t()) :: last_result()
  def last_result(%{last_result: last_result}), do: last_result
end
