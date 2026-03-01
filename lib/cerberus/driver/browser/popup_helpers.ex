defmodule Cerberus.Driver.Browser.PopupHelpers do
  @moduledoc false

  @same_tab_popup_preload_script """
  ;(() => {
    if (window.__cerberusPopup && window.__cerberusPopup.__version === 1) return;

    const originalOpen = window.open;

    const sameTabOpen = (url) => {
      const destination = typeof url === "string" ? url.trim() : "";

      if (destination !== "") {
        window.location.assign(destination);
      }

      return window;
    };

    window.__cerberusPopup = {
      __version: 1,
      originalOpen
    };

    try {
      window.open = sameTabOpen;
    } catch (_error) {
      Object.defineProperty(window, "open", {
        value: sameTabOpen,
        configurable: true,
        writable: true
      });
    }
  })();
  """

  @spec same_tab_popup_preload_script() :: String.t()
  def same_tab_popup_preload_script, do: @same_tab_popup_preload_script
end
