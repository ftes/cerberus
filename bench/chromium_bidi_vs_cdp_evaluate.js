#!/usr/bin/env node
"use strict";

const { spawn } = require("child_process");

const CHROME = process.env.CHROME || (() => { throw new Error("Set CHROME"); })();
const CHROMEDRIVER = process.env.CHROMEDRIVER || (() => { throw new Error("Set CHROMEDRIVER"); })();
const CHROMEDRIVER_PORT = 9515;
const ITERATIONS = 200;
const WARMUP = 30;
const TIMEOUT_MS = 10_000;
const EXPRESSION = "(() => ({value: 42, text: 'ok'}))()";
const CHROME_ARGS = [
  "--headless=new",
  "--disable-gpu",
  "--no-first-run",
  "--no-default-browser-check",
  "--disable-background-networking",
  "--disable-background-timer-throttling",
  "--disable-renderer-backgrounding",
  "--enable-automation"
];

async function rpc(url) {
  const ws = new WebSocket(url);
  const pending = new Map();
  let nextId = 1;

  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve, { once: true });
    ws.addEventListener("error", () => reject(new Error(`WebSocket failed: ${url}`)), { once: true });
  });

  ws.addEventListener("message", (event) => {
    const msg = JSON.parse(String(event.data));
    const job = pending.get(msg.id);
    if (!job) return;
    clearTimeout(job.timer);
    pending.delete(msg.id);
    job.resolve(msg.result);
  });

  ws.addEventListener("close", () => {
    for (const [id, job] of pending) {
      clearTimeout(job.timer);
      job.reject(new Error(`Socket closed: ${url}`));
      pending.delete(id);
    }
  });

  return {
    call(method, params) {
      const id = nextId++;

      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          pending.delete(id);
          reject(new Error(`Timeout waiting for ${method}`));
        }, TIMEOUT_MS);

        pending.set(id, { resolve, reject, timer });
        ws.send(JSON.stringify({ id, method, params }));
      });
    },
    close() {
      try {
        ws.close();
      } catch (_error) {
      }
    }
  };
}

(async () => {
  const base = `http://127.0.0.1:${CHROMEDRIVER_PORT}`;
  const driver = spawn(CHROMEDRIVER, [`--port=${CHROMEDRIVER_PORT}`], { stdio: "ignore" });

  let ready = false;
  while (!ready) {
    try {
      const status = await fetch(`${base}/status`, { signal: AbortSignal.timeout(1_000) });
      ready = (await status.json()).value.ready;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
  }

  const sessionResponse = await fetch(`${base}/session`, {
    method: "POST",
    headers: { "content-type": "application/json; charset=utf-8" },
    body: JSON.stringify({
      capabilities: {
        alwaysMatch: {
          browserName: "chrome",
          webSocketUrl: true,
          "goog:chromeOptions": { binary: CHROME, args: CHROME_ARGS }
        }
      }
    }),
    signal: AbortSignal.timeout(TIMEOUT_MS)
  });

  const session = await sessionResponse.json();
  const sessionId = session.value.sessionId;
  const caps = session.value.capabilities;
  const bidi = await rpc(caps.webSocketUrl);
  const context = (await bidi.call("browsingContext.getTree", { maxDepth: 0 })).contexts[0].context;

  await bidi.call("browsingContext.navigate", {
    context,
    url: `data:text/html,${encodeURIComponent("<!doctype html><title>bench</title><div>ready</div>")}`,
    wait: "complete"
  });

  const targetsResponse = await fetch(`http://${caps["goog:chromeOptions"].debuggerAddress}/json/list`, {
    signal: AbortSignal.timeout(TIMEOUT_MS)
  });
  const targets = await targetsResponse.json();
  const cdp = await rpc(targets.find((target) => target.type === "page").webSocketDebuggerUrl);

  for (let i = 0; i < WARMUP; i += 1) {
    await cdp.call("Runtime.evaluate", {
      expression: EXPRESSION,
      awaitPromise: true,
      returnByValue: true,
      userGesture: true
    });

    await bidi.call("script.evaluate", {
      target: { context },
      expression: EXPRESSION,
      awaitPromise: true,
      resultOwnership: "none"
    });
  }

  const cdpTimes = [];
  const bidiTimes = [];

  for (let i = 0; i < ITERATIONS; i += 1) {
    let started = process.hrtime.bigint();
    await cdp.call("Runtime.evaluate", {
      expression: EXPRESSION,
      awaitPromise: true,
      returnByValue: true,
      userGesture: true
    });
    cdpTimes.push(Number(process.hrtime.bigint() - started) / 1e6);

    started = process.hrtime.bigint();
    await bidi.call("script.evaluate", {
      target: { context },
      expression: EXPRESSION,
      awaitPromise: true,
      resultOwnership: "none"
    });
    bidiTimes.push(Number(process.hrtime.bigint() - started) / 1e6);
  }

  const summarize = (values) => {
    const sorted = values.slice().sort((a, b) => a - b);
    return {
      mean: values.reduce((sum, value) => sum + value, 0) / values.length,
      median: sorted[Math.ceil(sorted.length * 0.5) - 1],
      p95: sorted[Math.ceil(sorted.length * 0.95) - 1]
    };
  };

  const cdpStats = summarize(cdpTimes);
  const bidiStats = summarize(bidiTimes);

  console.log(`iterations=${ITERATIONS}`);
  console.log(`warmup=${WARMUP}`);
  console.log(`expression=${EXPRESSION}`);
  console.log("");
  console.log("mode,mean_ms,median_ms,p95_ms");
  console.log(`cdp,${cdpStats.mean.toFixed(3)},${cdpStats.median.toFixed(3)},${cdpStats.p95.toFixed(3)}`);
  console.log(`bidi,${bidiStats.mean.toFixed(3)},${bidiStats.median.toFixed(3)},${bidiStats.p95.toFixed(3)}`);
  console.log("");
  console.log(`bidi_vs_cdp_mean_ratio=${(bidiStats.mean / cdpStats.mean).toFixed(3)}x`);
  console.log(`bidi_vs_cdp_median_ratio=${(bidiStats.median / cdpStats.median).toFixed(3)}x`);

  cdp.close();
  bidi.close();
  fetch(`${base}/session/${sessionId}`, { method: "DELETE" }).catch(() => {});
  driver.kill("SIGTERM");
})().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
