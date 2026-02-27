defmodule Cerberus.Fixtures.PageController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  alias Cerberus.Fixtures.SandboxMessages

  def index(conn, _params), do: redirect(conn, to: "/articles")

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
          <h1>Articles</h1>
          <p>This is an articles index page</p>
          <p style="display:none">Hidden helper text</p>
          <a href="/live/counter">Counter</a>
        </main>
      </body>
    </html>
    """)
  end

  def main(conn, _params) do
    custom_header = conn |> Plug.Conn.get_req_header("x-custom-header") |> List.first() |> Kernel.||("")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Main Page</title>
      </head>
      <body>
        <main>
          <h1>Main page</h1>
          <p id="custom-header">x-custom-header: #{custom_header}</p>
          <a href="/articles">Articles</a>
        </main>
      </body>
    </html>
    """)
  end

  def sandbox_messages(conn, _params) do
    messages = SandboxMessages.list_bodies()

    message_items =
      Enum.map_join(messages, "\n", fn body ->
        ~s(<li class="sandbox-message">#{body}</li>)
      end)

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Sandbox Messages</title>
      </head>
      <body>
        <main>
          <h1>Sandbox messages</h1>
          <ul id="sandbox-messages">
            #{message_items}
          </ul>
        </main>
      </body>
    </html>
    """)
  end

  def redirect_static(conn, _params), do: redirect(conn, to: "/articles")
  def redirect_live(conn, _params), do: redirect(conn, to: "/live/counter")

  def scoped(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Scoped Page</title>
      </head>
      <body>
        <main>
          <section id="primary-panel">
            <h2>Primary Panel</h2>
            <p>Status: primary</p>
            <a href="/articles">Open</a>
          </section>

          <section id="secondary-panel">
            <h2>Secondary Panel</h2>
            <p>Status: secondary</p>
            <a href="/search">Open</a>
          </section>
        </main>
      </body>
    </html>
    """)
  end

  def search_form(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Search Form</title>
      </head>
      <body>
        <main>
          <h1>Search</h1>
          <a href="/articles">Articles</a>
          <form action="/search/results" method="get">
            <label for="search_q">Search term</label>
            <input id="search_q" name="q" type="text" value="" />
            <button type="submit">Run Search</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def search_results(conn, params) do
    params = merged_request_params(conn, params)
    query = Map.get(params, "q", "")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Search Results</title>
      </head>
      <body>
        <main>
          <p>Search query: #{query}</p>
        </main>
      </body>
    </html>
    """)
  end

  def owner_form(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Owner Form</title>
      </head>
      <body>
        <main>
          <form id="owner-form" action="/owner-form/result" method="get">
            <label for="owner_name">Name</label>
            <input id="owner_name" name="name" form="owner-form" type="text" value="" />
          </form>
          <button type="button" form="owner-form">Reset</button>
          <button type="submit" form="owner-form" name="form-button" value="save-owner-form">
            Save Owner Form
          </button>
          <button
            type="submit"
            form="owner-form"
            formaction="/owner-form/redirect"
            name="form-button"
            value="save-owner-form-redirect"
          >
            Save Owner Form Redirect
          </button>
        </main>
      </body>
    </html>
    """)
  end

  def owner_form_result(conn, params) do
    params = merged_request_params(conn, params)
    name = Map.get(params, "name", "")
    button = Map.get(params, "form-button", "")
    flow_token = conn |> Plug.Conn.get_req_header("x-flow-token") |> List.first() |> Kernel.||("")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Owner Form Result</title>
      </head>
      <body>
        <main>
          <p id="form-data-name">name: #{name}</p>
          <p id="form-data-button">form-button: #{button}</p>
          <p id="form-data-flow-token">x-flow-token: #{flow_token}</p>
        </main>
      </body>
    </html>
    """)
  end

  def owner_form_redirect(conn, params) do
    params = merged_request_params(conn, params)
    query = URI.encode_query(params)
    path = "/owner-form/result"
    destination = if query == "", do: path, else: path <> "?" <> query
    redirect(conn, to: destination)
  end

  defp merged_request_params(conn, params) when is_map(params) do
    conn
    |> Plug.Conn.fetch_query_params()
    |> Map.get(:query_params, %{})
    |> Map.merge(params)
  end

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
          <p>Oracle mismatch static fixture marker</p>
        </main>
      </body>
    </html>
    """)
  end
end
