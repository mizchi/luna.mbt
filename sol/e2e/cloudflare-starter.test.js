import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { spawn, spawnSync } from "node:child_process";
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
const WRANGLER_BIN = path.join(
  SOL_DIR,
  "node_modules",
  ".bin",
  process.platform === "win32" ? "wrangler.cmd" : "wrangler"
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
  moonMod.deps["mizchi/luna"] = { path: path.join(ROOT, "luna") };
  moonMod.deps["mizchi/sol_adapter_node"] = {
    path: path.join(ROOT, "sol_adapter_node"),
  };
  moonMod.deps["mizchi/sol_adapter_cloudflare"] = {
    path: path.join(ROOT, "sol_adapter_cloudflare"),
  };
  fs.writeFileSync(moonModPath, `${JSON.stringify(moonMod, null, 2)}\n`);
}

function reservePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      const port = address && typeof address === "object" ? address.port : 0;
      server.close(() => resolve(port));
    });
  });
}

function startWranglerDev(projectDir, port) {
  const child = spawn(
    WRANGLER_BIN,
    [
      "dev",
      "--local",
      "--ip",
      "127.0.0.1",
      "--port",
      String(port),
      "--show-interactive-dev-session=false",
    ],
    {
      cwd: projectDir,
      env: {
        ...process.env,
        CI: "true",
        NO_COLOR: "1",
        WRANGLER_SEND_METRICS: "false",
      },
      stdio: ["ignore", "pipe", "pipe"],
    }
  );

  let stdout = "";
  let stderr = "";
  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");
  child.stdout.on("data", (chunk) => {
    stdout += chunk;
  });
  child.stderr.on("data", (chunk) => {
    stderr += chunk;
  });

  return {
    child,
    output() {
      return `stdout:\n${stdout}\nstderr:\n${stderr}`;
    },
  };
}

async function stopWrangler(server) {
  const { child } = server;
  if (child.exitCode !== null || child.signalCode !== null) {
    return;
  }
  await new Promise((resolve) => {
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      resolve();
    }, 2_000);
    child.once("exit", () => {
      clearTimeout(timer);
      resolve();
    });
    child.kill("SIGTERM");
  });
}

async function waitForHttp(url, server) {
  const started = Date.now();
  let lastError;
  while (Date.now() - started < 20_000) {
    if (server.child.exitCode !== null) {
      throw new Error(`wrangler dev exited early\n${server.output()}`);
    }
    try {
      return await fetch(url);
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
  }
  throw new Error(
    `wrangler dev did not serve ${url}\nlast error: ${lastError}\n${server.output()}`
  );
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
  assert.ok(
    fs.existsSync(WRANGLER_BIN),
    "sol node_modules must include wrangler before running the Worker smoke test"
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
      kv: false,
      r2: false,
    });

    const ui = await worker.fetch(new Request("https://example.test/"), {}, {});
    assert.equal(ui.status, 200);
    assert.match(ui.headers.get("content-type") ?? "", /text\/html/);
    const html = await ui.text();
    assert.match(html, /Welcome to Sol/);
    assert.match(html, /Operations Console/);
    assert.match(html, /\/static\/api_tools\.js/);

    const jobs = await worker.fetch(
      new Request("https://example.test/api/jobs"),
      {},
      {}
    );
    assert.equal(jobs.status, 200);
    assert.deepEqual((await jobs.json()).jobs.map((job) => job.id), [
      "job-104",
      "job-105",
      "job-106",
    ]);

    const denied = await worker.fetch(
      new Request("https://example.test/api/jobs/batch", { method: "POST" }),
      {},
      {}
    );
    assert.equal(denied.status, 401);

    const accepted = await worker.fetch(
      new Request("https://example.test/api/jobs/batch", {
        method: "POST",
        headers: { Authorization: "Bearer dev-token" },
      }),
      {},
      {}
    );
    assert.equal(accepted.status, 202);

    const favicon = await worker.fetch(
      new Request("https://example.test/favicon.ico"),
      {},
      {}
    );
    assert.equal(favicon.status, 200);
    assert.match(favicon.headers.get("content-type") ?? "", /image\/svg\+xml/);
    assert.match(await favicon.text(), /<svg/);

    const port = await reservePort();
    const wrangler = startWranglerDev(projectDir, port);
    try {
      const wranglerApi = await waitForHttp(
        `http://127.0.0.1:${port}/api/health`,
        wrangler
      );
      assert.equal(wranglerApi.status, 200);
      assert.match(
        wranglerApi.headers.get("content-type") ?? "",
        /application\/json/
      );
      assert.deepEqual(await wranglerApi.json(), {
        status: "ok",
        source: "worker-api",
        kv: true,
        r2: true,
      });

      const wranglerUi = await fetch(`http://127.0.0.1:${port}/`);
      assert.equal(wranglerUi.status, 200);
      assert.match(wranglerUi.headers.get("content-type") ?? "", /text\/html/);
      const wranglerHtml = await wranglerUi.text();
      assert.match(wranglerHtml, /Welcome to Sol/);
      assert.match(wranglerHtml, /Operations Console/);
      assert.match(wranglerHtml, /\/static\/api_tools\.js/);
    } finally {
      await stopWrangler(wrangler);
    }
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
