import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const homeTrend = new Trend('home_duration');
const aboutTrend = new Trend('about_duration');
const formTrend = new Trend('form_duration');
const adminTrend = new Trend('admin_duration');

export const options = {
  scenarios: {
    static_routes: {
      executor: 'constant-vus',
      vus: 10,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  // Home page
  const homeRes = http.get(`${BASE_URL}/`);
  homeTrend.add(homeRes.timings.duration);
  check(homeRes, {
    'home status 200': (r) => r.status === 200,
    'home has content': (r) => r.body.includes('__sol__'),
  }) || errorRate.add(1);

  // About page
  const aboutRes = http.get(`${BASE_URL}/about`);
  aboutTrend.add(aboutRes.timings.duration);
  check(aboutRes, {
    'about status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // Form page
  const formRes = http.get(`${BASE_URL}/form`);
  formTrend.add(formRes.timings.duration);
  check(formRes, {
    'form status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  // Admin page
  const adminRes = http.get(`${BASE_URL}/admin`);
  adminTrend.add(adminRes.timings.duration);
  check(adminRes, {
    'admin status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(0.1);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'bench/results/static-routes.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  return `
=== Static Routes Benchmark ===

Requests:
  Total: ${metrics.http_reqs?.values?.count || 0}
  Rate:  ${(metrics.http_reqs?.values?.rate || 0).toFixed(2)}/s

Response Times (p95):
  Home:  ${(metrics.home_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  About: ${(metrics.about_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  Form:  ${(metrics.form_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  Admin: ${(metrics.admin_duration?.values?.['p(95)'] || 0).toFixed(2)}ms

Overall:
  Avg: ${(metrics.http_req_duration?.values?.avg || 0).toFixed(2)}ms
  p95: ${(metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  p99: ${(metrics.http_req_duration?.values?.['p(99)'] || 0).toFixed(2)}ms

Errors: ${(metrics.errors?.values?.rate || 0) * 100}%
`;
}
