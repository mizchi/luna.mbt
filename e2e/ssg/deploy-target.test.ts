import { test, expect } from "@playwright/test";
import { execSync } from "node:child_process";
import { join } from "node:path";
import { existsSync, readFileSync, mkdirSync, writeFileSync, rmSync } from "node:fs";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const CLI_PATH = join(PROJECT_ROOT, "target/js/release/build/sol/cli/cli.js");

function createTestProject(name: string, config: object): string {
  const testDir = join(PROJECT_ROOT, ".test-output", name);

  // Clean up if exists
  if (existsSync(testDir)) {
    rmSync(testDir, { recursive: true });
  }

  // Create test project structure
  mkdirSync(join(testDir, "docs"), { recursive: true });

  // Write config
  writeFileSync(
    join(testDir, "sol.config.json"),
    JSON.stringify(config, null, 2)
  );

  // Write a sample markdown file
  writeFileSync(
    join(testDir, "docs/index.md"),
    `---
title: Home
---
# Test Page
Hello world
`
  );

  // Write another page for testing routes
  mkdirSync(join(testDir, "docs/guide"), { recursive: true });
  writeFileSync(
    join(testDir, "docs/guide/intro.md"),
    `---
title: Introduction
---
# Introduction
Getting started guide
`
  );

  return testDir;
}

function runBuild(testDir: string): { success: boolean; output: string } {
  try {
    const output = execSync(`node ${CLI_PATH} build`, {
      cwd: testDir,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return { success: true, output };
  } catch (error: any) {
    return { success: false, output: error.stderr || error.message };
  }
}

test.describe("Astra Deploy Target", () => {
  test.beforeAll(() => {
    // Ensure CLI is built
    execSync("moon build --target js", {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    });
  });

  test("cloudflare target generates _routes.json", async () => {
    const testDir = createTestProject("cloudflare-target", {
      docs: "docs",
      output: "dist",
      title: "Cloudflare Test",
      deploy: "cloudflare",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check _routes.json exists
    const routesPath = join(testDir, "dist/_routes.json");
    expect(existsSync(routesPath)).toBe(true);

    // Verify content
    const routes = JSON.parse(readFileSync(routesPath, "utf-8"));
    expect(routes.version).toBe(1);
    expect(Array.isArray(routes.include)).toBe(true);
    expect(Array.isArray(routes.exclude)).toBe(true);

    // Should have standard exclusions
    expect(routes.exclude).toContain("/*.html");
    expect(routes.exclude).toContain("/*.css");
    expect(routes.exclude).toContain("/*.js");
    expect(routes.exclude).toContain("/_luna/*");
  });

  test("static target (default) does NOT generate _routes.json", async () => {
    const testDir = createTestProject("static-target", {
      docs: "docs",
      output: "dist",
      title: "Static Test",
      // No deploy field = default static
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check _routes.json does NOT exist
    const routesPath = join(testDir, "dist/_routes.json");
    expect(existsSync(routesPath)).toBe(false);
  });

  test("explicit static target does NOT generate _routes.json", async () => {
    const testDir = createTestProject("explicit-static-target", {
      docs: "docs",
      output: "dist",
      title: "Explicit Static Test",
      deploy: "static",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check _routes.json does NOT exist
    const routesPath = join(testDir, "dist/_routes.json");
    expect(existsSync(routesPath)).toBe(false);
  });

  test("cloudflare _routes.json excludes page URLs", async () => {
    const testDir = createTestProject("cloudflare-page-urls", {
      docs: "docs",
      output: "dist",
      title: "Cloudflare Pages Test",
      deploy: "cloudflare",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    const routesPath = join(testDir, "dist/_routes.json");
    const routes = JSON.parse(readFileSync(routesPath, "utf-8"));

    // Should exclude page paths (with trailing slash pattern)
    // The exact format depends on implementation
    const hasPageExclusions = routes.exclude.some(
      (pattern: string) => pattern.includes("/") && !pattern.startsWith("/*")
    );
    expect(hasPageExclusions).toBe(true);
  });
});

test.describe("Astra Client Manifest", () => {
  test("generates _luna/manifest.json", async () => {
    const testDir = createTestProject("client-manifest", {
      docs: "docs",
      output: "dist",
      title: "Manifest Test",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check manifest.json exists
    const manifestPath = join(testDir, "dist/_luna/manifest.json");
    expect(existsSync(manifestPath)).toBe(true);

    // Verify it's valid JSON
    const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));
    expect(manifest).toBeDefined();
    expect(typeof manifest).toBe("object");
  });

  test("manifest.json contains route information", async () => {
    const testDir = createTestProject("manifest-routes", {
      docs: "docs",
      output: "dist",
      title: "Manifest Routes Test",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    const manifestPath = join(testDir, "dist/_luna/manifest.json");
    const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

    // Should have routes object
    expect(manifest.routes).toBeDefined();
    expect(typeof manifest.routes).toBe("object");

    // Should have base path
    expect(manifest.base).toBeDefined();
  });
});

test.describe("Astra Build Output Structure", () => {
  test("generates expected output files", async () => {
    const testDir = createTestProject("output-structure", {
      docs: "docs",
      output: "dist",
      title: "Output Structure Test",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check core output files
    expect(existsSync(join(testDir, "dist/index.html"))).toBe(true);
    expect(existsSync(join(testDir, "dist/guide/intro/index.html"))).toBe(true);
    expect(existsSync(join(testDir, "dist/sitemap.xml"))).toBe(true);
    expect(existsSync(join(testDir, "dist/feed.xml"))).toBe(true);
    expect(existsSync(join(testDir, "dist/404.html"))).toBe(true);
    expect(existsSync(join(testDir, "dist/_luna/manifest.json"))).toBe(true);

    // Check assets
    expect(existsSync(join(testDir, "dist/assets/style.css"))).toBe(true);
  });

  test("HTML pages have proper structure", async () => {
    const testDir = createTestProject("html-structure", {
      docs: "docs",
      output: "dist",
      title: "HTML Structure Test",
    });

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    const indexHtml = readFileSync(join(testDir, "dist/index.html"), "utf-8");

    // Basic HTML structure
    expect(indexHtml).toContain("<!DOCTYPE html>");
    expect(indexHtml).toContain("<html");
    expect(indexHtml).toContain("</html>");
    expect(indexHtml).toContain("<head>");
    expect(indexHtml).toContain("<body>");

    // Should have title
    expect(indexHtml).toContain("<title>");

    // Should have content
    expect(indexHtml).toContain("Test Page");
    expect(indexHtml).toContain("Hello world");
  });
});
