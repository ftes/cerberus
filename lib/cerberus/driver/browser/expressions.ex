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

  @spec upload_field(
          non_neg_integer(),
          String.t(),
          String.t(),
          integer(),
          binary(),
          String.t() | nil,
          String.t() | nil
        ) ::
          String.t()
  def upload_field(index, file_name, mime_type, last_modified_unix_ms, content, scope, selector) do
    encoded_file_name = JSON.encode!(file_name)
    encoded_mime_type = JSON.encode!(mime_type)
    encoded_last_modified = JSON.encode!(last_modified_unix_ms)
    encoded_content = JSON.encode!(Base.encode64(content))
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const fileName = #{encoded_file_name};
      const mimeType = #{encoded_mime_type};
      const lastModified = #{encoded_last_modified};
      const contentBase64 = #{encoded_content};
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

      const fields = queryWithinRoots("input[type='file']").filter(selectorMatches);
      const field = fields[#{index}];

      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      try {
        const decoded = atob(contentBase64);
        const bytes = new Uint8Array(decoded.length);

        for (let i = 0; i < decoded.length; i += 1) {
          bytes[i] = decoded.charCodeAt(i);
        }

        const file = new File([bytes], fileName, { type: mimeType, lastModified });
        const transfer = new DataTransfer();
        transfer.items.add(file);
        field.files = transfer.files;

        field.dispatchEvent(new Event("input", { bubbles: true }));
        field.dispatchEvent(new Event("change", { bubbles: true }));

        return JSON.stringify({
          ok: true,
          path: window.location.pathname + window.location.search
        });
      } catch (error) {
        return JSON.stringify({
          ok: false,
          reason: "file_set_failed",
          message: String(error && error.message ? error.message : error)
        });
      }
    })()
    """
  end

  @spec field_set(non_neg_integer(), term(), String.t() | nil, String.t() | nil) :: String.t()
  def field_set(index, value, scope, selector) do
    encoded_value = JSON.encode!(to_string(value))
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
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

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const value = #{encoded_value};
      field.value = value;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end

  @spec select_set(
          non_neg_integer(),
          [String.t()],
          boolean(),
          boolean(),
          [String.t()],
          String.t() | nil,
          String.t() | nil
        ) ::
          String.t()
  def select_set(index, options, exact_option, preserve_existing, remembered_values, scope, selector) do
    encoded_options = JSON.encode!(options)
    encoded_exact_option = JSON.encode!(exact_option)
    encoded_preserve_existing = JSON.encode!(preserve_existing)
    encoded_remembered_values = JSON.encode!(remembered_values)
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const requestedOptions = #{encoded_options};
      const exactOption = #{encoded_exact_option};
      const preserveExisting = #{encoded_preserve_existing};
      const rememberedValues = #{encoded_remembered_values};
      const defaultRoot = document.body || document.documentElement;
      let roots = defaultRoot ? [defaultRoot] : [];

      if (scopeSelector) {
        try {
          roots = Array.from(document.querySelectorAll(scopeSelector));
        } catch (_error) {
          roots = [];
        }
      }

      const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").replace(/\\s+/g, " ").trim();

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

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      if ((field.tagName || "").toLowerCase() !== "select") {
        return JSON.stringify({ ok: false, reason: "field_not_select" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      if (!field.multiple && requestedOptions.length > 1) {
        return JSON.stringify({ ok: false, reason: "select_not_multiple" });
      }

      const matchOption = (option, requested) => {
        const optionText = normalize(option.textContent);
        const requestedText = normalize(requested);

        if (exactOption) {
          return optionText === requestedText;
        }

        return optionText.includes(requestedText);
      };

      const matched = [];

      for (const requested of requestedOptions) {
        const enabled = Array.from(field.options || []).find((option) => matchOption(option, requested) && !option.disabled);

        if (enabled) {
          matched.push(enabled);
          continue;
        }

        const disabled = Array.from(field.options || []).find((option) => matchOption(option, requested) && option.disabled);

        if (disabled) {
          return JSON.stringify({ ok: false, reason: "option_disabled", option: requested });
        }

        return JSON.stringify({ ok: false, reason: "option_not_found", option: requested });
      }

      if (field.multiple) {
        const remembered = new Set((rememberedValues || []).map((value) => String(value)));
        const selectedValues = preserveExisting
          ? new Set(
              Array.from(field.selectedOptions || []).map((option) => option.value || normalize(option.textContent))
                .concat(Array.from(remembered))
            )
          : new Set();

        for (const option of matched) {
          selectedValues.add(option.value || normalize(option.textContent));
        }

        for (const option of Array.from(field.options || [])) {
          const value = option.value || normalize(option.textContent);
          option.selected = selectedValues.has(value);
        }
      } else {
        for (const option of Array.from(field.options || [])) {
          option.selected = false;
        }

        if (matched[0]) {
          matched[0].selected = true;
          field.value = matched[0].value || normalize(matched[0].textContent);
        }
      }

      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      const value = field.multiple
        ? Array.from(field.selectedOptions || []).map((option) => option.value || normalize(option.textContent))
        : field.value;

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search,
        value
      });
    })()
    """
  end

  @spec checkbox_set(non_neg_integer(), boolean(), String.t() | nil, String.t() | nil) :: String.t()
  def checkbox_set(index, checked, scope, selector) do
    encoded_checked = JSON.encode!(checked)
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const scopeSelector = #{encoded_scope};
      const elementSelector = #{encoded_selector};
      const shouldCheck = #{encoded_checked};
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

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const type = (field.getAttribute("type") || "").toLowerCase();
      if (type !== "checkbox") {
        return JSON.stringify({ ok: false, reason: "field_not_checkbox" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      field.checked = shouldCheck;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end

  @spec radio_set(non_neg_integer(), String.t() | nil, String.t() | nil) :: String.t()
  def radio_set(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
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

      const fields = queryWithinRoots("input, textarea, select")
        .filter((element) => {
          const type = (element.getAttribute("type") || "").toLowerCase();
          return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
        });

      const field = fields[#{index}];
      if (!field) {
        return JSON.stringify({ ok: false, reason: "field_not_found" });
      }

      const type = (field.getAttribute("type") || "").toLowerCase();
      if (type !== "radio") {
        return JSON.stringify({ ok: false, reason: "field_not_radio" });
      }

      if (field.disabled) {
        return JSON.stringify({ ok: false, reason: "field_disabled" });
      }

      field.checked = true;
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search,
        value: field.value || "on"
      });
    })()
    """
  end

  @spec button_click(non_neg_integer(), String.t() | nil, String.t() | nil) :: String.t()
  def button_click(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
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

      const buttons = queryWithinRoots("button").filter(selectorMatches);
      const button = buttons[#{index}];

      if (!button) {
        return JSON.stringify({ ok: false, reason: "button_not_found" });
      }

      button.click();

      return JSON.stringify({
        ok: true,
        path: window.location.pathname + window.location.search
      });
    })()
    """
  end
end
