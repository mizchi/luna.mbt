import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const docsTrend = new Trend('docs_duration');
const blogTrend = new Trend('blog_duration');
const apiCatchAllTrend = new Trend('api_catch_all_duration');

export const options = {
  scenarios: {
    dynamic_routes: {
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

// Sample paths for dynamic routes
const docsPaths = [
  '/docs/getting-started',
  '/docs/api/reference',
  '/docs/guide/introduction',
  '/docs/advanced/configuration',
  '/docs/tutorial/step1/part2',
];

const blogPaths = [
  '/blog',
  '/blog/2024',
  '/blog/2024/01',
  '/blog/2024/01/hello-world',
  '/blog/posts/my-first-post',
];

const apiPaths = [
  '/api/test/users',
  '/api/test/users/123',
  '/api/test/products/category/electronics',
];

export default function () {
  // Docs catch-all route [...slug]
  const docsPath = docsPaths[Math.floor(Math.random() * docsPaths.length)];
  const docsRes = http.get(`${BASE_URL}${docsPath}`);
  docsTrend.add(docsRes.timings.duration);
  check(docsRes, {
    'docs status 200': (r) => r.status === 200,
    'docs has content': (r) => r.body.includes('__sol__'),
  }) || errorRate.add(1);

  // Blog optional catch-all route [[...path]]
  const blogPath = blogPaths[Math.floor(Math.random() * blogPaths.length)];
  const blogRes = http.get(`${BASE_URL}${blogPath}`);
  blogTrend.add(blogRes.timings.duration);
  check(blogRes, {
    'blog status 200': (r) => r.status === 200,
    'blog has content': (r) => r.body.includes('__sol__'),
  }) || errorRate.add(1);

  // API catch-all route
  const apiPath = apiPaths[Math.floor(Math.random() * apiPaths.length)];
  const apiRes = http.get(`${BASE_URL}${apiPath}`);
  apiCatchAllTrend.add(apiRes.timings.duration);
  check(apiRes, {
    'api status 200': (r) => r.status === 200,
    'api returns json': (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch {
        return false;
      }
    },
  }) || errorRate.add(1);

  sleep(0.1);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
    'bench/results/dynamic-routes.json': JSON.stringify(data, null, 2),
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  return `
=== Dynamic Routes Benchmark ===

Requests:
  Total: ${metrics.http_reqs?.values?.count || 0}
  Rate:  ${(metrics.http_reqs?.values?.rate || 0).toFixed(2)}/s

Response Times (p95):
  Docs [...slug]:      ${(metrics.docs_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  Blog [[...path]]:    ${(metrics.blog_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  API [...path]:       ${(metrics.api_catch_all_duration?.values?.['p(95)'] || 0).toFixed(2)}ms

Overall:
  Avg: ${(metrics.http_req_duration?.values?.avg || 0).toFixed(2)}ms
  p95: ${(metrics.http_req_duration?.values?.['p(95)'] || 0).toFixed(2)}ms
  p99: ${(metrics.http_req_duration?.values?.['p(99)'] || 0).toFixed(2)}ms

Errors: ${(metrics.errors?.values?.rate || 0) * 100}%
`;
}
