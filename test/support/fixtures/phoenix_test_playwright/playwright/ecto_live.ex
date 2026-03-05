defmodule Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.EctoLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Cerberus.Fixtures.Repo

  def render(assigns) do
    ~H"""
    <div>
    Version:
    <.async_result :let={version} assign={@version}>
      {version}
      <:loading>
        Loading...
      </:loading>
    </.async_result>
    </div>

    <div>
    Long running:
    <.async_result :let={long_running} assign={@long_running}>
      {long_running}
      <:loading>
        Loading...
      </:loading>
    </.async_result>
    </div>

    <div>
    Delayed version:
    <.async_result :let={delayed_version} assign={@delayed_version}>
      {delayed_version}
      <:loading>
        Loading...
      </:loading>
    </.async_result>
    </div>
    """
  end

  def mount(params, _session, socket) do
    delay_ms = String.to_integer(params["delay_ms"] || "0")

    {:ok,
     socket
     |> assign_async(:version, fn -> {:ok, %{version: version_query()}} end)
     |> assign_async(:long_running, fn -> {:ok, %{long_running: long_running_query(delay_ms)}} end)
     |> assign_async(:delayed_version, fn ->
       Process.sleep(delay_ms)
       {:ok, %{delayed_version: version_query()}}
     end)}
  end

  defp version_query do
    %{rows: [[version]]} = Repo.query!("SELECT VERSION();")
    version
  end

  defp long_running_query(delay_ms) do
    %{rows: [[:void]]} = Repo.query!("SELECT PG_SLEEP(#{delay_ms / 1000});")
    :void
  end
end
