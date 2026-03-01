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

  @spec snapshot(String.t() | nil) :: String.t()
  def snapshot(scope) do
    encoded_scope = JSON.encode!(scope)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};

      const isElementHidden = (element) => {
        let current = element;
        while (current) {
          if (current.hasAttribute("hidden")) return true;
          const style = window.getComputedStyle(current);
          if (style.display === "none" || style.visibility === "hidden") return true;
          current = current.parentElement;
        }
        return false;
      };

      const pushUnique = (list, value) => {
        if (!list.includes(value)) list.push(value);
      };

      const visible = [];
      const hiddenTexts = [];
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const elements = [];
      for (const root of roots) {
        if (!root) continue;
        elements.push(root, ...Array.from(root.querySelectorAll("*")));
      }

      for (const element of elements) {
        const tag = (element.tagName || "").toLowerCase();
        if (tag === "script" || tag === "style" || tag === "noscript") continue;

        const hidden = isElementHidden(element);
        const source = hidden ? element.textContent : (element.innerText || element.textContent);
        const value = normalize(source);
        if (!value) continue;

        if (hidden) {
          pushUnique(hiddenTexts, value);
        } else {
          pushUnique(visible, value);
        }
      }

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        visible,
        hidden: hiddenTexts
      });
    })()
    """
  end

  @spec clickables(String.t() | nil, String.t() | nil) :: String.t()
  def clickables(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const links = queryWithinRoots("a[href]")
        .filter(selectorMatches)
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        title: element.getAttribute("title") || "",
        alt: (() => {
          const direct = element.getAttribute("alt");
          if (direct) return direct;
          const nested = element.querySelector("img[alt],input[type='image'][alt],[role='img'][alt]");
          return nested ? (nested.getAttribute("alt") || "") : "";
        })(),
        testid: element.getAttribute("data-testid") || "",
        href: element.getAttribute("href") || "",
        resolvedHref: element.href || ""
      }));

      const buttons = queryWithinRoots("button")
        .filter(selectorMatches)
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        title: element.getAttribute("title") || "",
        alt: (() => {
          const direct = element.getAttribute("alt");
          if (direct) return direct;
          const nested = element.querySelector("img[alt],input[type='image'][alt]");
          return nested ? (nested.getAttribute("alt") || "") : "";
        })(),
        testid: element.getAttribute("data-testid") || "",
        type: (element.getAttribute("type") || "submit").toLowerCase(),
        name: element.getAttribute("name") || "",
        value: element.getAttribute("value") || ""
      }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        links,
        buttons
      });
    })()
    """
  end

  @spec form_fields(String.t() | nil, String.t() | nil) :: String.t()
  def form_fields(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const labels = new Map();

      queryWithinRoots("label[for]").forEach((label) => {
        const id = label.getAttribute("for");
        if (id) labels.set(id, normalize(label.textContent));
      });

      const labelForControl = (element) => {
        const byId = labels.get(element.id || "");
        if (byId) return byId;

        const wrappingLabel = element.closest("label");
        if (wrappingLabel) return normalize(wrappingLabel.textContent);

        return "";
      };

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        })
        .map((element, index) => {
          const tag = (element.tagName || "").toLowerCase();
          const rawType = (element.getAttribute("type") || "").toLowerCase();
          const type = tag === "select" ? (element.multiple ? "select-multiple" : "select-one") : rawType;
          const value = tag === "select"
            ? (element.multiple
              ? Array.from(element.selectedOptions || []).map((option) => option.value || option.textContent || "")
              : (element.value || ""))
            : (element.value || "");

          return {
            index,
            id: element.id || "",
            name: element.name || "",
            label: labelForControl(element),
            placeholder: element.getAttribute("placeholder") || "",
            title: element.getAttribute("title") || "",
            testid: element.getAttribute("data-testid") || "",
            type,
            value,
            checked: element.checked === true,
            tag,
            multiple: tag === "select" && element.multiple === true,
            disabled: element.disabled === true
          };
        });

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        fields
      });
    })()
    """
  end

  @spec file_fields(String.t() | nil, String.t() | nil) :: String.t()
  def file_fields(scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const queryWithinRoots = (selector) => {
        const seen = new Set();
        const matches = [];

        for (const root of roots) {
          if (root.matches && root.matches(selector) && !seen.has(root)) {
            seen.add(root);
            matches.push(root);
          }

          for (const element of root.querySelectorAll(selector)) {
            if (!seen.has(element)) {
              seen.add(element);
              matches.push(element);
            }
          }
        }

        return matches;
      };

      const labels = new Map();

      queryWithinRoots("label[for]").forEach((label) => {
        const id = label.getAttribute("for");
        if (id) labels.set(id, normalize(label.textContent));
      });

      const selectorMatches = (element) => {
        if (!elementSelector) return true;
        try {
          return element.matches(elementSelector);
        } catch (_error) {
          return false;
        }
      };

      const fields = queryWithinRoots("input[type='file']")
        .filter(selectorMatches)
        .map((element, index) => ({
          index,
          id: element.id || "",
          name: element.name || "",
          label: labels.get(element.id) || "",
          placeholder: element.getAttribute("placeholder") || "",
          title: element.getAttribute("title") || "",
          testid: element.getAttribute("data-testid") || ""
        }));

      return JSON.stringify({
        path: window.location.pathname + window.location.search,
        fields
      });
    })()
    """
  end
end
