defmodule MigrationFixtureWeb do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html],
        layouts: []

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: false

      unquote(html_helpers())
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
      unquote(verified_routes())
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML

      alias Phoenix.LiveView.JS
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MigrationFixtureWeb.Endpoint,
        router: MigrationFixtureWeb.Router,
        statics: []
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
