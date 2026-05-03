#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const files = process.argv.slice(2);

if (files.length === 0) {
  console.error(
    "Usage: node bench/k6/summarize-results.js <result1.json> <result2.json> ..."
  );
  process.exit(1);
}

const runs = files.map((file) => {
  const raw = fs.readFileSync(file, "utf8");
  const data = JSON.parse(raw);
  return {
    file,
    reqRate: metric(data, "http_reqs", "rate"),
    httpP95: metric(data, "http_req_duration", "p(95)"),
    httpMax: metric(data, "http_req_duration", "max"),
    pageP95: metric(data, "page_duration", "p(95)"),
    apiP95: metric(data, "api_duration", "p(95)"),
    errors: metric(data, "errors", "rate"),
  };
});

const metrics = [
  { key: "reqRate", label: "http_reqs.rate (/s)", unit: "" },
  { key: "httpP95", label: "http_req_duration p95", unit: "ms" },
  { key: "httpMax", label: "http_req_duration max", unit: "ms" },
  { key: "pageP95", label: "page_duration p95", unit: "ms" },
  { key: "apiP95", label: "api_duration p95", unit: "ms" },
  { key: "errors", label: "errors rate", unit: "" },
];

const lines = [];
lines.push("=== k6 Multi-Run Summary ===");
lines.push(`runs: ${runs.length}`);
lines.push("");
for (const metricInfo of metrics) {
  const values = runs
    .map((run) => run[metricInfo.key])
    .filter((value) => Number.isFinite(value));
  if (values.length === 0) continue;
  const med = median(values);
  const min = Math.min(...values);
  const max = Math.max(...values);
  lines.push(
    `${metricInfo.label}: median=${format(med)}${metricInfo.unit} min=${format(
      min
    )}${metricInfo.unit} max=${format(max)}${metricInfo.unit}`
  );
}

lines.push("");
lines.push("files:");
for (const run of runs) {
  lines.push(`- ${normalizePath(run.file)}`);
}

console.log(lines.join("\n"));

function metric(data, name, key) {
  const entry = data?.metrics?.[name];
  const value = entry?.values?.[key];
  return Number.isFinite(value) ? value : Number.NaN;
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 1) {
    return sorted[mid];
  }
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

function format(value) {
  return Number(value).toFixed(3);
}

function normalizePath(filePath) {
  return filePath.split(path.sep).join("/");
}
