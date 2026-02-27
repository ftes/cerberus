defmodule Cerberus.Fixtures.TriggerActionLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       trigger_submit: false,
       trigger_multiple_submit: false,
       trigger_after_patch: false,
       show_dynamic_form: false,
       dynamic_trigger_submit: false
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("trigger-form", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("trigger-from-elsewhere", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("trigger-multiple-forms", _params, socket) do
    {:noreply, assign(socket, :trigger_multiple_submit, true)}
  end

  def handle_event("patch-and-trigger-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:trigger_after_patch, true)
     |> push_patch(to: "/live/trigger-action?patched=true")}
  end

  def handle_event("redirect-and-trigger-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:trigger_after_patch, true)
     |> redirect(to: "/live/counter")}
  end

  def handle_event("navigate-and-trigger-form", _params, socket) do
    {:noreply,
     socket
     |> assign(:trigger_after_patch, true)
     |> push_navigate(to: "/live/counter")}
  end

  def handle_event("show-dynamic-form", _params, socket) do
    {:noreply, assign(socket, :show_dynamic_form, true)}
  end

  def handle_event("submit-dynamic-form", _params, socket) do
    {:noreply, assign(socket, :dynamic_trigger_submit, true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <h1>Trigger Action Fixture</h1>

      <form
        id="trigger-form"
        phx-submit="trigger-form"
        phx-trigger-action={@trigger_submit}
        action="/trigger-action/result"
        method="post"
      >
        <input type="hidden" name="trigger_action_hidden_input" value="trigger_action_hidden_value" />
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

        <label for="trigger_action_input">Trigger action</label>
        <input id="trigger_action_input" type="text" name="trigger_action_input" />

        <button type="submit">Submit Trigger Form</button>
      </form>

      <button phx-click="trigger-from-elsewhere">Trigger from elsewhere</button>

      <form
        id="trigger-multiple-form-1"
        phx-submit="trigger-form"
        phx-trigger-action={@trigger_multiple_submit}
        action="/trigger-action/result"
        method="post"
      >
        <input type="hidden" name="multi_hidden" value="trigger_action_hidden_value" />
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
      </form>

      <form
        id="trigger-multiple-form-2"
        phx-submit="trigger-form"
        phx-trigger-action={@trigger_multiple_submit}
        action="/trigger-action/result"
        method="post"
      >
        <input type="hidden" name="multi_hidden" value="trigger_action_hidden_value" />
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
      </form>

      <button phx-click="trigger-multiple-forms">Trigger multiple</button>

      <form
        id="patch-trigger-form"
        phx-change="patch-and-trigger-form"
        phx-trigger-action={@trigger_after_patch}
        action="/trigger-action/result"
        method="post"
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

        <label for="patch_and_trigger_action">Patch and trigger action</label>
        <input id="patch_and_trigger_action" type="text" name="patch_and_trigger_action" />
      </form>

      <button phx-click="redirect-and-trigger-form">Redirect and trigger action</button>
      <button phx-click="navigate-and-trigger-form">Navigate and trigger action</button>

      <button phx-click="show-dynamic-form">Show Dynamic Form</button>

      <form
        :if={@show_dynamic_form}
        id="dynamic-trigger-form"
        phx-submit="submit-dynamic-form"
        phx-trigger-action={@dynamic_trigger_submit}
        action="/trigger-action/result"
        method="post"
      >
        <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

        <label for="dynamic_message">Message</label>
        <input id="dynamic_message" type="text" name="message" />
        <button type="submit">Submit Dynamic Form</button>
      </form>
    </main>
    """
  end
end
