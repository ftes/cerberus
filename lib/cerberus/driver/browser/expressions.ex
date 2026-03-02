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
    (() => JSON.stringify({ path: #{current_path_expression()} }))()
    """
  end

  @spec assertion_helpers_preload() :: String.t()
  def assertion_helpers_preload do
    """
    (() => {
      #{AssertionHelpers.preload_script()}

      #{assert_helper_binding_snippet()}

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
      #{assert_helper_binding_snippet()}
      if (helper && typeof helper.text === "function") {
        return helper.text(#{encoded_payload});
      }

      const mode = #{JSON.encode!(mode_value)};
      const reason = mode === "assert" ? "expected text not found" : "unexpected matching text found";

      return JSON.stringify({
        ok: false,
        reason,
        path: #{current_path_expression()},
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
      #{assert_helper_binding_snippet()}
      if (helper && typeof helper.pathCheck === "function") {
        return helper.pathCheck(#{encoded_payload});
      }

      const payload = #{encoded_payload};
      const expected = payload.expected;
      const expectedQuery = payload.expectedQuery;
      const exact = payload.exact === true;
      const op = payload.op || "assert_path";
      const path = #{current_path_expression()};
      const pathOnly = (() => {
        try {
          const idx = path.indexOf("?");
          return idx >= 0 ? path.slice(0, idx) : path;
        } catch (_error) {
          return path || "/";
        }
      })();

      const expectedRegex = (() => {
        if (!expected || expected.type !== "regex") return null;

        try {
          const supported = new Set(["i", "m", "s", "u"]);
          const flags = (expected.opts || "")
            .split("")
            .filter((flag) => supported.has(flag))
            .join("");

          return new RegExp(expected.source || "", flags);
        } catch (_error) {
          return null;
        }
      })();

      const pathMatch = (() => {
        if (expectedRegex) return expectedRegex.test(path);

        const expectedValue = expected && expected.value ? expected.value : "";
        const actualTarget = expectedValue.includes("?") ? path : pathOnly;
        return exact ? actualTarget === expectedValue : actualTarget.includes(expectedValue);
      })();

      const queryMatch = (() => {
        if (!expectedQuery) return true;

        const idx = path.indexOf("?");
        const query = idx >= 0 ? path.slice(idx + 1) : "";
        const params = new URLSearchParams(query);

        return Object.entries(expectedQuery).every(([key, value]) => {
          return (params.get(key) || null) === String(value);
        });
      })();

      const combinedMatch = pathMatch && queryMatch;
      const ok = op === "assert_path" ? combinedMatch : !combinedMatch;

      return JSON.stringify({
        ok,
        reason: ok ? "matched" : "mismatch",
        path,
        "path_match?": pathMatch,
        "query_match?": queryMatch,
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
      #{normalize_trim_snippet()}
      #{scoped_roots_setup(encoded_scope)}

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
      #{normalize_trim_snippet()}
      #{scoped_query_setup(encoded_scope, encoded_selector)}

      const links = queryWithinRoots("a[href]")
        .filter(selectorMatches)
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        outer_html: element.outerHTML || "",
        checked: false,
        selected: false,
        disabled: false,
        readonly: false,
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

      const buttons = #{button_candidates_expression()}
        .map((element, index) => ({
        index,
        text: normalize(element.textContent),
        outer_html: element.outerHTML || "",
        checked: false,
        selected: false,
        disabled: element.disabled === true,
        readonly: element.readOnly === true || element.hasAttribute("readonly"),
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
        path: #{current_path_expression()},
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
      #{normalize_trim_snippet()}
      #{scoped_query_setup(encoded_scope, encoded_selector)}
      #{labels_by_for_snippet()}

      const labelForControl = (element) => {
        const byId = labels.get(element.id || "");
        if (byId) return byId;

        const wrappingLabel = element.closest("label");
        if (wrappingLabel) return normalize(wrappingLabel.textContent);

        return "";
      };

      #{form_field_candidates_snippet()}
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
            outer_html: element.outerHTML || "",
            label: labelForControl(element),
            placeholder: element.getAttribute("placeholder") || "",
            title: element.getAttribute("title") || "",
            testid: element.getAttribute("data-testid") || "",
            type,
            value,
            checked: element.checked === true,
            selected:
              tag === "select"
                ? Array.from(element.options || []).some((option) => option.hasAttribute("selected"))
                : element.checked === true,
            readonly: element.readOnly === true || element.hasAttribute("readonly"),
            tag,
            multiple: tag === "select" && element.multiple === true,
            disabled: element.disabled === true
          };
        });

      return JSON.stringify({
        path: #{current_path_expression()},
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
      #{normalize_trim_snippet()}
      #{scoped_query_setup(encoded_scope, encoded_selector)}
      #{labels_by_for_snippet()}

      #{file_field_candidates_snippet()}
        .map((element, index) => ({
          index,
          id: element.id || "",
          name: element.name || "",
          outer_html: element.outerHTML || "",
          label: labels.get(element.id) || "",
          placeholder: element.getAttribute("placeholder") || "",
          title: element.getAttribute("title") || "",
          testid: element.getAttribute("data-testid") || "",
          checked: element.checked === true,
          selected: element.checked === true,
          readonly: element.readOnly === true || element.hasAttribute("readonly"),
          disabled: element.disabled === true
        }));

      return JSON.stringify({
        path: #{current_path_expression()},
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
      #{scoped_query_setup(encoded_scope, encoded_selector)}
      const fileName = #{encoded_file_name};
      const mimeType = #{encoded_mime_type};
      const lastModified = #{encoded_last_modified};
      const contentBase64 = #{encoded_content};
      #{file_field_candidates_snippet()}
      #{indexed_lookup_snippet("fields", "field", index, "field_not_found")}

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

        #{dispatch_input_change_events("field")}
        #{ok_path_payload()}
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
      #{scoped_form_field_lookup_snippet(encoded_scope, encoded_selector, index)}

      const value = #{encoded_value};
      field.value = value;
      #{dispatch_input_change_events("field")}
      #{ok_path_payload()}
    })()
    """
  end

  @spec select_set(
          non_neg_integer(),
          [String.t()],
          boolean(),
          String.t() | nil,
          String.t() | nil
        ) ::
          String.t()
  def select_set(index, options, exact_option, scope, selector) do
    encoded_options = JSON.encode!(options)
    encoded_exact_option = JSON.encode!(exact_option)
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      const requestedOptions = #{encoded_options};
      const exactOption = #{encoded_exact_option};

      #{normalize_collapsed_snippet()}
      #{scoped_form_field_lookup_snippet(encoded_scope, encoded_selector, index)}

      #{guard_condition_snippet(~s/(field.tagName || "").toLowerCase() !== "select"/, "field_not_select")}
      #{guard_condition_snippet("field.disabled", "field_disabled")}
      #{guard_condition_snippet("!field.multiple && requestedOptions.length > 1", "select_not_multiple")}

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

        #{guard_condition_snippet("disabled", "option_disabled", ["option: requested"])}
        #{error_reason_payload("option_not_found", ["option: requested"])}
      }

      if (field.multiple) {
        const selectedValues = new Set();

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

      #{dispatch_input_change_events("field")}

      const value = field.multiple
        ? Array.from(field.selectedOptions || []).map((option) => option.value || normalize(option.textContent))
        : field.value;

      #{ok_path_payload(["value"])}
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
      const shouldCheck = #{encoded_checked};
      #{scoped_form_field_lookup_snippet(encoded_scope, encoded_selector, index)}

      #{typed_enabled_field_guards_snippet("checkbox", "field_not_checkbox")}

      field.checked = shouldCheck;
      #{dispatch_input_change_events("field")}
      #{ok_path_payload()}
    })()
    """
  end

  @spec radio_set(non_neg_integer(), String.t() | nil, String.t() | nil) :: String.t()
  def radio_set(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      #{scoped_form_field_lookup_snippet(encoded_scope, encoded_selector, index)}

      #{typed_enabled_field_guards_snippet("radio", "field_not_radio")}

      field.checked = true;
      #{dispatch_input_change_events("field")}
      #{ok_path_payload([~s(value: field.value || "on")])}
    })()
    """
  end

  @spec button_click(non_neg_integer(), String.t() | nil, String.t() | nil) :: String.t()
  def button_click(index, scope, selector) do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      #{scoped_query_setup(encoded_scope, encoded_selector)}

      const buttons = #{button_candidates_expression()};
      #{indexed_lookup_snippet("buttons", "button", index, "button_not_found")}

      button.click();

      #{ok_path_payload()}
    })()
    """
  end

  defp scoped_roots_setup(encoded_scope) do
    """
    const scopeSelector = #{encoded_scope};
    const defaultRoot = document.body || document.documentElement;
    let roots = defaultRoot ? [defaultRoot] : [];

    if (scopeSelector) {
      try {
        roots = Array.from(document.querySelectorAll(scopeSelector));
      } catch (_error) {
        roots = [];
      }
    }
    """
  end

  defp scoped_query_setup(encoded_scope, encoded_selector) do
    """
    #{scoped_roots_setup(encoded_scope)}
    const elementSelector = #{encoded_selector};

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
    """
  end

  defp form_field_candidates_snippet do
    """
    const fields = queryWithinRoots("input, textarea, select")
      .filter((element) => {
        const type = (element.getAttribute("type") || "").toLowerCase();
        return type !== "hidden" && type !== "submit" && type !== "button" && selectorMatches(element);
      })
    """
  end

  defp file_field_candidates_snippet do
    """
    const fields = queryWithinRoots("input[type='file']").filter(selectorMatches)
    """
  end

  defp button_candidates_expression, do: ~s/queryWithinRoots("button").filter(selectorMatches)/

  defp labels_by_for_snippet do
    """
    const labels = new Map();

    queryWithinRoots("label[for]").forEach((label) => {
      const id = label.getAttribute("for");
      if (id) labels.set(id, normalize(label.textContent));
    });
    """
  end

  defp normalize_trim_snippet do
    """
    const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
    """
  end

  defp normalize_collapsed_snippet do
    """
    const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").replace(/\\s+/g, " ").trim();
    """
  end

  defp dispatch_input_change_events(target_name) when is_binary(target_name) do
    """
    #{target_name}.dispatchEvent(new Event("input", { bubbles: true }));
    #{target_name}.dispatchEvent(new Event("change", { bubbles: true }));
    """
  end

  defp ok_path_payload(extra_fields \\ []) when is_list(extra_fields) do
    extra_payload =
      case extra_fields do
        [] -> ""
        fields -> ",\n  " <> Enum.join(fields, ",\n  ")
      end

    """
    return JSON.stringify({
      ok: true,
      path: #{current_path_expression()}#{extra_payload}
    });
    """
  end

  defp current_path_expression, do: "window.location.pathname + window.location.search"

  defp assert_helper_binding_snippet do
    """
    const helper = window.__cerberusAssert;
    """
  end

  defp indexed_lookup_snippet(collection_name, variable_name, index, reason)
       when is_binary(collection_name) and is_binary(variable_name) and is_integer(index) and is_binary(reason) do
    reason_payload = error_reason_payload(reason)

    """
    const #{variable_name} = #{collection_name}[#{index}];
    if (!#{variable_name}) {
      #{reason_payload}
    }
    """
  end

  defp indexed_form_field_snippet(index, reason \\ "field_not_found") when is_integer(index) and is_binary(reason) do
    """
    #{form_field_candidates_snippet()}
    #{indexed_lookup_snippet("fields", "field", index, reason)}
    """
  end

  defp scoped_form_field_lookup_snippet(encoded_scope, encoded_selector, index)
       when is_binary(encoded_scope) and is_binary(encoded_selector) and is_integer(index) do
    """
    #{scoped_query_setup(encoded_scope, encoded_selector)}
    #{indexed_form_field_snippet(index)}
    """
  end

  defp typed_enabled_field_guards_snippet(type, not_type_reason) when is_binary(type) and is_binary(not_type_reason) do
    encoded_type = JSON.encode!(type)
    type_mismatch_condition = ~s{(field.getAttribute("type") || "").toLowerCase() !== } <> encoded_type

    """
    #{guard_condition_snippet(type_mismatch_condition, not_type_reason)}
    #{guard_condition_snippet("field.disabled", "field_disabled")}
    """
  end

  defp guard_condition_snippet(condition, reason, extra_fields \\ [])
       when is_binary(condition) and is_binary(reason) and is_list(extra_fields) do
    """
    if (#{condition}) {
      #{error_reason_payload(reason, extra_fields)}
    }
    """
  end

  defp error_reason_payload(reason, extra_fields \\ []) when is_binary(reason) and is_list(extra_fields) do
    encoded_reason = JSON.encode!(reason)

    extra_payload =
      case extra_fields do
        [] -> ""
        fields -> ",\n  " <> Enum.join(fields, ",\n  ")
      end

    """
    return JSON.stringify({
      ok: false,
      reason: #{encoded_reason}#{extra_payload}
    });
    """
  end
end
