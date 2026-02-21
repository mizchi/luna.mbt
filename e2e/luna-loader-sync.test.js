import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const scriptPath = path.join(root, "scripts", "sync-luna-loader-assets.mjs");
const lunaDir = process.env.LUNA_REPO_DIR ?? path.resolve(root, "..", "luna.mbt");
const lunaDistDir = path.join(lunaDir, "js", "loader", "dist");

test(
  "luna loader assets check passes when luna repo is available",
  { skip: !existsSync(lunaDistDir) },
  () => {
    const result = spawnSync(
      process.execPath,
      [scriptPath, "--luna-dir", lunaDir, "--check"],
      {
        cwd: root,
        encoding: "utf-8",
      },
    );
    assert.equal(
      result.status,
      0,
      `sync check failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
  },
);
