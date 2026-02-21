import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const CLI_DEBUG = path.join(ROOT, "_build", "js", "debug", "build", "cli", "cli.js");

function runSol(args, cwd) {
  return spawnSync("node", [CLI_DEBUG, ...args], {
    cwd,
    encoding: "utf8",
  });
}

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

test("cli golden path command availability (new/dev/build/deploy)", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-cli-golden-"));
  try {
    const projectName = "demo-app";
    const create = runSol(["new", projectName, "--user", "mizchi"], sandbox);
    assert.equal(
      create.status,
      0,
      `sol new failed\nstdout:\n${create.stdout}\nstderr:\n${create.stderr}`
    );

    const projectDir = path.join(sandbox, projectName);
    assert.ok(fs.existsSync(path.join(projectDir, "moon.mod.json")));

    const devHelp = runSol(["dev", "--help"], projectDir);
    assert.equal(devHelp.status, 0, devHelp.stderr);
    assert.match(devHelp.stdout, /Usage:\s*sol dev/i);

    const buildHelp = runSol(["build", "--help"], projectDir);
    assert.equal(buildHelp.status, 0, buildHelp.stderr);
    assert.match(buildHelp.stdout, /Usage:\s*sol build/i);

    const deployHelp = runSol(["deploy", "--help"], projectDir);
    assert.equal(
      deployHelp.status,
      0,
      `sol deploy --help failed\nstdout:\n${deployHelp.stdout}\nstderr:\n${deployHelp.stderr}`
    );
    assert.match(deployHelp.stdout, /Usage:\s*sol deploy/i);
    assert.match(deployHelp.stdout, /default:\s*cloudflare-workers/i);
    assert.match(deployHelp.stdout, /wrangler@4 deploy/i);
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
