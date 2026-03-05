defmodule Cerberus.Fixtures.PhoenixTestPlaywright.Playwright.PageView do
  use Phoenix.Component

  def render("other.html", assigns) do
    ~H"""
    <h1>Other</h1>
    """
  end

  def render("longer_than_viewport.html", assigns) do
    ~H"""
    <h1>Longer than viewport</h1>
    <div :for={_ <- 1..100}>Lorem ipsum</div>
    """
  end

  def render("js_script_console_error.html", assigns) do
    ~H"""
    <script type="text/javascript">
      console.error("TESTME 42")
    </script>
    """
  end

  def render("data.html", assigns) do
    ~H"""
    <dl id={@id}>
      <%= for {key, value} <- @data do %>
        <dt>{key}:</dt> <dd>{value}</dd>
      <% end %>
    </dl>
    """
  end
end
