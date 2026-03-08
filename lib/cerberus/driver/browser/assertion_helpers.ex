defmodule Cerberus.Driver.Browser.AssertionHelpers do
  @moduledoc false

  @preload_script """
  ;(() => {
    if (window.__cerberusAssert && window.__cerberusAssert.__version === 10) return;

    const helper = {};
    helper.__version = 10;
    helper.now = () =>
      typeof performance !== "undefined" && typeof performance.now === "function"
        ? performance.now()
        : Date.now();

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

    helper.buttonSelector = "button,input[type='submit'],input[type='button'],input[type='image']";

    helper.isButtonLikeElement = (element) => {
      const tag = (element.tagName || "").toLowerCase();
      if (tag === "button") return true;
      if (tag !== "input") return false;
      const type = (element.getAttribute("type") || "").toLowerCase();
      return type === "submit" || type === "button" || type === "image";
    };

    helper.buttonText = (element, hidden) => {
      const tag = (element.tagName || "").toLowerCase();

      if (tag === "input") {
        return element.getAttribute("value") || "";
      }

      return hidden ? element.textContent : element.innerText || element.textContent;
    };

    helper.labelMapForDocument = (doc, cache) => {
      if (!doc) return new Map();
      if (cache && cache.has(doc)) return cache.get(doc);

      const labels = new Map();

      let nodes = [];
      try {
        nodes = Array.from(doc.querySelectorAll("label[for]"));
      } catch (_error) {
        nodes = [];
      }

      for (const label of nodes) {
        const id = label.getAttribute("for");
        if (!id) continue;
        labels.set(id, label.textContent || "");
      }

      if (cache) cache.set(doc, labels);
      return labels;
    };

    helper.referencedText = (element, hidden) => {
      if (!element || typeof element.getAttribute !== "function") return "";

      const ids = (element.getAttribute("aria-labelledby") || "").trim();
      if (ids === "") return "";

      const doc = element.ownerDocument || document;

      return helper.normalize(
        ids
          .split(/\s+/)
          .map((id) => {
            if (!doc || typeof doc.getElementById !== "function") return "";
            const ref = doc.getElementById(id);
            return ref ? (hidden ? ref.textContent : ref.innerText || ref.textContent || "") : "";
          })
          .filter((value) => value !== "")
          .join(" "),
        true
      );
    };

    helper.labelForControl = (element, hidden, context) => {
      const doc = element.ownerDocument || document;
      const labels = helper.labelMapForDocument(doc, context && context.labelCache);
      return helper.labelSourcesForControl(element, hidden, labels)[0] || "";
    };

    helper.labelSourcesForControl = (element, hidden, labels = null) => {
      if (!element) return [];

      const sources = [];
      const byId = labels instanceof Map ? labels.get(element.id || "") : "";
      if (byId) sources.push(helper.normalize(byId, true));

      try {
        if (element.labels && element.labels.length > 0) {
          const labelText = Array.from(element.labels)
            .map((label) => helper.normalize(hidden ? label.textContent : label.innerText || label.textContent, true))
            .filter((value) => value !== "")
            .join(" ");

          if (labelText !== "") sources.push(labelText);
        }
      } catch (_error) {
        // ignored
      }

      if (typeof element.closest === "function") {
        const wrappingLabel = element.closest("label");
        if (wrappingLabel) {
          sources.push(helper.normalize(hidden ? wrappingLabel.textContent : wrappingLabel.innerText || wrappingLabel.textContent, true));
        }
      }

      const labelledby = helper.referencedText(element, hidden);
      if (labelledby) sources.push(labelledby);

      const ariaLabel = helper.normalize(element.getAttribute("aria-label") || "", true);
      if (ariaLabel) sources.push(ariaLabel);

      return Array.from(new Set(sources.filter((value) => value !== "")));
    };

    helper.accessibleNameSources = (element, hidden, kind, context) => {
      if (!element) return [];

      const tag = (element.tagName || "").toLowerCase();
      const sources = [helper.referencedText(element, hidden), helper.normalize(element.getAttribute("aria-label") || "", true)];

      switch (kind) {
        case "button":
          if (!helper.isButtonLikeElement(element)) return [];
          sources.push(helper.normalize(helper.buttonText(element, hidden), true));
          break;
        case "link":
          if (tag !== "a" || !element.hasAttribute("href")) return [];
          sources.push(helper.normalize(hidden ? element.textContent : element.innerText || element.textContent, true));
          break;
        case "heading":
          if (!/^h[1-6]$/.test(tag) && element.getAttribute("role") !== "heading") return [];
          sources.push(helper.normalize(hidden ? element.textContent : element.innerText || element.textContent, true));
          break;
        case "img":
          sources.push(helper.normalize(helper.altSourceForElement(element, context && context.altCache), true));
          break;
        default:
          return [];
      }

      return Array.from(new Set(sources.filter((value) => value !== "")));
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
          if (!helper.isButtonLikeElement(element)) return null;
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
        case "text":
          source = hidden ? element.textContent : element.innerText || element.textContent;
          break;
        case "button":
          source = helper.buttonText(element, hidden);
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
      const matchBy = options.matchBy || "text";
      const prefilterSelector = helper.selectorForMatchBy(matchBy);
      const needsHiddenState = visibility !== "all" || helper.isTextLikeMatchBy(matchBy);
      const roots = helper.resolveRoots(options.scopeSelector || null);
      const matchText = helper.buildTextMatcher(options.expected, exact, normalizeWs);
      const filters = helper.matchFilters(options);
      const hasFilters = helper.hasMatchFilters(filters);
      const context = { altCache: new Map() };
      let matchCount = 0;

      helper.eachCandidateElement(roots, null, prefilterSelector, (element) => {
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

      helper.eachCandidateElement(roots, null, prefilterSelector, (element) => {
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

    helper.roleToKind = (roleName) => {
      switch (String(roleName || "").toLowerCase()) {
        case "button":
        case "menuitem":
        case "tab":
          return "button";
        case "link":
          return "link";
        case "textbox":
        case "searchbox":
        case "combobox":
        case "listbox":
        case "spinbutton":
        case "checkbox":
        case "radio":
        case "switch":
          return "label";
        case "img":
          return "alt";
        case "heading":
          return "text";
        default:
          return null;
      }
    };

    helper.roleSelector = (roleName) => {
      switch (String(roleName || "").toLowerCase()) {
        case "button":
        case "menuitem":
        case "tab":
          return helper.buttonSelector;
        case "link":
          return "a[href]";
        case "textbox":
        case "searchbox":
        case "combobox":
        case "listbox":
        case "spinbutton":
        case "checkbox":
        case "radio":
        case "switch":
          return "input,textarea,select";
        case "heading":
          return "h1,h2,h3,h4,h5,h6,[role='heading']";
        case "img":
          return "img,[role='img'],input[type='image'],button,a[href]";
        default:
          return "*";
      }
    };

    helper.locatorKind = (locator) => {
      if (!locator || typeof locator !== "object") return null;

      const rawKind = String(locator.kind || "").toLowerCase();
      if (rawKind !== "role") return rawKind;

      const opts = locator.opts && typeof locator.opts === "object" ? locator.opts : {};
      return helper.roleToKind(opts.role);
    };

    helper.locatorOpts = (locator) => {
      if (!locator || typeof locator !== "object") return {};
      return locator.opts && typeof locator.opts === "object" ? locator.opts : {};
    };

    helper.locatorWithoutFrom = (locator) => {
      if (!locator || typeof locator !== "object") return locator;

      const opts = helper.locatorOpts(locator);
      if (!opts.from) return locator;

      const nextOpts = { ...opts };
      delete nextOpts.from;

      return { ...locator, opts: nextOpts };
    };

    helper.locatorQuerySelector = (locator) => {
      if (!locator || typeof locator !== "object") return "*";

      const rawKind = String(locator.kind || "").toLowerCase();
      if (rawKind === "role") {
        const opts = helper.locatorOpts(locator);
        return helper.roleSelector(opts.role);
      }

      const kind = helper.locatorKind(locator);

      switch (kind) {
        case "css":
          return typeof locator.value === "string" && locator.value.trim() !== "" ? locator.value : "*";
        case "text":
          return "*";
        case "and": {
          const members = Array.isArray(locator.members) ? locator.members : [];

          for (const member of members) {
            const selector = helper.locatorQuerySelector(member);
            if (selector && selector !== "*") return selector;
          }

          return "*";
        }
        case "not": {
          const members = Array.isArray(locator.members) ? locator.members : [];

          if (members.length === 1) {
            const selector = helper.locatorQuerySelector(members[0]);
            if (selector && selector !== "*") return selector;
          }

          return "*";
        }
        case "or":
          return "*";
        case "link":
          return "a[href]";
        case "button":
          return helper.buttonSelector;
        case "label":
          return "input,textarea,select";
        case "placeholder":
          return "input[placeholder],textarea[placeholder],select[placeholder]";
        case "title":
          return "[title]";
        case "alt":
          return "[alt],img[alt],input[type='image'][alt],[role='img'][alt],button,a[href]";
        case "testid":
          return "[data-testid]";
        case "scope": {
          const members = Array.isArray(locator.members) ? locator.members : [];

          if (members.length === 0) return "*";
          return helper.locatorQuerySelector(members[members.length - 1]);
        }
        default:
          return "*";
      }
    };

    helper.stateElementForLocator = (element) => {
      if (!(element instanceof Element)) return element;

      const tag = (element.tagName || "").toLowerCase();
      if (tag !== "label") return element;

      if (element.control instanceof Element) return element.control;

      const forId = element.getAttribute("for");
      if (typeof forId === "string" && forId.trim() !== "") {
        const byId = element.ownerDocument && element.ownerDocument.getElementById(forId);
        if (byId instanceof Element) return byId;
      }

      const nested = element.querySelector("input,textarea,select,option,button");
      if (nested instanceof Element) return nested;

      return element;
    };

    helper.matchesLocatorStateFilters = (element, opts) => {
      if (!opts || typeof opts !== "object") return true;

      const stateElement = helper.stateElementForLocator(element);
      const tag = (stateElement.tagName || "").toLowerCase();
      const checked = stateElement.checked === true;
      const selected =
        tag === "option"
          ? stateElement.selected === true
          : tag === "select"
            ? Array.from(stateElement.options || []).some((option) => option.selected === true)
            : checked;
      const disabled = stateElement.disabled === true;
      const readonly = stateElement.readOnly === true || stateElement.hasAttribute("readonly");
      const visible = !helper.isHidden(element);

      if (typeof opts.checked === "boolean" && checked !== opts.checked) return false;
      if (typeof opts.selected === "boolean" && selected !== opts.selected) return false;
      if (typeof opts.disabled === "boolean" && disabled !== opts.disabled) return false;
      if (typeof opts.readonly === "boolean" && readonly !== opts.readonly) return false;
      if (typeof opts.visible === "boolean" && visible !== opts.visible) return false;

      return true;
    };

    helper.locatorValuesForMatch = (element, hidden, locator, context) => {
      const rawKind = String((locator && locator.kind) || "").toLowerCase();
      const kind = helper.locatorKind(locator);
      const tag = (element.tagName || "").toLowerCase();
      if (tag === "script" || tag === "style" || tag === "noscript") return null;

      if (rawKind === "role") {
        const opts = helper.locatorOpts(locator);
        const role = String(opts.role || "").toLowerCase();

        switch (role) {
          case "button":
          case "menuitem":
          case "tab":
            return helper.accessibleNameSources(element, hidden, "button", context);
          case "link":
            return helper.accessibleNameSources(element, hidden, "link", context);
          case "textbox":
          case "searchbox":
          case "combobox":
          case "listbox":
          case "spinbutton":
          case "checkbox":
          case "radio":
          case "switch":
            return helper.labelSourcesForControl(element, hidden);
          case "heading":
            return helper.accessibleNameSources(element, hidden, "heading", context);
          case "img":
            return helper.accessibleNameSources(element, hidden, "img", context);
          default:
            return [];
        }
      }

      switch (kind) {
        case "text":
          return [hidden ? element.textContent : element.innerText || element.textContent];
        case "link":
          if (tag !== "a" || !element.hasAttribute("href")) return [];
          return [hidden ? element.textContent : element.innerText || element.textContent];
        case "button":
          if (!helper.isButtonLikeElement(element)) return [];
          return [helper.buttonText(element, hidden)];
        case "label":
          if (tag === "input" || tag === "textarea" || tag === "select") {
            return helper.labelSourcesForControl(element, hidden);
          }
          return [];
        case "placeholder":
          if (!(tag === "input" || tag === "textarea" || tag === "select")) return [];
          return [element.getAttribute("placeholder") || ""];
        case "title":
          return [element.getAttribute("title") || ""];
        case "testid":
          return [element.getAttribute("data-testid") || ""];
        case "alt":
          return [helper.altSourceForElement(element, context && context.altCache)];
        default:
          return [];
      }
    };

    helper.locatorObservationValue = (element, hidden, locator, context) => {
      const values = helper.locatorValuesForMatch(element, hidden, locator, context) || [];
      const value = values.find((entry) => typeof entry === "string" && entry !== "") || "";
      const fallback = hidden ? element.textContent : element.innerText || element.textContent;
      return helper.normalize(value || fallback || "", true);
    };

    helper.matchesLocatorCommonOpts = (element, locator, context) => {
      const opts = helper.locatorOpts(locator);

      if (!helper.matchesLocatorStateFilters(element, opts)) return false;

      if (opts.has && !helper.elementHasLocator(element, opts.has, context)) return false;

      if (opts.has_not && helper.elementHasLocator(element, opts.has_not, context)) return false;

      return true;
    };

    helper.matchesLocator = (element, locator, hidden, context) => {
      if (!locator || typeof locator !== "object") return false;

      const kind = helper.locatorKind(locator);
      if (!kind) return false;

      if (kind === "not") {
        const members = Array.isArray(locator.members) ? locator.members : [];
        if (members.length !== 1) return false;

        return !helper.matchesLocator(element, members[0], hidden, context) && helper.matchesLocatorCommonOpts(element, locator, context);
      }

      if (kind === "scope") {
        const members = Array.isArray(locator.members) ? locator.members : [];

        return helper.scopeMembersMatch(element, hidden, members, context) && helper.matchesLocatorCommonOpts(element, locator, context);
      }

      const cssAndText = helper.cssAndTextMembers(locator);
      if (cssAndText) {
        if (!helper.matchesSelector(element, cssAndText.cssMember.value)) return false;

        const locatorOpts = helper.locatorOpts(cssAndText.textMember);
        const exact = locatorOpts.exact === true;
        const normalizeWs = locatorOpts.normalizeWs !== false;
        const matchText = helper.buildTextMatcher(cssAndText.textMember.expected, exact, normalizeWs);
        const textValue = hidden ? element.textContent : element.innerText || element.textContent;
        if (!matchText(textValue || "")) return false;

        return helper.matchesLocatorCommonOpts(element, locator, context);
      }

      if (kind === "and" || kind === "or") {
        const members = Array.isArray(locator.members) ? locator.members : [];
        if (members.length === 0) return false;

        const memberMatch =
          kind === "and"
            ? members.every((member) => helper.matchesLocator(element, member, hidden, context))
            : members.some((member) => helper.matchesLocator(element, member, hidden, context));

        return memberMatch && helper.matchesLocatorCommonOpts(element, locator, context);
      }

      if (kind === "css") {
        if (typeof locator.value !== "string") return false;
        if (!helper.matchesSelector(element, locator.value)) return false;
        return helper.matchesLocatorCommonOpts(element, locator, context);
      }

      const locatorOpts = helper.locatorOpts(locator);
      const exact = locatorOpts.exact === true;
      const normalizeWs = locatorOpts.normalizeWs !== false;
      const matchText = helper.buildTextMatcher(locator.expected, exact, normalizeWs);

      const values = helper.locatorValuesForMatch(element, hidden, locator, context) || [];
      if (!values.some((value) => typeof value === "string" && matchText(value))) return false;
      return helper.matchesLocatorCommonOpts(element, locator, context);
    };

    helper.elementHasLocator = (element, locator, context) => {
      if (!element || !locator) return false;

      const nestedLocator = helper.locatorWithoutFrom(locator);
      const selector = helper.locatorQuerySelector(nestedLocator);
      let nodes = [];

      try {
        nodes = Array.from(element.querySelectorAll(selector));
      } catch (_error) {
        return false;
      }

      return nodes.some((node) => {
        const hidden = helper.isHidden(node);
        return helper.matchesLocator(node, nestedLocator, hidden, context);
      });
    };

    helper.containsNodeOrSame = (container, node) => {
      if (!container || !node) return false;
      return container === node || (typeof container.contains === "function" && container.contains(node));
    };

    helper.strictDescendant = (container, node) => {
      if (!container || !node) return false;
      return container !== node && helper.containsNodeOrSame(container, node);
    };

    helper.scopeMembersMatch = (element, hidden, members, context) => {
      if (!element || !Array.isArray(members) || members.length < 2) return false;

      const targetLocator = members[members.length - 1];
      if (!helper.matchesLocator(element, targetLocator, hidden, context)) return false;

      const scopeMembers = members.slice(0, -1);
      const scopeLocator =
        scopeMembers.length === 1
          ? scopeMembers[0]
          : { kind: "scope", members: scopeMembers, opts: {} };

      const scopeSelector = helper.locatorQuerySelector(scopeLocator);
      const doc = element.ownerDocument || document;
      if (!doc || typeof doc.querySelectorAll !== "function") return false;

      let scopeNodes = [];

      try {
        scopeNodes = Array.from(doc.querySelectorAll(scopeSelector));
      } catch (_error) {
        return false;
      }

      return scopeNodes.some((scopeNode) => {
        if (!helper.strictDescendant(scopeNode, element)) return false;

        const scopeHidden = helper.isHidden(scopeNode);
        return helper.matchesLocator(scopeNode, scopeLocator, scopeHidden, context);
      });
    };

    helper.cssAndTextMembers = (locator) => {
      if (!locator || helper.locatorKind(locator) !== "and") return null;
      const members = Array.isArray(locator.members) ? locator.members : [];
      if (members.length !== 2) return null;

      const cssMember = members.find((member) => helper.locatorKind(member) === "css");
      const textMember = members.find((member) => helper.locatorKind(member) === "text");

      if (!cssMember || !textMember || typeof cssMember.value !== "string") return null;
      return { cssMember, textMember };
    };

    helper.scopeCandidateIsClosestForFrom = (candidate, candidates, fromNode) => {
      return candidates.every((other) => {
        if (other.element === candidate.element) return true;
        if (!helper.containsNodeOrSame(other.element, fromNode)) return true;
        return !helper.containsNodeOrSame(candidate.element, other.element);
      });
    };

    helper.closestScopeCandidateForAnyFrom = (candidate, candidates, fromCandidates) => {
      return fromCandidates.some((fromEntry) => {
        const fromNode = fromEntry.element;

        return (
          helper.containsNodeOrSame(candidate.element, fromNode) &&
          helper.scopeCandidateIsClosestForFrom(candidate, candidates, fromNode)
        );
      });
    };

    helper.collectLocatorMatches = (options) => {
      const jsTiming = {};
      const rootsStartedAt = helper.now();
      const roots = helper.resolveRoots(options.scopeSelector || null);
      jsTiming.locatorResolveRootsMs = helper.now() - rootsStartedAt;
      const locator = options.locator && typeof options.locator === "object" ? options.locator : null;
      if (!locator) return { matches: [], jsTiming };

      const locatorWithoutFrom = helper.locatorWithoutFrom(locator);
      const fromLocator = helper.locatorOpts(locator).from || null;
      const visibility = options.visibility || "visible";
      const selector = helper.locatorQuerySelector(locatorWithoutFrom);
      const context = { altCache: new Map(), labelCache: new WeakMap() };
      const candidates = [];

      const collectStartedAt = helper.now();
      helper.eachCandidateElement(roots, selector, null, (element) => {
        const hidden = helper.isHidden(element);
        if (visibility !== "all" && !helper.selectedVisibility(visibility, hidden)) return true;
        if (!helper.matchesLocator(element, locatorWithoutFrom, hidden, context)) return true;

        candidates.push({ element, hidden });
        return true;
      });
      jsTiming.locatorCollectCandidatesMs = helper.now() - collectStartedAt;

      if (!fromLocator) return { matches: candidates, jsTiming };

      const fromCandidates = [];
      const fromSelector = helper.locatorQuerySelector(fromLocator);

      const fromStartedAt = helper.now();
      helper.eachCandidateElement(roots, fromSelector, null, (element) => {
        const hidden = helper.isHidden(element);
        if (!helper.matchesLocator(element, fromLocator, hidden, context)) return true;
        fromCandidates.push({ element, hidden });
        return true;
      });
      jsTiming.locatorFromCandidatesMs = helper.now() - fromStartedAt;

      const filterStartedAt = helper.now();
      const matches = candidates.filter((candidate) => helper.closestScopeCandidateForAnyFrom(candidate, candidates, fromCandidates));
      jsTiming.locatorFromFilterMs = helper.now() - filterStartedAt;
      return { matches, jsTiming };
    };

    helper.findFirstLocatorMatch = (options) => {
      const jsTiming = {};
      const rootsStartedAt = helper.now();
      const roots = helper.resolveRoots(options.scopeSelector || null);
      jsTiming.locatorResolveRootsMs = helper.now() - rootsStartedAt;
      const locator = options.locator && typeof options.locator === "object" ? options.locator : null;
      if (!locator) return { match: null, jsTiming };

      const locatorWithoutFrom = helper.locatorWithoutFrom(locator);
      const fromLocator = helper.locatorOpts(locator).from || null;
      if (fromLocator) return null;

      const visibility = options.visibility || "visible";
      const selector = helper.locatorQuerySelector(locatorWithoutFrom);
      const context = { altCache: new Map(), labelCache: new WeakMap() };
      let match = null;

      const collectStartedAt = helper.now();
      helper.eachCandidateElement(roots, selector, null, (element) => {
        const hidden = helper.isHidden(element);
        if (visibility !== "all" && !helper.selectedVisibility(visibility, hidden)) return true;
        if (!helper.matchesLocator(element, locatorWithoutFrom, hidden, context)) return true;
        match = { element, hidden };
        return false;
      });
      jsTiming.locatorCollectCandidatesMs = helper.now() - collectStartedAt;

      return { match, jsTiming };
    };

    helper.locatorQuick = (options) => {
      const mode = options.mode || "assert";
      const filters = helper.matchFilters(options);
      const noCountFilters = !helper.hasMatchFilters(filters);

      if (mode === "assert" && noCountFilters) {
        const firstMatch = helper.findFirstLocatorMatch(options);

        if (firstMatch) {
          const ok = !!firstMatch.match;

          return {
            ok,
            reason: helper.assertionReason(mode, ok ? 1 : 0, filters, ok),
            matchCount: ok ? 1 : 0,
            path: window.location.pathname + window.location.search,
            title: document.title || "",
            jsTiming: firstMatch.jsTiming
          };
        }
      }

      const { matches, jsTiming } = helper.collectLocatorMatches(options);
      const matchCount = matches.length;
      const ok = helper.assertionSatisfied(mode, matchCount, filters);
      const reason = helper.assertionReason(mode, matchCount, filters, ok);

      return {
        ok,
        reason,
        matchCount,
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        jsTiming
      };
    };

    helper.locatorDiagnostics = (options) => {
      const mode = options.mode || "assert";
      const filters = helper.matchFilters(options);
      const locator = options.locator && typeof options.locator === "object" ? options.locator : null;
      const locatorWithoutFrom = locator ? helper.locatorWithoutFrom(locator) : null;
      const context = { altCache: new Map(), labelCache: new WeakMap() };
      const { matches, jsTiming } = helper.collectLocatorMatches(options);
      const observationStartedAt = helper.now();
      const values = matches
        .map((entry) => helper.locatorObservationValue(entry.element, entry.hidden, locatorWithoutFrom, context))
        .filter((value) => value !== "");
      jsTiming.locatorObservationMs = helper.now() - observationStartedAt;
      const matchCount = matches.length;
      const ok = helper.assertionSatisfied(mode, matchCount, filters);
      const reason = helper.assertionReason(mode, matchCount, filters, ok);

      return {
        ok,
        reason,
        matchCount,
        path: window.location.pathname + window.location.search,
        title: document.title || "",
        texts: values,
        matched: values,
        jsTiming
      };
    };

    helper.locator = (options) => {
      const timeoutMs = Math.max(0, Number(options.timeoutMs || 0));
      const pollMs = Math.max(50, Number(options.pollMs || 250));
      const deadline = Date.now() + timeoutMs;
      const initial = helper.locatorQuick(options);

      if (initial.ok) {
        return Promise.resolve(JSON.stringify(initial));
      }

      if (timeoutMs <= 0) {
        return Promise.resolve(JSON.stringify(helper.locatorDiagnostics(options)));
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
            const quick = helper.locatorQuick(options);
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
            finish(helper.locatorDiagnostics(options));
            return;
          }

          dirty = true;
          scheduleCheck();
        }, pollMs);
        cleanupFns.push(() => clearInterval(intervalRef));

        const timeoutRef = setTimeout(() => finish(helper.locatorDiagnostics(options)), timeoutMs);
        cleanupFns.push(() => clearTimeout(timeoutRef));
      });
    };

    helper.pathQuick = (options) => {
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

      return {
        ok,
        reason: ok ? "matched" : "mismatch",
        path: currentPath,
        "path_match?": pathMatch,
        "query_match?": queryMatch
      };
    };

    helper.pathCheck = (options) => {
      return JSON.stringify(helper.pathQuick(options));
    };

    helper.path = (options) => {
      const timeoutMs = Math.max(0, Number(options.timeoutMs || 0));
      const pollMs = Math.max(50, Number(options.pollMs || 100));
      const deadline = Date.now() + timeoutMs;
      const initial = helper.pathQuick(options);

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
            const attempt = helper.pathQuick(options);
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

          const root = document.documentElement || document.body || document;
          if (root) {
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

        const intervalRef = setInterval(() => {
          if (Date.now() >= deadline) {
            finish(helper.pathQuick(options));
            return;
          }

          dirty = true;
          scheduleCheck();
        }, pollMs);
        cleanupFns.push(() => clearInterval(intervalRef));

        const timeoutRef = setTimeout(() => finish(helper.pathQuick(options)), timeoutMs);
        cleanupFns.push(() => clearTimeout(timeoutRef));

        scheduleCheck();
      });
    };

    window.__cerberusAssert = helper;
  })();
  """

  @spec preload_script() :: String.t()
  def preload_script, do: @preload_script
end
