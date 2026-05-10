// Regression coverage for `pnpm add -g @luna_ui/sol` / `@luna_ui/astra`.
// Up to 0.17.0 the bin shim imported `../../../_build/...` directly,
// which only resolves inside the workspace — every npm install crashed
// with ERR_MODULE_NOT_FOUND. The fix is to bundle the moonbit CLI JS
// (and astra's runtime asset directory) into js/<pkg>/dist/ at publish
// time. This test packs each tarball, extracts it, and runs the bin
// from the extracted location to verify the npm layout is self-contained.

import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");

function ensureMoonReleaseBuild() {
  const sentinel = path.join(
    ROOT,
    "_build/js/release/build/mizchi/sol/cmd/sol/sol.js",
  );
  if (existsSync(sentinel)) return;
  const r = spawnSync("moon", ["build", "--target", "js", "--release"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(
    r.status,
    0,
    `moon build --release failed:\n${r.stdout}\n${r.stderr}`,
  );
}

function packAndInstall(pkgDir, binName) {
  const stage = mkdtempSync(path.join(tmpdir(), "luna-cli-pack-"));
  const pack = spawnSync(
    "pnpm",
    ["pack", "--pack-destination", stage],
    { cwd: pkgDir, encoding: "utf8" },
  );
  assert.equal(
    pack.status,
    0,
    `pnpm pack failed in ${pkgDir}:\n${pack.stdout}\n${pack.stderr}`,
  );
  const tgz = readdirSync(stage).find((f) => f.endsWith(".tgz"));
  assert.ok(tgz, `no .tgz produced under ${stage}`);

  // Read-only inspection: extract a copy so the test can sanity-check
  // dist/ before committing to the install round-trip.
  const tar = spawnSync("tar", ["-xzf", path.join(stage, tgz), "-C", stage], {
    encoding: "utf8",
  });
  assert.equal(tar.status, 0, `tar -xzf failed:\n${tar.stderr}`);
  const extracted = path.join(stage, "package");
  assert.ok(existsSync(extracted), `extracted root missing: ${extracted}`);

  // Install the tarball into a fresh sandbox so runtime deps (colorette)
  // resolve the same way they would on a `pnpm add -g` install.
  const sandbox = path.join(stage, "sandbox");
  mkdirSync(sandbox, { recursive: true });
  const initPkg = JSON.stringify({ name: "luna-cli-sandbox", private: true });
  writeFileSync(path.join(sandbox, "package.json"), initPkg);
  const install = spawnSync(
    "npm",
    [
      "install",
      "--no-audit",
      "--no-fund",
      "--prefix",
      sandbox,
      path.join(stage, tgz),
    ],
    { encoding: "utf8" },
  );
  assert.equal(
    install.status,
    0,
    `npm install of ${tgz} failed:\n${install.stdout}\n${install.stderr}`,
  );

  const installedRoot = path.join(
    sandbox,
    "node_modules",
    "@luna_ui",
    binName === "sol" ? "sol" : "astra",
  );
  return {
    extracted,
    installedRoot,
    cleanup: () => rmSync(stage, { recursive: true, force: true }),
  };
}

test("@luna_ui/sol tarball contains a runnable CLI", { timeout: 240_000 }, () => {
  ensureMoonReleaseBuild();
  const { extracted, installedRoot, cleanup } = packAndInstall(
    path.join(ROOT, "js/sol"),
    "sol",
  );
  try {
    const distEntry = path.join(extracted, "dist", "sol.js");
    assert.ok(
      existsSync(distEntry) && statSync(distEntry).size > 100_000,
      `dist/sol.js is missing or suspiciously small at ${distEntry}`,
    );

    const binEntry = path.join(installedRoot, "bin", "sol.js");
    const r = spawnSync(process.execPath, [binEntry, "--help"], {
      encoding: "utf8",
    });
    assert.equal(
      r.status,
      0,
      `sol --help failed:\nstdout=${r.stdout}\nstderr=${r.stderr}`,
    );
    assert.match(r.stdout, /Sol CLI/, `unexpected --help output: ${r.stdout}`);
  } finally {
    cleanup();
  }
});

test("@luna_ui/astra tarball contains a runnable CLI and bundled assets", { timeout: 240_000 }, () => {
  ensureMoonReleaseBuild();
  const { extracted, installedRoot, cleanup } = packAndInstall(
    path.join(ROOT, "js/astra"),
    "astra",
  );
  try {
    const distEntry = path.join(extracted, "dist", "astra.js");
    assert.ok(
      existsSync(distEntry) && statSync(distEntry).size > 100_000,
      `dist/astra.js is missing or suspiciously small at ${distEntry}`,
    );

    // astra's load_asset() reads styles/main.css and scripts/*.js at
    // runtime; both must ship inside the tarball or the docs build
    // falls back to a 143-byte stub stylesheet (see PR #47).
    const mainCss = path.join(extracted, "dist", "assets", "styles", "main.css");
    assert.ok(
      existsSync(mainCss) && statSync(mainCss).size > 10_000,
      `dist/assets/styles/main.css missing or too small at ${mainCss}`,
    );
    for (const script of ["loader.js", "theme.js", "sidebar.js", "toc.js"]) {
      const p = path.join(extracted, "dist", "assets", "scripts", script);
      assert.ok(existsSync(p), `dist/assets/scripts/${script} missing`);
    }

    const binEntry = path.join(installedRoot, "bin", "astra.js");
    const r = spawnSync(process.execPath, [binEntry, "--help"], {
      encoding: "utf8",
    });
    assert.equal(
      r.status,
      0,
      `astra --help failed:\nstdout=${r.stdout}\nstderr=${r.stderr}`,
    );
    assert.match(r.stdout, /astra/, `unexpected --help output: ${r.stdout}`);
  } finally {
    cleanup();
  }
});
