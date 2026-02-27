defmodule Cerberus.Fixtures.PageController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Cerberus.Fixtures

  def index(conn, _params), do: redirect(conn, to: Fixtures.articles_path())

  def articles(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Articles</title>
      </head>
      <body>
        <main>
          <h1>#{Fixtures.articles_title()}</h1>
          <p>#{Fixtures.articles_summary()}</p>
          <p style="display:none">#{Fixtures.hidden_helper_text()}</p>
          <a href="#{Fixtures.counter_path()}">#{Fixtures.counter_link()}</a>
        </main>
      </body>
    </html>
    """)
  end

  def redirect_static(conn, _params), do: redirect(conn, to: Fixtures.articles_path())
  def redirect_live(conn, _params), do: redirect(conn, to: Fixtures.counter_path())

  def oracle_mismatch(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Oracle Mismatch</title>
      </head>
      <body>
        <main>
          <p>#{Fixtures.oracle_static_marker()}</p>
        </main>
      </body>
    </html>
    """)
  end
end
