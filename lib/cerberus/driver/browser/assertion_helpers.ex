defmodule Cerberus.Driver.Browser.AssertionHelpers do
  @moduledoc false

  @preload_script """
  ;(() => {
    if (window.__cerberusAssert && window.__cerberusAssert.__version === 5) return;

    const helper = {};
    helper.__version = 5;

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

    helper.normalizeScopeInput = (scopeInput) => {
      if (typeof scopeInput === "string") {
        const selector = scopeInput.trim();
        return { frameChain: [], selector: selector === "" ? null : selector };
      }

      if (scopeInput && typeof scopeInput === "object") {
        const frameChainSource = Array.isArray(scopeInput.frame_chain)
          ? scopeInput.frame_chain
          : (Array.isArray(scopeInput.frameChain) ? scopeInput.frameChain : []);

        const frameChain = frameChainSource.filter((entry) => typeof entry === "string" && entry.trim() !== "");
        const selector = typeof scopeInput.selector === "string" && scopeInput.selector.trim() !== ""
          ? scopeInput.selector
          : null;

        return { frameChain, selector };
      }

      return { frameChain: [], selector: null };
    };

    helper.resolveScopeContext = (scopeInput) => {
      const parsed = helper.normalizeScopeInput(scopeInput);
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
        document: scopeDocument,
        frameChain: parsed.frameChain,
        scopeSelector: parsed.selector,
        error
      };
    };

    helper.resolveRoots = (scopeInput) => {
      const context = helper.resolveScopeContext(scopeInput);
      if (context.error) return [];

      const scopeDocument = context.document;
      const defaultRoot = scopeDocument.body || scopeDocument.documentElement;
      if (!context.scopeSelector) return defaultRoot ? [defaultRoot] : [];

      try {
        return Array.from(scopeDocument.querySelectorAll(context.scopeSelector));
      } catch (_error) {
        return [];
      }
    };

    helper.selectorForMatchBy = (matchBy) => {
      switch (matchBy) {
        case "label":
          return "label";
        case "link":
          return "a[href]";
        case "button":
          return "button";
        case "placeholder":
          return "input[placeholder],textarea[placeholder],select[placeholder]";
        case "title":
          return "[title]";
        case "alt":
          return "[alt],img[alt],input[type='image'][alt],[role='img'][alt],button,a[href]";
        case "testid":
          return "[data-testid]";
        default:
          return null;
      }
    };

    helper.isTextLikeMatchBy = (matchBy) => {
      return matchBy === "text" || matchBy === "label" || matchBy === "link" || matchBy === "button";
    };

    helper.matchesSelector = (element, selector) => {
      if (!selector || typeof element.matches !== "function") return true;
      try {
        return element.matches(selector);
      } catch (_error) {
        return false;
      }
    };

    helper.eachCandidateElement = (roots, selector, prefilterSelector, callback) => {
      const seen = new Set();

      const visit = (candidate) => {
        if (!candidate || seen.has(candidate)) return true;
        seen.add(candidate);
        return callback(candidate) !== false;
      };

      for (const root of roots) {
        if (!root) continue;

        const effectiveSelector = selector || prefilterSelector;

        if (effectiveSelector && typeof root.querySelectorAll === "function") {
          if (helper.matchesSelector(root, effectiveSelector) && helper.matchesSelector(root, prefilterSelector)) {
            if (!visit(root)) return false;
          }

          let nodes = [];
          try {
            nodes = root.querySelectorAll(effectiveSelector);
          } catch (_error) {
            nodes = [];
          }

          for (const node of nodes) {
            if (!helper.matchesSelector(node, prefilterSelector)) continue;
            if (!visit(node)) return false;
          }
          continue;
        }

        if (!selector && !prefilterSelector) {
          if (!visit(root)) return false;
        } else if (helper.matchesSelector(root, selector) && helper.matchesSelector(root, prefilterSelector)) {
          if (!visit(root)) return false;
        }

        const rootDocument = root.ownerDocument || document;
        if (!rootDocument || typeof rootDocument.createTreeWalker !== "function") continue;

        const walker = rootDocument.createTreeWalker(root, NodeFilter.SHOW_ELEMENT);
        let node = walker.nextNode();

        while (node) {
          if (helper.matchesSelector(node, selector) && helper.matchesSelector(node, prefilterSelector)) {
            if (!visit(node)) return false;
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
        const view = (current.ownerDocument && current.ownerDocument.defaultView) || window;
        const style = view.getComputedStyle(current);
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
      const expectedValue = helper.normalize(expected && expected.value ? expected.value : "", normalizeWs);

      return (actual) => {
        const normalizedActual = helper.normalize(actual, normalizeWs);

        if (expectedRegex) {
          return expectedRegex.test(normalizedActual);
        }

        return exact ? normalizedActual === expectedValue : normalizedActual.includes(expectedValue);
      };
    };

    helper.altSourceForElement = (element, cache) => {
      if (cache && cache.has(element)) {
        return cache.get(element);
      }

      const direct = element.getAttribute("alt");
      if (direct) {
        if (cache) cache.set(element, direct);
        return direct;
      }

      let source = "";

      if (typeof element.querySelector === "function") {
        const nested = element.querySelector("img[alt],input[type='image'][alt],[role='img'][alt]");
        source = nested ? (nested.getAttribute("alt") || "") : "";
      }

      if (cache) cache.set(element, source);
      return source;
    };

    helper.valueForMatch = (element, hidden, matchBy, normalizeWs, context) => {
      const tag = (element.tagName || "").toLowerCase();
      if (tag === "script" || tag === "style" || tag === "noscript") return null;

      switch (matchBy) {
        case "label":
          if (tag !== "label") return null;
          break;
        case "link":
          if (tag !== "a" || !element.hasAttribute("href")) return null;
          break;
        case "button":
          if (tag !== "button") return null;
          break;
        case "placeholder":
          if (!(tag === "input" || tag === "textarea" || tag === "select")) return null;
          break;
        case "title":
          break;
        case "alt":
          break;
        case "testid":
          break;
        default:
          break;
      }

      let source = "";

      switch (matchBy) {
        case "label":
        case "link":
        case "button":
        case "text":
          source = hidden ? element.textContent : element.innerText || element.textContent;
          break;
        case "placeholder":
          source = element.getAttribute("placeholder") || "";
          break;
        case "title":
          source = element.getAttribute("title") || "";
          break;
        case "testid":
          source = element.getAttribute("data-testid") || "";
          break;
        case "alt": {
          source = helper.altSourceForElement(element, context && context.altCache);
          break;
        }
        default:
          source = hidden ? element.textContent : element.innerText || element.textContent;
          break;
      }

      const value = helper.normalize(source, normalizeWs);
      return value || null;
    };

    helper.numberOrNull = (value) => {
      if (value === null || value === undefined) return null;
      const number = Number(value);
      if (!Number.isFinite(number) || number < 0) return null;
      return Math.floor(number);
    };

    helper.matchFilters = (options) => {
      const betweenMin = helper.numberOrNull(options.betweenMin);
      const betweenMax = helper.numberOrNull(options.betweenMax);

      return {
        count: helper.numberOrNull(options.count),
        min: helper.numberOrNull(options.min),
        max: helper.numberOrNull(options.max),
        betweenMin,
        betweenMax
      };
    };

    helper.hasMatchFilters = (filters) => {
      return (
        filters.count !== null ||
        filters.min !== null ||
        filters.max !== null ||
        (filters.betweenMin !== null && filters.betweenMax !== null)
      );
    };

    helper.countSatisfiesFilters = (count, filters) => {
      if (filters.count !== null && count !== filters.count) return false;
      if (filters.min !== null && count < filters.min) return false;
      if (filters.max !== null && count > filters.max) return false;

      if (filters.betweenMin !== null && filters.betweenMax !== null) {
        if (count < filters.betweenMin || count > filters.betweenMax) return false;
      }

      return true;
    };

    helper.assertionSatisfied = (mode, matchCount, filters) => {
      if (helper.hasMatchFilters(filters)) {
        const satisfies = helper.countSatisfiesFilters(matchCount, filters);
        return mode === "assert" ? satisfies : !satisfies;
      }

      return mode === "assert" ? matchCount > 0 : matchCount === 0;
    };

    helper.assertionReason = (mode, matchCount, filters, ok) => {
      if (ok) return "matched";

      if (helper.hasMatchFilters(filters)) {
        if (mode === "assert") {
          return `expected count constraints to match, got ${matchCount}`;
        }

        return `unexpected matching text count satisfied constraints (${matchCount})`;
      }

      return mode === "assert" ? "expected text not found" : "unexpected matching text found";
    };

    helper.textQuick = (options) => {
      const visibility = options.visibility || "visible";
      const mode = options.mode || "assert";
      const normalizeWs = options.normalizeWs !== false;
      const exact = options.exact === true;
      const selector = options.selector || null;
      const matchBy = options.matchBy || "text";
      const prefilterSelector = helper.selectorForMatchBy(matchBy);
      const needsHiddenState = visibility !== "all" || helper.isTextLikeMatchBy(matchBy);
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);
      const filters = helper.matchFilters(options);
      const hasFilters = helper.hasMatchFilters(filters);
      const context = { altCache: new Map() };
      let matchCount = 0;

      helper.eachCandidateElement(roots, selector, prefilterSelector, (element) => {
        const hidden = needsHiddenState ? helper.isHidden(element) : false;
        if (visibility !== "all" && !helper.selectedVisibility(visibility, hidden)) return true;

        const value = helper.valueForMatch(element, hidden, matchBy, normalizeWs, context);
        if (!value) return true;

        if (matchText(value)) {
          matchCount += 1;

          if (!hasFilters) {
            return false;
          }
        }

        return true;
      });

      const ok = helper.assertionSatisfied(mode, matchCount, filters);
      const reason = helper.assertionReason(mode, matchCount, filters, ok);

      return {
        ok,
        reason,
        matchCount,
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
      const matchBy = options.matchBy || "text";
      const prefilterSelector = helper.selectorForMatchBy(matchBy);
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);
      const filters = helper.matchFilters(options);
      const context = { altCache: new Map() };
      const visibleTexts = [];
      const hiddenTexts = [];
      const visibleSet = new Set();
      const hiddenSet = new Set();

      helper.eachCandidateElement(roots, selector, prefilterSelector, (element) => {
        const hidden = helper.isHidden(element);
        const value = helper.valueForMatch(element, hidden, matchBy, normalizeWs, context);
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
      const ok = helper.assertionSatisfied(mode, matched.length, filters);
      const reason = helper.assertionReason(mode, matched.length, filters, ok);

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
        const observedRoots = helper.resolveRoots(options.scopeSelector || null);

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
          const observer = new MutationObserver(() => {
            dirty = true;
            scheduleCheck();
          });

          const roots = observedRoots.length > 0 ? observedRoots : [document.documentElement || document.body || document];

          for (const root of roots) {
            if (!root) continue;

            observer.observe(root, {
              subtree: true,
              childList: true,
              attributes: true,
              characterData: true
            });
          }

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
