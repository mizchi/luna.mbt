import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));

function buildWithCompiler(version, check) {
  const stage = mkdtempSync(path.join(tmpdir(), "luna-moon-toolchain-"));
  const calls = path.join(stage, "calls.jsonl");
  writeFileSync(calls, "");
  writeFileSync(path.join(stage, "moon"), `#!/usr/bin/env node
import { appendFileSync } from 'node:fs';
const args = process.argv.slice(2);
appendFileSync(${JSON.stringify(calls)}, JSON.stringify(args) + '\\n');
if (args[0] === 'version') console.log(${JSON.stringify(version)});
`, { mode: 0o755 });
  try {
    const result = spawnSync("pnpm", ["run", "build:moon"], {
      cwd: root,
      env: { ...process.env, PATH: `${stage}${path.delimiter}${process.env.PATH}` },
      encoding: "utf8",
    });
    check(result, readFileSync(calls, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse));
  } finally {
    rmSync(stage, { recursive: true, force: true });
  }
}

test("npm builds reject an old MoonBit compiler before compiling dependencies", () => {
  buildWithCompiler("moon 0.1.20260824\nmoonc v0.10.10+f8a486b6f (2026-08-21)", (result, calls) => {
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /requires MoonBit v0\.10\.12 or newer/);
    assert.match(result.stderr, /moon upgrade/);
    assert.ok(!calls.some(([command]) => command === "build"));
  });
});

test("npm builds accept the supported compiler and run the release build", () => {
  buildWithCompiler("moon 0.1.20260904\nmoonc v0.10.12+1634b282e (2026-09-07)", (result, calls) => {
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(calls.at(-1), ["build", "--target", "js", "--release"]);
  });
});

test("npm builds compare compiler versions numerically", () => {
  buildWithCompiler("moonc v0.10.9+example", (result, calls) => {
    assert.notEqual(result.status, 0);
    assert.ok(!calls.some(([command]) => command === "build"));
  });
});

test("npm builds report an unrecognizable compiler version", () => {
  buildWithCompiler("moon without a compiler version", (result, calls) => {
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Could not determine the MoonBit compiler version/);
    assert.ok(!calls.some(([command]) => command === "build"));
  });
});
