defmodule Cerberus.Fixtures.DelayedActionabilityLive do
  @moduledoc false

  use Phoenix.LiveView

  @enable_delay_ms 90

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       category: "basic",
       role: "",
       notify: false,
       role_enabled: false,
       notify_enabled: false,
       role_options: []
     )}
  end

  @impl true
  def handle_event("change", %{"category" => category} = params, socket) do
    Process.send_after(self(), {:enable_dependents, category}, @enable_delay_ms)

    {:noreply,
     socket
     |> assign(:category, category)
     |> assign(:role, Map.get(params, "role", ""))
     |> assign(:notify, truthy?(Map.get(params, "notify")))
     |> assign(:role_enabled, false)
     |> assign(:notify_enabled, false)
     |> assign(:role_options, [])}
  end

  def handle_event("change", params, socket) do
    {:noreply,
     socket
     |> assign(:category, Map.get(params, "category", socket.assigns.category))
     |> assign(:role, Map.get(params, "role", ""))
     |> assign(:notify, truthy?(Map.get(params, "notify")))}
  end

  @impl true
  def handle_info({:enable_dependents, "advanced"}, socket) do
    {:noreply,
     socket
     |> assign(:role_enabled, true)
     |> assign(:notify_enabled, true)
     |> assign(:role_options, [{"Analyst", "analyst"}, {"Pilot", "pilot"}])}
  end

  def handle_info({:enable_dependents, _category}, socket) do
    {:noreply,
     socket
     |> assign(:role_enabled, false)
     |> assign(:notify_enabled, false)
     |> assign(:role_options, [])
     |> assign(:role, "")
     |> assign(:notify, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Delayed Actionability</h1>

      <form id="delayed-actionability-form" phx-change="change">
        <label for="delayed_actionability_category">Category</label>
        <select id="delayed_actionability_category" name="category">
          <option value="basic" selected={@category == "basic"}>Basic</option>
          <option value="advanced" selected={@category == "advanced"}>Advanced</option>
        </select>

        <label for="delayed_actionability_role">Role</label>
        <select id="delayed_actionability_role" name="role" disabled={!@role_enabled}>
          <option value="">Choose role</option>
          <%= for {label, value} <- @role_options do %>
            <option value={value} selected={@role == value}>{label}</option>
          <% end %>
        </select>

        <label for="delayed_actionability_notify">Notify team</label>
        <input
          id="delayed_actionability_notify"
          type="checkbox"
          name="notify"
          value="true"
          checked={@notify}
          disabled={!@notify_enabled}
        />
      </form>

      <div id="delayed-actionability-state">
        <p>category: <%= @category %></p>
        <p>role: <%= @role %></p>
        <p>notify: <%= @notify %></p>
        <p>role_enabled: <%= @role_enabled %></p>
        <p>notify_enabled: <%= @notify_enabled %></p>
      </div>
    </main>
    """
  end

  defp truthy?(value), do: value in [true, "true", "on", "1", 1]
end
