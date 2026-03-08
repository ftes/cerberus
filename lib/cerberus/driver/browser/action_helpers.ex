defmodule Cerberus.Driver.Browser.ActionHelpers do
  @moduledoc false

  @preload_script """
  ;(() => {
    if (window.__cerberusAction && window.__cerberusAction.__version === 17) return;

    const helper = {};
    helper.__version = 17;

    helper.normalize = (value, normalizeWs) => {
      const source = (value || "").replace(/\\u00A0/g, " ");
      if (!normalizeWs) return source;
      return source.replace(/\\s+/g, " ").trim();
    };

    helper.cssEscape = (value) => {
      const source = String(value || "");

      if (typeof CSS !== "undefined" && CSS && typeof CSS.escape === "function") {
        return CSS.escape(source);
      }

      return source.replace(/\\\\/g, "\\\\\\\\").replace(/"/g, "\\\\22 ");
    };

    helper.uniqueSelector = (element) => {
      if (!element || element.nodeType !== 1) return null;

      const parts = [];
      let node = element;

      while (node && node.nodeType === 1) {
        const tag = (node.tagName || "").toLowerCase();
        if (!tag) break;

        const id = typeof node.getAttribute === "function" ? node.getAttribute("id") : null;
        if (id) {
          parts.unshift(`${tag}[id="${helper.cssEscape(id)}"]`);
          break;
        }

        let index = 1;
        let sibling = node;

        while (sibling && sibling.previousElementSibling) {
          sibling = sibling.previousElementSibling;
          if ((sibling.tagName || "").toLowerCase() === tag) index += 1;
        }

        parts.unshift(`${tag}:nth-of-type(${index})`);
        node = node.parentElement;
      }

      return parts.length > 0 ? parts.join(" > ") : null;
    };

    helper.formSelector = (element) => {
      if (!element) return "";

      const form = element.form || (typeof element.closest === "function" ? element.closest("form") : null);
      if (!form) return "";

      const id = typeof form.getAttribute === "function" ? form.getAttribute("id") : "";
      if (id) return `form[id="${helper.cssEscape(id)}"]`;

      return helper.uniqueSelector(form) || "";
    };

    helper.buttonSelector = "button,input[type='submit'],input[type='button'],input[type='image']";

    helper.isButtonLikeInput = (element) => {
      const tag = (element.tagName || "").toLowerCase();
      if (tag !== "input") return false;
      const type = (element.getAttribute("type") || "").toLowerCase();
      return type === "submit" || type === "button" || type === "image";
    };

    helper.isButtonLikeElement = (element) => {
      const tag = (element.tagName || "").toLowerCase();
      return tag === "button" || helper.isButtonLikeInput(element);
    };

    helper.buttonText = (element) => {
      const tag = (element.tagName || "").toLowerCase();

      if (tag === "input") {
        return helper.normalize(element.getAttribute("value") || "", true);
      }

      return helper.normalize(element.textContent, true);
    };

    helper.currentPath = () => window.location.pathname + window.location.search;
    helper.multiSelectCache = new Map();
    helper.multiSelectCachePath = helper.currentPath();

    helper.refreshMultiSelectCache = () => {
      const path = helper.currentPath();

      if (helper.multiSelectCachePath !== path) {
        helper.multiSelectCache.clear();
        helper.multiSelectCachePath = path;
      }
    };

    helper.multiSelectCacheKey = (element) => {
      if (!element) return "";

      const formSelector = helper.formSelector(element);
      const fieldName =
        (typeof element.getAttribute === "function" ? element.getAttribute("name") : "") ||
        (typeof element.getAttribute === "function" ? element.getAttribute("id") : "") ||
        helper.uniqueSelector(element) ||
        "";

      return `${helper.currentPath()}::${formSelector}::${fieldName}`;
    };

    helper.liveRoots = () => {
      try {
        return Array.from(document.querySelectorAll("[data-phx-session]"));
      } catch (_error) {
        return [];
      }
    };

    helper.liveConnected = () => {
      const roots = helper.liveRoots();
      if (roots.length === 0) return true;

      return roots.some((root) => {
        try {
          return !!(root && root.classList && root.classList.contains("phx-connected"));
        } catch (_error) {
          return false;
        }
      });
    };

    helper.inLiveRoot = (element) => {
      try {
        return !!(element && typeof element.closest === "function" && element.closest("[data-phx-session]"));
      } catch (_error) {
        return false;
      }
    };

    helper.waitForLiveConnected = async (timeoutMs, pollMs = 50) => {
      if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) return helper.liveConnected();

      const deadline = Date.now() + timeoutMs;
      while (Date.now() <= deadline) {
        if (helper.liveConnected()) return true;
        await new Promise((resolve) => setTimeout(resolve, pollMs));
      }

      return helper.liveConnected();
    };

    helper.needsAwaitReady = (options, result, prePath) => {
      const op = options && options.op ? options.op : "click";
      const path = result && typeof result.path === "string" ? result.path : helper.currentPath();
      const pathChanged = typeof prePath === "string" && prePath !== path;

      return pathChanged && (op === "click" || op === "submit");
    };

    helper.dispatchInputChange = (field) => {
      field.dispatchEvent(new Event("input", { bubbles: true }));
      field.dispatchEvent(new Event("change", { bubbles: true }));
    };

    helper.dispatchOptionClick = (option) => {
      if (!option) return;

      try {
        option.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
      } catch (_error) {
        option.dispatchEvent(new Event("click", { bubbles: true, cancelable: true }));
      }
    };

    helper.dispatchElementClick = (element) => {
      if (!element) return;

      try {
        element.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));
      } catch (_error) {
        element.dispatchEvent(new Event("click", { bubbles: true, cancelable: true }));
      }
    };

    helper.submitDataMethod = (target, element) => {
      const rawMethod =
        (target && typeof target.dataMethod === "string" ? target.dataMethod : "") ||
        (element && typeof element.getAttribute === "function" ? element.getAttribute("data-method") || "" : "");
      const method = String(rawMethod).trim().toLowerCase();

      if (!method) return { ok: false, reason: "data_method_missing" };

      const rawTarget =
        (target && typeof target.dataTo === "string" ? target.dataTo : "") ||
        (element && typeof element.getAttribute === "function" ? element.getAttribute("data-to") || "" : "") ||
        (target && typeof target.href === "string" ? target.href : "") ||
        (element && typeof element.getAttribute === "function" ? element.getAttribute("href") || "" : "");
      const action = String(rawTarget || "").trim();

      if (!action) return { ok: false, reason: "data_method_target_missing" };

      const metaCsrf =
        typeof document.querySelector === "function"
          ? (document.querySelector("meta[name='csrf-token']") || {}).content || ""
          : "";
      const csrfToken =
        String(metaCsrf || "").trim() ||
        (target && typeof target.dataCsrf === "string" ? target.dataCsrf : "") ||
        (element && typeof element.getAttribute === "function" ? element.getAttribute("data-csrf") || "" : "");

      const form = document.createElement("form");
      form.style.display = "none";
      form.method = method === "get" ? "get" : "post";
      form.action = action;

      if (form.method !== "get" && method !== "post") {
        const hiddenMethod = document.createElement("input");
        hiddenMethod.type = "hidden";
        hiddenMethod.name = "_method";
        hiddenMethod.value = method;
        form.appendChild(hiddenMethod);
      }

      if (form.method !== "get" && typeof csrfToken === "string" && csrfToken.trim() !== "") {
        const hiddenCsrf = document.createElement("input");
        hiddenCsrf.type = "hidden";
        hiddenCsrf.name = "_csrf_token";
        hiddenCsrf.value = csrfToken.trim();
        form.appendChild(hiddenCsrf);
      }

      document.body.appendChild(form);
      form.submit();
      return { ok: true };
    };

    helper.scrollTargetIntoView = (element) => {
      if (!element || typeof element.scrollIntoView !== "function") return;

      try {
        element.scrollIntoView({ block: "center", inline: "center" });
      } catch (_error) {
        try {
          element.scrollIntoView();
        } catch (_nestedError) {
          // ignored
        }
      }
    };

    helper.isElementVisible = (element) => {
      if (!element || element.isConnected !== true) return false;

      let current = element;
      while (current && current.nodeType === Node.ELEMENT_NODE) {
        if (typeof current.hasAttribute === "function" && current.hasAttribute("hidden")) return false;

        let style = null;
        try {
          style = window.getComputedStyle(current);
        } catch (_error) {
          return false;
        }

        if (!style) return false;
        if (style.display === "none") return false;
        if (style.visibility === "hidden" || style.visibility === "collapse") return false;

        current = current.parentElement;
      }

      try {
        const rect = element.getBoundingClientRect();
        return !!rect && rect.width > 0 && rect.height > 0;
      } catch (_error) {
        return false;
      }
    };

    helper.requiresVisibilityCheck = (op) => op !== "upload";

    helper.prepareTargetForAction = (element, op) => {
      if (!element || element.isConnected !== true) {
        return { ok: false, reason: "target_detached" };
      }

      helper.scrollTargetIntoView(element);

      if (helper.requiresVisibilityCheck(op) && !helper.isElementVisible(element)) {
        return { ok: false, reason: "target_not_visible" };
      }

      return { ok: true };
    };

    helper.retryableActionFailure = (result, options) => {
      if (!result || result.ok === true) return false;
      if (options && options.force === true) return false;

      const op = options && options.op ? options.op : "click";
      const reason = result.reason || "";

      if (reason === "field_disabled") {
        return ["fill_in", "select", "choose", "check", "uncheck", "upload", "click", "submit"].includes(op);
      }

      return false;
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
      const stateKeys = ["checked", "disabled", "selected", "readonly", "visible"];

      for (const key of stateKeys) {
        if (typeof options[key] !== "boolean") continue;

        if (key === "visible") {
          const actualVisible =
            typeof candidate.visible === "boolean"
              ? candidate.visible
              : helper.isElementVisible(candidate && candidate.__el ? candidate.__el : null);

          if (actualVisible !== options[key]) return false;
          continue;
        }

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

    helper.queryWithinRoots = (roots, querySelector) => {
      const seen = new Set();
      const matches = [];

      const addUnique = (element) => {
        if (!element || seen.has(element)) return;
        seen.add(element);
        matches.push(element);
      };

      for (const root of roots) {
        if (!root || typeof root.querySelectorAll !== "function") continue;

        if (helper.matchesSelector(root, querySelector)) {
          addUnique(root);
        }

        let nodes = [];
        try {
          nodes = root.querySelectorAll(querySelector);
        } catch (_error) {
          nodes = [];
        }

        for (const node of nodes) {
          addUnique(node);
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

    helper.clickCandidates = (roots, kind) => {
      const links =
        kind === "button"
          ? []
          : helper.queryWithinRoots(roots, "a[href]").map((element, index) =>
              helper.attachElement(
                {
                  kind: "link",
                  index,
                  text: helper.normalize(element.textContent, true),
                  title: element.getAttribute("title") || "",
                  ariaLabel: element.getAttribute("aria-label") || "",
                  alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt],[role='img'][alt]"),
                  testid: element.getAttribute("data-testid") || "",
                  formSelector: helper.formSelector(element),
                  href: element.getAttribute("href") || "",
                  resolvedHref: element.href || "",
                  dataMethod: element.getAttribute("data-method") || "",
                  dataTo: element.getAttribute("data-to") || "",
                  dataCsrf: element.getAttribute("data-csrf") || "",
                  checked: false,
                  disabled: false,
                  readonly: false,
                  selected: false
                },
                element
              )
            );

      const clickables =
        kind === "any"
          ? helper
              .queryWithinRoots(roots, "[phx-click]")
              .filter((element) => {
                const tag = (element.tagName || "").toLowerCase();
                return tag !== "a" && tag !== "button" && !helper.isButtonLikeInput(element);
              })
              .map((element, index) =>
                helper.attachElement(
                  {
                    kind: "clickable",
                    index,
                    tag: (element.tagName || "").toLowerCase(),
                    text: helper.normalize(element.textContent, true),
                    title: element.getAttribute("title") || "",
                    ariaLabel: element.getAttribute("aria-label") || "",
                    alt: "",
                    testid: element.getAttribute("data-testid") || "",
                    formSelector: helper.formSelector(element),
                    checked: false,
                    disabled: element.disabled === true || element.hasAttribute("disabled"),
                    readonly: element.readOnly === true || element.hasAttribute("readonly"),
                    selected: false
                  },
                  element
                )
              )
          : [];

      const labels =
        kind === "any"
          ? helper.queryWithinRoots(roots, "label").map((element, index) =>
              helper.attachElement(
                {
                  kind: "label",
                  index,
                  tag: "label",
                  text: helper.normalize(element.textContent, true),
                  title: element.getAttribute("title") || "",
                  ariaLabel: element.getAttribute("aria-label") || "",
                  alt: "",
                  testid: element.getAttribute("data-testid") || "",
                  formSelector: helper.formSelector(element),
                  checked: false,
                  disabled: false,
                  readonly: false,
                  selected: false
                },
                element
              )
            )
          : [];

      const buttons =
        kind === "link"
          ? []
          : helper.queryWithinRoots(roots, helper.buttonSelector).map((element, index) =>
              helper.attachElement(
                {
                  kind: "button",
                  index,
                  text: helper.buttonText(element),
                  title: element.getAttribute("title") || "",
                  ariaLabel: element.getAttribute("aria-label") || "",
                  alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt]"),
                  testid: element.getAttribute("data-testid") || "",
                  type: (element.getAttribute("type") || "submit").toLowerCase(),
                  formSelector: helper.formSelector(element),
                  dataMethod: element.getAttribute("data-method") || "",
                  dataTo: element.getAttribute("data-to") || "",
                  dataCsrf: element.getAttribute("data-csrf") || "",
                  checked: false,
                  disabled: element.disabled === true,
                  readonly: element.readOnly === true || element.hasAttribute("readonly"),
                  selected: false
                },
                element
              )
            );

      return links.concat(clickables).concat(labels).concat(buttons);
    };

    helper.submitCandidates = (roots) => {
      const allButtons = helper.queryWithinRoots(roots, helper.buttonSelector);

      return allButtons
        .map((element, index) => ({ element, index }))
        .filter(({ element }) => {
          const tag = (element.tagName || "").toLowerCase();
          const type = (element.getAttribute("type") || (tag === "button" ? "submit" : "")).toLowerCase();
          return type === "submit" || type === "";
        })
        .map(({ element, index }) => {
          const tag = (element.tagName || "").toLowerCase();
          const type = (element.getAttribute("type") || (tag === "button" ? "submit" : "")).toLowerCase();

          return helper.attachElement(
            {
              kind: "button",
              index,
              text: helper.buttonText(element),
              title: element.getAttribute("title") || "",
              ariaLabel: element.getAttribute("aria-label") || "",
              alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt]"),
              testid: element.getAttribute("data-testid") || "",
              type,
              formSelector: helper.formSelector(element),
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

      for (const label of helper.queryWithinRoots(roots, "label[for]")) {
        const id = label.getAttribute("for");
        if (id) labels.set(id, helper.normalize(label.textContent, true));
      }

      return labels;
    };

    helper.referencedText = (element) => {
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
            return ref ? (ref.innerText || ref.textContent || "") : "";
          })
          .filter((value) => value !== "")
          .join(" "),
        true
      );
    };

    helper.labelSourcesForControl = (labels, element) => {
      const sources = [];
      const byId = labels.get(element.id || "");
      if (byId) sources.push(byId);

      try {
        if (element.labels && element.labels.length > 0) {
          const labelText = Array.from(element.labels)
            .map((label) => helper.normalize(label.textContent, true))
            .filter((value) => value !== "")
            .join(" ");

          if (labelText !== "") sources.push(labelText);
        }
      } catch (_error) {
        // ignored
      }

      if (typeof element.closest === "function") {
        const wrappingLabel = element.closest("label");
        if (wrappingLabel) sources.push(helper.normalize(wrappingLabel.textContent, true));
      }

      const labelledby = helper.referencedText(element);
      if (labelledby) sources.push(labelledby);

      const ariaLabel = helper.normalize(element.getAttribute("aria-label") || "", true);
      if (ariaLabel) sources.push(ariaLabel);

      return Array.from(new Set(sources.filter((value) => value !== "")));
    };

    helper.labelForControl = (labels, element) => {
      return helper.labelSourcesForControl(labels, element)[0] || "";
    };

    helper.accessibleNameSources = (element, kind) => {
      if (!element) return [];

      const tag = (element.tagName || "").toLowerCase();
      const labelledby = helper.referencedText(element);
      const ariaLabel = helper.normalize(element.getAttribute("aria-label") || "", true);
      const sources = [labelledby, ariaLabel];

      switch (kind) {
        case "button":
          if (!helper.isButtonLikeElement(element)) return [];
          sources.push(helper.buttonText(element));
          break;
        case "link":
          if (tag !== "a" || !element.hasAttribute("href")) return [];
          sources.push(helper.normalize(element.textContent, true));
          break;
        case "heading":
          if (!/^h[1-6]$/.test(tag) && element.getAttribute("role") !== "heading") return [];
          sources.push(helper.normalize(element.textContent, true));
          break;
        default:
          return [];
      }

      return Array.from(new Set(sources.filter((value) => value !== "")));
    };

    helper.formCandidates = (roots) => {
      const labels = helper.labelsByFor(roots);

      return helper
        .queryWithinRoots(roots, "input, textarea, select")
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
              ariaLabel: element.getAttribute("aria-label") || "",
              testid: element.getAttribute("data-testid") || "",
              formSelector: helper.formSelector(element),
              value: helper.fieldValueForElement(element, tag, type),
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

    helper.fileCandidates = (roots) => {
      const labels = helper.labelsByFor(roots);

      return helper.queryWithinRoots(roots, "input[type='file']").map((element, index) =>
        helper.attachElement(
          {
            kind: "field",
            index,
            tag: "input",
            type: "file",
            label: helper.labelForControl(labels, element),
            placeholder: element.getAttribute("placeholder") || "",
            title: element.getAttribute("title") || "",
            ariaLabel: element.getAttribute("aria-label") || "",
            testid: element.getAttribute("data-testid") || "",
            formSelector: helper.formSelector(element),
            value: helper.fieldValueForElement(element, "input", "file"),
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

    helper.previewValues = (candidates, op, matchBy, limit = 8) => {
      const values = [];

      for (const candidate of candidates) {
        const value = helper.normalize(helper.matchValue(candidate, op, matchBy), true);
        if (!value || values.includes(value)) continue;

        values.push(value);
        if (values.length >= limit) break;
      }

      return values;
    };

    helper.firstCssSelector = (locator) => {
      if (!locator || typeof locator !== "object") return null;

      const kind = String(locator.kind || "").toLowerCase();
      if (kind === "css" && typeof locator.value === "string" && locator.value.trim() !== "") {
        return locator.value;
      }

      const members = Array.isArray(locator.members)
        ? locator.members
        : null;

      if (kind === "and" && Array.isArray(members)) {
        for (const member of members) {
          const selector = helper.firstCssSelector(member);
          if (selector) return selector;
        }
      }

      return null;
    };

    helper.previewCandidates = (candidates, locator, op) => {
      if (!Array.isArray(candidates) || !locator || (op !== "click" && op !== "submit")) {
        return candidates;
      }

      const selector = helper.firstCssSelector(locator);
      if (!selector) return candidates;

      const scoped = candidates.filter((candidate) => candidate && candidate.__el && helper.matchesSelector(candidate.__el, selector));
      return scoped.length > 0 ? scoped : candidates;
    };

    helper.querySelectorForLocator = (locator) => {
      if (!locator || typeof locator !== "object") return "*";

      const rawKind = String(locator.kind || "").toLowerCase();
      if (rawKind === "role") {
        const opts = locator.opts && typeof locator.opts === "object" ? locator.opts : {};
        return helper.roleSelector(opts.role);
      }

      const kind = rawKind;

      switch (kind) {
        case "css":
          return typeof locator.value === "string" && locator.value.trim() !== "" ? locator.value : "*";
        case "text":
          return "*";
        case "link":
          return "a[href]";
        case "button":
          return helper.buttonSelector;
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
        case "scope": {
          const members = Array.isArray(locator.members) ? locator.members : [];

          if (members.length === 0) return "*";
          return helper.querySelectorForLocator(members[members.length - 1]);
        }
        case "and":
        case "or":
        case "not":
          return "*";
        default:
          return "*";
      }
    };

    helper.locatorValuesForKind = (candidate, kind, op) => {
      const element = candidate && candidate.__el ? candidate.__el : null;

      if (op === "click" || op === "submit") {
        switch (kind) {
          case "text":
            return [candidate.text || ""].filter((value) => value !== "");
          case "link":
            return candidate.kind === "link" ? helper.accessibleNameSources(element, "link") : [];
          case "button":
            return candidate.kind === "button" ? helper.accessibleNameSources(element, "button") : [];
          case "title":
            return [candidate.title || ""].filter((value) => value !== "");
          case "alt":
            return [candidate.alt || ""].filter((value) => value !== "");
          case "testid":
            return [candidate.testid || ""].filter((value) => value !== "");
          default:
            return [];
        }
      }

      switch (kind) {
        case "text":
          return [candidate.label || ""].filter((value) => value !== "");
        case "label":
          return element ? helper.labelSourcesForControl(new Map(), element) : [];
        case "placeholder":
          return [candidate.placeholder || ""].filter((value) => value !== "");
        case "title":
          return [candidate.title || ""].filter((value) => value !== "");
        case "testid":
          return [candidate.testid || ""].filter((value) => value !== "");
        default:
          return [];
      }
    };

    helper.roleLocatorValues = (candidate, locator) => {
      if (!candidate || !candidate.__el || !locator || typeof locator !== "object") return [];

      const opts = locator.opts && typeof locator.opts === "object" ? locator.opts : {};
      const role = String(opts.role || "").toLowerCase();

      switch (role) {
        case "button":
        case "menuitem":
        case "tab":
          return helper.accessibleNameSources(candidate.__el, "button");
        case "link":
          return helper.accessibleNameSources(candidate.__el, "link");
        case "textbox":
        case "searchbox":
        case "combobox":
        case "listbox":
        case "spinbutton":
        case "checkbox":
        case "radio":
        case "switch":
          return helper.labelSourcesForControl(new Map(), candidate.__el);
        case "heading":
          return helper.accessibleNameSources(candidate.__el, "heading");
        case "img":
          return [helper.altSourceForElement(candidate.__el, "img[alt],input[type='image'][alt],[role='img'][alt]")].filter((value) => value !== "");
        default:
          return [];
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

    helper.fieldValueForElement = (element, tag, type) => {
      if (!element) return "";

      if (tag === "select") {
        if (element.multiple) {
          const selected = Array.from(element.selectedOptions || []);
          const first = selected[0];
          return first ? first.value || helper.normalize(first.textContent, true) : "";
        }

        return typeof element.value === "string" ? element.value : "";
      }

      if (type === "checkbox" || type === "radio") {
        return (typeof element.value === "string" && element.value !== "") ? element.value : "on";
      }

      if (type === "file") {
        if (element.files && element.files.length > 0) {
          const firstFile = element.files[0];
          return firstFile && typeof firstFile.name === "string" ? firstFile.name : "";
        }

        return "";
      }

      const value = element.value;
      if (value === null || value === undefined) return "";
      return String(value);
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
          ariaLabel: (element.getAttribute("aria-label") || ""),
          alt: helper.altSourceForElement(element, "img[alt],input[type='image'][alt],[role='img'][alt]"),
          testid: (element.getAttribute("data-testid") || ""),
          formSelector: helper.formSelector(element),
          value: helper.fieldValueForElement(element, tag, type),
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

      if (opts.has) {
        if (!helper.elementHasLocator(candidate.__el, opts.has, op)) return false;
      }

      if (opts.has_not) {
        if (helper.elementHasLocator(candidate.__el, opts.has_not, op)) return false;
      }

      return true;
    };

    helper.containsNodeOrSame = (container, node) => {
      if (!container || !node) return false;
      return container === node || (typeof container.contains === "function" && container.contains(node));
    };

    helper.strictDescendant = (container, node) => {
      if (!container || !node) return false;
      return container !== node && helper.containsNodeOrSame(container, node);
    };

    helper.scopeMembersMatch = (candidate, members, op) => {
      if (!candidate || !candidate.__el || !Array.isArray(members) || members.length < 2) return false;

      const targetLocator = members[members.length - 1];
      if (!helper.matchesLocator(candidate, targetLocator, op)) return false;

      const scopeMembers = members.slice(0, -1);
      const scopeLocator =
        scopeMembers.length === 1
          ? scopeMembers[0]
          : { kind: "scope", members: scopeMembers, opts: {} };

      const scopeSelector = helper.querySelectorForLocator(scopeLocator);
      const doc = candidate.__el.ownerDocument;
      if (!doc || typeof doc.querySelectorAll !== "function") return false;

      let scopeNodes = [];

      try {
        scopeNodes = Array.from(doc.querySelectorAll(scopeSelector));
      } catch (_error) {
        return false;
      }

      return scopeNodes.some((scopeNode) => {
        if (!helper.strictDescendant(scopeNode, candidate.__el)) return false;
        const scopeCandidate = helper.candidateFromElement(scopeNode);
        return helper.matchesLocator(scopeCandidate, scopeLocator, op);
      });
    };

    helper.matchesLocator = (candidate, locator, op) => {
      if (!locator || typeof locator !== "object") return false;

      const rawKind = String(locator.kind || "").toLowerCase();
      const kind = rawKind === "role" ? helper.locatorKind(locator) : rawKind;

      if (!kind) return false;

      if (kind === "not") {
        const members = Array.isArray(locator.members) ? locator.members : [];
        if (members.length !== 1) return false;

        return !helper.matchesLocator(candidate, members[0], op) && helper.matchesLocatorCommonOpts(candidate, locator.opts, op);
      }

      if (kind === "scope") {
        const members = Array.isArray(locator.members) ? locator.members : [];

        return helper.scopeMembersMatch(candidate, members, op) && helper.matchesLocatorCommonOpts(candidate, locator.opts, op);
      }

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

      const locatorOpts = locator.opts && typeof locator.opts === "object" ? locator.opts : {};
      const exact = locatorOpts.exact === true;
      const normalizeWs = locatorOpts.normalizeWs !== false;
      const matchText = helper.buildTextMatcher(locator.expected, exact, normalizeWs);

      const values =
        rawKind === "role"
          ? helper.roleLocatorValues(candidate, locator)
          : helper.locatorValuesForKind(candidate, kind, op);

      if (!Array.isArray(values) || values.length === 0) return false;
      if (!values.some((value) => typeof value === "string" && matchText(value))) return false;
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

      if (op === "click") {
        const kind = options.kind || "any";
        return helper.clickCandidates(roots, kind);
      }

      if (op === "submit") {
        return helper.submitCandidates(roots);
      }

      if (op === "upload") {
        return helper.fileCandidates(roots);
      }

      return helper.formCandidates(roots);
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

      const stateMatched = candidates.filter((candidate) => helper.matchesStateFilters(candidate, options));

      const matched = stateMatched.filter((candidate) => {
        if (locator) {
          return helper.matchesLocator(candidate, locator, op);
        }

        const value = helper.matchValue(candidate, op, matchBy);
        return matchText(value);
      });

      const previewCandidates = helper.previewCandidates(stateMatched, locator, op);
      const candidateValues = helper.previewValues(previewCandidates, op, matchBy);
      const matchedValues = helper.previewValues(matched, op, matchBy);

      if (!helper.countSatisfiesFilters(matched.length, filters)) {
        return {
          ok: false,
          reason: "matched element count did not satisfy count constraints",
          matchCount: matched.length,
          candidateValues: matchedValues,
          candidateCount: matched.length,
          path: window.location.pathname + window.location.search
        };
      }

      if (matched.length === 0) {
        return {
          ok: false,
          reason: "no elements matched locator",
          matchCount: 0,
          candidateValues,
          candidateCount: previewCandidates.length,
          path: window.location.pathname + window.location.search
        };
      }

      const position = helper.positionIndex(matched.length, options);
      if (position.error) {
        return {
          ok: false,
          reason: position.error,
          matchCount: matched.length,
          candidateValues: matchedValues,
          candidateCount: matched.length,
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

    helper.resolveInternal = (options) => {
      const timeoutMs = Math.max(0, Number(options.timeoutMs || 0));
      const pollMs = Math.max(50, Number(options.pollMs || 100));
      const deadline = Date.now() + timeoutMs;
      const initial = helper.resolveOnce(options);

      if (initial.ok || timeoutMs <= 0) {
        return Promise.resolve(initial);
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
          resolve(result);
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

    helper.resolve = async (options) => JSON.stringify(await helper.resolveInternal(options));

    helper.performResolved = (resolved, options) => {
      const target = resolved && resolved.target ? resolved.target : null;
      const op = options && options.op ? options.op : "click";
      helper.refreshMultiSelectCache();

      if (!target || !target.__el) {
        return {
          ok: false,
          reason: "matched target is no longer attached",
          matchCount: resolved && Number.isInteger(resolved.matchCount) ? resolved.matchCount : 0,
          path: helper.currentPath()
        };
      }

      const element = target.__el;
      const matchCount = resolved && Number.isInteger(resolved.matchCount) ? resolved.matchCount : 1;
      const fail = (reason, extra = {}) => ({
        ok: false,
        reason,
        matchCount,
        target,
        path: helper.currentPath(),
        ...extra
      });

      const force = options && options.force === true;

      if (!force) {
        const actionability = helper.prepareTargetForAction(element, op);
        if (!actionability || actionability.ok !== true) {
          return fail(actionability && actionability.reason ? actionability.reason : "actionability_check_failed");
        }
      }

      if (op === "fill_in") {
        if (target.kind !== "field") return fail("field_fill_failed");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        try {
          const value = String(options && options.value !== undefined && options.value !== null ? options.value : "");
          element.value = value;
          helper.dispatchInputChange(element);
          return { ok: true, target, value, matchCount, path: helper.currentPath() };
        } catch (error) {
          return fail("field_fill_failed", { message: String(error && error.message ? error.message : error) });
        }
      }

      if (op === "select") {
        if (target.kind !== "field" || target.tag !== "select") return fail("field_not_select");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        const requestedOptions = Array.isArray(options && options.option)
          ? options.option.map((value) => String(value))
          : [];
        const exactOption = options && options.exactOption !== false;

        if (!element.multiple && requestedOptions.length > 1) return fail("select_not_multiple");

        const matchOption = (option, requested) => {
          const optionText = helper.normalize(option.textContent, true);
          const requestedText = helper.normalize(requested, true);
          return exactOption ? optionText === requestedText : optionText.includes(requestedText);
        };

        const matched = [];

        for (const requested of requestedOptions) {
          const enabled = Array.from(element.options || []).find((option) => matchOption(option, requested) && !option.disabled);
          if (enabled) {
            matched.push(enabled);
            continue;
          }

          const disabled = Array.from(element.options || []).find((option) => matchOption(option, requested) && option.disabled);
          if (disabled) return fail("option_disabled", { option: requested });
          return fail("option_not_found", { option: requested });
        }

        if (element.multiple) {
          const selectedValues = new Set();
          const replaceExistingSelections = options && options.optionListInput === true;
          const preserveLiveSelections = !replaceExistingSelections && helper.inLiveRoot(element);
          const cacheKey = helper.multiSelectCacheKey(element);
          const cachedValues = helper.multiSelectCache.get(cacheKey);

          if (preserveLiveSelections) {
            if (Array.isArray(cachedValues)) {
              for (const cachedValue of cachedValues) {
                selectedValues.add(String(cachedValue));
              }
            }

            for (const selectedOption of Array.from(element.selectedOptions || [])) {
              selectedValues.add(selectedOption.value || helper.normalize(selectedOption.textContent, true));
            }
          }

          for (const option of matched) {
            selectedValues.add(option.value || helper.normalize(option.textContent, true));
          }

          for (const option of Array.from(element.options || [])) {
            const value = option.value || helper.normalize(option.textContent, true);
            option.selected = selectedValues.has(value);
          }

          if (preserveLiveSelections) {
            helper.multiSelectCache.set(cacheKey, Array.from(selectedValues));
          } else {
            helper.multiSelectCache.delete(cacheKey);
          }
        } else {
          for (const option of Array.from(element.options || [])) {
            option.selected = false;
          }

          if (matched[0]) {
            matched[0].selected = true;
            element.value = matched[0].value || helper.normalize(matched[0].textContent, true);
          }

          helper.multiSelectCache.delete(helper.multiSelectCacheKey(element));
        }

        for (const option of matched) {
          if (typeof option.hasAttribute === "function" && option.hasAttribute("phx-click")) {
            helper.dispatchOptionClick(option);
          }
        }

        helper.dispatchInputChange(element);

        const value = element.multiple
          ? Array.from(element.selectedOptions || []).map((option) => option.value || helper.normalize(option.textContent, true))
          : element.value;

        return {
          ok: true,
          target,
          value,
          matchCount,
          path: helper.currentPath()
        };
      }

      if (op === "choose") {
        if (target.kind !== "field" || target.type !== "radio") return fail("field_not_radio");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        element.checked = true;
        if (typeof element.hasAttribute === "function" && element.hasAttribute("phx-click")) {
          helper.dispatchElementClick(element);
        }
        helper.dispatchInputChange(element);
        return { ok: true, target, value: element.value || "on", matchCount, path: helper.currentPath() };
      }

      if (op === "check" || op === "uncheck") {
        if (target.kind !== "field" || target.type !== "checkbox") return fail("field_not_checkbox");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        element.checked = op === "check";
        helper.dispatchInputChange(element);
        return { ok: true, target, value: element.checked, matchCount, path: helper.currentPath() };
      }

      if (op === "upload") {
        if (target.kind !== "field" || target.type !== "file") return fail("no file input matched locator");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        const filePayload = options && options.file && typeof options.file === "object" ? options.file : null;
        if (!filePayload || typeof filePayload.contentBase64 !== "string") return fail("upload_failed");

        try {
          const decoded = atob(filePayload.contentBase64);
          const bytes = new Uint8Array(decoded.length);

          for (let i = 0; i < decoded.length; i += 1) {
            bytes[i] = decoded.charCodeAt(i);
          }

          const file = new File([bytes], filePayload.fileName || "upload.bin", {
            type: filePayload.mimeType || "application/octet-stream",
            lastModified: Number(filePayload.lastModified || Date.now())
          });

          const transfer = new DataTransfer();
          transfer.items.add(file);
          element.files = transfer.files;
          helper.dispatchInputChange(element);

          return { ok: true, target, fileName: file.name, matchCount, path: helper.currentPath() };
        } catch (error) {
          return fail("upload_failed", { message: String(error && error.message ? error.message : error) });
        }
      }

      if (op === "submit") {
        if (target.kind !== "button") return fail("submit_target_failed");
        if (target.disabled === true || element.disabled === true) return fail("field_disabled");

        try {
          element.click();
          return { ok: true, target, matchCount, path: helper.currentPath() };
        } catch (error) {
          return fail("submit_target_failed", { message: String(error && error.message ? error.message : error) });
        }
      }

      if (target.kind !== "button" && target.kind !== "link" && target.kind !== "clickable" && target.kind !== "label") {
        return fail("click_target_failed");
      }

      try {
        if (target.kind === "button") {
          if (target.disabled === true || element.disabled === true) return fail("field_disabled");

          const submission = helper.submitDataMethod(target, element);

          if (submission && submission.ok === true) {
            return { ok: true, target, matchCount, path: helper.currentPath() };
          }

          if (submission && submission.reason === "data_method_target_missing") {
            return fail("data_method_target_missing");
          }
        }

        if (target.kind === "link" && target.dataMethod && target.dataTo) {
          const submission = helper.submitDataMethod(target, element);

          if (submission && submission.ok === true) {
            return { ok: true, target, matchCount, path: helper.currentPath() };
          }

          if (submission && submission.reason === "data_method_target_missing") {
            return fail("data_method_target_missing");
          }
        }

        element.click();
        return { ok: true, target, matchCount, path: helper.currentPath() };
      } catch (error) {
        return fail("click_target_failed", { message: String(error && error.message ? error.message : error) });
      }
    };

    helper.perform = async (options) => {
      const now = () =>
        typeof performance !== "undefined" && typeof performance.now === "function"
          ? performance.now()
          : Date.now();

      const startedAt = now();
      let waitForLiveMs = 0;
      let resolveMs = 0;
      let performResolvedMs = 0;
      const readyTimeoutMs = Number(options && options.readyTimeoutMs);
      const timeoutMs = Math.max(0, Number(options && options.timeoutMs || 0));
      if (Number.isFinite(readyTimeoutMs) && readyTimeoutMs > 0) {
        const waitStartedAt = now();
        await helper.waitForLiveConnected(readyTimeoutMs, 50);
        waitForLiveMs = now() - waitStartedAt;
      }

      let result = null;
      const deadline = Date.now() + timeoutMs;

      while (true) {
        const remaining = Math.max(0, deadline - Date.now());
        const resolveStartedAt = now();
        const resolved = await helper.resolveInternal({ ...options, timeoutMs: remaining });
        resolveMs += now() - resolveStartedAt;

        if (!resolved || resolved.ok !== true) {
          result = resolved || { ok: false, reason: "action_resolve_failed", path: helper.currentPath() };
          break;
        }

        const prePath = helper.currentPath();
        const performStartedAt = now();
        result = helper.performResolved(resolved, options);
        performResolvedMs += now() - performStartedAt;

        if (result && result.ok === true) {
          result.needsAwaitReady = helper.needsAwaitReady(options, result, prePath);
          break;
        }

        if (!helper.retryableActionFailure(result, options) || remaining <= 0) {
          break;
        }

        await new Promise((resolve) => setTimeout(resolve, Math.min(50, Math.max(remaining, 1))));
      }

      if (!result || typeof result !== "object") {
        result = { ok: false, reason: "action_perform_failed", path: helper.currentPath() };
      }

      const jsTiming = result.jsTiming && typeof result.jsTiming === "object" ? result.jsTiming : {};

      result.jsTiming = {
        ...jsTiming,
        actionWaitForLiveMs: waitForLiveMs,
        actionResolveMs: resolveMs,
        actionPerformResolvedMs: performResolvedMs,
        actionTotalMs: now() - startedAt
      };

      return JSON.stringify(result);
    };

    window.__cerberusAction = helper;
  })();
  """

  @spec preload_script() :: String.t()
  def preload_script, do: @preload_script
end
