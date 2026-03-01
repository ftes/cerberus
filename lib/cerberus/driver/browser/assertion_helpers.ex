defmodule Cerberus.Driver.Browser.AssertionHelpers do
  @moduledoc false

  @preload_script """
  ;(() => {
    if (window.__cerberusAssert && window.__cerberusAssert.__version === 1) return;

    const helper = {};
    helper.__version = 1;

    helper.normalize = (value, normalizeWs) => {
      const source = (value || "").replace(/\\u00A0/g, " ");
      if (!normalizeWs) return source;
      return source.replace(/\\s+/g, " ").trim();
    };

    helper.regexFromExpected = (payload) => {
      if (!payload || payload.type !== "regex") return null;

      try {
        const supported = new Set(["i", "m", "s", "u"]);
        const flags = (payload.opts || "")
          .split("")
          .filter((flag) => supported.has(flag))
          .join("");

        return new RegExp(payload.source || "", flags);
      } catch (_error) {
        return null;
      }
    };

    helper.resolveRoots = (scopeSelector) => {
      const defaultRoot = document.body || document.documentElement;
      if (!scopeSelector) return defaultRoot ? [defaultRoot] : [];

      try {
        return Array.from(document.querySelectorAll(scopeSelector));
      } catch (_error) {
        return [];
      }
    };

    helper.eachCandidateElement = (roots, selector, callback) => {
      const seen = new Set();

      const visit = (candidate) => {
        if (!candidate || seen.has(candidate)) return true;
        seen.add(candidate);
        return callback(candidate) !== false;
      };

      for (const root of roots) {
        if (!root) continue;

        if (!selector) {
          if (!visit(root)) return false;
        } else if (typeof root.matches === "function") {
          try {
            if (root.matches(selector) && !visit(root)) return false;
          } catch (_error) {
            // ignored
          }
        }

        const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT);
        let node = walker.nextNode();

        while (node) {
          if (!selector) {
            if (!visit(node)) return false;
          } else {
            try {
              if (node.matches(selector) && !visit(node)) return false;
            } catch (_error) {
              // ignored
            }
          }

          node = walker.nextNode();
        }
      }

      return true;
    };

    helper.isHidden = (element) => {
      let current = element;

      while (current) {
        if (current.hasAttribute("hidden")) return true;
        const style = window.getComputedStyle(current);
        if (style.display === "none" || style.visibility === "hidden") return true;
        current = current.parentElement;
      }

      return false;
    };

    helper.selectedVisibility = (visibility, hidden) => {
      if (visibility === "visible") return !hidden;
      if (visibility === "hidden") return hidden;
      return true;
    };

    helper.buildTextMatcher = (expected, exact, normalizeWs) => {
      const expectedRegex = helper.regexFromExpected(expected);

      return (actual) => {
        const normalizedActual = helper.normalize(actual, normalizeWs);

        if (expectedRegex) {
          return expectedRegex.test(normalizedActual);
        }

        const expectedValue = helper.normalize(expected && expected.value ? expected.value : "", normalizeWs);
        return exact ? normalizedActual === expectedValue : normalizedActual.includes(expectedValue);
      };
    };

    helper.textQuick = (options) => {
      const visibility = options.visibility || "visible";
      const mode = options.mode || "assert";
      const normalizeWs = options.normalizeWs !== false;
      const exact = options.exact === true;
      const selector = options.selector || null;
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);
      let matchedAny = false;

      helper.eachCandidateElement(roots, selector, (element) => {
        const tag = (element.tagName || "").toLowerCase();
        if (tag === "script" || tag === "style" || tag === "noscript") return true;

        const hidden = helper.isHidden(element);
        if (!helper.selectedVisibility(visibility, hidden)) return true;

        const source = hidden ? element.textContent : element.innerText || element.textContent;
        const value = helper.normalize(source, normalizeWs);
        if (!value) return true;

        if (matchText(value)) {
          matchedAny = true;
          return false;
        }

        return true;
      });

      const ok = mode === "assert" ? matchedAny : !matchedAny;
      const reason = ok ? "matched" : mode === "assert" ? "expected text not found" : "unexpected matching text found";

      return {
        ok,
        reason,
        path: window.location.pathname + window.location.search,
        title: document.title || ""
      };
    };

    helper.textDiagnostics = (options) => {
      const visibility = options.visibility || "visible";
      const mode = options.mode || "assert";
      const normalizeWs = options.normalizeWs !== false;
      const exact = options.exact === true;
      const selector = options.selector || null;
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);
      const visibleTexts = [];
      const hiddenTexts = [];
      const visibleSet = new Set();
      const hiddenSet = new Set();

      helper.eachCandidateElement(roots, selector, (element) => {
        const tag = (element.tagName || "").toLowerCase();
        if (tag === "script" || tag === "style" || tag === "noscript") return true;

        const hidden = helper.isHidden(element);
        const source = hidden ? element.textContent : element.innerText || element.textContent;
        const value = helper.normalize(source, normalizeWs);
        if (!value) return true;

        if (hidden) {
          if (!hiddenSet.has(value)) {
            hiddenSet.add(value);
            hiddenTexts.push(value);
          }
        } else if (!visibleSet.has(value)) {
          visibleSet.add(value);
          visibleTexts.push(value);
        }

        return true;
      });

      const texts =
        visibility === "visible"
          ? visibleTexts
          : visibility === "hidden"
            ? hiddenTexts
            : visibleTexts.concat(hiddenTexts);

      const matched = texts.filter((text) => matchText(text));
      const ok = mode === "assert" ? matched.length > 0 : matched.length === 0;
      const reason = mode === "assert" ? "expected text not found" : "unexpected matching text found";

      return {
        ok,
        reason,
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        texts,
        matched
      };
    };

    helper.text = (options) => {
      const timeoutMs = Math.max(0, Number(options.timeoutMs || 0));
      const pollMs = Math.max(50, Number(options.pollMs || 250));
      const deadline = Date.now() + timeoutMs;
      const initial = helper.textQuick(options);

      if (initial.ok) {
        return Promise.resolve(JSON.stringify(initial));
      }

      if (timeoutMs <= 0) {
        return Promise.resolve(JSON.stringify(helper.textDiagnostics(options)));
      }

      return new Promise((resolve) => {
        let resolved = false;
        let dirty = true;
        let pendingCheck = false;
        const cleanupFns = [];

        const finish = (result) => {
          if (resolved) return;
          resolved = true;
          for (const cleanup of cleanupFns) {
            try {
              cleanup();
            } catch (_error) {
              // ignored
            }
          }
          resolve(JSON.stringify(result));
        };

        const scheduleCheck = () => {
          if (resolved || pendingCheck || !dirty) return;
          pendingCheck = true;

          const run = () => {
            pendingCheck = false;
            if (resolved) return;
            dirty = false;
            const quick = helper.textQuick(options);
            if (quick.ok) finish(quick);
          };

          if (typeof window.requestAnimationFrame === "function") {
            window.requestAnimationFrame(() => run());
          } else {
            setTimeout(run, 0);
          }
        };

        try {
          const root = document.documentElement || document.body || document;
          const observer = new MutationObserver(() => {
            dirty = true;
            scheduleCheck();
          });

          observer.observe(root, {
            subtree: true,
            childList: true,
            attributes: true,
            characterData: true
          });

          cleanupFns.push(() => observer.disconnect());
        } catch (_error) {
          // ignored
        }

        scheduleCheck();

        const intervalRef = setInterval(() => {
          if (Date.now() >= deadline) {
            finish(helper.textDiagnostics(options));
            return;
          }

          dirty = true;
          scheduleCheck();
        }, pollMs);
        cleanupFns.push(() => clearInterval(intervalRef));

        const timeoutRef = setTimeout(() => finish(helper.textDiagnostics(options)), timeoutMs);
        cleanupFns.push(() => clearTimeout(timeoutRef));
      });
    };

    helper.pathCheck = (options) => {
      const expected = options.expected;
      const expectedQuery = options.expectedQuery;
      const exact = options.exact === true;
      const op = options.op || "assert_path";

      const currentPath = window.location.pathname + window.location.search;
      const pathOnly = (() => {
        try {
          const idx = currentPath.indexOf("?");
          return idx >= 0 ? currentPath.slice(0, idx) : currentPath;
        } catch (_error) {
          return currentPath || "/";
        }
      })();

      const expectedRegex = helper.regexFromExpected(expected);
      const pathMatch = (() => {
        if (expectedRegex) return expectedRegex.test(currentPath);

        const expectedValue = expected && expected.value ? expected.value : "";
        const actualTarget = expectedValue.includes("?") ? currentPath : pathOnly;
        return exact ? actualTarget === expectedValue : actualTarget.includes(expectedValue);
      })();

      const queryMatch = (() => {
        if (!expectedQuery) return true;

        const idx = currentPath.indexOf("?");
        const query = idx >= 0 ? currentPath.slice(idx + 1) : "";
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
        path: currentPath,
        "path_match?": pathMatch,
        "query_match?": queryMatch
      });
    };

    window.__cerberusAssert = helper;
  })();
  """

  @spec preload_script() :: String.t()
  def preload_script, do: @preload_script
end
