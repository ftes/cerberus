defmodule MigrationFixtureWeb.PageController do
  use MigrationFixtureWeb, :controller

  def home(conn, _params) do
    html(
      conn,
      """
      <h1>Migration fixture</h1>
      <a href=\"/counter\">Counter</a>
      <a href=\"/search\">Search</a>
      <a href=\"/select\">Select</a>
      <a href=\"/choose\">Choose</a>
      <a href=\"/upload\">Upload</a>
      <a href=\"/checkbox\">Checkbox</a>
      <a href=\"/live-nav\">Live Nav</a>
      <a href=\"/live-change\">Live Change</a>
      <a href=\"/live-async\">Live Async</a>
      <a href=\"/session-counter\">Session Tally</a>
      """
    )
  end

  def search(conn, _params) do
    html(
      conn,
      """
      <h1>Search</h1>
      <form action=\"/search/results\" method=\"get\">
        <label for=\"search_q\">Search term</label>
        <input id=\"search_q\" name=\"q\" type=\"text\" value=\"\" />
        <button type=\"submit\">Run Search</button>
      </form>
      """
    )
  end

  def search_results(conn, params) do
    query = params["q"] || ""

    html(
      conn,
      """
      <h1>Search Results</h1>
      <p>Search query: #{query}</p>
      """
    )
  end

  def select_page(conn, _params) do
    html(
      conn,
      """
      <h1>Select Role</h1>
      <form action=\"/select/result\" method=\"get\">
        <label for=\"role_select\">Role</label>
        <select id=\"role_select\" name=\"role\">
          <option value=\"ranger\">Ranger</option>
          <option value=\"wizard\">Wizard</option>
          <option value=\"elf\">Elf</option>
        </select>
        <button type=\"submit\">Apply Selection</button>
      </form>
      """
    )
  end

  def select_result(conn, params) do
    role = params["role"] || ""

    html(
      conn,
      """
      <h1>Select Result</h1>
      <p>Selected role: #{role}</p>
      """
    )
  end

  def choose_page(conn, _params) do
    html(
      conn,
      """
      <h1>Choose Contact</h1>
      <form action=\"/choose/result\" method=\"get\">
        <input id=\"contact_email\" type=\"radio\" name=\"contact\" value=\"email\" />
        <label for=\"contact_email\">Email</label>

        <input id=\"contact_phone\" type=\"radio\" name=\"contact\" value=\"phone\" />
        <label for=\"contact_phone\">Phone</label>

        <button type=\"submit\">Apply Choice</button>
      </form>
      """
    )
  end

  def choose_result(conn, params) do
    contact = params["contact"] || ""

    html(
      conn,
      """
      <h1>Choose Result</h1>
      <p>Contact via: #{contact}</p>
      """
    )
  end

  def upload_page(conn, _params) do
    html(
      conn,
      """
      <h1>Upload</h1>
      <form id=\"upload-form\" action=\"/upload/result\" method=\"post\" enctype=\"multipart/form-data\">
        <label for=\"upload_avatar\">Avatar</label>
        <input id=\"upload_avatar\" name=\"avatar\" type=\"file\" />
        <button type=\"submit\">Upload Avatar</button>
      </form>
      """
    )
  end

  def upload_result(conn, params) do
    file_name = params |> Map.get("avatar") |> upload_filename()

    html(
      conn,
      """
      <h1>Upload Result</h1>
      <p>Uploaded file: #{file_name}</p>
      """
    )
  end

  def checkbox(conn, _params) do
    html(
      conn,
      """
      <h1>Checkbox Array</h1>
      <form action=\"/checkbox/save\" method=\"get\">
        <label for=\"item_one\">One</label>
        <input name=\"items[]\" type=\"hidden\" value=\"\" />
        <input id=\"item_one\" name=\"items[]\" type=\"checkbox\" value=\"one\" checked />

        <label for=\"item_two\">Two</label>
        <input id=\"item_two\" name=\"items[]\" type=\"checkbox\" value=\"two\" />

        <button type=\"submit\">Save Items</button>
      </form>
      """
    )
  end

  def checkbox_save(conn, params) do
    items =
      case Map.get(params, "items", []) do
        values when is_list(values) -> values
        value when is_binary(value) -> [value]
        _ -> []
      end
      |> Enum.reject(&(&1 in ["", "false"]))

    selected =
      case items do
        [] -> "None"
        values -> Enum.join(values, ",")
      end

    html(
      conn,
      """
      <h1>Checkbox Result</h1>
      <p>Selected Items: #{selected}</p>
      """
    )
  end

  def session_counter(conn, _params) do
    count = get_session(conn, :session_counter) || 0

    html(
      conn,
      """
      <h1>Session Counter</h1>
      <p id=\"session-count\">Session Count: #{count}</p>
      <a href=\"/session-counter/increment\">Increment Session</a>
      """
    )
  end

  def session_counter_increment(conn, _params) do
    count = (get_session(conn, :session_counter) || 0) + 1

    conn
    |> put_session(:session_counter, count)
    |> redirect(to: "/session-counter")
  end

  defp upload_filename(%Plug.Upload{filename: filename}) when is_binary(filename), do: filename
  defp upload_filename([%Plug.Upload{} = upload | _]), do: upload_filename(upload)
  defp upload_filename(_), do: ""
end
