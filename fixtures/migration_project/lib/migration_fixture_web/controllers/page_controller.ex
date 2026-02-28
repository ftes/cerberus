defmodule MigrationFixtureWeb.PageController do
  use MigrationFixtureWeb, :controller

  def home(conn, _params) do
    html(
      conn,
      """
      <h1>Migration fixture</h1>
      <a href=\"/counter\">Counter</a>
      <a href=\"/search\">Search</a>
      <a href=\"/checkbox\">Checkbox</a>
      <a href=\"/session-counter\">Session Counter</a>
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
end
