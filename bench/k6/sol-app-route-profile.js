import http from "k6/http";
import { check, fail, sleep } from "k6";
import { Trend, Rate } from "k6/metrics";

const BASE_URL = __ENV.BASE_URL || "http://localhost:7777";
const VUS = parseIntEnv(__ENV.VUS, 15);
const DURATION = __ENV.DURATION || "20s";
const THINK_TIME = parseNumber(__ENV.THINK_TIME, 0.05);

const errorRate = new Rate("errors");

const ROUTES = [
  { key: "page_home", path: "/", expect: "html", trend: new Trend("page_home_duration") },
  { key: "page_about", path: "/about", expect: "html", trend: new Trend("page_about_duration") },
  { key: "page_form", path: "/form", expect: "html", trend: new Trend("page_form_duration") },
  { key: "page_admin", path: "/admin", expect: "html", trend: new Trend("page_admin_duration") },
  { key: "page_admin_settings", path: "/admin/settings", expect: "html", trend: new Trend("page_admin_settings_duration") },
  { key: "page_docs", path: "/docs/getting-started", expect: "html", trend: new Trend("page_docs_duration") },
  { key: "page_blog", path: "/blog/2024", expect: "html", trend: new Trend("page_blog_duration") },
  { key: "api_health", path: "/api/health", expect: "json", trend: new Trend("api_health_duration") },
  { key: "api_middleware", path: "/api/bench/ping", expect: "json", trend: new Trend("api_middleware_duration") },
  { key: "api_catch_all", path: "/api/bench/test/users", expect: "json", trend: new Trend("api_catch_all_duration") },
];

export const options = {
  scenarios: buildScenarios(),
  thresholds: {
    errors: ["rate<0.01"],
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<700"],
  },
};

export function setup() {
  const health = http.get(`${BASE_URL}/api/health`);
  if (health.status !== 200) {
    fail(`health check failed: ${health.status}`);
  }
}

export default function () {
  const route = ROUTES.find((r) => __ENV.SCENARIO === r.key);
  if (!route) {
    fail(`unknown scenario: ${__ENV.SCENARIO}`);
  }

  const res = http.get(`${BASE_URL}${route.path}`, {
    tags: { route: route.path, kind: route.expect },
  });
  route.trend.add(res.timings.duration);

  let ok;
  if (route.expect === "html") {
    ok = check(res, {
      "status is 200": (r) => r.status === 200,
      "html has __sol__": (r) => r.body.includes('id="__sol__"'),
    });
  } else {
    ok = check(res, {
      "status is 200": (r) => r.status === 200,
      "json body": (r) => {
        try {
          JSON.parse(r.body);
          return true;
        } catch {
          return false;
        }
      },
    });
  }
  errorRate.add(ok ? 0 : 1, { route: route.path });

  if (THINK_TIME > 0) {
    sleep(THINK_TIME);
  }
}

export function handleSummary(data) {
  const rows = [];
  for (const route of ROUTES) {
    const metricName = `${route.key}_duration`;
    rows.push({
      path: route.path,
      p95: metric(data, metricName, "p(95)"),
      avg: metric(data, metricName, "avg"),
      max: metric(data, metricName, "max"),
    });
  }
  rows.sort((a, b) => b.p95 - a.p95);

  const lines = [
    "=== Sol App Route Profile (k6) ===",
    `base_url: ${BASE_URL}`,
    `vus/route: ${VUS}, duration: ${DURATION}`,
    "",
    "Top routes by p95 (ms):",
  ];
  for (const row of rows) {
    lines.push(
      `  ${row.path.padEnd(22)} p95=${row.p95.toFixed(2)} avg=${row.avg.toFixed(2)} max=${row.max.toFixed(2)}`
    );
  }

  const result = { stdout: `${lines.join("\n")}\n` };
  if (__ENV.RESULTS_JSON) {
    result[__ENV.RESULTS_JSON] = JSON.stringify(data, null, 2);
  }
  return result;
}

function buildScenarios() {
  const scenarios = {};
  let start = 0;
  for (const route of ROUTES) {
    scenarios[route.key] = {
      executor: "constant-vus",
      vus: VUS,
      duration: DURATION,
      startTime: `${start}s`,
      env: { SCENARIO: route.key },
      tags: { route: route.path },
    };
    start += parseDurationSeconds(DURATION) + 1;
  }
  return scenarios;
}

function parseDurationSeconds(duration) {
  if (duration.endsWith("s")) {
    return parseIntEnv(duration.slice(0, -1), 20);
  }
  if (duration.endsWith("m")) {
    return parseIntEnv(duration.slice(0, -1), 1) * 60;
  }
  return parseIntEnv(duration, 20);
}

function parseIntEnv(value, fallback) {
  const n = Number.parseInt(value || "", 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function parseNumber(value, fallback) {
  const n = Number.parseFloat(value || "");
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

function metric(data, name, key) {
  const m = data.metrics[name];
  if (!m || !m.values || m.values[key] === undefined) {
    return 0;
  }
  return m.values[key];
}
