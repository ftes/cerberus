defmodule Cerberus.Fixtures.ToastLocatorLive do
  @moduledoc false
  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <ul class="toast-container" aria-live="polite" aria-atomic="true">
        <li id="toast-0" class="toast-success toast" aria-live="assertive" aria-atomic="true">
          <div class="flex justify-between" role="alert">
            <span class="flex flex-row items-center">
              <div class="ml-3">
                <p class="text-sm font-semibold text-inherit">
                  Team Engine will email an official quote within 24hrs to: billing@example.com
                </p>
              </div>
            </span>
            <button type="button" aria-label="Close" class="toast-btn">x</button>
          </div>
        </li>
      </ul>

      <template id="toast-success-template">
        <li id="toast-template-success" class="toast-success toast" aria-live="assertive" aria-atomic="true">
          <div class="flex justify-between" role="alert">
            <span class="flex flex-row items-center">
              <div class="ml-3">
                <p class="text-sm font-semibold text-inherit">
                  <span data-toast-body></span>
                </p>
              </div>
            </span>
            <button type="button" aria-label="Close" class="toast-btn">x</button>
          </div>
        </li>
      </template>
    </main>
    """
  end
end
