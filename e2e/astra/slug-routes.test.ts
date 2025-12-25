import { test, expect } from "@playwright/test";
import { execSync, spawn, ChildProcess } from "node:child_process";
import { join } from "node:path";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const ASTRA_APP_DIR = join(PROJECT_ROOT, "examples/astra_app");
const CLI_PATH = join(PROJECT_ROOT, "target/js/release/build/astra/cli/cli.js");

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

test.describe("Dynamic Routes - _slug_ Pattern", () => {
  let server: { url: string; process: ChildProcess };

  test.beforeAll(async () => {
    // Build astra_app
    execSync(`node ${CLI_PATH} build`, {
      cwd: ASTRA_APP_DIR,
      stdio: "inherit",
    });

    // Start static server
    server = await startStaticServer(join(ASTRA_APP_DIR, "dist"));
  });

  test.afterAll(() => {
    server?.process?.kill();
  });

  test("posts index page loads with links to all posts", async ({ page }) => {
    await page.goto(`${server.url}/posts/`);

    // Check page title
    await expect(page).toHaveTitle(/Posts/);

    // Check that all post links are present in the main content area
    // Note: Hello World is now a static page (takes priority over dynamic)
    const mainContent = page.locator(".doc-content, article.doc-content").first();
    await expect(mainContent.getByRole("link", { name: "Hello World" })).toBeVisible();
    await expect(mainContent.getByRole("link", { name: "Getting Started" })).toBeVisible();
    await expect(mainContent.getByRole("link", { name: "Advanced Topics" })).toBeVisible();
  });

  test("hello-world post page uses static version (priority test)", async ({ page }) => {
    // hello-world has both static and dynamic sources
    // Static should take priority
    await page.goto(`${server.url}/posts/hello-world/`);

    // Check that STATIC page content is shown
    await expect(page.locator("h1")).toContainText("Hello World - Static Page");

    // Check static page content is rendered
    await expect(page.locator("body")).toContainText("static page");
  });

  test("getting-started post page is generated correctly", async ({ page }) => {
    await page.goto(`${server.url}/posts/getting-started/`);

    // Check page loads
    await expect(page.locator("h1")).toContainText("Post Page");

    // Check it's a different page (same template content)
    await expect(page.locator("body")).toContainText("dynamically generated post page");
  });

  test("advanced-topics post page is generated correctly", async ({ page }) => {
    await page.goto(`${server.url}/posts/advanced-topics/`);

    // Check page loads
    await expect(page.locator("h1")).toContainText("Post Page");

    // Check content
    await expect(page.locator("body")).toContainText("staticParams");
  });

  test("navigation from index to dynamic post works", async ({ page }) => {
    await page.goto(`${server.url}/posts/`);

    // Click on Getting Started link (dynamic page, not static)
    const mainContent = page.locator(".doc-content, article.doc-content").first();
    await mainContent.getByRole("link", { name: "Getting Started" }).click();

    // Verify navigation
    await expect(page).toHaveURL(/\/posts\/getting-started\/?$/);
    await expect(page.locator("h1")).toContainText("Post Page");
  });

  test("dynamic posts have correct meta description", async ({ page }) => {
    // Check getting-started (dynamic page)
    await page.goto(`${server.url}/posts/getting-started/`);
    const metaGetting = page.locator('meta[name="description"]');
    await expect(metaGetting).toHaveAttribute("content", "A blog post example");

    // Check advanced-topics (dynamic page)
    await page.goto(`${server.url}/posts/advanced-topics/`);
    const metaAdvanced = page.locator('meta[name="description"]');
    await expect(metaAdvanced).toHaveAttribute("content", "A blog post example");
  });

  test("non-existent slug returns 404", async ({ page }) => {
    const response = await page.goto(`${server.url}/posts/non-existent-post/`);

    // Static server returns 404 for non-existent pages
    expect(response?.status()).toBe(404);
  });

  test("generated pages have proper HTML structure", async ({ page }) => {
    await page.goto(`${server.url}/posts/hello-world/`);

    // Check basic HTML structure
    await expect(page.locator("html")).toHaveAttribute("lang", "en");
    await expect(page.locator("meta[charset]")).toHaveAttribute("charset", "UTF-8");
    await expect(page.locator("meta[name='viewport']")).toBeAttached();
  });

  test("posts index explains _slug_ pattern usage", async ({ page }) => {
    await page.goto(`${server.url}/posts/`);

    // Check that the documentation about _slug_ pattern is present
    await expect(page.locator("body")).toContainText("_slug_");
    await expect(page.locator("body")).toContainText("staticParams");
  });

  // Priority tests: static paths should take precedence over dynamic _slug_ paths
  test("static path takes priority over dynamic _slug_ path", async ({ page }) => {
    // hello-world exists both as:
    // - posts/hello-world/index.md (static)
    // - posts/_slug_/index.md?slug=hello-world (dynamic)
    // The static page should be used
    await page.goto(`${server.url}/posts/hello-world/`);

    // Check that the STATIC page content is shown, not the dynamic template
    await expect(page.locator("h1")).toContainText("Hello World - Static Page");
    await expect(page.locator("body")).toContainText("static page");
    await expect(page.locator("body")).toContainText("Priority Rule");
  });

  test("static page has correct title in sidebar", async ({ page }) => {
    await page.goto(`${server.url}/posts/hello-world/`);

    // The sidebar should show the static page's title "Hello World (Static)"
    // not the auto-generated "Hello world" from _slug_
    const sidebar = page.locator(".sidebar, aside").first();
    await expect(sidebar).toContainText("Hello World (Static)");
  });

  test("static page has its own meta description", async ({ page }) => {
    await page.goto(`${server.url}/posts/hello-world/`);

    // Static page has its own description
    const meta = page.locator('meta[name="description"]');
    await expect(meta).toHaveAttribute("content", "This is the static version of Hello World page");
  });

  test("other dynamic pages still work alongside static override", async ({ page }) => {
    // getting-started should still use the dynamic template
    await page.goto(`${server.url}/posts/getting-started/`);

    // This should be from the dynamic template
    await expect(page.locator("h1")).toContainText("Post Page");
    await expect(page.locator("body")).toContainText("dynamically generated post page");

    // But not the static override content
    await expect(page.locator("body")).not.toContainText("Priority Rule");
  });
});
