import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..", "..");
const SOL_VERSION = readMoonModVersion(path.join(ROOT, "sol", "moon.mod"));

function readMoonModVersion(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  const match = content.match(/^version\s*=\s*"([^"]+)"/m);
  assert.ok(match, `missing version assignment in ${filePath}`);
  return match[1];
}

test("moon install mizchi/sol/cmd/sol creates a runnable sol binary", (t) => {
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-moon-install-"));
  const binDir = path.join(sandbox, "bin");
  const targetDir = path.join(sandbox, "target");
  fs.mkdirSync(binDir, { recursive: true });

  try {
    const install = spawnSync(
      "moon",
      [
        "install",
        "--target-dir",
        targetDir,
        "--bin",
        binDir,
        "--path",
        "./sol/src/cmd/sol",
      ],
      { cwd: ROOT, encoding: "utf8" }
    );
    if (
      install.status !== 0 &&
      install.stderr.includes(`no version satisfies requirement \`${SOL_VERSION}\``)
    ) {
      t.skip(`mizchi/sol ${SOL_VERSION} has not been published to mooncakes yet`);
      return;
    }
    assert.equal(
      install.status,
      0,
      `moon install failed\nstdout:\n${install.stdout}\nstderr:\n${install.stderr}`
    );

    const solBin = path.join(binDir, process.platform === "win32" ? "sol.exe" : "sol");
    assert.ok(fs.existsSync(solBin), `expected installed binary at ${solBin}`);

    const help = spawnSync(solBin, ["--help"], {
      cwd: sandbox,
      encoding: "utf8",
    });
    assert.equal(help.status, 0, help.stderr);
    assert.match(help.stdout, /Usage:\s*sol <command>/i);

    const version = spawnSync(solBin, ["--version"], {
      cwd: sandbox,
      encoding: "utf8",
    });
    assert.equal(version.status, 0, version.stderr);
    assert.equal(version.stdout.trim(), `sol ${SOL_VERSION}`);

    const delegatedHelp = spawnSync(solBin, ["build", "--help"], {
      cwd: ROOT,
      encoding: "utf8",
    });
    assert.equal(
      delegatedHelp.status,
      0,
      `installed sol should delegate subcommands to the JS CLI from a checkout\nstdout:\n${delegatedHelp.stdout}\nstderr:\n${delegatedHelp.stderr}`
    );
    assert.match(delegatedHelp.stdout, /Usage:\s*sol build/i);
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
