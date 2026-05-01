import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');

// Page trends
const staticTrend = new Trend('static_pages');
const dynamicTrend = new Trend('dynamic_pages');
const apiTrend = new Trend('api_endpoints');

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '10s',
      tags: { test_type: 'smoke' },
    },
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 20 },
        { duration: '30s', target: 20 },
        { duration: '10s', target: 0 },
      ],
      startTime: '15s',
      tags: { test_type: 'load' },
    },
    stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 50 },
        { duration: '20s', target: 50 },
        { duration: '10s', target: 0 },
      ],
      startTime: '60s',
      tags: { test_type: 'stress' },
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Route definitions
const staticRoutes = ['/', '/about', '/form', '/admin', '/admin/settings'];

const dynamicRoutes = [
  '/docs/getting-started',
  '/docs/api/reference',
  '/blog',
  '/blog/2024/01/post',
];

const apiRoutes = [
  '/api/health',
  '/api/middleware-test',
  '/api/test/users/123',
];

export default function () {
  // Static route
  const staticPath = staticRoutes[Math.floor(Math.random() * staticRoutes.length)];
  const staticRes = http.get(`${BASE_URL}${staticPath}`);
  staticTrend.add(staticRes.timings.duration);
  check(staticRes, {
    'static status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // Dynamic route
  const dynamicPath = dynamicRoutes[Math.floor(Math.random() * dynamicRoutes.length)];
  const dynamicRes = http.get(`${BASE_URL}${dynamicPath}`);
  dynamicTrend.add(dynamicRes.timings.duration);
  check(dynamicRes, {
    'dynamic status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // API route
  const apiPath = apiRoutes[Math.floor(Math.random() * apiRoutes.length)];
  const apiRes = http.get(`${BASE_URL}${apiPath}`);
  apiTrend.add(apiRes.timings.duration);
  check(apiRes, {
    'api status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'bench/results/all.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  return `
=== Sol App Full Benchmark ===

Requests:
  Total: ${metrics.http_reqs?.values?.count || 0}
  Rate:  ${(metrics.http_reqs?.values?.rate || 0).toFixed(2)}/s

Response Times by Route Type (p95):
  Static Pages:   ${(metrics.static_pages?.values?.['p(95)'] || 0).toFixed(2)}ms
  Dynamic Pages:  ${(metrics.dynamic_pages?.values?.['p(95)'] || 0).toFixed(2)}ms
  API Endpoints:  ${(metrics.api_endpoints?.values?.['p(95)'] || 0).toFixed(2)}ms

Overall Response Times:
  Avg: ${(metrics.http_req_duration?.values?.avg || 0).toFixed(2)}ms
  p50: ${(metrics.http_req_duration?.values?.['p(50)'] || 0).toFixed(2)}ms
  p95: ${(metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  p99: ${(metrics.http_req_duration?.values?.['p(99)'] || 0).toFixed(2)}ms
  max: ${(metrics.http_req_duration?.values?.max || 0).toFixed(2)}ms

Virtual Users:
  Max: ${metrics.vus?.values?.max || 0}

Error Rate: ${((metrics.errors?.values?.rate || 0) * 100).toFixed(2)}%
`;
}
