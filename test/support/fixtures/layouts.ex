defmodule Cerberus.Fixtures.Layouts do
  @moduledoc false

  use Phoenix.Component

  attr(:inner_content, :any, required: true)

  def root(assigns) do
    ~H"""
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <script defer phx-track-static src="/phoenix.min.js"></script>
        <script defer phx-track-static src="/phoenix_live_view.min.js"></script>
        <script defer phx-track-static src="/assets/app.js"></script>
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end
end
