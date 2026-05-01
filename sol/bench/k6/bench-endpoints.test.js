import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..", "..");
const MIX_SCRIPT = path.join(ROOT, "bench", "k6", "sol-app-mix.js");
const ROUTE_PROFILE_SCRIPT = path.join(
  ROOT,
  "bench",
  "k6",
  "sol-app-route-profile.js"
);
const APP_ROUTES = path.join(
  ROOT,
  "examples",
  "sol_app",
  "app",
  "server",
  "routes.mbt"
);

test("k6 mix script uses dedicated benchmark API endpoints", () => {
  const script = fs.readFileSync(MIX_SCRIPT, "utf8");
  assert.match(script, /\/api\/bench\/ping/);
  assert.match(script, /\/api\/bench\/test\/users/);
  assert.doesNotMatch(script, /\/api\/middleware-test/);
  assert.doesNotMatch(script, /\/api\/test\/users/);
});

test("k6 route profile script uses dedicated benchmark API endpoints", () => {
  const script = fs.readFileSync(ROUTE_PROFILE_SCRIPT, "utf8");
  assert.match(script, /\/api\/bench\/ping/);
  assert.match(script, /\/api\/bench\/test\/users/);
  assert.doesNotMatch(script, /\/api\/middleware-test/);
  assert.doesNotMatch(script, /\/api\/test\/users/);
});

test("sol_app exposes benchmark API routes separately from debug routes", () => {
  const routes = fs.readFileSync(APP_ROUTES, "utf8");
  assert.match(routes, /path="\/api\/bench\/ping"/);
  assert.match(routes, /path="\/api\/bench\/test\/\[\.\.\.path\]"/);
  assert.match(routes, /path="\/api\/middleware-test"/);
  assert.match(routes, /path="\/api\/test\/\[\.\.\.path\]"/);
});
