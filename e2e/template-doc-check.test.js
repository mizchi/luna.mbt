import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "cli",
  "cli.js"
);

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

test("sol new --doc generates project structure", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-doc-template-check-")
  );
  try {
    // Create doc project
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "mydocs", "--user", "testuser", "--doc"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(
      create.status,
      0,
      `sol new --doc failed\nstdout:\n${create.stdout}\nstderr:\n${create.stderr}`
    );

    const projectDir = path.join(sandbox, "mydocs");

    // Verify essential files exist
    assert.ok(
      fs.existsSync(path.join(projectDir, "moon.mod.json")),
      "moon.mod.json should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "sol.config.json")),
      "sol.config.json should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "package.json")),
      "package.json should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "app/server/main.mbt")),
      "app/server/main.mbt should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "app/server/routes.mbt")),
      "app/server/routes.mbt should exist"
    );

    // Verify docs directory structure
    assert.ok(
      fs.existsSync(path.join(projectDir, "docs/index.md")),
      "docs/index.md should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "docs/guide/index.md")),
      "docs/guide/index.md should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "docs/guide/getting-started.md")),
      "docs/guide/getting-started.md should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "docs/guide/configuration.md")),
      "docs/guide/configuration.md should exist"
    );
    assert.ok(
      fs.existsSync(path.join(projectDir, "docs/api/index.md")),
      "docs/api/index.md should exist"
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol new --doc config has staticDirs", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-doc-config-check-")
  );
  try {
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "mydocs", "--user", "testuser", "--doc"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(create.status, 0, "sol new --doc should succeed");

    const projectDir = path.join(sandbox, "mydocs");
    const config = JSON.parse(
      fs.readFileSync(path.join(projectDir, "sol.config.json"), "utf8")
    );

    // Verify staticDirs config
    assert.ok(Array.isArray(config.staticDirs), "staticDirs should be array");
    assert.equal(config.staticDirs.length, 1, "should have 1 staticDir");
    assert.equal(config.staticDirs[0].pathPrefix, "/docs");
    assert.equal(config.staticDirs[0].sourceDir, "docs");
    assert.equal(config.staticDirs[0].sidebar, "auto");
    assert.ok(config.staticDirs[0].theme, "theme should exist");
    assert.ok(
      config.staticDirs[0].theme.header,
      "header config should exist"
    );
    assert.ok(
      config.staticDirs[0].theme.footer,
      "footer config should exist"
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol new --doc template passes moon check", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-doc-build-check-")
  );
  try {
    // Create doc project
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "mydocs", "--user", "testuser", "--doc"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(create.status, 0, "sol new --doc should succeed");

    const projectDir = path.join(sandbox, "mydocs");

    // Install MoonBit dependencies
    const install = spawnSync("moon", ["install"], {
      cwd: projectDir,
      encoding: "utf8",
    });
    assert.ok(
      fs.existsSync(path.join(projectDir, ".mooncakes")),
      "moon install should create .mooncakes directory"
    );

    // Run moon check (the real build check)
    const check = spawnSync("moon", ["check", "--target", "js"], {
      cwd: projectDir,
      encoding: "utf8",
    });
    assert.equal(
      check.status,
      0,
      `moon check failed for doc template\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol new --doc frontmatter is valid", () => {
  ensureCliBuilt();

  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-doc-frontmatter-check-")
  );
  try {
    const create = spawnSync(
      "node",
      [CLI_DEBUG, "new", "mydocs", "--user", "testuser", "--doc"],
      { cwd: sandbox, encoding: "utf8" }
    );
    assert.equal(create.status, 0);

    const projectDir = path.join(sandbox, "mydocs");

    // Check index.md has layout: home frontmatter
    const indexMd = fs.readFileSync(
      path.join(projectDir, "docs/index.md"),
      "utf8"
    );
    assert.ok(indexMd.includes("layout: home"), "index.md should have layout: home");
    assert.ok(indexMd.includes("title:"), "index.md should have title");

    // Check guide pages have title frontmatter
    const gettingStarted = fs.readFileSync(
      path.join(projectDir, "docs/guide/getting-started.md"),
      "utf8"
    );
    assert.ok(
      gettingStarted.includes("title: Getting Started"),
      "getting-started.md should have title"
    );

    // Check configuration page has useful content
    const configMd = fs.readFileSync(
      path.join(projectDir, "docs/guide/configuration.md"),
      "utf8"
    );
    assert.ok(
      configMd.includes("sol.config.json"),
      "configuration.md should reference sol.config.json"
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});
