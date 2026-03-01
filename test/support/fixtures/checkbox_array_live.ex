defmodule Cerberus.Fixtures.CheckboxArrayLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, selected_items: ["one"])}
  end

  @impl true
  def handle_event("validate", params, socket) do
    selected =
      params
      |> Map.get("items", [])
      |> List.wrap()
      |> Enum.reject(&(&1 == ""))

    {:noreply, assign(socket, selected_items: selected)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Checkbox Arrays</h1>

      <form id="live-checkbox-array-form" phx-change="validate">
        <input type="hidden" name="items[]" value="" />

        <label for="live_item_one">One</label>
        <input
          id="live_item_one"
          type="checkbox"
          name="items[]"
          value="one"
          checked={"one" in @selected_items}
          data-testid="live-item-one-checkbox"
        />

        <label for="live_item_two">Two</label>
        <input
          id="live_item_two"
          type="checkbox"
          name="items[]"
          value="two"
          checked={"two" in @selected_items}
          data-testid="live-item-two-checkbox"
        />

        <label for="live_item_three">Three</label>
        <input
          id="live_item_three"
          type="checkbox"
          name="items[]"
          value="three"
          checked={"three" in @selected_items}
          data-testid="live-item-three-checkbox"
        />
      </form>

      <p id="live-selected-items">
        Selected Items: <%= if @selected_items == [], do: "None", else: Enum.join(@selected_items, ",") %>
      </p>
    </main>
    """
  end
end
