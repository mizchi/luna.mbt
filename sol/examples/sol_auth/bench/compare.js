import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Metrics for Sol
const solStaticTrend = new Trend('sol_static');
const solDynamicTrend = new Trend('sol_dynamic');
const solApiTrend = new Trend('sol_api');

// Metrics for Hono
const honoStaticTrend = new Trend('hono_static');
const honoDynamicTrend = new Trend('hono_dynamic');
const honoApiTrend = new Trend('hono_api');

const errorRate = new Rate('errors');

export const options = {
  scenarios: {
    comparison: {
      executor: 'constant-vus',
      vus: 50,
      duration: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.01'],
  },
};

const SOL_URL = __ENV.SOL_URL || 'http://localhost:3000';
const HONO_URL = __ENV.HONO_URL || 'http://localhost:3001';

const staticRoutes = ['/', '/about', '/form', '/admin'];
const dynamicRoutes = ['/docs/getting-started', '/docs/api/reference', '/blog', '/blog/2024/post'];
const apiRoutes = ['/api/health', '/api/middleware-test'];

export default function () {
  // Static route comparison
  const staticPath = staticRoutes[Math.floor(Math.random() * staticRoutes.length)];

  const solStaticRes = http.get(`${SOL_URL}${staticPath}`);
  solStaticTrend.add(solStaticRes.timings.duration);
  check(solStaticRes, { 'sol static 200': (r) => r.status === 200 }) || errorRate.add(1);

  const honoStaticRes = http.get(`${HONO_URL}${staticPath}`);
  honoStaticTrend.add(honoStaticRes.timings.duration);
  check(honoStaticRes, { 'hono static 200': (r) => r.status === 200 }) || errorRate.add(1);

  // Dynamic route comparison
  const dynamicPath = dynamicRoutes[Math.floor(Math.random() * dynamicRoutes.length)];

  const solDynamicRes = http.get(`${SOL_URL}${dynamicPath}`);
  solDynamicTrend.add(solDynamicRes.timings.duration);
  check(solDynamicRes, { 'sol dynamic 200': (r) => r.status === 200 }) || errorRate.add(1);

  const honoDynamicRes = http.get(`${HONO_URL}${dynamicPath}`);
  honoDynamicTrend.add(honoDynamicRes.timings.duration);
  check(honoDynamicRes, { 'hono dynamic 200': (r) => r.status === 200 }) || errorRate.add(1);

  // API route comparison
  const apiPath = apiRoutes[Math.floor(Math.random() * apiRoutes.length)];

  const solApiRes = http.get(`${SOL_URL}${apiPath}`);
  solApiTrend.add(solApiRes.timings.duration);
  check(solApiRes, { 'sol api 200': (r) => r.status === 200 }) || errorRate.add(1);

  const honoApiRes = http.get(`${HONO_URL}${apiPath}`);
  honoApiTrend.add(honoApiRes.timings.duration);
  check(honoApiRes, { 'hono api 200': (r) => r.status === 200 }) || errorRate.add(1);

  sleep(0.05);
}

export function handleSummary(data) {
  return {
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const m = data.metrics;

  const solStatic = m.sol_static?.values || {};
  const honoStatic = m.hono_static?.values || {};
  const solDynamic = m.sol_dynamic?.values || {};
  const honoDynamic = m.hono_dynamic?.values || {};
  const solApi = m.sol_api?.values || {};
  const honoApi = m.hono_api?.values || {};

  const fmt = (v) => (v || 0).toFixed(2);
  const ratio = (sol, hono) => {
    if (!hono || hono === 0) return 'N/A';
    return (sol / hono).toFixed(2) + 'x';
  };

  return `
╔══════════════════════════════════════════════════════════════════╗
║                    Sol vs Hono Comparison                        ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Response Times (p95)                                            ║
║  ─────────────────────────────────────────────────────────────   ║
║  Route Type      │ Sol (ms)  │ Hono (ms) │ Ratio (Sol/Hono)      ║
║  ────────────────┼───────────┼───────────┼──────────────────     ║
║  Static Pages    │ ${fmt(solStatic['p(95)']).padStart(7)}   │ ${fmt(honoStatic['p(95)']).padStart(7)}   │ ${ratio(solStatic['p(95)'], honoStatic['p(95)']).padStart(6)}            ║
║  Dynamic Routes  │ ${fmt(solDynamic['p(95)']).padStart(7)}   │ ${fmt(honoDynamic['p(95)']).padStart(7)}   │ ${ratio(solDynamic['p(95)'], honoDynamic['p(95)']).padStart(6)}            ║
║  API Endpoints   │ ${fmt(solApi['p(95)']).padStart(7)}   │ ${fmt(honoApi['p(95)']).padStart(7)}   │ ${ratio(solApi['p(95)'], honoApi['p(95)']).padStart(6)}            ║
║                                                                  ║
║  Average Response Times                                          ║
║  ─────────────────────────────────────────────────────────────   ║
║  Static Pages    │ ${fmt(solStatic.avg).padStart(7)}   │ ${fmt(honoStatic.avg).padStart(7)}   │ ${ratio(solStatic.avg, honoStatic.avg).padStart(6)}            ║
║  Dynamic Routes  │ ${fmt(solDynamic.avg).padStart(7)}   │ ${fmt(honoDynamic.avg).padStart(7)}   │ ${ratio(solDynamic.avg, honoDynamic.avg).padStart(6)}            ║
║  API Endpoints   │ ${fmt(solApi.avg).padStart(7)}   │ ${fmt(honoApi.avg).padStart(7)}   │ ${ratio(solApi.avg, honoApi.avg).padStart(6)}            ║
║                                                                  ║
║  Total Requests: ${m.http_reqs?.values?.count || 0}                                          ║
║  Error Rate: ${((m.errors?.values?.rate || 0) * 100).toFixed(2)}%                                              ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Note: Ratio > 1.0x means Sol is slower than Hono
      Ratio < 1.0x means Sol is faster than Hono
`;
}
