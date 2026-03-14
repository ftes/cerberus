#!/usr/bin/env node

const fs = require("fs");
const vm = require("vm");
const { JSDOM } = require("jsdom");

function normalizeActionValue(target, payload) {
  if (!target || typeof target !== "object") return [];

  const op = String(payload.op || "");
  const matchBy = String(payload.matchBy || (op === "click" || op === "submit" ? "text" : "label"));

  if (op === "fill_in") {
    return typeof target.label === "string" && target.label !== "" ? [target.label] : [];
  }

  switch (matchBy) {
    case "label":
      return typeof target.label === "string" && target.label !== "" ? [target.label] : [];
    case "title":
      return typeof target.title === "string" && target.title !== "" ? [target.title] : [];
    case "testid":
      return typeof target.testid === "string" && target.testid !== "" ? [target.testid] : [];
    case "alt":
      return typeof target.alt === "string" && target.alt !== "" ? [target.alt] : [];
    case "placeholder":
      return typeof target.placeholder === "string" && target.placeholder !== "" ? [target.placeholder] : [];
    default:
      return typeof target.text === "string" && target.text !== "" ? [target.text] : [];
  }
}

function run(inputPath) {
  const input = JSON.parse(fs.readFileSync(inputPath, "utf8"));
  const dom = new JSDOM(input.html, { url: "http://example.test/contracts" });
  const { window } = dom;

  global.window = window;
  global.document = window.document;
  global.Node = window.Node;
  global.NodeFilter = window.NodeFilter;
  global.Element = window.Element;
  global.HTMLElement = window.HTMLElement;
  global.Document = window.Document;
  global.CSS = window.CSS;
  global.performance = window.performance;
  global.navigator = window.navigator;
  global.atob = (value) => Buffer.from(value, "base64").toString("binary");
  global.File = window.File;
  global.DataTransfer = window.DataTransfer;
  global.Event = window.Event;
  global.MouseEvent = window.MouseEvent;
  global.URLSearchParams = window.URLSearchParams;

  vm.runInThisContext(input.assertionScript);
  vm.runInThisContext(input.actionScript);

  if (input.kind === "assertion") {
    const result = window.__cerberusAssert.resolveAssertionRound(input.payload);

    return {
      ok: result.ok === true,
      reason: result.reason || "",
      match_count: result.matchCount || 0,
      matched: Array.isArray(result.matched) ? result.matched.slice().sort() : [],
      candidate_values: Array.isArray(result.candidateValues) ? result.candidateValues.slice().sort() : []
    };
  }

  const result = window.__cerberusAction.resolveActionRound(input.payload);

  return {
    ok: result && result.ok === true,
    reason: (result && result.reason) || "",
    match_count: (result && result.matchCount) || 0,
    matched: normalizeActionValue(result && result.target, input.payload).sort(),
    candidate_values: Array.isArray(result && result.candidateValues) ? result.candidateValues.slice().sort() : [],
    target_selector: result && result.target ? result.target.selector || null : null,
    target_kind: result && result.target ? result.target.kind || null : null
  };
}

const inputPath = process.argv[2];

if (!inputPath) {
  console.error("usage: browser_match_round_runner.js <input.json>");
  process.exit(1);
}

try {
  const result = run(inputPath);
  process.stdout.write(JSON.stringify(result));
} catch (error) {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
}
