defmodule Cerberus.Fixtures.UploadLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:saved_file, nil)
     |> assign(:upload_change_triggered, false)
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg))
     |> allow_upload(:avatar_3, accept: ~w(.jpg .jpeg))
     |> allow_upload(:tiny, accept: ~w(.jpg .jpeg), max_file_size: 8)
     |> allow_upload(:redirect_avatar, accept: ~w(.jpg .jpeg), auto_upload: true, progress: &handle_progress/3)}
  end

  @impl true
  def handle_event("save-avatar", _params, socket) do
    [saved_file | _rest] =
      consume_uploaded_entries(socket, :avatar, fn _, %{client_name: name} ->
        {:ok, name}
      end) ++ [nil]

    {:noreply, assign(socket, :saved_file, saved_file)}
  end

  @impl true
  def handle_event("upload-change", _params, socket) do
    {:noreply, assign(socket, :upload_change_triggered, true)}
  end

  defp handle_progress(:redirect_avatar, entry, socket) do
    if entry.done? do
      {:noreply, push_navigate(socket, to: "/live/async_page_2")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Live Uploads</h1>

      <form id="full-form" phx-change="upload-change" phx-submit="save-avatar">
        <label for={@uploads.avatar.ref}>Avatar</label>
        <.live_file_input upload={@uploads.avatar} />
        <button type="submit">Save Avatar</button>
      </form>

      <div :if={@saved_file} id="upload-save-result">
        avatar: {@saved_file}
      </div>

      <form id="tiny-upload-form">
        <label for={@uploads.tiny.ref}>Tiny</label>
        <.live_file_input upload={@uploads.tiny} />
      </form>

      <form id="upload-change-form" phx-change="upload-change">
        <label for={@uploads.avatar_3.ref}>Avatar</label>
        <.live_file_input upload={@uploads.avatar_3} />
      </form>

      <div :if={@upload_change_triggered} id="upload-change-result">
        phx-change triggered on file selection
      </div>

      <form id="upload-redirect-form" phx-change="upload-change">
        <label for={@uploads.redirect_avatar.ref}>Redirect Avatar</label>
        <.live_file_input upload={@uploads.redirect_avatar} />
      </form>
    </main>
    """
  end
end
