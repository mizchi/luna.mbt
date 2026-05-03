import http from "k6/http";
import { check, fail, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

const errorRate = new Rate("errors");
const pageDuration = new Trend("page_duration");
const apiDuration = new Trend("api_duration");

const BASE_URL = __ENV.BASE_URL || "http://localhost:7777";
const THINK_TIME = parseNumber(__ENV.THINK_TIME, 0.1);
const VUS = parseIntEnv(__ENV.VUS, 20);
const DURATION = __ENV.DURATION || "30s";

const PAGE_ROUTES = [
  "/",
  "/about",
  "/form",
  "/admin",
  "/admin/settings",
  "/docs/getting-started",
  "/blog/2024",
];

const API_ROUTES = [
  "/api/health",
  "/api/bench/ping",
  "/api/bench/test/users",
];

export const options = {
  vus: VUS,
  duration: DURATION,
  thresholds: {
    http_req_failed: ["rate<0.01"],
    errors: ["rate<0.01"],
    http_req_duration: ["p(95)<600", "p(99)<1200"],
    page_duration: ["p(95)<700"],
    api_duration: ["p(95)<250"],
  },
};

export function setup() {
  const health = http.get(`${BASE_URL}/api/health`);
  if (health.status !== 200) {
    fail(`health check failed: ${health.status} (${BASE_URL}/api/health)`);
  }
}

export default function () {
  const pagePath = pickRoute(PAGE_ROUTES);
  const pageResponse = http.get(`${BASE_URL}${pagePath}`, {
    tags: { kind: "page", route: pagePath },
  });
  pageDuration.add(pageResponse.timings.duration, { route: pagePath });
  const pageOk = check(pageResponse, {
    "page status is 200": (r) => r.status === 200,
    "page includes __sol__ root": (r) => r.body.includes('id="__sol__"'),
  });
  errorRate.add(pageOk ? 0 : 1, { kind: "page", route: pagePath });

  const apiPath = pickRoute(API_ROUTES);
  const apiResponse = http.get(`${BASE_URL}${apiPath}`, {
    tags: { kind: "api", route: apiPath },
  });
  apiDuration.add(apiResponse.timings.duration, { route: apiPath });
  const apiOk = check(apiResponse, {
    "api status is 200": (r) => r.status === 200,
    "api returns json": (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch {
        return false;
      }
    },
  });
  errorRate.add(apiOk ? 0 : 1, { kind: "api", route: apiPath });

  if (THINK_TIME > 0) {
    sleep(THINK_TIME);
  }
}

export function handleSummary(data) {
  const summary = [
    "=== Sol App k6 Benchmark ===",
    `base_url: ${BASE_URL}`,
    `vus: ${VUS}`,
    `duration: ${DURATION}`,
    "",
    `http_reqs: ${formatNumber(metric(data, "http_reqs", "count"))}`,
    `req_rate: ${formatNumber(metric(data, "http_reqs", "rate"))}/s`,
    `errors: ${(metric(data, "errors", "rate") * 100).toFixed(2)}%`,
    "",
    `http_req_duration p95: ${formatNumber(metric(data, "http_req_duration", "p(95)"))}ms`,
    `http_req_duration max: ${formatNumber(metric(data, "http_req_duration", "max"))}ms`,
    `page_duration p95: ${formatNumber(metric(data, "page_duration", "p(95)"))}ms`,
    `api_duration p95: ${formatNumber(metric(data, "api_duration", "p(95)"))}ms`,
  ].join("\n");

  const result = { stdout: `${summary}\n` };
  if (__ENV.RESULTS_JSON) {
    result[__ENV.RESULTS_JSON] = JSON.stringify(data, null, 2);
  }
  return result;
}

function parseIntEnv(value, fallback) {
  const n = Number.parseInt(value || "", 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function parseNumber(value, fallback) {
  const n = Number.parseFloat(value || "");
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

function pickRoute(routes) {
  const i = Math.floor(Math.random() * routes.length);
  return routes[i];
}

function metric(data, name, key) {
  const entry = data.metrics[name];
  if (!entry || !entry.values || entry.values[key] === undefined) {
    return 0;
  }
  return entry.values[key];
}

function formatNumber(value) {
  return Number(value).toFixed(2);
}
