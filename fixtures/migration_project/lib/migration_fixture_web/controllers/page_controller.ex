defmodule MigrationFixtureWeb.PageController do
  use MigrationFixtureWeb, :controller

  def home(conn, _params) do
    html(
      conn,
      """
      <h1>Migration fixture</h1>
      <a href=\"/counter\">Counter</a>
      """
    )
  end
end
