defmodule Cerberus.Driver.Browser.ActionHelpers do
  @moduledoc false

  @preload_script """
  ;(() => {
    if (window.__cerberusAction && window.__cerberusAction.__version === 2) return;

    const helper = {};
    helper.__version = 2;

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

    helper.countSatisfiesFilters = (count, filters) => {
      if (filters.count !== null && count !== filters.count) return false;
      if (filters.min !== null && count < filters.min) return false;
      if (filters.max !== null && count > filters.max) return false;

      if (filters.betweenMin !== null && filters.betweenMax !== null) {
        if (count < filters.betweenMin || count > filters.betweenMax) return false;
      }

      return true;
    };

    helper.resolvePosition = (options) => {
      const candidates = [];

      if (options.first === true) candidates.push({ key: "first", value: true });
      if (options.last === true) candidates.push({ key: "last", value: true });
      if (options.nth !== null && options.nth !== undefined) candidates.push({ key: "nth", value: Number(options.nth) });
      if (options.index !== null && options.index !== undefined)
        candidates.push({ key: "index", value: Number(options.index) });

      if (candidates.length > 1) {
        return { error: "position options are mutually exclusive; use only one of :first, :last, :nth, or :index" };
      }

      if (candidates.length === 0) return { key: "none", value: 0 };
      return candidates[0];
    };

    helper.positionIndex = (matchCount, options) => {
      const position = helper.resolvePosition(options);
      if (position.error) return { error: position.error };

      switch (position.key) {
        case "first":
          return { index: 0 };
        case "last":
          return { index: matchCount - 1 };
        case "nth": {
          const nth = position.value;
          if (!Number.isInteger(nth) || nth <= 0) {
            return { error: ":nth must be a positive integer" };
          }

          const idx = nth - 1;
          if (idx < 0 || idx >= matchCount) {
            return { error: `nth=${nth} is out of bounds for ${matchCount} matched element(s)` };
          }

          return { index: idx };
        }
        case "index": {
          const idx = position.value;
          if (!Number.isInteger(idx) || idx < 0) {
            return { error: ":index must be a non-negative integer" };
          }

          if (idx >= matchCount) {
            return { error: `index=${idx} is out of bounds for ${matchCount} matched element(s)` };
          }

          return { index: idx };
        }
        default:
          return { index: 0 };
      }
    };

    helper.matchesStateFilters = (candidate, options) => {
      const stateKeys = ["checked", "disabled", "selected", "readonly"];

      for (const key of stateKeys) {
        if (typeof options[key] !== "boolean") continue;
        if ((candidate[key] === true) !== options[key]) return false;
      }

      return true;
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
        const selector = typeof scopeInput.selector === "string" && scopeInput.selector.trim() !== "" ? scopeInput.selector : null;

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

    helper.matchesSelector = (element, selector) => {
      if (!selector || typeof element.matches !== "function") return true;

      try {
        return element.matches(selector);
      } catch (_error) {
        return false;
      }
    };

    helper.altSourceForElement = (element, nestedSelector) => {
      const direct = element.getAttribute("alt");
      if (direct) return direct;

      if (typeof element.querySelector !== "function") return "";
      const nested = element.querySelector(nestedSelector);
      return nested ? (nested.getAttribute("alt") || "") : "";
    };

    helper.queryWithinRoots = (roots, querySelector, selector) => {
      const seen = new Set();
      const matches = [];

      const maybePush = (element) => {
        if (!element || seen.has(element)) return;
        if (!helper.matchesSelector(element, selector)) return;
        seen.add(element);
        matches.push(element);
      };

      for (const root of roots) {
        if (!root || typeof root.querySelectorAll !== "function") continue;

        if (helper.matchesSelector(root, querySelector)) {
          maybePush(root);
        }

        let nodes = [];
        try {
          nodes = root.querySelectorAll(querySelector);
        } catch (_error) {
          nodes = [];
        }

        for (const node of nodes) {
          maybePush(node);
        }
      }

      return matches;
    };

    helper.attachElement = (candidate, element) => {
      if (candidate && element) {
        Object.defineProperty(candidate, "__el", {
          value: element,
          enumerable: false,
          configurable: false,
          writable: false
        });
      }

      return candidate;
    };

    helper.clickCandidates = (roots, selector, kind) => {
      const links =
        kind === "button"
          ? []
          : helper.queryWithinRoots(roots, "a[href]", selector).map((element, index) =>
              helper.attachElement(
                {
                  kind: "link",
                  index,
                  text: helper.normalize(element.textContent, true),
                  title: element.getAttribute("title") || "",
                  alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt],[role='img'][alt]"),
                  testid: element.getAttribute("data-testid") || "",
                  href: element.getAttribute("href") || "",
                  resolvedHref: element.href || "",
                  checked: false,
                  disabled: false,
                  readonly: false,
                  selected: false
                },
                element
              )
            );

      const buttons =
        kind === "link"
          ? []
          : helper.queryWithinRoots(roots, "button", selector).map((element, index) =>
              helper.attachElement(
                {
                  kind: "button",
                  index,
                  text: helper.normalize(element.textContent, true),
                  title: element.getAttribute("title") || "",
                  alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt]"),
                  testid: element.getAttribute("data-testid") || "",
                  type: (element.getAttribute("type") || "submit").toLowerCase(),
                  checked: false,
                  disabled: element.disabled === true,
                  readonly: element.readOnly === true || element.hasAttribute("readonly"),
                  selected: false
                },
                element
              )
            );

      return links.concat(buttons);
    };

    helper.submitCandidates = (roots, selector) => {
      return helper
        .queryWithinRoots(roots, "button", selector)
        .filter((element) => {
          const type = (element.getAttribute("type") || "submit").toLowerCase();
          return type === "submit" || type === "";
        })
        .map((element, index) => {
          const type = (element.getAttribute("type") || "submit").toLowerCase();

          return helper.attachElement(
            {
              kind: "button",
              index,
              text: helper.normalize(element.textContent, true),
              title: element.getAttribute("title") || "",
              alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt]"),
              testid: element.getAttribute("data-testid") || "",
              type,
              checked: false,
              disabled: element.disabled === true,
              readonly: element.readOnly === true || element.hasAttribute("readonly"),
              selected: false
            },
            element
          );
        });
    };

    helper.labelsByFor = (roots) => {
      const labels = new Map();

      for (const label of helper.queryWithinRoots(roots, "label[for]", null)) {
        const id = label.getAttribute("for");
        if (id) labels.set(id, helper.normalize(label.textContent, true));
      }

      return labels;
    };

    helper.labelForControl = (labels, element) => {
      const byId = labels.get(element.id || "");
      if (byId) return byId;

      if (typeof element.closest === "function") {
        const wrappingLabel = element.closest("label");
        if (wrappingLabel) return helper.normalize(wrappingLabel.textContent, true);
      }

      return "";
    };

    helper.formCandidates = (roots, selector) => {
      const labels = helper.labelsByFor(roots);

      return helper
        .queryWithinRoots(roots, "input, textarea, select", selector)
        .filter((element) => {
          const tag = (element.tagName || "").toLowerCase();
          const rawType = (element.getAttribute("type") || "").toLowerCase();
          const type = tag === "select" ? (element.multiple ? "select-multiple" : "select-one") : rawType;

          return type !== "hidden" && type !== "submit" && type !== "button";
        })
        .map((element, index) => {
          const tag = (element.tagName || "").toLowerCase();
          const rawType = (element.getAttribute("type") || "").toLowerCase();
          const type = tag === "select" ? (element.multiple ? "select-multiple" : "select-one") : rawType;

          return helper.attachElement(
            {
              kind: "field",
              index,
              tag,
              type,
              label: helper.labelForControl(labels, element),
              placeholder: element.getAttribute("placeholder") || "",
              title: element.getAttribute("title") || "",
              testid: element.getAttribute("data-testid") || "",
              checked: element.checked === true,
              selected:
                tag === "select"
                  ? Array.from(element.options || []).some((option) => option.hasAttribute("selected"))
                  : element.checked === true,
              disabled: element.disabled === true,
              readonly: element.readOnly === true || element.hasAttribute("readonly")
            },
            element
          );
        });
    };

    helper.fileCandidates = (roots, selector) => {
      const labels = helper.labelsByFor(roots);

      return helper.queryWithinRoots(roots, "input[type='file']", selector).map((element, index) =>
        helper.attachElement(
          {
            kind: "field",
            index,
            tag: "input",
            type: "file",
            label: labels.get(element.id || "") || "",
            placeholder: element.getAttribute("placeholder") || "",
            title: element.getAttribute("title") || "",
            testid: element.getAttribute("data-testid") || "",
            checked: element.checked === true,
            selected: element.checked === true,
            disabled: element.disabled === true,
            readonly: element.readOnly === true || element.hasAttribute("readonly")
          },
          element
        )
      );
    };

    helper.matchValue = (candidate, op, matchBy) => {
      if (op === "click" || op === "submit") {
        switch (matchBy) {
          case "title":
            return candidate.title || "";
          case "alt":
            return candidate.alt || "";
          case "testid":
            return candidate.testid || "";
          default:
            return candidate.text || "";
        }
      }

      switch (matchBy) {
        case "placeholder":
          return candidate.placeholder || "";
        case "title":
          return candidate.title || "";
        case "testid":
          return candidate.testid || "";
        default:
          return candidate.label || "";
      }
    };

    helper.querySelectorForLocator = (locator) => {
      if (!locator || typeof locator !== "object") return "*";

      const opts = locator.opts && typeof locator.opts === "object" ? locator.opts : null;
      if (opts && typeof opts.selector === "string" && opts.selector.trim() !== "") {
        return opts.selector;
      }

      switch ((locator.kind || "").toLowerCase()) {
        case "css":
          return typeof locator.value === "string" && locator.value.trim() !== "" ? locator.value : "*";
        case "text":
          return "*";
        case "link":
          return "a[href]";
        case "button":
          return "button";
        case "label":
          return "label,input,textarea,select";
        case "placeholder":
          return "input[placeholder],textarea[placeholder],select[placeholder]";
        case "title":
          return "[title]";
        case "alt":
          return "[alt],img[alt],input[type='image'][alt],[role='img'][alt],button,a[href]";
        case "testid":
          return "[data-testid]";
        case "and":
        case "or":
          return "*";
        default:
          return "*";
      }
    };

    helper.candidateValueForKind = (candidate, kind, op) => {
      if (op === "click" || op === "submit") {
        switch (kind) {
          case "text":
            return candidate.text || "";
          case "link":
            return candidate.kind === "link" ? candidate.text || "" : null;
          case "button":
            return candidate.kind === "button" ? candidate.text || "" : null;
          case "title":
            return candidate.title || "";
          case "alt":
            return candidate.alt || "";
          case "testid":
            return candidate.testid || "";
          default:
            return null;
        }
      }

      switch (kind) {
        case "text":
        case "label":
          return candidate.label || "";
        case "placeholder":
          return candidate.placeholder || "";
        case "title":
          return candidate.title || "";
        case "testid":
          return candidate.testid || "";
        default:
          return null;
      }
    };

    helper.labelForElement = (element) => {
      if (!element) return "";

      try {
        if (element.labels && element.labels.length > 0) {
          const labelText = Array.from(element.labels)
            .map((label) => helper.normalize(label.textContent, true))
            .filter((value) => value !== "")
            .join(" ");

          if (labelText !== "") return labelText;
        }
      } catch (_error) {
        // ignored
      }

      if (typeof element.closest === "function") {
        const wrappingLabel = element.closest("label");
        if (wrappingLabel) return helper.normalize(wrappingLabel.textContent, true);
      }

      return "";
    };

    helper.candidateFromElement = (element) => {
      const tag = (element && element.tagName ? element.tagName : "").toLowerCase();
      const rawType = (element && typeof element.getAttribute === "function" ? element.getAttribute("type") : "") || "";
      const type = tag === "select" ? (element.multiple ? "select-multiple" : "select-one") : rawType.toLowerCase();

      return helper.attachElement(
        {
          kind: tag === "a" ? "link" : (tag === "button" ? "button" : "field"),
          index: -1,
          tag,
          type,
          text: helper.normalize(element.textContent, true),
          label: helper.labelForElement(element),
          placeholder: (element.getAttribute("placeholder") || ""),
          title: (element.getAttribute("title") || ""),
          alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt],[role='img'][alt]"),
          testid: (element.getAttribute("data-testid") || ""),
          checked: element.checked === true,
          selected:
            tag === "select"
              ? Array.from(element.options || []).some((option) => option.hasAttribute("selected"))
              : element.checked === true,
          disabled: element.disabled === true,
          readonly: element.readOnly === true || element.hasAttribute("readonly")
        },
        element
      );
    };

    helper.matchesLocatorCommonOpts = (candidate, opts, op) => {
      if (!opts || typeof opts !== "object") return true;

      if (!helper.matchesStateFilters(candidate, opts)) return false;

      if (typeof opts.selector === "string" && opts.selector.trim() !== "") {
        if (!helper.matchesSelector(candidate.__el, opts.selector)) return false;
      }

      if (opts.has) {
        if (!helper.elementHasLocator(candidate.__el, opts.has, op)) return false;
      }

      return true;
    };

    helper.matchesLocator = (candidate, locator, op) => {
      if (!locator || typeof locator !== "object") return false;

      const kind = (locator.kind || "").toLowerCase();

      if (kind === "and" || kind === "or") {
        const members = Array.isArray(locator.members) ? locator.members : [];
        if (members.length === 0) return false;

        const memberMatch =
          kind === "and"
            ? members.every((member) => helper.matchesLocator(candidate, member, op))
            : members.some((member) => helper.matchesLocator(candidate, member, op));

        return memberMatch && helper.matchesLocatorCommonOpts(candidate, locator.opts, op);
      }

      if (kind === "css") {
        if (!candidate.__el || typeof locator.value !== "string") return false;
        if (!helper.matchesSelector(candidate.__el, locator.value)) return false;
        return helper.matchesLocatorCommonOpts(candidate, locator.opts, op);
      }

      const value = helper.candidateValueForKind(candidate, kind, op);
      if (typeof value !== "string") return false;

      const locatorOpts = locator.opts && typeof locator.opts === "object" ? locator.opts : {};
      const exact = locatorOpts.exact === true;
      const normalizeWs = locatorOpts.normalizeWs !== false;
      const matchText = helper.buildTextMatcher(locator.expected, exact, normalizeWs);

      if (!matchText(value)) return false;
      return helper.matchesLocatorCommonOpts(candidate, locator.opts, op);
    };

    helper.elementHasLocator = (element, locator, op) => {
      if (!element || !locator) return false;

      const selector = helper.querySelectorForLocator(locator);
      let nodes = [];

      try {
        nodes = Array.from(element.querySelectorAll(selector));
      } catch (_error) {
        return false;
      }

      return nodes.some((node) => {
        const nestedCandidate = helper.candidateFromElement(node);
        return helper.matchesLocator(nestedCandidate, locator, op);
      });
    };

    helper.resolveCandidates = (options, roots) => {
      const op = options.op;
      const selector = options.selector || null;

      if (op === "click") {
        const kind = options.kind || "any";
        return helper.clickCandidates(roots, selector, kind);
      }

      if (op === "submit") {
        return helper.submitCandidates(roots, selector);
      }

      if (op === "upload") {
        return helper.fileCandidates(roots, selector);
      }

      return helper.formCandidates(roots, selector);
    };

    helper.resolveOnce = (options) => {
      const op = options.op || "click";
      const matchBy = options.matchBy || (op === "click" || op === "submit" ? "text" : "label");
      const normalizeWs = options.normalizeWs !== false;
      const exact = options.exact === true;
      const filters = helper.matchFilters(options);
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const candidates = helper.resolveCandidates(options, roots);
      const locator = options.locator && typeof options.locator === "object" ? options.locator : null;
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);

      const matched = candidates.filter((candidate) => {
        if (!helper.matchesStateFilters(candidate, options)) return false;

        if (locator) {
          return helper.matchesLocator(candidate, locator, op);
        }

        const value = helper.matchValue(candidate, op, matchBy);
        return matchText(value);
      });

      if (!helper.countSatisfiesFilters(matched.length, filters)) {
        return {
          ok: false,
          reason: "matched element count did not satisfy count constraints",
          matchCount: matched.length,
          path: window.location.pathname + window.location.search
        };
      }

      if (matched.length === 0) {
        return {
          ok: false,
          reason: "no elements matched locator",
          matchCount: 0,
          path: window.location.pathname + window.location.search
        };
      }

      const position = helper.positionIndex(matched.length, options);
      if (position.error) {
        return {
          ok: false,
          reason: position.error,
          matchCount: matched.length,
          path: window.location.pathname + window.location.search
        };
      }

      return {
        ok: true,
        target: matched[position.index],
        matchCount: matched.length,
        path: window.location.pathname + window.location.search
      };
    };

    helper.resolve = (options) => {
      const timeoutMs = Math.max(0, Number(options.timeoutMs || 0));
      const pollMs = Math.max(50, Number(options.pollMs || 100));
      const deadline = Date.now() + timeoutMs;
      const initial = helper.resolveOnce(options);

      if (initial.ok || timeoutMs <= 0) {
        return Promise.resolve(JSON.stringify(initial));
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
            const attempt = helper.resolveOnce(options);
            if (attempt.ok) finish(attempt);
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

          const observedRoots = helper.resolveRoots(options.scopeSelector || null);
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
            finish(helper.resolveOnce(options));
            return;
          }

          dirty = true;
          scheduleCheck();
        }, pollMs);
        cleanupFns.push(() => clearInterval(intervalRef));

        const timeoutRef = setTimeout(() => finish(helper.resolveOnce(options)), timeoutMs);
        cleanupFns.push(() => clearTimeout(timeoutRef));
      });
    };

    window.__cerberusAction = helper;
  })();
  """

  @spec preload_script() :: String.t()
  def preload_script, do: @preload_script
end
