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
          <span id="articles-title-label">Articles heading labelledby</span>
          <h1
            data-testid="articles-title"
            title="Articles heading"
            aria-label="Articles heading aria"
            aria-labelledby="articles-title-label"
          >
            Articles
          </h1>
          <p>This is an articles index page</p>
          <img
            src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs="
            alt="Articles hero image"
            title="Hero image"
          />
          <p style="display:none">Hidden helper text</p>
          <span id="articles-counter-link-label">Counter link labelledby</span>
          <a
            href="/live/counter"
            data-testid="articles-counter-link"
            aria-label="Counter link aria"
            aria-labelledby="articles-counter-link-label"
          >
            Counter
          </a>
        </main>
      </body>
    </html>
    """)
  end

  def styled_snapshot(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Styled Snapshot</title>
        <link rel="stylesheet" href="/assets/app.css" />
        <script src="/assets/app.js"></script>
      </head>
      <body>
        <main>
          <h1>Styled Snapshot</h1>
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

  def field_wrapper_errors(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Field Wrapper Errors</title>
      </head>
      <body>
        <main>
          <h1>Field wrapper fixture</h1>

          <div id="email-outer-wrapper" class="fieldset mb-2">
            <label for="profile_email_group">
              <span class="label mb-1">Contact</span>
              <input id="profile_email_group" name="profile[email_group]" type="text" value="" />
            </label>

            <div id="email-inner-wrapper" class="fieldset mb-2">
              <label for="profile_email">
                <span class="label mb-1">Email</span>
                <input
                  id="profile_email"
                  name="profile[email]"
                  type="email"
                  value=""
                  class="w-full input input-error"
                />
              </label>
              <p class="mt-1.5 flex gap-2 items-center text-sm text-error">Email can't be blank</p>
            </div>

            <p class="mt-1.5 flex gap-2 items-center text-sm text-error">Outer wrapper error</p>
          </div>

          <div id="name-wrapper" class="fieldset mb-2">
            <label for="profile_name">
              <span class="label mb-1">Name</span>
              <input
                id="profile_name"
                name="profile[name]"
                type="text"
                value=""
                class="w-full input input-error"
              />
            </label>
            <p class="mt-1.5 flex gap-2 items-center text-sm text-error">Name can't be blank</p>
          </div>
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
          <span id="search-title-label">Search heading labelledby</span>
          <h1
            data-testid="search-title"
            title="Search heading"
            aria-label="Search heading aria"
            aria-labelledby="search-title-label"
          >
            Search
          </h1>
          <a href="/articles">Articles</a>
          <form action="/search/results" method="get">
            <span id="search-field-label">Search term labelledby</span>
            <span id="search-submit-label">Run search labelledby</span>
            <label for="search_q">Search term</label>
            <input
              id="search_q"
              name="q"
              type="text"
              value=""
              placeholder="Search by term"
              title="Search input"
              aria-label="Search term aria"
              aria-labelledby="search-field-label"
              data-testid="search-input"
            />
            <button
              type="submit"
              title="Run search button"
              aria-label="Run search aria"
              aria-labelledby="search-submit-label"
              data-testid="search-submit"
            >
              Run Search
            </button>
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

  def nested_submit_form(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Nested Submit Form</title>
      </head>
      <body>
        <main>
          <h1>Nested Submit</h1>
          <form action="/nested-submit/result" method="post">
            <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}" />
            <label for="session_email">Email</label>
            <input id="session_email" name="session[email]" type="email" value="" />
            <label for="session_password">Password</label>
            <input id="session_password" name="session[password]" type="password" value="" />
            <button type="submit">Sign In</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def nested_submit_result(conn, params) do
    params = merged_request_params(conn, params)
    session = Map.get(params, "session", %{})
    email = Map.get(session, "email", "")
    password = Map.get(session, "password", "")
    has_flat_email_key = Map.has_key?(params, "session[email]")
    has_flat_password_key = Map.has_key?(params, "session[password]")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Nested Submit Result</title>
      </head>
      <body>
        <main>
          <p id="session-email">session.email: #{email}</p>
          <p id="session-password">session.password: #{password}</p>
          <p id="flat-session-email-key">flat session[email] key?: #{has_flat_email_key}</p>
          <p id="flat-session-password-key">flat session[password] key?: #{has_flat_password_key}</p>
        </main>
      </body>
    </html>
    """)
  end

  def static_upload(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Static Upload</title>
      </head>
      <body>
        <main>
          <h1>Static Upload</h1>
          <form
            id="static-upload-form"
            action="/upload/static/result"
            method="post"
            enctype="multipart/form-data"
          >
            <label for="static_upload_avatar">Avatar</label>
            <input id="static_upload_avatar" type="file" name="avatar" data-testid="static-avatar-upload" />
            <button type="submit" data-testid="static-upload-submit">Upload Avatar</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def static_upload_result(conn, params) do
    params = merged_request_params(conn, params)
    file_name = params |> Map.get("avatar") |> upload_filename()

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Static Upload Result</title>
      </head>
      <body>
        <main>
          <p id="uploaded-file">Uploaded file: #{file_name}</p>
        </main>
      </body>
    </html>
    """)
  end

  def controls_form(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Controls Form</title>
      </head>
      <body>
        <main>
          <h1>Controls</h1>

          <form id="controls-form" action="/controls/result" method="get">
            <label for="controls_race">Race</label>
            <select id="controls_race" name="race" data-testid="controls-race-select">
              <option value="human">Human</option>
              <option value="elf">Elf</option>
              <option value="dwarf">Dwarf</option>
              <option value="disabled_race" disabled>Disabled Race</option>
            </select>

            <label for="controls_age">Age</label>
            <input id="controls_age" type="number" name="age" value="33" data-testid="controls-age-input" />

            <label for="controls_disabled_name">Disabled name</label>
            <input id="controls_disabled_name" type="text" name="disabled_name" value="" disabled />

            <label for="controls_race_2">Race 2</label>
            <select id="controls_race_2" name="race_2[]" multiple data-testid="controls-race-2-select">
              <option value="elf">Elf</option>
              <option value="dwarf">Dwarf</option>
              <option value="orc">Orc</option>
            </select>

            <fieldset>
              <legend>Contact</legend>
              <input type="radio" id="controls_contact_email" name="contact" value="email" data-testid="controls-contact-email" />
              <label for="controls_contact_email">Email Choice</label>

              <input type="radio" id="controls_contact_phone" name="contact" value="phone" data-testid="controls-contact-phone" />
              <label for="controls_contact_phone">Phone Choice</label>

              <input type="radio" id="controls_contact_mail" name="contact" value="mail" checked data-testid="controls-contact-mail" />
              <label for="controls_contact_mail">Mail Choice</label>
            </fieldset>

            <label for="controls_disabled_notify">Disabled notify</label>
            <input type="checkbox" id="controls_disabled_notify" name="disabled_notify" value="yes" disabled />

            <label for="controls_disabled_contact">Disabled contact</label>
            <input type="radio" id="controls_disabled_contact" name="disabled_contact" value="pager" disabled />

            <label for="controls_disabled_select">Disabled select</label>
            <select id="controls_disabled_select" name="disabled_select" disabled>
              <option value="cannot_submit">Cannot submit</option>
            </select>

            <button type="button" disabled>Disabled Action</button>
            <button type="submit" disabled>Disabled Save Controls</button>
            <button type="submit" data-testid="save-controls">Save Controls</button>
          </form>
        </main>
      </body>
    </html>
    """)
  end

  def controls_result(conn, params) do
    params = merged_request_params(conn, params)
    race = Map.get(params, "race", "")
    age = Map.get(params, "age", "")
    race_2 = params |> Map.get("race_2", []) |> List.wrap() |> Enum.reject(&(&1 == ""))
    contact = Map.get(params, "contact", "")
    disabled_select = Map.get(params, "disabled_select", "")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Controls Result</title>
      </head>
      <body>
        <main>
          <div id="form-data">
            <p>race: #{race}</p>
            <p>age: #{age}</p>
            <p>race_2: [#{Enum.join(race_2, ",")}]</p>
            <p>contact: #{contact}</p>
            <p>disabled_select: #{disabled_select}</p>
          </div>
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
            <p id="keyboard-keydown-count">Keyboard keydown count: 0</p>
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
            <h2>Tab blur</h2>
            <label for="tab-input">Tab input</label>
            <input id="tab-input" type="text" value="" />
            <label for="tab-next">Next input</label>
            <input id="tab-next" type="text" value="" />
            <p id="tab-result">Tab result: pending</p>
            <p id="blur-result">Blur result: pending</p>
          </section>

          <section>
            <h2>Dialog</h2>
            <button id="confirm-dialog" type="button">Open Confirm Dialog</button>
            <p id="dialog-result">Dialog result: pending</p>
            <button id="prompt-dialog" type="button">Open Prompt Dialog</button>
            <p id="prompt-result">Prompt result: pending</p>
            <button id="alert-dialog" type="button">Open Alert Dialog</button>
            <p id="alert-result">Alert result: pending</p>
          </section>

          <section>
            <h2>Download</h2>
            <a id="download-report" href="/browser/download/report">Download Report</a>
          </section>

          <section>
            <h2>Drag</h2>
            <div id="drag-source" draggable="true">Drag source</div>
            <div id="drop-target">Drop target</div>
            <p id="drag-result">Drag result: pending</p>
          </section>

          <section>
            <h2>Actionability</h2>
            <button id="hidden-action" type="button" style="display:none">Hidden Action</button>
            <p id="hidden-action-result">Hidden action result: pending</p>

            <div style="height: 1600px"></div>

            <button id="offscreen-action" type="button">Offscreen Action</button>
            <p id="offscreen-action-result">Offscreen action result: pending</p>
          </section>

          <section>
            <h2>Labels</h2>
            <label id="checkbox-label" for="label-checkbox">Label checkbox</label>
            <input id="label-checkbox" type="checkbox" />
            <p id="label-click-result">Label click result: unchecked</p>
          </section>
        </main>

        <script>
          (() => {
            const keyboardInput = document.getElementById("keyboard-input");
            const keyboardValue = document.getElementById("keyboard-value");
            const keyboardKeydownCount = document.getElementById("keyboard-keydown-count");
            const pressForm = document.getElementById("press-form");
            const pressInput = document.getElementById("press-input");
            const pressResult = document.getElementById("press-result");
            const tabInput = document.getElementById("tab-input");
            const tabNext = document.getElementById("tab-next");
            const tabResult = document.getElementById("tab-result");
            const blurResult = document.getElementById("blur-result");
            const dialogButton = document.getElementById("confirm-dialog");
            const dialogResult = document.getElementById("dialog-result");
            const promptButton = document.getElementById("prompt-dialog");
            const promptResult = document.getElementById("prompt-result");
            const alertButton = document.getElementById("alert-dialog");
            const alertResult = document.getElementById("alert-result");
            const dragSource = document.getElementById("drag-source");
            const dropTarget = document.getElementById("drop-target");
            const dragResult = document.getElementById("drag-result");
            const hiddenActionButton = document.getElementById("hidden-action");
            const hiddenActionResult = document.getElementById("hidden-action-result");
            const offscreenActionButton = document.getElementById("offscreen-action");
            const offscreenActionResult = document.getElementById("offscreen-action-result");
            const labelCheckbox = document.getElementById("label-checkbox");
            const labelClickResult = document.getElementById("label-click-result");
            let keyboardKeydownTotal = 0;

            keyboardInput.addEventListener("input", () => {
              keyboardValue.textContent = "Keyboard value: " + keyboardInput.value;
            });

            keyboardInput.addEventListener("keydown", () => {
              keyboardKeydownTotal += 1;
              keyboardKeydownCount.textContent = "Keyboard keydown count: " + keyboardKeydownTotal;
            });

            pressForm.addEventListener("submit", (event) => {
              event.preventDefault();
              pressResult.textContent = "Press result: submitted";
            });

            pressInput.addEventListener("input", () => {
              pressResult.textContent = "Press result: value=" + pressInput.value;
            });

            tabInput.addEventListener("blur", () => {
              blurResult.textContent = "Blur result: blurred";
            });

            tabNext.addEventListener("focus", () => {
              tabResult.textContent = "Tab result: focused next";
            });

            dialogButton.addEventListener("click", () => {
              const accepted = window.confirm("Delete item?");
              dialogResult.textContent = accepted
                ? "Dialog result: confirmed"
                : "Dialog result: cancelled";
            });

            promptButton.addEventListener("click", () => {
              const value = window.prompt("Type value");
              promptResult.textContent = value === null
                ? "Prompt result: cancelled"
                : "Prompt result: " + value;
            });

            alertButton.addEventListener("click", () => {
              window.alert("Heads up!");
              alertResult.textContent = "Alert result: acknowledged";
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

            hiddenActionButton.addEventListener("click", () => {
              hiddenActionResult.textContent = "Hidden action result: clicked";
            });

            offscreenActionButton.addEventListener("click", () => {
              offscreenActionResult.textContent = "Offscreen action result: clicked";
            });

            labelCheckbox.addEventListener("change", () => {
              labelClickResult.textContent = labelCheckbox.checked
                ? "Label click result: checked"
                : "Label click result: unchecked";
            });
          })();
        </script>
      </body>
    </html>
    """)
  end

  def browser_download_report(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-disposition", ~s(attachment; filename="report.txt"))
    |> send_resp(200, "cerberus,download")
  end

  def mixed_live_roots(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Mixed Live Roots</title>
      </head>
      <body>
        <main>
          <div data-phx-session="stale-root" id="stale-root" class="phx-disconnected">
            stale root
          </div>
          <div data-phx-session="active-root" id="active-root" class="phx-connected">
            active root
          </div>
          <h1>Mixed Live Roots</h1>
        </main>
      </body>
    </html>
    """)
  end

  def mixed_live_roots_source(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Mixed Live Roots Source</title>
      </head>
      <body>
        <main>
          <a href="/browser/readiness/mixed-live-roots">Open mixed roots</a>
        </main>
      </body>
    </html>
    """)
  end

  def disconnected_live_root(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Disconnected Live Root</title>
      </head>
      <body>
        <main>
          <div data-phx-session="disconnected-root" id="disconnected-root" class="phx-disconnected">
            disconnected root
          </div>
          <h1>Disconnected Live Root</h1>
        </main>
      </body>
    </html>
    """)
  end

  def busy_live_root(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Busy Live Root</title>
        <script>
          (() => {
            let ticks = 0;

            const start = () => {
              const target = document.getElementById("busy-live-root-ticks");
              if (!target) return;

              setInterval(() => {
                ticks += 1;
                target.textContent = String(ticks);
              }, 5);
            };

            if (document.readyState === "loading") {
              document.addEventListener("DOMContentLoaded", start, { once: true });
            } else {
              start();
            }
          })();
        </script>
      </head>
      <body>
        <main>
          <div data-phx-session="busy-root" id="busy-root" class="phx-connected">
            connected root
          </div>
          <h1>Busy Live Root</h1>
          <p id="busy-live-root-ticks">0</p>
        </main>
      </body>
    </html>
    """)
  end

  def long_action_budget(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Long Action Budget</title>
        <script>
          (() => {
            // Keep each phase comfortably under the 1.5s action timeout while the
            // combined resolve + settle path still exceeds it. That preserves the
            // phased-budget assertion without spending more wall-clock time than needed.
            const connectDelayMs = 120;
            const enableDelayMs = 420;
            const settleDelayMs = 220;

            const onReady = () => {
              const root = document.getElementById("long-action-root");
              const select = document.getElementById("long-action-select");
              const status = document.getElementById("long-action-status");
              if (!root || !select || !status) return;

              window.setTimeout(() => {
                root.classList.remove("phx-disconnected");
                root.classList.add("phx-connected");
                status.textContent = "connected";
              }, connectDelayMs);

              window.setTimeout(() => {
                select.disabled = false;
                status.textContent = "enabled";
              }, enableDelayMs);

              select.addEventListener("change", () => {
                const startedAt = Date.now();
                status.textContent = "settling";

                const interval = window.setInterval(() => {
                  status.textContent = `settling-${Date.now() - startedAt}`;

                  if (Date.now() - startedAt >= settleDelayMs) {
                    window.clearInterval(interval);
                    status.textContent = "selected";
                  }
                }, 25);
              });
            };

            if (document.readyState === "loading") {
              document.addEventListener("DOMContentLoaded", onReady, { once: true });
            } else {
              onReady();
            }
          })();
        </script>
      </head>
      <body>
        <main>
          <div data-phx-session="long-action-root" id="long-action-root" class="phx-disconnected">
            <label for="long-action-select">Slow role</label>
            <select id="long-action-select" name="role" disabled>
              <option value="">Choose</option>
              <option value="analyst">Analyst</option>
            </select>
            <p id="long-action-status">booting</p>
          </div>
        </main>
      </body>
    </html>
    """)
  end

  def popup_auto(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Popup Auto</title>
        <script>
          (() => {
            window.open("/browser/popup/destination?source=auto-load", "fixture-popup");
          })();
        </script>
      </head>
      <body>
        <main>
          <h1>Popup Auto Source</h1>
          <p id="popup-source-note">Opened popup from source page.</p>
        </main>
      </body>
    </html>
    """)
  end

  def browser_link_semantics(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Browser Link Semantics</title>
      </head>
      <body>
        <main>
          <h1>Browser Link Semantics</h1>
          <p id="link-event-result">Link result: idle</p>
          <a id="prevented-link" href="/main?from=prevented">Prevented link</a>
          <a id="intercepted-link" href="/main?from=href-default">Intercepted link</a>
        </main>

        <script>
          (() => {
            const result = document.getElementById("link-event-result");
            const prevented = document.getElementById("prevented-link");
            const intercepted = document.getElementById("intercepted-link");

            prevented.addEventListener("click", (event) => {
              event.preventDefault();
              result.textContent = "Link result: prevented";
            });

            intercepted.addEventListener("click", (event) => {
              event.preventDefault();
              result.textContent = "Link result: intercepted";
              window.location.assign("/main?from=intercepted");
            });
          })();
        </script>
      </body>
    </html>
    """)
  end

  def popup_click(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Popup Click</title>
      </head>
      <body>
        <main>
          <h1>Popup Click Source</h1>
          <button id="open-popup" type="button">Open Popup</button>
          <p id="popup-click-status">Waiting for click</p>
        </main>

        <script>
          (() => {
            const trigger = document.getElementById("open-popup");
            const status = document.getElementById("popup-click-status");

            trigger.addEventListener("click", () => {
              window.open("/browser/popup/destination?source=click-trigger", "fixture-popup-click");
              status.textContent = "Popup opened";
            });
          })();
        </script>
      </body>
    </html>
    """)
  end

  def popup_destination(conn, params) do
    params = merged_request_params(conn, params)
    source = Map.get(params, "source", "unknown")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Popup Destination</title>
      </head>
      <body>
        <main>
          <h1>Popup Destination</h1>
          <p id="popup-source">popup source: #{source}</p>
        </main>
      </body>
    </html>
    """)
  end

  def iframe_cross_origin(conn, _params) do
    cross_origin_url = cross_origin_fixture_url(conn, "/browser/iframe/target")

    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Cross-Origin Iframe Source</title>
      </head>
      <body>
        <main>
          <h1>Cross-Origin Iframe Source</h1>
          <iframe
            id="cross-origin-frame"
            src="#{cross_origin_url}"
            title="Cross Origin Fixture Frame"
            width="640"
            height="240"
          ></iframe>
        </main>
      </body>
    </html>
    """)
  end

  def iframe_same_origin(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Same-Origin Iframe Source</title>
      </head>
      <body>
        <main>
          <h1>Same-Origin Iframe Source</h1>
          <p id="iframe-source-marker">Outside iframe marker</p>
          <iframe
            id="same-origin-frame"
            src="/browser/iframe/same-origin-target"
            title="Same Origin Fixture Frame"
            width="640"
            height="240"
          ></iframe>
        </main>
      </body>
    </html>
    """)
  end

  def iframe_target(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Iframe Target</title>
      </head>
      <body>
        <main>
          <p id="iframe-target-marker">Cross-origin iframe body marker</p>
        </main>
      </body>
    </html>
    """)
  end

  def iframe_same_origin_target(conn, _params) do
    html(conn, """
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <title>Fixture Same-Origin Iframe Target</title>
      </head>
      <body>
        <main>
          <p id="iframe-same-origin-marker">Same-origin iframe body marker</p>
          <button id="iframe-increment" type="button">Frame Increment</button>
          <p id="iframe-count">Frame Count: 0</p>
        </main>

        <script>
          (() => {
            const button = document.getElementById("iframe-increment");
            const count = document.getElementById("iframe-count");
            let value = 0;

            button.addEventListener("click", () => {
              value += 1;
              count.textContent = `Frame Count: ${value}`;
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
            <input id="item_one" type="checkbox" name="items[]" value="one" checked data-testid="item-one-checkbox" />

            <label for="item_two">Two</label>
            <input id="item_two" type="checkbox" name="items[]" value="two" data-testid="item-two-checkbox" />

            <label for="item_three">Three</label>
            <input id="item_three" type="checkbox" name="items[]" value="three" data-testid="item-three-checkbox" />

            <button type="submit" data-testid="save-items-submit">Save Items</button>
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

  defp upload_filename(%Plug.Upload{filename: filename}) when is_binary(filename), do: filename
  defp upload_filename([%Plug.Upload{} = upload | _]), do: upload_filename(upload)
  defp upload_filename(_), do: ""

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

  defp cross_origin_fixture_url(conn, path) when is_binary(path) do
    alt_host = alternate_host(conn.host)
    "#{conn.scheme}://#{alt_host}:#{conn.port}#{path}"
  end

  defp alternate_host("localhost"), do: "127.0.0.1"
  defp alternate_host("127.0.0.1"), do: "localhost"
  defp alternate_host(_host), do: "localhost"
end
