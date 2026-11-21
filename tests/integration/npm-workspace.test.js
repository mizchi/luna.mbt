import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = fileURLToPath(new URL("../../", import.meta.url));

// The npm packages released by .github/workflows/publish.yml, one
// "<component>-npm-v<version>" tag each (<component> = name without the scope).
const publicPackages = [
  "js/astra",
  "js/components",
  "js/loader",
  "js/luna",
  "js/sol",
  "js/stella",
  "js/testing",
  "js/wcr",
];

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
  assert.deepEqual(actual.sort(), [...publicPackages].sort());
});

test("each public package prepares its artifacts when packed directly", () => {
  for (const directory of publicPackages) {
    const manifest = JSON.parse(readFileSync(path.join(root, directory, "package.json"), "utf8"));
    assert.ok(manifest.scripts?.prepack, `${directory} needs a prepack build for recursive publishing`);
    assert.equal(manifest.publishConfig?.access, "public", directory);
  }
});

test("each public package carries the metadata trusted publishing needs", () => {
  for (const directory of publicPackages) {
    const manifest = JSON.parse(readFileSync(path.join(root, directory, "package.json"), "utf8"));
    // The publish workflow maps a tag to a package by "@luna_ui/<component>".
    assert.match(manifest.name, /^@luna_ui\/[a-z][a-z-]*$/, directory);
    // Provenance verification compares repository.url with the publishing repo.
    assert.deepEqual(
      manifest.repository,
      { type: "git", url: "git+https://github.com/mizchi/luna.mbt.git", directory },
      directory,
    );
    assert.equal(manifest.license, "MIT", directory);
    assert.ok(Array.isArray(manifest.files) && manifest.files.length > 0, `${directory} needs files`);
  }
});
