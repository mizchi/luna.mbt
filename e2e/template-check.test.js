import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
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

test("sol new template passes moon check --deny-warn", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-template-check-"));
  try {
    // Create project
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "check-app", "--user", "testuser"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(
      create.status,
      0,
      `sol new failed\nstdout:\n${create.stdout}\nstderr:\n${create.stderr}`
    );

    const projectDir = path.join(sandbox, "check-app");

    // Install dependencies
    const install = spawnSync("moon", ["install"], {
      cwd: projectDir,
      encoding: "utf8",
    });
    // moon install may warn about deprecation but should succeed
    assert.ok(
      fs.existsSync(path.join(projectDir, ".mooncakes")),
      "moon install should create .mooncakes directory"
    );

    // Run moon check --deny-warn
    const check = spawnSync(
      "moon",
      ["check", "--target", "js", "--deny-warn"],
      { cwd: projectDir, encoding: "utf8" }
    );
    assert.equal(
      check.status,
      0,
      `moon check --deny-warn failed\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
