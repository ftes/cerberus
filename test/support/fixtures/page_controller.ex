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

          <form action="/search/nested/results" method="get">
            <label>
              Search term <span class="required">*</span>
              <input name="nested_q" type="text" value="" />
            </label>
            <button type="submit">Run Nested Search</button>
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

  def search_nested_results(conn, params) do
    params = merged_request_params(conn, params)
    query = Map.get(params, "nested_q", "")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Nested Search Results</title>
      </head>
      <body>
        <main>
          <p>Nested search query: #{query}</p>
        </main>
      </body>
    </html>
    """)
  end

  def profile_version_a(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Profile Version A</title>
      </head>
      <body>
        <main>
          <h1>Profile Form Version A</h1>
          <a href="/search/profile/b">Switch to Version B</a>

          <form id="profile-form" action="/search/profile/results" method="get">
            <input type="hidden" name="profile[version]" value="a" />
            <label for="profile_version_a_text">Version A Text</label>
            <input id="profile_version_a_text" type="text" name="profile[version_a_text]" value="" />
            <button type="submit">Save Profile</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def profile_version_b(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Profile Version B</title>
      </head>
      <body>
        <main>
          <h1>Profile Form Version B</h1>
          <a href="/search/profile/a">Switch to Version A</a>

          <form id="profile-form" action="/search/profile/results" method="get">
            <input type="hidden" name="profile[version]" value="b" />
            <label for="profile_version_b_text">Version B Text</label>
            <input id="profile_version_b_text" type="text" name="profile[version_b_text]" value="" />
            <button type="submit">Save Profile</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def profile_results(conn, params) do
    params = merged_request_params(conn, params)
    profile = Map.get(params, "profile", %{})

    has_version_a_text? = Map.has_key?(profile, "version_a_text")
    has_version_b_text? = Map.has_key?(profile, "version_b_text")
    version_b_text = Map.get(profile, "version_b_text", "")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Profile Results</title>
      </head>
      <body>
        <main>
          <p>has version_a_text?: #{has_version_a_text?}</p>
          <p>has version_b_text?: #{has_version_b_text?}</p>
          <p>submitted version_b_text: #{version_b_text}</p>
        </main>
      </body>
    </html>
    """)
  end

  def browser_extensions(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Browser Extensions</title>
      </head>
      <body>
        <main>
          <h1>Browser Extensions</h1>

          <section>
            <h2>Keyboard</h2>
            <label for="keyboard-input">Keyboard input</label>
            <input id="keyboard-input" type="text" value="" />
            <p id="keyboard-value">Keyboard value: </p>
          </section>

          <section>
            <h2>Press</h2>
            <form id="press-form">
              <label for="press-input">Press input</label>
              <input id="press-input" type="text" value="" />
            </form>
            <p id="press-result">Press result: pending</p>
          </section>

          <section>
            <h2>Dialog</h2>
            <button id="confirm-dialog" type="button">Open Confirm Dialog</button>
            <p id="dialog-result">Dialog result: pending</p>
          </section>

          <section>
            <h2>Drag</h2>
            <div id="drag-source" draggable="true">Drag source</div>
            <div id="drop-target">Drop target</div>
            <p id="drag-result">Drag result: pending</p>
          </section>
        </main>

        <script>
          (() => {
            const keyboardInput = document.getElementById("keyboard-input");
            const keyboardValue = document.getElementById("keyboard-value");
            const pressForm = document.getElementById("press-form");
            const pressResult = document.getElementById("press-result");
            const dialogButton = document.getElementById("confirm-dialog");
            const dialogResult = document.getElementById("dialog-result");
            const dragSource = document.getElementById("drag-source");
            const dropTarget = document.getElementById("drop-target");
            const dragResult = document.getElementById("drag-result");

            keyboardInput.addEventListener("input", () => {
              keyboardValue.textContent = "Keyboard value: " + keyboardInput.value;
            });

            pressForm.addEventListener("submit", (event) => {
              event.preventDefault();
              pressResult.textContent = "Press result: submitted";
            });

            dialogButton.addEventListener("click", () => {
              const accepted = window.confirm("Delete item?");
              dialogResult.textContent = accepted
                ? "Dialog result: confirmed"
                : "Dialog result: cancelled";
            });

            dragSource.addEventListener("dragstart", (event) => {
              event.dataTransfer.setData("text/plain", "drag-source");
            });

            dropTarget.addEventListener("dragover", (event) => {
              event.preventDefault();
            });

            dropTarget.addEventListener("drop", (event) => {
              event.preventDefault();
              dragResult.textContent = "Drag result: dropped";
            });
          })();
        </script>
      </body>
    </html>
    """)
  end

  def session_user(conn, _params) do
    value = Plug.Conn.get_session(conn, :session_user) || "unset"

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Session User</title>
      </head>
      <body>
        <main>
          <p>Session user: #{value}</p>
        </main>
      </body>
    </html>
    """)
  end

  def set_session_user(conn, %{"value" => value}) do
    conn
    |> Plug.Conn.put_session(:session_user, value)
    |> redirect(to: "/session/user")
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

  def checkbox_array(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Checkbox Arrays</title>
      </head>
      <body>
        <main>
          <form id="checkbox-array-form" action="/checkbox-array/result" method="get">
            <input type="hidden" name="items[]" value="" />

            <label for="item_one">One</label>
            <input id="item_one" type="checkbox" name="items[]" value="one" checked />

            <label for="item_two">Two</label>
            <input id="item_two" type="checkbox" name="items[]" value="two" />

            <label for="item_three">Three</label>
            <input id="item_three" type="checkbox" name="items[]" value="three" />

            <button type="submit">Save Items</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def checkbox_array_result(conn, params) do
    params = merged_request_params(conn, params)

    items =
      params
      |> Map.get("items", [])
      |> List.wrap()
      |> Enum.reject(&(&1 == ""))

    selected = if items == [], do: "None", else: Enum.join(items, ",")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Checkbox Array Result</title>
      </head>
      <body>
        <main>
          <p id="selected-items">Selected Items: #{selected}</p>
        </main>
      </body>
    </html>
    """)
  end

  def trigger_action_result(conn, params) do
    params = merged_request_params(conn, params)
    trigger_hidden = Map.get(params, "trigger_action_hidden_input", "")
    trigger_input = Map.get(params, "trigger_action_input", "")
    patch_value = Map.get(params, "patch_and_trigger_action", "")
    message = Map.get(params, "message", "")
    multi_hidden = Map.get(params, "multi_hidden", "")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Trigger Action Result</title>
      </head>
      <body>
        <main>
          <p id="request-method">method: #{conn.method}</p>
          <div id="form-data">
            <p>trigger_action_hidden_input: #{trigger_hidden}</p>
            <p>trigger_action_input: #{trigger_input}</p>
            <p>patch_and_trigger_action: #{patch_value}</p>
            <p>message: #{message}</p>
            <p>multi_hidden: #{multi_hidden}</p>
          </div>
        </main>
      </body>
    </html>
    """)
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
