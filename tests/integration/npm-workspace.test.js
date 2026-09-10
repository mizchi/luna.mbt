import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = fileURLToPath(new URL("../../", import.meta.url));

test("recursive publish selects exactly the release-managed npm packages", () => {
  const result = spawnSync("pnpm", ["list", "-r", "--depth", "-1", "--json"], {
    cwd: root,
    encoding: "utf8",
  });
  assert.equal(result.status, 0, result.stderr);
  const actual = JSON.parse(result.stdout).flatMap(({ path: directory }) => {
    const manifest = JSON.parse(readFileSync(path.join(directory, "package.json"), "utf8"));
    return manifest.private ? [] : [path.relative(root, directory)];
  });
  const config = JSON.parse(readFileSync(path.join(root, "release-please-config.json"), "utf8"));
  assert.deepEqual(actual.sort(), Object.keys(config.packages).sort());
});

test("each public package prepares its artifacts when packed directly", () => {
  const config = JSON.parse(readFileSync(path.join(root, "release-please-config.json"), "utf8"));
  for (const directory of Object.keys(config.packages)) {
    const manifest = JSON.parse(readFileSync(path.join(root, directory, "package.json"), "utf8"));
    assert.ok(manifest.scripts?.prepack, `${directory} needs a prepack build for recursive publishing`);
    assert.equal(manifest.publishConfig?.access, "public", directory);
  }
});
