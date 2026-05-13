import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

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
  // sol depends on astra during co-development; pin that too for transitive resolution.
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

test("sol new templates pass moon check --deny-warn", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-template-check-"));
  try {
    for (const scenario of [
      { name: "check-app", extraArgs: [] },
      { name: "check-worker", extraArgs: ["--cloudflare"] },
    ]) {
      const create = spawnSync(
        "node",
        [
          CLI_DEBUG,
          "new",
          scenario.name,
          "--user",
          "testuser",
          ...scenario.extraArgs,
        ],
        { cwd: sandbox, encoding: "utf8" }
      );
      assert.equal(
        create.status,
        0,
        `sol new ${scenario.name} failed\nstdout:\n${create.stdout}\nstderr:\n${create.stderr}`
      );

      const projectDir = path.join(sandbox, scenario.name);
      pinWorkspaceSol(projectDir);

      const install = spawnSync("moon", ["install"], {
        cwd: projectDir,
        encoding: "utf8",
      });
      assert.ok(
        fs.existsSync(path.join(projectDir, ".mooncakes")),
        `${scenario.name}: moon install should create .mooncakes directory`
      );

      const check = spawnSync(
        "moon",
        ["check", "--target", "js", "--deny-warn"],
        { cwd: projectDir, encoding: "utf8" }
      );
      assert.equal(
        check.status,
        0,
        `${scenario.name}: moon check --deny-warn failed\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`
      );
    }
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
