// Smoke test: astra build and astra dev must serve every list_urls()
// entry — both go through the same Middleware::handler() (build via
// @testing.invoke, dev via node:http). Asserts presence + key markers
// rather than byte-identical (renderer has non-deterministic ordering
// in places like prefetch hints; tightening that is a separate issue).

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { setTimeout as sleep } from "node:timers/promises";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ASTRA_DIR = path.resolve(__dirname, "..");
const ROOT = path.resolve(ASTRA_DIR, "..");
const FIXTURE = path.join(ASTRA_DIR, "examples", "sol_docs");
const ASTRA_CLI = path.join(
  ROOT,
  "_build",
  "js",
  "release",
  "build",
  "mizchi",
  "astra",
  "cmd",
  "astra",
  "astra.js",
);
const PORT = Number(process.env.ASTRA_PARITY_PORT ?? 17840);

// Each entry: URL, marker (substring expected in both build + dev output).
const CASES = [
  { url: "/", markers: ['<link rel="modulepreload" href="/assets/loader.js">'] },
  { url: "/guide/", markers: ["<title>Getting Started</title>"] },
  { url: "/assets/loader.js", markers: ["luna:url"] },
];

function ensureBuilt() {
  if (fs.existsSync(ASTRA_CLI)) return;
  const r = spawnSync("moon", ["build", "--target", "js", "--release"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(r.status, 0, `moon build failed: ${r.stderr}`);
}

async function waitForServer(url, timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.status >= 200 && res.status < 600) return;
    } catch {
      // not yet up
    }
    await sleep(150);
  }
  throw new Error(`server at ${url} not reachable within ${timeoutMs}ms`);
}

function urlToDiskPath(outDir, url) {
  if (url === "/") return path.join(outDir, "index.html");
  if (url.endsWith("/")) return path.join(outDir, url.slice(1) + "index.html");
  return path.join(outDir, url.slice(1));
}

test("astra build dumps every URL with expected markers", async (t) => {
  ensureBuilt();

  const outDir = fs.mkdtempSync(path.join(os.tmpdir(), "astra-parity-"));
  t.after(() => fs.rmSync(outDir, { recursive: true, force: true }));

  const build = spawnSync("node", [ASTRA_CLI, "build", "--out", outDir], {
    cwd: FIXTURE,
    encoding: "utf8",
  });
  assert.equal(
    build.status,
    0,
    `astra build failed:\nstdout:\n${build.stdout}\nstderr:\n${build.stderr}`,
  );

  for (const { url, markers } of CASES) {
    const onDisk = urlToDiskPath(outDir, url);
    assert.ok(
      fs.existsSync(onDisk),
      `build output missing for ${url} (expected at ${onDisk})`,
    );
    const body = fs.readFileSync(onDisk, "utf-8");
    for (const m of markers) {
      assert.ok(
        body.includes(m),
        `build output for ${url} missing marker ${JSON.stringify(m)}`,
      );
    }
  }
});

test("astra dev serves every URL with the same markers as build", async (t) => {
  ensureBuilt();

  const dev = spawn("node", [ASTRA_CLI, "dev", "--port", String(PORT)], {
    cwd: FIXTURE,
    stdio: ["ignore", "pipe", "pipe"],
  });
  t.after(() => dev.kill("SIGTERM"));

  await waitForServer(`http://localhost:${PORT}/`);

  for (const { url, markers } of CASES) {
    const res = await fetch(`http://localhost:${PORT}${url}`);
    assert.equal(res.status, 200, `dev returned ${res.status} for ${url}`);
    const body = await res.text();
    for (const m of markers) {
      assert.ok(
        body.includes(m),
        `dev output for ${url} missing marker ${JSON.stringify(m)}`,
      );
    }
  }
});
