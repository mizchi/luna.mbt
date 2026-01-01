import { test, expect } from "@playwright/test";
import { execSync, spawn, ChildProcess } from "node:child_process";
import { join } from "node:path";
import { readFileSync, existsSync } from "node:fs";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const SOL_DOCS_DIR = join(PROJECT_ROOT, "examples/sol_docs");
const CLI_PATH = join(PROJECT_ROOT, "target/js/release/build/sol/cli/cli.js");

function startStaticServer(distDir: string): Promise<{ url: string; process: ChildProcess }> {
  return new Promise((resolve, reject) => {
    const server = spawn("npx", ["serve", "-l", "0", distDir], {
      stdio: ["pipe", "pipe", "pipe"],
    });

    let output = "";
    let resolved = false;

    const tryResolve = () => {
      if (resolved) return;
      const match = output.match(/http:\/\/localhost:(\d+)/);
      if (match) {
        resolved = true;
        setTimeout(() => {
          resolve({
            url: `http://localhost:${match[1]}`,
            process: server,
          });
        }, 500);
      }
    };

    server.stdout?.on("data", (data: Buffer) => {
      output += data.toString();
      tryResolve();
    });

    server.stderr?.on("data", (data: Buffer) => {
      output += data.toString();
      tryResolve();
    });

    server.on("error", reject);

    setTimeout(() => {
      if (!resolved) {
        reject(new Error("Server failed to start within 10 seconds"));
      }
    }, 10000);
  });
}

test.describe("Hierarchical Manifest - SPA Segments", () => {
  let server: { url: string; process: ChildProcess };

  test.beforeAll(async () => {
    // Build sol_docs
    execSync(`node ${CLI_PATH} build`, {
      cwd: SOL_DOCS_DIR,
      stdio: "inherit",
    });

    // Start static server
    server = await startStaticServer(join(SOL_DOCS_DIR, "dist"));
  });

  test.afterAll(() => {
    server?.process?.kill();
  });

  test("v2 manifest is generated when SPA segment exists", async () => {
    const manifestPath = join(SOL_DOCS_DIR, "dist/_luna/manifest.json");
    expect(existsSync(manifestPath)).toBe(true);

    const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

    // Should be v2 manifest with SPA wiki segment
    expect(manifest.version).toBe(2);
    expect(manifest.base).toBe("/_luna/");
    expect(manifest.segments).toBeDefined();
    expect(manifest.segments.wiki).toBeDefined();
    expect(manifest.segments.wiki.spa).toBe(true);
    expect(manifest.segments.wiki.pattern).toBe("/wiki/*");
  });

  test("segment manifest file is generated", async () => {
    const wikiManifestPath = join(SOL_DOCS_DIR, "dist/_luna/routes/wiki.json");
    expect(existsSync(wikiManifestPath)).toBe(true);

    const manifest = JSON.parse(readFileSync(wikiManifestPath, "utf-8"));

    expect(manifest.base).toBe("/wiki");
    expect(manifest.fallback).toBe("spa");
    expect(manifest.routes).toBeDefined();
  });

  test("manifest.json is accessible via HTTP", async ({ page }) => {
    const response = await page.goto(`${server.url}/_luna/manifest.json`);
    expect(response?.status()).toBe(200);

    const manifest = await response?.json();
    expect(manifest.version).toBe(2);
  });

  test("segment manifest is accessible via HTTP", async ({ page }) => {
    const response = await page.goto(`${server.url}/_luna/routes/wiki.json`);
    expect(response?.status()).toBe(200);

    const manifest = await response?.json();
    expect(manifest.base).toBe("/wiki");
  });

  test("wiki page loads correctly with SPA segment", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);

    // Check page loads (use first() since wiki component renders its own h1)
    await expect(page.locator("h1").first()).toBeVisible();
    await expect(page).toHaveTitle(/Wiki|Luna/);
  });

  test("inline routes (root level) still work", async ({ page }) => {
    await page.goto(`${server.url}/`);

    // Root page should load from inline routes
    await expect(page.locator("h1")).toBeVisible();
  });

  test("non-SPA segments work normally", async ({ page }) => {
    await page.goto(`${server.url}/posts/`);

    // Posts is not marked as SPA
    await expect(page.locator("h1")).toBeVisible();
  });

  test("chunks are defined in manifest", async () => {
    const manifestPath = join(SOL_DOCS_DIR, "dist/_luna/manifest.json");
    const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

    expect(manifest.chunks).toBeDefined();
    expect(manifest.chunks.boot).toBeDefined();
    expect(manifest.chunks.boot).toContain("boot");
  });
});
