import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

const canonicalLoader = path.join(
  root,
  "src",
  "ssg",
  "assets",
  "scripts",
  "loader.js",
);
const canonicalWcLoader = path.join(
  root,
  "src",
  "ssg",
  "assets",
  "scripts",
  "wc-loader.js",
);
const canonicalSolNav = path.join(
  root,
  "src",
  "ssg",
  "assets",
  "scripts",
  "sol-nav.js",
);
const canonicalLib = path.join(
  root,
  "src",
  "ssg",
  "assets",
  "scripts",
  "lib.js",
);

const loaderTargets = [
  path.join(root, "examples", "sol_app", "static", "loader.js"),
  path.join(root, "examples", "sol_auth", "static", "loader.js"),
  path.join(root, "examples", "sol_todo", "static", "loader.js"),
];

const wcLoaderTargets = [
  path.join(root, "examples", "sol_app", "static", "wc-loader.js"),
  path.join(root, "examples", "sol_auth", "static", "wc-loader.js"),
];

const solNavTargets = [
  path.join(root, "examples", "sol_app", "static", "sol-nav.js"),
  path.join(root, "examples", "sol_auth", "static", "sol-nav.js"),
  path.join(root, "examples", "sol_todo", "static", "sol-nav.js"),
];

const libTargets = [
  path.join(root, "examples", "sol_app", "static", "lib.js"),
  path.join(root, "examples", "sol_auth", "static", "lib.js"),
];

function read(pathname) {
  return fs.readFileSync(pathname, "utf-8");
}

test("examples loader.js are synced with ssg canonical loader", () => {
  const expected = read(canonicalLoader);
  for (const target of loaderTargets) {
    assert.equal(
      read(target),
      expected,
      `outdated loader.js: ${path.relative(root, target)}`,
    );
  }
});

test("examples wc-loader.js are synced with ssg canonical wc-loader", () => {
  const expected = read(canonicalWcLoader);
  for (const target of wcLoaderTargets) {
    assert.equal(
      read(target),
      expected,
      `outdated wc-loader.js: ${path.relative(root, target)}`,
    );
  }
});

test("examples sol-nav.js are synced with ssg canonical sol-nav", () => {
  const expected = read(canonicalSolNav);
  for (const target of solNavTargets) {
    assert.equal(
      read(target),
      expected,
      `outdated sol-nav.js: ${path.relative(root, target)}`,
    );
  }
});

test("examples lib.js are synced with ssg canonical lib", () => {
  const expected = read(canonicalLib);
  for (const target of libTargets) {
    assert.equal(
      read(target),
      expected,
      `outdated lib.js: ${path.relative(root, target)}`,
    );
  }
});
