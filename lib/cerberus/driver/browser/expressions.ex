defmodule Cerberus.Driver.Browser.Expressions do
  @moduledoc false

  alias Cerberus.Driver.Browser.AssertionHelpers

  @spec browser_html() :: String.t()
  def browser_html do
    """
    (() => {
      const doc = document.documentElement;
      const html = doc ? doc.outerHTML : "";
      const doctype = document.doctype ? `<!DOCTYPE ${document.doctype.name}>` : "<!DOCTYPE html>";
      return JSON.stringify({ html: doctype + html, url: window.location.href });
    })()
    """
  end

  @spec current_path() :: String.t()
  def current_path do
    """
    (() => JSON.stringify({ path: window.location.pathname + window.location.search }))()
    """
  end

  @spec assertion_helpers_preload() :: String.t()
  def assertion_helpers_preload do
    """
    (() => {
      #{AssertionHelpers.preload_script()}

      const helper = window.__cerberusAssert;

      return JSON.stringify({
        ok: !!(helper && typeof helper.text === "function" && typeof helper.pathCheck === "function")
      });
    })()
    """
  end

  @spec text_assertion(map()) :: String.t()
  def text_assertion(payload) when is_map(payload) do
    encoded_payload = JSON.encode!(payload)
    mode_value = Map.get(payload, :mode, "assert")

    """
    (() => {
      const helper = window.__cerberusAssert;
      if (helper && typeof helper.text === "function") {
        return helper.text(#{encoded_payload});
      }

      const mode = #{JSON.encode!(mode_value)};
      const reason = mode === "assert" ? "expected text not found" : "unexpected matching text found";

      return JSON.stringify({
        ok: false,
        reason,
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        texts: [],
        matched: [],
        helperMissing: true
      });
    })()
    """
  end

  @spec path_assertion(String.t() | map(), map(), boolean(), :assert_path | :refute_path) :: String.t()
  def path_assertion(expected, expected_query, exact, op) when op in [:assert_path, :refute_path] do
    payload = %{
      expected: expected,
      expectedQuery: expected_query,
      exact: exact,
      op: Atom.to_string(op)
    }

    encoded_payload = JSON.encode!(payload)

    """
    (() => {
      const helper = window.__cerberusAssert;
      if (helper && typeof helper.pathCheck === "function") {
        return helper.pathCheck(#{encoded_payload});
      }

      const path = window.location.pathname + window.location.search;

      return JSON.stringify({
        ok: false,
        reason: "helper-missing",
        path,
        "path_match?": false,
        "query_match?": false,
        helperMissing: true
      });
    })()
    """
  end
end
