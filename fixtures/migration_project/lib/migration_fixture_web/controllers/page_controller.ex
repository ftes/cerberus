defmodule MigrationFixtureWeb.PageController do
  use MigrationFixtureWeb, :controller

  def home(conn, _params) do
    html(
      conn,
      """
      <h1>Migration fixture</h1>
      <a href=\"/counter\">Counter</a>
      <a href=\"/search\">Search</a>
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
end
