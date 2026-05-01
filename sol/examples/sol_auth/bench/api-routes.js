import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const healthTrend = new Trend('health_duration');
const middlewareTestTrend = new Trend('middleware_test_duration');

export const options = {
  scenarios: {
    api_routes: {
      executor: 'constant-vus',
      vus: 10,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<100'],
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Health check API
  const healthRes = http.get(`${BASE_URL}/api/health`);
  healthTrend.add(healthRes.timings.duration);
  check(healthRes, {
    'health status 200': (r) => r.status === 200,
    'health returns ok': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.status === 'ok';
      } catch {
        return false;
      }
    },
  }) || errorRate.add(1);

  // Middleware test API
  const mwRes = http.get(`${BASE_URL}/api/middleware-test`);
  middlewareTestTrend.add(mwRes.timings.duration);
  check(mwRes, {
    'middleware-test status 200': (r) => r.status === 200,
    'middleware-test returns json': (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch {
        return false;
      }
    },
  }) || errorRate.add(1);

  sleep(0.05);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'bench/results/api-routes.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  return `
=== API Routes Benchmark ===

Requests:
  Total: ${metrics.http_reqs?.values?.count || 0}
  Rate:  ${(metrics.http_reqs?.values?.rate || 0).toFixed(2)}/s

Response Times (p95):
  /api/health:          ${(metrics.health_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  /api/middleware-test: ${(metrics.middleware_test_duration?.values?.['p(95)'] || 0).toFixed(2)}ms

Overall:
  Avg: ${(metrics.http_req_duration?.values?.avg || 0).toFixed(2)}ms
  p95: ${(metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  p99: ${(metrics.http_req_duration?.values?.['p(99)'] || 0).toFixed(2)}ms

Errors: ${(metrics.errors?.values?.rate || 0) * 100}%
`;
}
