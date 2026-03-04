defmodule Cerberus.Driver.Browser.Expressions do
  @moduledoc false

  alias Cerberus.Driver.Browser.ActionHelpers
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
        ok:
          !!(
            helper &&
              typeof helper.text === "function" &&
              typeof helper.locator === "function" &&
              typeof helper.path === "function"
          )
      });
    })()
    """
  end

  @spec action_helpers_preload() :: String.t()
  def action_helpers_preload do
    """
    (() => {
      #{ActionHelpers.preload_script()}

      const helper = window.__cerberusAction;

      return JSON.stringify({
        ok: !!(helper && typeof helper.resolve === "function" && typeof helper.perform === "function")
      });
    })()
    """
  end

  @spec action_resolve(map()) :: String.t()
  def action_resolve(payload) when is_map(payload) do
    encoded_payload = JSON.encode!(payload)

    """
    (async () => {
      const helper = window.__cerberusAction;

      if (helper && typeof helper.resolve === "function") {
        return await helper.resolve(#{encoded_payload});
      }

      return JSON.stringify({
        ok: false,
        reason: "action helper is not available",
        helperMissing: true,
        path: #{current_path_expression()}
      });
    })()
    """
  end

  @spec action_perform(map()) :: String.t()
  def action_perform(payload) when is_map(payload) do
    encoded_payload = JSON.encode!(payload)

    """
    (async () => {
      const now = () =>
        typeof performance !== "undefined" && typeof performance.now === "function"
          ? performance.now()
          : Date.now();

      const helper = window.__cerberusAction;

      if (helper && typeof helper.perform === "function") {
        const startedAt = now();
        const raw = await helper.perform(#{encoded_payload});
        const elapsedMs = now() - startedAt;

        try {
          const parsed = JSON.parse(raw);
          const jsTiming = parsed && parsed.jsTiming && typeof parsed.jsTiming === "object" ? parsed.jsTiming : {};
          parsed.jsTiming = { ...jsTiming, expressionActionPerformMs: elapsedMs };
          return JSON.stringify(parsed);
        } catch (_error) {
          return raw;
        }
      }

      return JSON.stringify({
        ok: false,
        reason: "action helper is not available",
        helperMissing: true,
        path: #{current_path_expression()},
        jsTiming: { expressionActionPerformMs: 0 }
      });
    })()
    """
  end

  @spec text_assertion(map()) :: String.t()
  def text_assertion(payload) when is_map(payload) do
    encoded_payload = JSON.encode!(payload)
    mode_value = Map.get(payload, :mode, "assert")

    """
    (async () => {
      const now = () =>
        typeof performance !== "undefined" && typeof performance.now === "function"
          ? performance.now()
          : Date.now();

      #{assert_helper_binding_snippet()}
      if (helper && typeof helper.text === "function") {
        const startedAt = now();
        const raw = await helper.text(#{encoded_payload});
        const elapsedMs = now() - startedAt;

        try {
          const parsed = JSON.parse(raw);
          const jsTiming = parsed && parsed.jsTiming && typeof parsed.jsTiming === "object" ? parsed.jsTiming : {};
          parsed.jsTiming = { ...jsTiming, expressionTextAssertionMs: elapsedMs };
          return JSON.stringify(parsed);
        } catch (_error) {
          return raw;
        }
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
        helperMissing: true,
        jsTiming: { expressionTextAssertionMs: 0 }
      });
    })()
    """
  end

  @spec locator_assertion(map()) :: String.t()
  def locator_assertion(payload) when is_map(payload) do
    encoded_payload = JSON.encode!(payload)
    mode_value = Map.get(payload, :mode, "assert")

    """
    (async () => {
      const now = () =>
        typeof performance !== "undefined" && typeof performance.now === "function"
          ? performance.now()
          : Date.now();

      #{assert_helper_binding_snippet()}
      if (helper && typeof helper.locator === "function") {
        const startedAt = now();
        const raw = await helper.locator(#{encoded_payload});
        const elapsedMs = now() - startedAt;

        try {
          const parsed = JSON.parse(raw);
          const jsTiming = parsed && parsed.jsTiming && typeof parsed.jsTiming === "object" ? parsed.jsTiming : {};
          parsed.jsTiming = { ...jsTiming, expressionLocatorAssertionMs: elapsedMs };
          return JSON.stringify(parsed);
        } catch (_error) {
          return raw;
        }
      }

      const mode = #{JSON.encode!(mode_value)};
      const reason = mode === "assert" ? "expected locator not found" : "unexpected matching locator found";

      return JSON.stringify({
        ok: false,
        reason,
        path: #{current_path_expression()},
        title: document.title || "",
        texts: [],
        matched: [],
        helperMissing: true,
        jsTiming: { expressionLocatorAssertionMs: 0 }
      });
    })()
    """
  end

  @spec path_assertion(
          String.t() | map(),
          map(),
          boolean(),
          :assert_path | :refute_path,
          non_neg_integer(),
          pos_integer()
        ) ::
          String.t()
  def path_assertion(expected, expected_query, exact, op, timeout_ms, poll_ms)
      when op in [:assert_path, :refute_path] and is_integer(timeout_ms) and timeout_ms >= 0 and is_integer(poll_ms) and
             poll_ms > 0 do
    payload = %{
      expected: expected,
      expectedQuery: expected_query,
      exact: exact,
      op: Atom.to_string(op),
      timeoutMs: timeout_ms,
      pollMs: poll_ms
    }

    encoded_payload = JSON.encode!(payload)

    """
    (() => {
      #{assert_helper_binding_snippet()}
      if (helper && typeof helper.path === "function") {
        return helper.path(#{encoded_payload});
      }

      const payload = #{encoded_payload};
      const expected = payload.expected;
      const expectedQuery = payload.expectedQuery;
      const exact = payload.exact === true;
      const op = payload.op || "assert_path";
      const timeoutMs = Number(payload.timeoutMs) > 0 ? Number(payload.timeoutMs) : 0;
      const pollMs = Number(payload.pollMs) > 0 ? Number(payload.pollMs) : 100;

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

      const evaluateOnce = () => {
        const path = #{current_path_expression()};
        const pathOnly = (() => {
          try {
            const idx = path.indexOf("?");
            return idx >= 0 ? path.slice(0, idx) : path;
          } catch (_error) {
            return path || "/";
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

        return {
          ok,
          reason: ok ? "matched" : "mismatch",
          path,
          "path_match?": pathMatch,
          "query_match?": queryMatch,
          helperMissing: true
        };
      };

      const initial = evaluateOnce();
      if (timeoutMs <= 0 || initial.ok) return JSON.stringify(initial);

      return new Promise((resolve) => {
        const deadline = Date.now() + timeoutMs;
        let settled = false;

        const finish = (result) => {
          if (settled) return;
          settled = true;
          resolve(JSON.stringify(result));
        };

        const tick = () => {
          const attempt = evaluateOnce();
          if (attempt.ok || Date.now() >= deadline) {
            finish(attempt);
          }
        };

        const intervalRef = setInterval(tick, pollMs);
        const timeoutRef = setTimeout(tick, timeoutMs);

        const originalFinish = finish;
        finish = (result) => {
          if (settled) return;
          clearInterval(intervalRef);
          clearTimeout(timeoutRef);
          originalFinish(result);
        };

        tick();
      });
    })()
    """
  end

  @spec snapshot(String.t() | map() | nil) :: String.t()
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

  @spec within_scope_snapshot(String.t() | map() | nil) :: String.t()
  def within_scope_snapshot(scope) do
    encoded_scope = JSON.encode!(scope)

    """
    (() => {
      #{scope_resolution_setup(encoded_scope)}

      if (scopeContext.error) {
        return JSON.stringify({
          ok: false,
          reason: scopeContext.error.reason,
          selector: scopeContext.error.selector,
          frameChain: scopeContext.frameChain
        });
      }

      const doc = scopeContext.document;
      const root = doc ? doc.documentElement : null;
      const html = root ? root.outerHTML : "";
      const doctype = doc && doc.doctype ? `<!DOCTYPE ${doc.doctype.name}>` : "<!DOCTYPE html>";

      return JSON.stringify({
        ok: true,
        html: doctype + html,
        scopeSelector: scopeContext.scopeSelector,
        frameChain: scopeContext.frameChain
      });
    })()
    """
  end

  @spec within_iframe_access(String.t() | map() | nil, String.t()) :: String.t()
  def within_iframe_access(scope, selector) when is_binary(selector) and selector != "" do
    encoded_scope = JSON.encode!(scope)
    encoded_selector = JSON.encode!(selector)

    """
    (() => {
      #{scope_resolution_setup(encoded_scope)}
      const iframeSelector = #{encoded_selector};

      if (scopeContext.error) {
        return JSON.stringify({
          ok: false,
          reason: scopeContext.error.reason,
          selector: scopeContext.error.selector
        });
      }

      let iframe = null;

      try {
        iframe = scopeContext.document.querySelector(iframeSelector);
      } catch (_error) {
        return JSON.stringify({ ok: false, reason: "invalid_iframe_selector" });
      }

      if (!iframe || (iframe.tagName || "").toLowerCase() !== "iframe") {
        return JSON.stringify({ ok: false, reason: "iframe_not_found" });
      }

      try {
        const childDocument = iframe.contentDocument;
        return JSON.stringify({ ok: true, sameOrigin: !!childDocument });
      } catch (_error) {
        return JSON.stringify({ ok: true, sameOrigin: false });
      }
    })()
    """
  end

  defp scoped_roots_setup(encoded_scope) do
    """
    #{scope_resolution_setup(encoded_scope)}
    const defaultRoot = scopeContext.document.body || scopeContext.document.documentElement;
    let roots = defaultRoot ? [defaultRoot] : [];

    if (scopeContext.error) {
      roots = [];
    } else if (scopeContext.scopeSelector) {
      try {
        roots = Array.from(scopeContext.document.querySelectorAll(scopeContext.scopeSelector));
      } catch (_error) {
        roots = [];
      }
    }
    """
  end

  defp normalize_trim_snippet do
    """
    const normalize = (value) => (value || "").replace(/\\u00A0/g, " ").trim();
    """
  end

  defp current_path_expression, do: "window.location.pathname + window.location.search"

  defp scope_resolution_setup(encoded_scope) do
    """
    const scopeInput = #{encoded_scope};

    const normalizeScopeInput = (value) => {
      if (typeof value === "string") {
        const selector = value.trim();
        return { frameChain: [], selector: selector === "" ? null : selector };
      }

      if (value && typeof value === "object") {
        const frameChainSource = Array.isArray(value.frame_chain)
          ? value.frame_chain
          : (Array.isArray(value.frameChain) ? value.frameChain : []);

        const frameChain = frameChainSource.filter((entry) => typeof entry === "string" && entry.trim() !== "");
        const selector = typeof value.selector === "string" && value.selector.trim() !== "" ? value.selector : null;

        return { frameChain, selector };
      }

      return { frameChain: [], selector: null };
    };

    const resolveScopeContext = (rawScope) => {
      const parsed = normalizeScopeInput(rawScope);
      let scopeDocument = document;
      let error = null;

      for (const frameSelector of parsed.frameChain) {
        let frame = null;

        try {
          frame = scopeDocument.querySelector(frameSelector);
        } catch (_error) {
          error = { reason: "invalid_frame_selector", selector: frameSelector };
          break;
        }

        if (!frame || (frame.tagName || "").toLowerCase() !== "iframe") {
          error = { reason: "frame_not_found", selector: frameSelector };
          break;
        }

        let nextDocument = null;

        try {
          nextDocument = frame.contentDocument;
        } catch (_error) {
          error = { reason: "cross_origin_frame", selector: frameSelector };
          break;
        }

        if (!nextDocument) {
          error = { reason: "cross_origin_frame", selector: frameSelector };
          break;
        }

        scopeDocument = nextDocument;
      }

      return {
        frameChain: parsed.frameChain,
        scopeSelector: parsed.selector,
        document: scopeDocument,
        error
      };
    };

    const scopeContext = resolveScopeContext(scopeInput);
    """
  end

  defp assert_helper_binding_snippet do
    """
    const helper = window.__cerberusAssert;
    """
  end
end
