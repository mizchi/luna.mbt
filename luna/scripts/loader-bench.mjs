#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { chromium } from "playwright";
import { rolldown } from "rolldown";

const root = fileURLToPath(new URL("../../", import.meta.url));
const sourcePath = "js/loader/src/runtime/islands.ts";
const turns = 2000;
const { values } = parseArgs({
  options: {
    compare: { type: "string" },
    json: { type: "string" },
    samples: { type: "string", default: "11" },
    warmup: { type: "string", default: "3" },
  },
});
const samples = Number(values.samples);
const warmup = Number(values.warmup);
if (!Number.isInteger(samples) || samples < 1 || !Number.isInteger(warmup) || warmup < 0) {
  throw new Error("samples must be positive and warmup must be non-negative integers");
}

async function compile(source, name) {
  const bundle = await rolldown({
    input: "lifecycle-bench",
    plugins: [
      {
        name: "lifecycle-bench",
        resolveId(id) {
          if (id === "lifecycle-bench") return id;
        },
        load(id) {
          if (id === "lifecycle-bench") return { code: source, moduleType: "ts" };
        },
      },
    ],
  });
  try {
    const { output } = await bundle.generate({ format: "iife", name, minify: true });
    return output[0].code;
  } finally {
    await bundle.close();
  }
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

const sources = new Map();
let compareCommit;
if (values.compare) {
  // Resolve to an immutable commit before reading the previous implementation.
  compareCommit = execFileSync(
    "git",
    ["rev-parse", "--verify", "--end-of-options", `${values.compare}^{commit}`],
    { cwd: root, encoding: "utf8" },
  ).trim();
  sources.set(
    "previous",
    execFileSync("git", ["show", `${compareCommit}:${sourcePath}`], {
      cwd: root,
      encoding: "utf8",
    }),
  );
}
sources.set("current", await readFile(new URL(`../../${sourcePath}`, import.meta.url), "utf8"));
const browser = await chromium.launch({ headless: true });
try {
  const page = await browser.newPage();
  await page.setContent("<!doctype html><body></body>");
  for (const [name, source] of sources) {
    await page.addScriptTag({ content: await compile(source, name) });
  }
  const entries = [];
  for (const islands of [0, 1, 100, 1000]) {
    for (const scenario of ["text-update", "append-only", "element-replace", "detach-remount"]) {
      if (!islands && scenario === "detach-remount") continue;
      const timings = Object.fromEntries([...sources.keys()].map((name) => [name, []]));
      for (let sample = -warmup; sample < samples; sample++) {
        // Alternate order so warmup and machine load do not favor one implementation.
        const order = [...sources.keys()];
        if (sample % 2) order.reverse();
        for (const name of order) {
          const elapsed = await page.evaluate(
            async ({ name, islands, scenario, turns }) => {
              const container = document.createElement("main");
              const sidebar = document.createElement("aside");
              const hosts = Array.from({ length: islands }, () =>
                document.createElement("section"),
              );
              container.append(...hosts, sidebar);
              document.body.append(container);
              const scope = window[name].createIslandLifecycle();
              let disposed = 0;
              const mount = () => () => disposed++;
              try {
                await Promise.all(hosts.map((host) => scope.mount(host, mount)));
                sidebar.append(document.createElement("i"));
                await Promise.resolve();
                const start = performance.now();
                for (let i = 0; i < turns; i++) {
                  if (scenario === "text-update") sidebar.textContent = String(i);
                  else if (scenario === "append-only") sidebar.append(document.createElement("i"));
                  else if (scenario === "element-replace")
                    sidebar.replaceChildren(document.createElement("i"));
                  else hosts[0].remove();
                  // Include MutationObserver work after every DOM update.
                  await Promise.resolve();
                  if (scenario === "detach-remount") {
                    container.append(hosts[0]);
                    await scope.mount(hosts[0], mount);
                  }
                }
                const elapsed = performance.now() - start;
                scope.dispose();
                const expected = islands + (scenario === "detach-remount" ? turns : 0);
                if (disposed !== expected)
                  throw new Error(`Disposal count: ${disposed}, expected ${expected}`);
                return elapsed;
              } finally {
                scope.dispose();
                container.remove();
              }
            },
            { name, islands, scenario, turns },
          );
          if (sample >= 0) timings[name].push(elapsed);
        }
      }
      const medians = Object.fromEntries(
        Object.entries(timings).map(([name, times]) => [name, median(times)]),
      );
      const entry = { scenario, islands, turns, medianMs: medians, samplesMs: timings };
      entries.push(entry);
      const comparison =
        medians.previous === undefined
          ? ""
          : `  previous ${medians.previous.toFixed(2)} ms  (${((medians.current / medians.previous - 1) * 100).toFixed(1)}%)`;
      console.log(
        `${scenario.padEnd(16)} ${String(islands).padStart(4)} islands  ${medians.current.toFixed(2).padStart(8)} ms${comparison}`,
      );
    }
  }
  const report = {
    browser: browser.version(),
    node: process.version,
    platform: process.platform,
    arch: process.arch,
    compare: compareCommit,
    samples,
    warmup,
    entries,
  };
  if (values.json) await writeFile(values.json, JSON.stringify(report, null, 2) + "\n");
} finally {
  await browser.close();
}
