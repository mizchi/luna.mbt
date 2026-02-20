#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const MIX_METRICS = [
  metricSpec("http_reqs", "rate", "http_reqs.rate", "/s", "higher"),
  metricSpec("http_req_duration", "p(95)", "http_req_duration p95", "ms", "lower"),
  metricSpec("http_req_duration", "avg", "http_req_duration avg", "ms", "lower"),
  metricSpec("page_duration", "p(95)", "page_duration p95", "ms", "lower"),
  metricSpec("page_duration", "avg", "page_duration avg", "ms", "lower"),
  metricSpec("api_duration", "p(95)", "api_duration p95", "ms", "lower"),
  metricSpec("api_duration", "avg", "api_duration avg", "ms", "lower"),
  metricSpec("errors", "rate", "errors rate", "", "lower"),
  metricSpec("http_req_failed", "rate", "http_req_failed rate", "", "lower"),
];

const AGGREGATED_ROUTE_METRICS = new Set([
  "http_req_duration",
  "page_duration",
  "api_duration",
]);

if (isCliExecution()) {
  const exitCode = runCli(process.argv.slice(2));
  process.exit(exitCode);
}

export function runCli(args) {
  if (args.length < 2 || args.length > 3) {
    console.error(
      "Usage: node bench/k6/compare.js <baseline.json> <candidate.json> [mix|route|auto]"
    );
    return 1;
  }

  const [baselineFile, candidateFile, modeArg = "auto"] = args;
  const mode = normalizeMode(modeArg);
  if (!mode) {
    console.error(`Invalid mode: ${modeArg} (expected: mix, route, auto)`);
    return 1;
  }

  const baseline = loadResultFile(baselineFile);
  const candidate = loadResultFile(candidateFile);
  if (!baseline || !candidate) {
    return 1;
  }

  const report = renderComparisonReport(
    baseline.data,
    candidate.data,
    mode,
    normalizePath(baseline.file),
    normalizePath(candidate.file)
  );
  console.log(report);
  return 0;
}

export function renderComparisonReport(
  baselineData,
  candidateData,
  mode = "auto",
  baselineLabel = "baseline",
  candidateLabel = "candidate"
) {
  const rows = buildComparisonRows(baselineData, candidateData, mode);
  const mixRows = rows.filter((row) => row.group === "mix");
  const routeRows = rows.filter((row) => row.group === "route");

  const lines = [];
  lines.push("=== k6 Comparison ===");
  lines.push(`baseline : ${baselineLabel}`);
  lines.push(`candidate: ${candidateLabel}`);
  lines.push(`mode     : ${mode}`);
  lines.push("");

  if (mixRows.length > 0) {
    lines.push("Mix metrics:");
    lines.push(...renderRows(mixRows));
    lines.push("");
  }

  if (routeRows.length > 0) {
    lines.push("Route metrics:");
    lines.push(...renderRows(routeRows));
    lines.push("");
  }

  if (mixRows.length === 0 && routeRows.length === 0) {
    lines.push("(no comparable metrics found)");
  }

  return lines.join("\n");
}

export function buildComparisonRows(baselineData, candidateData, mode = "auto") {
  const rows = [];
  if (mode === "mix" || mode === "auto") {
    rows.push(...buildMixRows(baselineData, candidateData));
  }
  if (mode === "route" || mode === "auto") {
    rows.push(...buildRouteRows(baselineData, candidateData));
  }
  return rows;
}

function buildMixRows(baselineData, candidateData) {
  const rows = [];
  for (const spec of MIX_METRICS) {
    const baseline = getMetricValue(baselineData, spec.metric, spec.key);
    const candidate = getMetricValue(candidateData, spec.metric, spec.key);
    const row = buildRow("mix", spec.label, spec.unit, spec.better, baseline, candidate);
    if (row) {
      rows.push(row);
    }
  }
  return rows;
}

