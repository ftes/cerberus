defmodule Cerberus.Fixtures.SelectControlsLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form_data: %{}, target: [])}
  end

  @impl true
  def handle_event("change", params, socket) do
    target = normalize_target(params["_target"])
    {:noreply, assign(socket, form_data: params, target: target)}
  end

  @impl true
  def handle_event("save", params, socket) do
    target = normalize_target(params["_target"])
    {:noreply, assign(socket, form_data: params, target: target)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Controls</h1>

      <form id="live-controls-form" phx-change="change" phx-submit="save">
        <label for="live_controls_race">Race</label>
        <select id="live_controls_race" name="race">
          <option value="human">Human</option>
          <option value="elf">Elf</option>
          <option value="dwarf">Dwarf</option>
          <option value="disabled_race" disabled>Disabled Race</option>
        </select>

        <label for="live_controls_race_2">Race 2</label>
        <select id="live_controls_race_2" name="race_2[]" multiple>
          <option value="elf">Elf</option>
          <option value="dwarf">Dwarf</option>
          <option value="orc">Orc</option>
        </select>

        <fieldset>
          <legend>Contact</legend>
          <input type="radio" id="live_controls_contact_email" name="contact" value="email" />
          <label for="live_controls_contact_email">Email Choice</label>

          <input type="radio" id="live_controls_contact_phone" name="contact" value="phone" />
          <label for="live_controls_contact_phone">Phone Choice</label>

          <input type="radio" id="live_controls_contact_mail" name="contact" value="mail" checked />
          <label for="live_controls_contact_mail">Mail Choice</label>
        </fieldset>

        <label for="live_controls_disabled_select">Disabled select</label>
        <select id="live_controls_disabled_select" name="disabled_select" disabled>
          <option value="cannot_submit">Cannot submit</option>
        </select>

        <button type="submit">Save Live Controls</button>
      </form>

      <div id="form-data">
        <p>_target: [<%= Enum.join(@target, ",") %>]</p>
        <p>race: <%= Map.get(@form_data, "race", "") %></p>
        <p>race_2: [<%= @form_data |> Map.get("race_2", []) |> List.wrap() |> Enum.join(",") %>]</p>
        <p>contact: <%= Map.get(@form_data, "contact", "") %></p>
        <p>disabled_select: <%= Map.get(@form_data, "disabled_select", "") %></p>
      </div>
    </main>
    """
  end

  defp normalize_target(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp normalize_target(value) when is_binary(value), do: [value]
  defp normalize_target(_), do: []
end
