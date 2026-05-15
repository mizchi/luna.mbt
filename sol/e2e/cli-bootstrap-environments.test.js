// Guard rails so the native sol launcher keeps working in both
// environments first-time users actually run it from:
//
//   1. An empty directory (no host moon project).
//      `sol new <name> --user <ns>`             — native self-host path
//      `sol new <name> --user <ns> --cloudflare`— native self-host path
//
//   2. The same launcher inside a host moon project / monorepo
//      (delegate path) is exercised by cli-golden-path.test.js, which
//      drives the bundled JS CLI directly.
//
// Regression context: 0.22.1 → 0.22.2 changed only the flag-less form
// to self-host, leaving `--cloudflare` on the delegate path. User
// thesparq hit "You're not inside a MoonBit project" when trying
// `sol new app --user me --cloudflare` from `~/Projects/`. 0.22.4
// extended self-host to `--cloudflare`. This test makes sure neither
// path regresses silently.
//
// The native launcher binary is what `moon install mizchi/sol/cmd/sol`
// ships — we rebuild it from local source via `moon install --path` so
// the binary actually under test is the one we just built, not whatever
// the registry currently has.

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const SOL_DIR = path.resolve(THIS_DIR, "..");
const REPO_ROOT = path.resolve(SOL_DIR, "..");
const MOON_HOME = process.env.MOON_HOME || path.join(os.homedir(), ".moon");
const SOL_NATIVE = path.join(MOON_HOME, "bin", "sol");

function ensureNativeSolInstalled() {
  const r = spawnSync(
    "moon",
    ["install", "--path", "./sol/src/cmd/sol"],
    { cwd: REPO_ROOT, encoding: "utf8" },
  );
  assert.equal(
    r.status,
    0,
    `moon install --path ./sol/src/cmd/sol failed:\nstdout:\n${r.stdout}\nstderr:\n${r.stderr}`,
  );
  assert.ok(
    fs.existsSync(SOL_NATIVE),
    `expected native sol binary at ${SOL_NATIVE} after install`,
  );
}

function runSol(args, cwd) {
  return spawnSync(SOL_NATIVE, args, { cwd, encoding: "utf8" });
}

function mkSandbox(prefix) {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

test("sol new (no flags) succeeds from an empty directory", () => {
  ensureNativeSolInstalled();
  const sandbox = mkSandbox("sol-bootstrap-noflag-");
  try {
    const result = runSol(["new", "ciapp", "--user", "ciuser"], sandbox);
    assert.equal(
      result.status,
      0,
      `sol new (no flag) failed in empty dir:\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
    const projectDir = path.join(sandbox, "ciapp");
    // Confirm we're on the 0.22.x scaffold layout (separate app/layout
    // package, co-located routes + handlers in app/server/routes.mbt,
    // user-managed main.mbt).
    for (const rel of [
      "moon.mod.json",
      "package.json",
      "sol.config.json",
      "app/server/main.mbt",
      "app/server/routes.mbt",
      "app/server/alias.mbt",
      "app/server/moon.pkg",
      "app/layout/layout.mbt",
      "app/layout/moon.pkg",
    ]) {
      assert.ok(
        fs.existsSync(path.join(projectDir, rel)),
        `missing scaffolded file: ${rel}`,
      );
    }
    // Cloudflare-only files must NOT exist on the no-flag path.
    for (const rel of ["wrangler.json", "wrangler.toml", "worker.entry.mjs"]) {
      assert.ok(
        !fs.existsSync(path.join(projectDir, rel)),
        `unexpected cloudflare file on no-flag path: ${rel}`,
      );
    }
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol new --cloudflare succeeds from an empty directory", () => {
  ensureNativeSolInstalled();
  const sandbox = mkSandbox("sol-bootstrap-cf-");
  try {
    const result = runSol(
      ["new", "cfapp", "--user", "ciuser", "--cloudflare"],
      sandbox,
    );
    assert.equal(
      result.status,
      0,
      `sol new --cloudflare failed in empty dir:\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
    const projectDir = path.join(sandbox, "cfapp");
    // Cloudflare scaffold ships the wrangler glue + a worker entry
    // alongside the regular sol app surface. Spot-check both.
    for (const rel of [
      "moon.mod.json",
      "package.json",
      "sol.config.json",
      "worker.entry.mjs",
      "app/server/main.mbt",
      "app/server/routes.mbt",
      "app/layout/layout.mbt",
    ]) {
      assert.ok(
        fs.existsSync(path.join(projectDir, rel)),
        `missing cloudflare scaffold file: ${rel}`,
      );
    }
    // wrangler.toml or wrangler.json — sol_app currently ships wrangler.toml.
    const hasWrangler =
      fs.existsSync(path.join(projectDir, "wrangler.toml")) ||
      fs.existsSync(path.join(projectDir, "wrangler.json"));
    assert.ok(hasWrangler, "missing wrangler.{toml,json}");
    // The scaffolded moon.mod.json must point at sol_adapter_cloudflare,
    // not sol_adapter_node (the wrong adapter would silently produce
    // bundles that won't start on Workers).
    const moonMod = JSON.parse(
      fs.readFileSync(path.join(projectDir, "moon.mod.json"), "utf8"),
    );
    assert.ok(
      Object.keys(moonMod.deps || {}).includes("mizchi/sol_adapter_cloudflare"),
      `cloudflare scaffold should declare mizchi/sol_adapter_cloudflare, got deps: ${Object.keys(moonMod.deps || {})}`,
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol new without --user exits non-zero and complains in an empty directory", () => {
  ensureNativeSolInstalled();
  const sandbox = mkSandbox("sol-bootstrap-no-user-");
  try {
    const result = runSol(["new", "ciapp"], sandbox);
    assert.notEqual(
      result.status,
      0,
      `sol new without --user should fail, got status=${result.status}\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
    // The native handler should reject the missing flag itself
    // (otherwise it would delegate, and the JS path's error is harder
    // to assert against). Either message form is acceptable.
    const combined = (result.stdout + "\n" + result.stderr).toLowerCase();
    assert.ok(
      /--user/.test(combined) && /(required|namespace)/.test(combined),
      `expected stderr to mention --user being required; got:\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
