#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { chromium } = require("playwright");

const BASE_URL = process.env.BASE_URL || "http://localhost:4002";
const CHROME = process.env.CHROME;
const ITERATIONS = parseInt(process.env.ITERATIONS || "10", 10);
const WARMUP = parseInt(process.env.WARMUP || "2", 10);
const FLOW_PATH = "/phoenix_test/playwright/live/performance";
const DONE_PATH = "/phoenix_test/playwright/live/performance/done?candidate=wizard-prime";
const SEARCH_VALUE = "wiz";
const CANDIDATE_NAME = "Wizard Prime";
const CANDIDATE_SCORE = "score 98";
const CANDIDATE_ID = "wizard-prime";
const TARGET_SLOT = "slot-120";
const TARGET_STATUS = "status-ready";
const TARGET_MARKER = "priority-prime";

function percentile(samples, pct) {
  if (samples.length === 0) return 0;
  const sorted = [...samples].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil(sorted.length * pct) - 1));
  return sorted[index];
}

function summarize(samples) {
  return {
    meanMs: samples.reduce((sum, value) => sum + value, 0) / Math.max(samples.length, 1),
    medianMs: percentile(samples, 0.5),
    p95Ms: percentile(samples, 0.95)
  };
}

function findManagedChromeExecutable() {
  const tmpDir = path.resolve(__dirname, "..", "tmp");

  if (!fs.existsSync(tmpDir)) return null;

  const chromeDirs = fs
    .readdirSync(tmpDir)
    .filter((entry) => entry.startsWith("chrome-"))
    .sort()
    .reverse();

  for (const chromeDir of chromeDirs) {
    const root = path.join(tmpDir, chromeDir);
    const macCandidates = [
      path.join(root, "chrome-mac-arm64", "Google Chrome for Testing.app", "Contents", "MacOS", "Google Chrome for Testing"),
      path.join(root, "chrome-mac-x64", "Google Chrome for Testing.app", "Contents", "MacOS", "Google Chrome for Testing")
    ];
    const linuxCandidate = path.join(root, "chrome-linux64", "chrome");

    for (const candidate of [...macCandidates, linuxCandidate]) {
      if (fs.existsSync(candidate)) return candidate;
    }
  }

  return null;
}

function resolveChromeExecutable() {
  if (CHROME && CHROME.includes("Google Chrome for Testing.app")) {
    return CHROME;
  }

  const managed = findManagedChromeExecutable();
  if (managed) return managed;
  if (CHROME) return CHROME;
  return null;
}

async function waitForExactText(page, selector, text) {
  await page.waitForFunction(
    ({ selector, text }) => {
      const node = document.querySelector(selector);
      return node && node.textContent.trim() === text;
    },
    { selector, text }
  );
}

async function runFlow(page) {
  await page.goto(`${BASE_URL}${FLOW_PATH}`, { waitUntil: "domcontentloaded" });
  await page.getByRole("heading", { name: "Performance LiveView", exact: true }).waitFor();
  await page.locator("[data-phx-main].phx-connected").waitFor();
  await page.getByRole("button", { name: "Open candidate search", exact: true }).click();
  const candidateDialog = page.getByRole("dialog", { name: "Candidate search", exact: true });
  await candidateDialog.waitFor();
  await candidateDialog.getByLabel("Candidate search", { exact: true }).fill(SEARCH_VALUE);
  const candidateOption = candidateDialog
    .locator('[data-testid="candidate-option"]')
    .filter({ hasText: CANDIDATE_NAME })
    .filter({ hasText: CANDIDATE_SCORE });
  await candidateOption.waitFor();
  await candidateOption.getByRole("button", { name: "Choose", exact: true }).click();
  await page.getByText(`Selected candidate: ${CANDIDATE_NAME}`, { exact: true }).waitFor();
  await page.getByRole("button", { name: "Load heavy results", exact: true }).click();
  const targetCard = page
    .locator('article[data-card-kind="result"]')
    .filter({ hasText: CANDIDATE_NAME })
    .filter({ hasText: TARGET_STATUS })
    .filter({ hasText: TARGET_SLOT })
    .filter({ hasText: TARGET_MARKER });
  await targetCard.waitFor();
  await targetCard.getByRole("button", { name: "Review", exact: true }).click();
  const reviewDialog = page.getByRole("dialog", { name: "Review candidate", exact: true });
  await reviewDialog.waitFor();
  await reviewDialog.getByText(CANDIDATE_NAME, { exact: true }).waitFor();
  await reviewDialog.getByRole("button", { name: "Apply filters", exact: true }).click();
  await page.waitForURL(`${BASE_URL}${FLOW_PATH}?step=patched&candidate=${CANDIDATE_ID}`);
  await page.getByRole("button", { name: "Continue workflow", exact: true }).click();
  await page.waitForURL(`${BASE_URL}${DONE_PATH}`);
  await page.getByRole("heading", { name: "Performance flow complete", exact: true }).waitFor();
}

(async () => {
  const executablePath = resolveChromeExecutable();

  if (!executablePath) {
    throw new Error("Set CHROME or install the managed Chrome runtime before running the Playwright benchmark");
  }

  const browser = await chromium.launch({
    executablePath,
    headless: true,
    args: ["--disable-dev-shm-usage", "--disable-setuid-sandbox"]
  });

  const page = await browser.newPage();
  const samples = [];

  try {
    for (let index = 0; index < WARMUP + ITERATIONS; index += 1) {
      const started = process.hrtime.bigint();
      await runFlow(page);
      const elapsedMs = Number(process.hrtime.bigint() - started) / 1e6;

      if (index >= WARMUP) {
        samples.push(elapsedMs);
      }
    }

    const metrics = summarize(samples);

    console.log("runner,iterations,warmup,mean_ms,median_ms,p95_ms");
    console.log(
      [
        "playwright",
        ITERATIONS,
        WARMUP,
        metrics.meanMs.toFixed(3),
        metrics.medianMs.toFixed(3),
        metrics.p95Ms.toFixed(3)
      ].join(",")
    );
  } finally {
    await page.close();
    await browser.close();
  }
})().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
