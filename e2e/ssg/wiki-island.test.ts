import { test, expect } from "@playwright/test";
import { execSync, spawn, ChildProcess } from "node:child_process";
import { join } from "node:path";

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

test.describe("Wiki Island - BrowserRouter Dynamic Routing", () => {
  let server: { url: string; process: ChildProcess };

  test.beforeAll(async () => {
    // Build the wiki component
    execSync("moon build --target js", {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    });

    // Copy wiki.js to sol_docs islands
    execSync(
      `cp ${join(PROJECT_ROOT, "target/js/release/build/examples/wiki/wiki.js")} ${join(SOL_DOCS_DIR, "docs/public/islands/wiki.js")}`,
      { stdio: "inherit" }
    );

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

  test("wiki page loads and hydrates", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);

    // Check page title
    await expect(page).toHaveTitle("Wiki");

    // Wait for hydration - wiki-container should appear
    // The island placeholder div with luna:id attribute should contain the hydrated content
    const wikiContainer = page.locator(".wiki-container");
    await expect(wikiContainer).toBeVisible({ timeout: 5000 });
  });

  test("wiki island hydrates and shows content", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);

    // Wait for hydration - wiki-container should appear
    const wikiContainer = page.locator(".wiki-container");
    await expect(wikiContainer).toBeVisible({ timeout: 5000 });

    // Check sidebar is rendered
    const sidebar = page.locator(".wiki-sidebar");
    await expect(sidebar).toBeVisible();
    await expect(sidebar.locator("h3")).toContainText("Wiki Pages");

    // Check main content area
    const mainContent = page.locator(".wiki-content");
    await expect(mainContent).toBeVisible();
  });

  test("wiki shows index page content by default", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);

    // Wait for hydration
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Check index page content
    const article = page.locator(".wiki-page").first();
    await expect(article.locator("h1")).toContainText("Wiki Home");
    await expect(article).toContainText("Welcome to the wiki");
  });

  test("sidebar navigation works - click to navigate", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);

    // Wait for hydration
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Click on "Getting Started" link in sidebar
    await page.locator(".wiki-sidebar").getByText("Getting Started").click();

    // Check URL changed
    await expect(page).toHaveURL(/\/wiki\/getting-started$/);

    // Check content changed
    const article = page.locator(".wiki-page");
    await expect(article.locator("h1")).toContainText("Getting Started");
    await expect(article).toContainText("pnpm install");
  });

  test("dynamic route parameter works - navigate to different pages", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Navigate to configuration
    await page.locator(".wiki-sidebar").getByText("Configuration").click();
    await expect(page).toHaveURL(/\/wiki\/configuration$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Configuration");

    // Navigate to API Reference
    await page.locator(".wiki-sidebar").getByText("API Reference").click();
    await expect(page).toHaveURL(/\/wiki\/api-reference$/);
    await expect(page.locator(".wiki-page h1")).toContainText("API Reference");

    // Navigate to Components
    await page.locator(".wiki-sidebar").getByText("Components").click();
    await expect(page).toHaveURL(/\/wiki\/components$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Components");
  });

  test("browser back/forward navigation works", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Navigate: Home -> Getting Started -> Configuration
    await page.locator(".wiki-sidebar").getByText("Getting Started").click();
    await expect(page).toHaveURL(/\/wiki\/getting-started$/);

    await page.locator(".wiki-sidebar").getByText("Configuration").click();
    await expect(page).toHaveURL(/\/wiki\/configuration$/);

    // Go back (should show Getting Started)
    await page.goBack();
    await expect(page).toHaveURL(/\/wiki\/getting-started$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Getting Started");

    // Go back again (should show Home)
    await page.goBack();
    await expect(page).toHaveURL(/\/wiki\/$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Wiki Home");

    // Go forward (should show Getting Started)
    await page.goForward();
    await expect(page).toHaveURL(/\/wiki\/getting-started$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Getting Started");
  });

  // Note: Direct URL access tests require SPA fallback configuration on the server.
  // In a static file server without fallback, /wiki/configuration returns 404.
  // These tests use client-side navigation from /wiki/ instead.

  test("navigate to page and back to home from sidebar", async ({ page }) => {
    // Start from wiki home (the only static page that exists)
    await page.goto(`${server.url}/wiki/`);
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Navigate to configuration via sidebar
    await page.locator(".wiki-sidebar").getByText("Configuration").click();
    await expect(page).toHaveURL(/\/wiki\/configuration$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Configuration");
    await expect(page.locator(".wiki-page")).toContainText("luna.json");

    // Click Wiki Home in sidebar to go back
    await page.locator(".wiki-sidebar").getByText("Wiki Home").click();
    // URL may be /wiki or /wiki/ depending on router implementation
    await expect(page).toHaveURL(/\/wiki\/?$/);
    await expect(page.locator(".wiki-page h1")).toContainText("Wiki Home");
  });

  test("unknown route via navigation shows not found", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    // Use BrowserRouter to navigate to unknown page
    await page.evaluate(() => {
      window.history.pushState({}, "", "/wiki/unknown-page");
      window.dispatchEvent(new PopStateEvent("popstate"));
    });

    // Wait for route update
    await page.waitForTimeout(100);

    // Should show not found message
    await expect(page.locator(".wiki-page h1")).toContainText("Page Not Found");
    await expect(page.locator(".wiki-page")).toContainText("unknown-page");
  });

  test("all sidebar links are present", async ({ page }) => {
    await page.goto(`${server.url}/wiki/`);
    await expect(page.locator(".wiki-container")).toBeVisible({ timeout: 5000 });

    const sidebar = page.locator(".wiki-sidebar");

    // Check all expected links
    await expect(sidebar.getByText("Wiki Home")).toBeVisible();
    await expect(sidebar.getByText("Getting Started")).toBeVisible();
    await expect(sidebar.getByText("Configuration")).toBeVisible();
    await expect(sidebar.getByText("API Reference")).toBeVisible();
    await expect(sidebar.getByText("Components")).toBeVisible();
  });
});
