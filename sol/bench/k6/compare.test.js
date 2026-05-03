import test from "node:test";
import assert from "node:assert/strict";

import { buildComparisonRows, renderComparisonReport } from "./compare.js";

test("mix mode compares p95/avg/error/rate metrics", () => {
  const baseline = {
    metrics: {
      http_reqs: { values: { rate: 100 } },
      http_req_duration: { values: { "p(95)": 10, avg: 8 } },
      page_duration: { values: { "p(95)": 12, avg: 9 } },
      api_duration: { values: { "p(95)": 5, avg: 4 } },
      errors: { values: { rate: 0.01 } },
      http_req_failed: { values: { rate: 0.02 } },
    },
  };
  const candidate = {
    metrics: {
      http_reqs: { values: { rate: 120 } },
      http_req_duration: { values: { "p(95)": 8, avg: 7 } },
      page_duration: { values: { "p(95)": 10, avg: 8 } },
      api_duration: { values: { "p(95)": 4, avg: 3 } },
      errors: { values: { rate: 0.005 } },
      http_req_failed: { values: { rate: 0.01 } },
    },
  };

  const rows = buildComparisonRows(baseline, candidate, "mix");
  const p95 = rows.find((row) => row.label === "http_req_duration p95");
  assert.ok(p95);
  assert.equal(p95.verdict, "better");
  assert.equal(Number(p95.delta.toFixed(3)), -2);

  const rate = rows.find((row) => row.label === "http_reqs.rate");
  assert.ok(rate);
  assert.equal(rate.verdict, "better");
  assert.equal(Number(rate.delta.toFixed(3)), 20);
});

test("route mode compares per-route duration metrics only", () => {
  const baseline = {
    metrics: {
      page_duration: { values: { "p(95)": 20, avg: 10 } },
      page_home_duration: { values: { "p(95)": 5, avg: 3 } },
      api_health_duration: { values: { "p(95)": 2, avg: 1 } },
    },
  };
  const candidate = {
    metrics: {
      page_duration: { values: { "p(95)": 19, avg: 9 } },
      page_home_duration: { values: { "p(95)": 4, avg: 2.5 } },
      api_health_duration: { values: { "p(95)": 1.8, avg: 0.9 } },
    },
  };

  const rows = buildComparisonRows(baseline, candidate, "route");
  assert.equal(rows.some((row) => row.label.startsWith("page_duration")), false);
  assert.equal(rows.some((row) => row.label === "page_home_duration p95"), true);
  assert.equal(rows.some((row) => row.label === "api_health_duration avg"), true);
});

test("renderComparisonReport includes mode and metric sections", () => {
  const baseline = {
    metrics: {
      http_reqs: { values: { rate: 100 } },
      http_req_duration: { values: { "p(95)": 10, avg: 8 } },
      page_duration: { values: { "p(95)": 12, avg: 9 } },
      api_duration: { values: { "p(95)": 5, avg: 4 } },
      errors: { values: { rate: 0.01 } },
      http_req_failed: { values: { rate: 0.02 } },
      page_home_duration: { values: { "p(95)": 5, avg: 3 } },
    },
  };
  const candidate = {
    metrics: {
      http_reqs: { values: { rate: 110 } },
      http_req_duration: { values: { "p(95)": 9, avg: 7 } },
      page_duration: { values: { "p(95)": 11, avg: 8 } },
      api_duration: { values: { "p(95)": 4.5, avg: 3.5 } },
      errors: { values: { rate: 0.008 } },
      http_req_failed: { values: { rate: 0.01 } },
      page_home_duration: { values: { "p(95)": 4.8, avg: 2.8 } },
    },
  };

  const report = renderComparisonReport(
    baseline,
    candidate,
    "auto",
    "base.json",
    "next.json"
  );
  assert.match(report, /=== k6 Comparison ===/);
  assert.match(report, /mode     : auto/);
  assert.match(report, /Mix metrics:/);
  assert.match(report, /Route metrics:/);
});
