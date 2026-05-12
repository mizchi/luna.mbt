import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const SOL_DIR = path.resolve(THIS_DIR, "..");
const ROOT = path.resolve(SOL_DIR, "..");
const CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "mizchi",
  "sol",
  "cmd",
  "sol_js",
  "sol_js.js"
);

function ensureCliBuilt() {
  const build = spawnSync("moon", ["build", "--target", "js"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(
    build.status,
    0,
    `failed to build CLI\nstdout:\n${build.stdout}\nstderr:\n${build.stderr}`
  );
}

function pinWorkspaceSol(projectDir) {
  const moonModPath = path.join(projectDir, "moon.mod.json");
  const moonMod = JSON.parse(fs.readFileSync(moonModPath, "utf8"));
  moonMod.deps["mizchi/sol"] = { path: SOL_DIR };
  moonMod.deps["mizchi/astra"] = { path: path.join(ROOT, "astra") };
  fs.writeFileSync(moonModPath, `${JSON.stringify(moonMod, null, 2)}\n`);
}

test("sol new --cloudflare builds a composable Worker that serves API, UI, and favicon", async () => {
  ensureCliBuilt();

  const rootNodeModules = path.join(ROOT, "node_modules");
  assert.ok(
    fs.existsSync(path.join(rootNodeModules, "hono")),
    "root node_modules must be installed before running the Worker smoke test"
  );
  assert.ok(
    fs.existsSync(path.join(rootNodeModules, "rolldown")),
    "root node_modules must include rolldown before running the Worker smoke test"
  );

  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-worker-starter-"));
  try {
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "worker-app", "--user", "testuser", "--cloudflare"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(
      create.status,
      0,
      `sol new --cloudflare failed\nstdout:\n${create.stdout}\nstderr:\n${create.stderr}`
    );

    const projectDir = path.join(sandbox, "worker-app");
    pinWorkspaceSol(projectDir);
    fs.symlinkSync(rootNodeModules, path.join(projectDir, "node_modules"));

    const install = spawnSync("moon", ["install"], {
      cwd: projectDir,
      encoding: "utf8",
    });
    assert.equal(
      install.status,
      0,
      `moon install failed\nstdout:\n${install.stdout}\nstderr:\n${install.stderr}`
    );

    const build = spawnSync("node", [CLI_DEBUG, "build"], {
      cwd: projectDir,
      encoding: "utf8",
    });
    assert.equal(
      build.status,
      0,
      `sol build failed\nstdout:\n${build.stdout}\nstderr:\n${build.stderr}`
    );

    const workerModule = await import(
      pathToFileURL(path.join(projectDir, "worker.entry.mjs")).href
    );
    const worker = workerModule.default;
    assert.equal(typeof worker.fetch, "function");

    const api = await worker.fetch(
      new Request("https://example.test/api/health"),
      {},
      {}
    );
    assert.equal(api.status, 200);
    assert.match(api.headers.get("content-type") ?? "", /application\/json/);
    assert.deepEqual(await api.json(), {
      status: "ok",
      source: "worker-api",
    });

    const ui = await worker.fetch(new Request("https://example.test/"), {}, {});
    assert.equal(ui.status, 200);
    assert.match(ui.headers.get("content-type") ?? "", /text\/html/);
    const html = await ui.text();
    assert.match(html, /Welcome to Sol/);
    assert.match(html, /\/static\/api_tools\.js/);

    const favicon = await worker.fetch(
      new Request("https://example.test/favicon.ico"),
      {},
      {}
    );
    assert.equal(favicon.status, 200);
    assert.match(favicon.headers.get("content-type") ?? "", /image\/svg\+xml/);
    assert.match(await favicon.text(), /<svg/);
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
