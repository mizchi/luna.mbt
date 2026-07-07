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

function moonWorkMember(projectDir, memberPath) {
  return path
    .relative(fs.realpathSync(projectDir), fs.realpathSync(memberPath))
    .split(path.sep)
    .join("/");
}

function pinWorkspaceSol(projectDir) {
  const members = [
    ".",
    moonWorkMember(projectDir, SOL_DIR),
    moonWorkMember(projectDir, path.join(ROOT, "astra")),
    moonWorkMember(projectDir, path.join(ROOT, "luna")),
    moonWorkMember(projectDir, path.join(ROOT, "luna_components")),
    moonWorkMember(projectDir, path.join(ROOT, "sol_adapter_node")),
    moonWorkMember(projectDir, path.join(ROOT, "sol_adapter_cloudflare")),
  ];
  fs.writeFileSync(
    path.join(projectDir, "moon.work"),
    `members = [\n${members.map((member) => `  "${member}",`).join("\n")}\n]\n`,
  );
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
