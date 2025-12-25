import { test, expect } from "@playwright/test";
import { execSync, spawn, ChildProcess } from "node:child_process";
import { join } from "node:path";
import {
  existsSync,
  readFileSync,
  mkdirSync,
  writeFileSync,
  rmSync,
} from "node:fs";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const CLI_PATH = join(
  PROJECT_ROOT,
  "target/js/release/build/astra/cli/cli.js"
);

function createTestProject(name: string, config: object): string {
  const testDir = join(PROJECT_ROOT, ".test-output", name);

  // Clean up if exists
  if (existsSync(testDir)) {
    rmSync(testDir, { recursive: true });
  }

  // Create test project structure
  mkdirSync(join(testDir, "docs"), { recursive: true });

  // Write config
  writeFileSync(join(testDir, "astra.json"), JSON.stringify(config, null, 2));

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

function startStaticServer(distDir: string): Promise<{ url: string; process: ChildProcess }> {
  return new Promise((resolve, reject) => {
    // Use npx serve for static file serving (without -s to avoid SPA fallback)
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
        // Wait a bit for server to be fully ready
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

test.describe("Astra Component Directory", () => {
  test.beforeAll(() => {
    // Ensure CLI is built
    execSync("moon build --target js", {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    });
  });

  test("detects component directory with moon.pkg.json", async () => {
    const testDir = createTestProject("component-detection", {
      docs: "docs",
      output: "dist",
      title: "Component Test",
    });

    // Create index page
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
---
# Home Page
`
    );

    // Create component directory with moon.pkg.json
    const componentDir = join(testDir, "docs/my-component");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false, import: [] }, null, 2)
    );

    writeFileSync(
      join(componentDir, "component.mbt"),
      `// My Component
pub fn my_component() -> String {
  "Hello from component!"
}
`
    );

    writeFileSync(
      join(componentDir, "page.json"),
      JSON.stringify(
        {
          title: "My Component",
          description: "A test component page",
        },
        null,
        2
      )
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);
    expect(result.output).toContain("Found 2 pages");

    // Check component page was generated
    const componentHtmlPath = join(testDir, "dist/my-component/index.html");
    expect(existsSync(componentHtmlPath)).toBe(true);

    // Verify HTML content
    const html = readFileSync(componentHtmlPath, "utf-8");
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("<title>My Component</title>");
    expect(html).toContain('data-component="my-component"');
    // Client-only components have data-hydrate and component-loading class
    expect(html).toContain('data-hydrate="true"');
    expect(html).toContain("class=\"component-loading\"");
  });

  test("component page is included in _routes.json for cloudflare", async () => {
    const testDir = createTestProject("component-routes", {
      docs: "docs",
      output: "dist",
      title: "Component Routes Test",
      deploy: "cloudflare",
    });

    // Create index page
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
---
# Home
`
    );

    // Create component directory
    const componentDir = join(testDir, "docs/counter");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false }, null, 2)
    );

    writeFileSync(
      join(componentDir, "counter.mbt"),
      `pub fn counter() -> Unit { () }
`
    );

    writeFileSync(
      join(componentDir, "page.json"),
      JSON.stringify({ title: "Counter" }, null, 2)
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check _routes.json includes component path
    const routesPath = join(testDir, "dist/_routes.json");
    const routes = JSON.parse(readFileSync(routesPath, "utf-8"));

    expect(routes.exclude).toContain("/counter/*");
  });

  test("component page is included in manifest.json", async () => {
    const testDir = createTestProject("component-manifest", {
      docs: "docs",
      output: "dist",
      title: "Component Manifest Test",
    });

    // Create index page
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
---
# Home
`
    );

    // Create component directory
    const componentDir = join(testDir, "docs/widget");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false }, null, 2)
    );

    writeFileSync(
      join(componentDir, "widget.mbt"),
      `pub fn widget() -> Unit { () }
`
    );

    writeFileSync(
      join(componentDir, "page.json"),
      JSON.stringify({ title: "Widget" }, null, 2)
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check manifest.json includes component route
    const manifestPath = join(testDir, "dist/_luna/manifest.json");
    const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

    expect(manifest.routes).toBeDefined();
    expect(manifest.routes["/widget/"]).toBeDefined();
  });

  test("component page renders in browser", async ({ page }) => {
    const testDir = createTestProject("component-browser", {
      docs: "docs",
      output: "dist",
      title: "Browser Component Test",
    });

    // Create index page
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
---
# Home

[Go to Demo](/demo/)
`
    );

    // Create component directory
    const componentDir = join(testDir, "docs/demo");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false }, null, 2)
    );

    writeFileSync(
      join(componentDir, "demo.mbt"),
      `pub fn demo() -> String { "Demo Component" }
`
    );

    writeFileSync(
      join(componentDir, "page.json"),
      JSON.stringify(
        {
          title: "Demo Component",
          description: "Interactive demo component",
        },
        null,
        2
      )
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Start server
    const server = await startStaticServer(join(testDir, "dist"));

    try {
      // Navigate to component page
      await page.goto(`${server.url}/demo/`);

      // Check page loaded correctly
      await expect(page).toHaveTitle("Demo Component");

      // Check component placeholder is rendered (client-only shows loading message)
      const placeholder = page.locator('[data-component="demo"]');
      await expect(placeholder).toBeVisible();
      await expect(placeholder).toContainText("Loading demo...");

      // Check sidebar shows the component (use first() to avoid strict mode violation from mobile/desktop duplicates)
      const sidebarLink = page.locator('.sidebar-link[href="/demo/"]').first();
      await expect(sidebarLink).toBeVisible();
    } finally {
      server.process.kill();
    }
  });

  test("navigation to component page works", async ({ page }) => {
    const testDir = createTestProject("component-navigation", {
      docs: "docs",
      output: "dist",
      title: "Navigation Test",
    });

    // Create home page with link
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
layout: home
---
# Welcome

Check out our [interactive component](/interactive/)!
`
    );

    // Create component directory
    const componentDir = join(testDir, "docs/interactive");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false }, null, 2)
    );

    writeFileSync(
      join(componentDir, "interactive.mbt"),
      `pub fn interactive() -> Unit { () }
`
    );

    writeFileSync(
      join(componentDir, "page.json"),
      JSON.stringify({ title: "Interactive Component" }, null, 2)
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Start server
    const server = await startStaticServer(join(testDir, "dist"));

    try {
      // Start at home page
      await page.goto(`${server.url}/`);
      await expect(page).toHaveTitle("Home");

      // Click link to component page
      await page.click('a[href="/interactive/"]');

      // Should navigate to component page
      await expect(page).toHaveTitle("Interactive Component");
      await expect(page.locator('[data-component="interactive"]')).toBeVisible();
    } finally {
      server.process.kill();
    }
  });

  test("component without page.json uses directory name as title", async () => {
    const testDir = createTestProject("component-no-page-json", {
      docs: "docs",
      output: "dist",
      title: "No Page JSON Test",
    });

    // Create index page
    writeFileSync(
      join(testDir, "docs/index.md"),
      `---
title: Home
---
# Home
`
    );

    // Create component directory WITHOUT page.json
    const componentDir = join(testDir, "docs/simple-widget");
    mkdirSync(componentDir, { recursive: true });

    writeFileSync(
      join(componentDir, "moon.pkg.json"),
      JSON.stringify({ "is-main": false }, null, 2)
    );

    writeFileSync(
      join(componentDir, "widget.mbt"),
      `pub fn widget() -> Unit { () }
`
    );

    const result = runBuild(testDir);
    expect(result.success).toBe(true);

    // Check component page was generated
    const componentHtmlPath = join(testDir, "dist/simple-widget/index.html");
    expect(existsSync(componentHtmlPath)).toBe(true);

    // Title should be derived from directory name
    const html = readFileSync(componentHtmlPath, "utf-8");
    expect(html).toContain('data-component="simple-widget"');
  });
});
