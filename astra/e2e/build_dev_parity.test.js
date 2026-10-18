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
  { url: "/", markers: ["__LUNA_WC_SCAN__"] },
  { url: "/guide/", markers: ["<title>Getting Started</title>"] },
  { url: "/assets/style.css", markers: [".nav-bar"] },
  { url: "/components/sidebar-disclosure.js", markers: ["export function hydrate"] },
];

const COMPONENT_FIXTURE = path.join(ASTRA_DIR, "examples", "sol_components_demo");
const COMPONENT_CASES = [
  { url: "/color_palette/", marker: 'class="color-palette-component"' },
  { url: "/info_box/", marker: 'class="info-box-component"' },
];

function componentFixture(t) {
  const cwd = fs.mkdtempSync(path.join(ASTRA_DIR, "examples", ".ssr-fixture-"));
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  for (const name of ["docs", "astra.config.json", "moon.mod"]) {
    fs.cpSync(path.join(COMPONENT_FIXTURE, name), path.join(cwd, name), { recursive: true });
  }
  return cwd;
}

let built = false;
function ensureBuilt() {
  if (built) return;
  const r = spawnSync("moon", ["build", "--target", "js", "--release"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(r.status, 0, `moon build failed: ${r.stderr}`);
  built = true;
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

test("astra build renders React and MoonBit component pages", (t) => {
  ensureBuilt();
  const fixture = componentFixture(t);
  const outDir = fs.mkdtempSync(path.join(os.tmpdir(), "astra-components-"));
  t.after(() => fs.rmSync(outDir, { recursive: true, force: true }));
  for (const mode of ["middleware", "ssg"]) {
    const modeDir = path.join(outDir, mode);
    const build = spawnSync("node", [ASTRA_CLI, "build", "--mode", mode, "--out", modeDir], {
      cwd: fixture,
      encoding: "utf8",
    });
    assert.equal(build.status, 0, `${build.stdout}\n${build.stderr}`);
    for (const { url, marker } of COMPONENT_CASES) {
      const html = fs.readFileSync(urlToDiskPath(modeDir, url), "utf8");
      assert.ok(html.includes(marker), `${mode}: ${url} must contain the rendered component`);
      assert.doesNotMatch(html, /data-ssr="(?:pending|failed)"/);
    }
    const sidebar = fs.readFileSync(path.join(modeDir, "components/sidebar-disclosure.js"), "utf8");
    assert.match(sidebar, /export function hydrate/);
  }
});

test("astra dev renders React and MoonBit component pages", async (t) => {
  ensureBuilt();
  const fixture = componentFixture(t);
  const port = PORT + 1;
  const dev = spawn("node", [ASTRA_CLI, "dev", "--port", String(port)], {
    cwd: fixture,
    stdio: ["ignore", "ignore", "pipe"],
  });
  let stderr = "";
  dev.stderr.on("data", (chunk) => { stderr += chunk; });
  t.after(() => dev.kill("SIGTERM"));
  await waitForServer(`http://localhost:${port}/`);
  for (const { url, marker } of COMPONENT_CASES) {
    const res = await fetch(`http://localhost:${port}${url}`);
    assert.equal(res.status, 200, `${url}: ${stderr}`);
    const html = await res.text();
    assert.ok(html.includes(marker), `${url} must contain the rendered component: ${stderr}`);
    assert.doesNotMatch(html, /data-ssr="(?:pending|failed)"/);
  }
  await Promise.all(Array.from({ length: 3 }, async () => {
    const res = await fetch(`http://localhost:${port}/color_palette/`);
    assert.equal(res.status, 200);
    assert.match(await res.text(), /class="color-palette-component"/);
  }));
});

test("component SSR errors fail the build and return HTTP 500", async (t) => {
  ensureBuilt();
  fs.mkdirSync(path.join(ROOT, ".test-output"), { recursive: true });
  const fixture = fs.mkdtempSync(path.join(ROOT, ".test-output/astra-ssr-error-"));
  t.after(() => fs.rmSync(fixture, { recursive: true, force: true }));
  fs.mkdirSync(path.join(fixture, "docs/broken"), { recursive: true });
  fs.writeFileSync(path.join(fixture, "astra.config.json"), JSON.stringify({ docs_dir: "docs" }));
  fs.writeFileSync(path.join(fixture, "docs/broken/page.json"), JSON.stringify({ ssr: true, renderer: "react" }));
  fs.writeFileSync(path.join(fixture, "docs/broken/broken.tsx"), 'export default function Broken() { throw new Error("intentional SSR failure"); }');
  for (const mode of ["middleware", "ssg"]) {
    const build = spawnSync("node", [ASTRA_CLI, "build", "--mode", mode], { cwd: fixture, encoding: "utf8" });
    assert.equal(build.status, 1, `${mode}: ${build.stdout}\n${build.stderr}`);
    assert.match(build.stdout, /astra build: FAILED:/);
    assert.equal(fs.existsSync(path.join(fixture, "dist/broken/index.html")), false);
  }

  const port = PORT + 2;
  const dev = spawn("node", [ASTRA_CLI, "dev", "--port", String(port)], {
    cwd: fixture,
    stdio: "ignore",
  });
  t.after(() => dev.kill("SIGTERM"));
  await waitForServer(`http://localhost:${port}/broken/`);
  const res = await fetch(`http://localhost:${port}/broken/`);
  assert.equal(res.status, 500);
  assert.match(await res.text(), /Failed to render TSX component: broken/);
});

test("SSG component output updates after a source change", (t) => {
  ensureBuilt();
  fs.mkdirSync(path.join(ROOT, ".test-output"), { recursive: true });
  const fixture = fs.mkdtempSync(path.join(ROOT, ".test-output/astra-ssr-cache-"));
  t.after(() => fs.rmSync(fixture, { recursive: true, force: true }));
  fs.mkdirSync(path.join(fixture, "docs/versioned"), { recursive: true });
  fs.writeFileSync(path.join(fixture, "astra.config.json"), JSON.stringify({ docs_dir: "docs" }));
  fs.writeFileSync(path.join(fixture, "docs/versioned/page.json"), JSON.stringify({ ssr: true, renderer: "react" }));
  for (const version of ["first-render", "second-render"]) {
    fs.writeFileSync(path.join(fixture, "docs/versioned/versioned.tsx"), `export default function Versioned() { return <p>${version}</p>; }`);
    const build = spawnSync("node", [ASTRA_CLI, "build", "--mode", "ssg"], { cwd: fixture, encoding: "utf8" });
    assert.equal(build.status, 0, `${build.stdout}\n${build.stderr}`);
    const html = fs.readFileSync(path.join(fixture, "dist/versioned/index.html"), "utf8");
    assert.ok(html.includes(version), `expected fresh SSR output for ${version}`);
  }
});
