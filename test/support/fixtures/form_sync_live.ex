defmodule Cerberus.Fixtures.FormSyncLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       version: "a",
       conditional_submitted: %{},
       no_change_value: "",
       mailing_list_emails: [%{"email" => ""}]
     )}
  end

  @impl true
  def handle_event("switch-version", %{"version" => version}, socket) when version in ["a", "b"] do
    {:noreply, assign(socket, version: version)}
  end

  def handle_event("switch-version", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("save_conditional", %{"profile" => profile}, socket) when is_map(profile) do
    {:noreply, assign(socket, conditional_submitted: profile)}
  end

  def handle_event("save_conditional", _params, socket) do
    {:noreply, assign(socket, conditional_submitted: %{})}
  end

  @impl true
  def handle_event("save_no_change", %{"profile" => %{"nickname" => nickname}}, socket) do
    {:noreply, assign(socket, no_change_value: nickname)}
  end

  def handle_event("save_no_change", _params, socket) do
    {:noreply, assign(socket, no_change_value: "")}
  end

  @impl true
  def handle_event("validate_mailing_list", %{"mailing_list" => mailing_list}, socket) when is_map(mailing_list) do
    indexed_emails = normalize_indexed_emails(Map.get(mailing_list, "emails", %{}))
    sort_values = mailing_list |> Map.get("emails_sort", []) |> List.wrap()
    drop_values = mailing_list |> Map.get("emails_drop", []) |> List.wrap() |> MapSet.new()

    emails =
      indexed_emails
      |> apply_sort_and_drop(sort_values, drop_values)
      |> ensure_non_empty_emails()

    {:noreply, assign(socket, mailing_list_emails: emails)}
  end

  def handle_event("validate_mailing_list", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Form Synchronization</h1>

      <section id="conditional-form-section">
        <h2>Conditional Fields</h2>

        <div id="version-switch">
          <button type="button" phx-click="switch-version" phx-value-version="a">Version A</button>
          <button type="button" phx-click="switch-version" phx-value-version="b">Version B</button>
        </div>

        <form id="conditional-form" phx-submit="save_conditional">
          <input type="hidden" name="profile[version]" value={@version} />

          <%= if @version == "a" do %>
            <label for="profile_version_a_text">Version A Text</label>
            <input
              id="profile_version_a_text"
              type="text"
              name="profile[version_a_text]"
              value=""
            />
          <% else %>
            <label for="profile_version_b_text">Version B Text</label>
            <input
              id="profile_version_b_text"
              type="text"
              name="profile[version_b_text]"
              value=""
            />
          <% end %>

          <button type="submit">Save Conditional</button>
        </form>

        <div id="conditional-result">
          <p>active version: <%= @version %></p>
          <p>has version_a_text?: <%= Map.has_key?(@conditional_submitted, "version_a_text") %></p>
          <p>has version_b_text?: <%= Map.has_key?(@conditional_submitted, "version_b_text") %></p>
          <p>submitted version_b_text: <%= Map.get(@conditional_submitted, "version_b_text", "") %></p>
        </div>
      </section>

      <section id="submit-only-form-section">
        <h2>Submit-Only Form</h2>

        <form id="no-change-submit-form" phx-submit="save_no_change">
          <label for="submit_only_nickname">Nickname (submit only)</label>
          <input id="submit_only_nickname" type="text" name="profile[nickname]" value="" />
          <button type="submit">Save No Change</button>
        </form>

        <p id="submit-only-result">no-change submitted: <%= @no_change_value %></p>
      </section>

      <section id="dynamic-inputs-section">
        <h2>Dynamic Inputs</h2>

        <form id="dynamic-inputs-form" phx-change="validate_mailing_list">
          <%= for {entry, index} <- Enum.with_index(@mailing_list_emails) do %>
            <input type="hidden" name="mailing_list[emails_sort][]" value={index} />

            <label for={"mailing_list_emails_#{index}_email"}>Mailing list email <%= index + 1 %></label>
            <input
              id={"mailing_list_emails_#{index}_email"}
              type="text"
              name={"mailing_list[emails][#{index}][email]"}
              value={Map.get(entry, "email", "")}
            />

            <button
              type="button"
              name="mailing_list[emails_drop][]"
              value={index}
              phx-click={JS.dispatch("change")}
            >
              delete
            </button>
          <% end %>

          <button
            type="button"
            name="mailing_list[emails_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            add more
          </button>
        </form>

        <p id="mailing-list-count">Email count: <%= length(@mailing_list_emails) %></p>
      </section>
    </main>
    """
  end

  defp normalize_indexed_emails(values) when is_map(values) do
    Enum.map(values, fn {index, params} ->
      email =
        case params do
          %{"email" => value} when is_binary(value) -> value
          _ -> ""
        end

      {to_string(index), %{"email" => email}}
    end)
  end

  defp normalize_indexed_emails(_values), do: []

  defp apply_sort_and_drop(indexed_emails, sort_values, drop_values) do
    email_map = Map.new(indexed_emails)

    sorted =
      sort_values
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.reduce([], fn
        "new", acc ->
          acc ++ [%{"email" => ""}]

        index, acc ->
          index = to_string(index)

          cond do
            MapSet.member?(drop_values, index) ->
              acc

            not Map.has_key?(email_map, index) ->
              acc

            true ->
              acc ++ [Map.fetch!(email_map, index)]
          end
      end)

    if sorted == [] do
      indexed_emails
      |> Enum.reject(fn {index, _entry} -> MapSet.member?(drop_values, to_string(index)) end)
      |> Enum.sort_by(fn {index, _entry} -> parse_index(index) end)
      |> Enum.map(fn {_index, entry} -> entry end)
    else
      sorted
    end
  end

  defp ensure_non_empty_emails([]), do: [%{"email" => ""}]
  defp ensure_non_empty_emails(values), do: values

  defp parse_index(index) when is_integer(index), do: index

  defp parse_index(index) do
    case Integer.parse(to_string(index)) do
      {value, _rest} -> value
      :error -> 0
    end
  end
end
