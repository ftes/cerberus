defmodule Cerberus.Fixtures.FormChangeLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       target: [],
       name: "",
       email: "",
       nickname: "",
       hidden_name: "",
       hidden_email: "",
       hidden_race: ""
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    target = normalize_target(params["_target"])

    {:noreply,
     assign(socket,
       target: target,
       name: params["name"] || "",
       email: params["email"] || "",
       nickname: params["nickname"] || "",
       hidden_race: params["hidden_race"] || ""
     )}
  end

  def handle_event("validate_hidden", params, socket) do
    target = normalize_target(params["_target"])

    {:noreply,
     assign(socket,
       target: target,
       hidden_name: params["name"] || "",
       hidden_email: params["email"] || "",
       hidden_race: params["hidden_race"] || ""
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Form Change</h1>

      <form id="change-form" phx-change="validate">
        <label for="change_name">Name</label>
        <input
          id="change_name"
          name="name"
          type="text"
          value={@name}
          placeholder="Live name"
          title="Live name input"
          data-testid="live-change-name"
        />

        <label for="change_email">Email</label>
        <input id="change_email" name="email" type="text" value={@email} />

        <label>
          Nickname <span class="required">*</span>
          <input name="nickname" type="text" value={@nickname} />
        </label>
      </form>

      <form id="no-phx-change-form">
        <label for="no_change_name">Name (no phx-change)</label>
        <input id="no_change_name" name="name" type="text" value="" />
      </form>
      <p id="no-change-result">No change value: unchanged</p>

      <form id="changes-hidden-input-form" phx-change="validate_hidden">
        <input type="hidden" name="hidden_race" value="hobbit" />

        <label for="hidden_name">Name for hidden</label>
        <input id="hidden_name" name="name" type="text" value={@hidden_name} />

        <label for="hidden_email">Email for hidden</label>
        <input id="hidden_email" name="email" type="text" value={@hidden_email} />
      </form>

      <div id="form-data">
        <p>_target: [<%= Enum.join(@target, ",") %>]</p>
        <p>name: <%= @hidden_name != "" && @hidden_name || @name %></p>
        <p>email: <%= @hidden_email != "" && @hidden_email || @email %></p>
        <p>nickname: <%= @nickname %></p>
        <p>hidden_race: <%= @hidden_race %></p>
      </div>
    </main>
    """
  end

  defp normalize_target(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp normalize_target(value) when is_binary(value), do: [value]
  defp normalize_target(_), do: []
end
