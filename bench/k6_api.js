import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE_URL || 'http://localhost:7800';

export const options = {
  vus: 10,
  duration: '10s',
};

export default function () {
  const health = http.get(`${BASE}/api/health`);
  check(health, { 'health 200': (r) => r.status === 200 });

  const items = http.get(`${BASE}/api/items`);
  check(items, { 'items 200': (r) => r.status === 200 });

  const echo = http.get(`${BASE}/api/echo/hello`);
  check(echo, { 'echo 200': (r) => r.status === 200 });
}
