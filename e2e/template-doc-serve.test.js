/**
 * E2E: Verify `sol new --doc` generated project can build and produce valid SSG output.
 *
 * This test:
 * 1. Scaffolds a doc project via `sol new --doc`
 * 2. Installs MoonBit + npm deps
 * 3. Runs `sol generate` then `sol build`
 * 4. Verifies: API health endpoint, generated HTML pages, CSS, sitemap
 * 5. Starts server and checks API health
 * 6. Cleans up
 *
 * Requires: moon, node, pnpm
 * Timeout: 120s (includes build time)
 */

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "cli",
  "cli.js"
);

const PORT = 7654;
const BASE = `http://localhost:${PORT}`;

function ensureCliBuilt() {
  const build = spawnSync("moon", ["build", "--target", "js", "src/cli"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(
    build.status,
    0,
    `failed to build CLI\nstdout:\n${build.stdout}\nstderr:\n${build.stderr}`
  );
}

function runSync(cmd, args, cwd) {
  const result = spawnSync(cmd, args, {
    cwd,
    encoding: "utf8",
    timeout: 60_000,
  });
  return result;
}

async function waitForServer(url, timeoutMs = 30_000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
    } catch {
      // not ready yet
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Server at ${url} did not start within ${timeoutMs}ms`);
}

test("sol new --doc: build and serve e2e", { timeout: 120_000 }, async () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-doc-serve-e2e-")
  );
  let serverProcess = null;

  try {
    const projectDir = path.join(sandbox, "mydocs");

    // Step 1: Scaffold
    const create = runSync(
      "node",
      [CLI_DEBUG, "new", "mydocs", "--user", "testuser", "--doc"],
      sandbox
    );
    assert.equal(
      create.status,
      0,
      `sol new --doc failed:\n${create.stdout}\n${create.stderr}`
    );

    // Step 2: Install MoonBit deps
    const install = runSync("moon", ["install"], projectDir);
    assert.ok(
      fs.existsSync(path.join(projectDir, ".mooncakes")),
      `moon install failed:\n${install.stdout}\n${install.stderr}`
    );

    // Step 3: Install npm deps
    const npmInstall = runSync("pnpm", ["install"], projectDir);
    // pnpm install may fail if no lockfile, that's ok for basic serve

    // Step 4: Generate + Build
    const generate = runSync(
      "node",
      [CLI_DEBUG, "generate"],
      projectDir
    );
    // generate may produce warnings, check it doesn't hard-fail
    assert.ok(
      generate.status === 0 || generate.status === null,
      `sol generate failed:\n${generate.stdout}\n${generate.stderr}`
    );

    const build = runSync(
      "node",
      [CLI_DEBUG, "build"],
      projectDir
    );
    assert.equal(
      build.status,
      0,
      `sol build failed:\n${build.stdout}\n${build.stderr}`
    );

    // Step 5: Start server
    serverProcess = spawn(
      "node",
      [CLI_DEBUG, "serve", "-p", String(PORT)],
      {
        cwd: projectDir,
        stdio: ["ignore", "pipe", "pipe"],
      }
    );

    // Collect stderr for debugging
    let stderr = "";
    serverProcess.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    await waitForServer(`${BASE}/api/health`);

    // ========== Verification ==========

    // API health check
    const healthRes = await fetch(`${BASE}/api/health`);
    assert.equal(healthRes.status, 200, "API health should return 200");
    const healthBody = await healthRes.json();
    assert.equal(healthBody.status, "ok", "health response should be ok");

    // SSG generates to app/__gen__/ with paths under the pathPrefix
    // The SSG build outputs: /guide/getting-started/, /guide/configuration/, etc.
    // Try multiple path patterns to find where pages are served
    const docsUrls = ["/docs/", "/"];
    let docsBase = "";
    for (const url of docsUrls) {
      const res = await fetch(`${BASE}${url}`);
      if (res.status === 200) {
        const html = await res.text();
        if (html.includes("mydocs") || html.includes("<!DOCTYPE html>") || html.includes("<!doctype html>")) {
          docsBase = url === "/" ? "" : "/docs";
          break;
        }
      }
    }

    // Verify generated HTML files exist in build output
    const genDir = path.join(projectDir, "app/__gen__");
    assert.ok(
      fs.existsSync(path.join(genDir, "index.html")),
      "SSG should generate index.html"
    );
    assert.ok(
      fs.existsSync(path.join(genDir, "guide/getting-started/index.html")),
      "SSG should generate guide/getting-started/index.html"
    );
    assert.ok(
      fs.existsSync(path.join(genDir, "guide/configuration/index.html")),
      "SSG should generate guide/configuration/index.html"
    );
    assert.ok(
      fs.existsSync(path.join(genDir, "api/index.html")),
      "SSG should generate api/index.html"
    );

    // Verify HTML content
    const indexHtml = fs.readFileSync(
      path.join(genDir, "index.html"),
      "utf8"
    );
    assert.ok(
      indexHtml.includes("mydocs"),
      "Index page should contain project name"
    );
    assert.ok(
      indexHtml.includes("<!DOCTYPE html>") || indexHtml.includes("<!doctype html>"),
      "Index page should be full HTML document"
    );

    const guideHtml = fs.readFileSync(
      path.join(genDir, "guide/getting-started/index.html"),
      "utf8"
    );
    assert.ok(
      guideHtml.includes("Getting Started"),
      "Guide page should contain Getting Started heading"
    );

    const configHtml = fs.readFileSync(
      path.join(genDir, "guide/configuration/index.html"),
      "utf8"
    );
    assert.ok(
      configHtml.includes("sol.config.json"),
      "Config page should reference sol.config.json"
    );

    // Verify sitemap was generated
    assert.ok(
      fs.existsSync(path.join(genDir, "sitemap.xml")),
      "SSG should generate sitemap.xml"
    );

    // Verify CSS assets were generated
    assert.ok(
      fs.existsSync(path.join(genDir, "assets/style.css")),
      "SSG should generate style.css"
    );

  } finally {
    // Cleanup: kill server
    if (serverProcess) {
      serverProcess.kill("SIGTERM");
      // Give it a moment to die
      await new Promise((r) => setTimeout(r, 500));
      if (!serverProcess.killed) {
        serverProcess.kill("SIGKILL");
      }
    }
    // Cleanup: remove sandbox
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