function buildRouteRows(baselineData, candidateData) {
  const baselineMetrics = baselineData?.metrics ?? {};
  const candidateMetrics = candidateData?.metrics ?? {};
  const routeMetricNames = intersectRouteMetricNames(
    Object.keys(baselineMetrics),
    Object.keys(candidateMetrics)
  );

  const rows = [];
  for (const name of routeMetricNames) {
    const p95 = buildRow(
      "route",
      `${name} p95`,
      "ms",
      "lower",
      getMetricValue(baselineData, name, "p(95)"),
      getMetricValue(candidateData, name, "p(95)")
    );
    if (p95) {
      rows.push(p95);
    }

    const avg = buildRow(
      "route",
      `${name} avg`,
      "ms",
      "lower",
      getMetricValue(baselineData, name, "avg"),
      getMetricValue(candidateData, name, "avg")
    );
    if (avg) {
      rows.push(avg);
    }
  }

  return rows;
}

function renderRows(rows) {
  const header = pad("metric", 40) +
    pad("baseline", 12) +
    pad("candidate", 12) +
    pad("delta", 12) +
    pad("delta%", 10) +
    "verdict";
  const lines = [header];
  for (const row of rows) {
    lines.push(
      pad(withUnit(row.label, row.unit), 40) +
      pad(format(row.baseline), 12) +
      pad(format(row.candidate), 12) +
      pad(formatSigned(row.delta), 12) +
      pad(formatPercent(row.deltaPercent), 10) +
      row.verdict
    );
  }
  return lines;
}

function buildRow(group, label, unit, better, baseline, candidate) {
  if (!Number.isFinite(baseline) || !Number.isFinite(candidate)) {
    return null;
  }
  const delta = candidate - baseline;
  const deltaPercent = baseline === 0 ? Number.NaN : (delta / baseline) * 100;
  const verdict = judge(delta, better);
  return {
    group,
    label,
    unit,
    better,
    baseline,
    candidate,
    delta,
    deltaPercent,
    verdict,
  };
}

function intersectRouteMetricNames(leftNames, rightNames) {
  const left = new Set(leftNames.filter(isRouteMetricName));
  const names = [];
  for (const name of rightNames) {
    if (left.has(name) && isRouteMetricName(name)) {
      names.push(name);
    }
  }
  names.sort();
  return names;
}

function isRouteMetricName(name) {
  if (!name.endsWith("_duration")) {
    return false;
  }
  if (AGGREGATED_ROUTE_METRICS.has(name)) {
    return false;
  }
  return name.startsWith("page_") || name.startsWith("api_");
}

function judge(delta, better) {
  const epsilon = 1e-9;
  if (Math.abs(delta) <= epsilon) {
    return "same";
  }
  if (better === "lower") {
    return delta < 0 ? "better" : "worse";
  }
  return delta > 0 ? "better" : "worse";
}

function metricSpec(metric, key, label, unit, better) {
  return { metric, key, label, unit, better };
}

function normalizeMode(value) {
  if (value === "mix" || value === "route" || value === "auto") {
    return value;
  }
  return null;
}

function loadResultFile(filePath) {
  try {
    const raw = fs.readFileSync(filePath, "utf8");
    return { file: filePath, data: JSON.parse(raw) };
  } catch (error) {
    console.error(`Failed to read ${filePath}: ${error.message}`);
    return null;
  }
}

function getMetricValue(data, metric, key) {
  const value = data?.metrics?.[metric]?.values?.[key];
  return Number.isFinite(value) ? value : Number.NaN;
}

function withUnit(label, unit) {
  return unit === "" ? label : `${label} (${unit})`;
}

function format(value) {
  return Number(value).toFixed(3);
}

function formatSigned(value) {
  const n = Number(value);
  const sign = n > 0 ? "+" : "";
  return `${sign}${n.toFixed(3)}`;
}

function formatPercent(value) {
  if (!Number.isFinite(value)) {
    return "n/a";
  }
  const sign = value > 0 ? "+" : "";
  return `${sign}${value.toFixed(1)}%`;
}

function pad(value, width) {
  return String(value).padEnd(width);
}

function normalizePath(filePath) {
  return filePath.split(path.sep).join("/");
}

function isCliExecution() {
  const scriptPath = process.argv[1];
  if (!scriptPath) {
    return false;
  }
  return path.resolve(scriptPath) === path.resolve(fileURLToPath(import.meta.url));
}
