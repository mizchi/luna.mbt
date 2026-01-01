import { test, expect } from "@playwright/test";
import { spawn, ChildProcess, execSync } from "node:child_process";
import { join } from "node:path";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const DEV_SERVER_PORT = 3355;
const HMR_PORT = 24679;

let devServer: ChildProcess | null = null;

function killExistingProcesses(): void {
  try {
    execSync(
      `lsof -ti:${DEV_SERVER_PORT},${HMR_PORT} | xargs kill -9 2>/dev/null || true`,
      { stdio: "ignore" }
    );
  } catch {
    // Ignore errors
  }
}

async function startDevServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    const cliPath = join(
      PROJECT_ROOT,
      "target/js/release/build/astra/cli/cli.js"
    );

    devServer = spawn("node", [cliPath, "dev"], {
      cwd: PROJECT_ROOT,
      stdio: ["pipe", "pipe", "pipe"],
    });

    let started = false;
    let output = "";

    devServer.stdout?.on("data", (data: Buffer) => {
      output += data.toString();
      if (output.includes("Dev server running at") && !started) {
        started = true;
        setTimeout(resolve, 1000);
      }
    });

    devServer.stderr?.on("data", (data: Buffer) => {
      const errOutput = data.toString();
      if (errOutput.includes("EADDRINUSE")) {
        reject(new Error(`Port already in use: ${errOutput}`));
      }
    });

    devServer.on("error", reject);

    devServer.on("exit", (code) => {
      if (!started && code !== 0) {
        reject(new Error(`Dev server exited with code ${code}`));
      }
    });

    setTimeout(() => {
      if (!started) {
        reject(new Error("Dev server failed to start within 60 seconds"));
      }
    }, 60000);
  });
}

function stopDevServer(): void {
  if (devServer) {
    devServer.kill("SIGTERM");
    devServer = null;
  }
}

test.describe("Astra Dark Theme", () => {
  test.beforeAll(async () => {
    killExistingProcesses();
    await new Promise((r) => setTimeout(r, 1000));
    await startDevServer();
  });

  test.afterAll(async () => {
    stopDevServer();
  });

  test("theme toggle button exists and works", async ({ page }) => {
    await page.goto(`http://localhost:${DEV_SERVER_PORT}/luna/api-js/islands/`);

    // Check that theme toggle button exists
    const themeToggle = page.locator("button.theme-toggle");
    await expect(themeToggle).toBeVisible();

    // Initial state - check if dark class is NOT on html (light mode default)
    const html = page.locator("html");

    // Clear localStorage to ensure clean state
    await page.evaluate(() => localStorage.removeItem("theme"));
    await page.reload();

    // Verify initial state (should be light unless system prefers dark)
    const initialDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );

    // Click to toggle
    await themeToggle.click();

    // Verify class changed
    const afterClickDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );
    expect(afterClickDark).toBe(!initialDark);

    // Click again to toggle back
    await themeToggle.click();

    // Verify class changed back
    const afterSecondClickDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );
    expect(afterSecondClickDark).toBe(initialDark);
  });

  test("dark theme persists in localStorage", async ({ page }) => {
    await page.goto(`http://localhost:${DEV_SERVER_PORT}/luna/api-js/islands/`);

    // Clear localStorage
    await page.evaluate(() => localStorage.removeItem("theme"));
    await page.reload();

    const themeToggle = page.locator("button.theme-toggle");

    // Set to dark mode
    const html = page.locator("html");
    const initialDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );

    if (!initialDark) {
      await themeToggle.click();
    }

    // Verify localStorage is set
    const storedTheme = await page.evaluate(() =>
      localStorage.getItem("theme")
    );
    expect(storedTheme).toBe("dark");

    // Reload page
    await page.reload();

    // Verify dark mode persists
    const afterReloadDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );
    expect(afterReloadDark).toBe(true);
  });

  test("code blocks change color in dark mode", async ({ page }) => {
    await page.goto(`http://localhost:${DEV_SERVER_PORT}/luna/api-js/islands/`);

    // Wait for code blocks to be visible
    const codeBlock = page.locator("pre.shiki").first();
    await expect(codeBlock).toBeVisible();

    // Clear localStorage and reload for clean state
    await page.evaluate(() => localStorage.removeItem("theme"));
    await page.reload();
    await expect(codeBlock).toBeVisible();

    // Get the computed background color in light mode
    const lightBgColor = await codeBlock.evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });

    // Toggle to dark mode
    const themeToggle = page.locator("button.theme-toggle");
    const html = page.locator("html");
    const initialDark = await html.evaluate((el) =>
      el.classList.contains("dark")
    );

    if (!initialDark) {
      await themeToggle.click();
    }

    // Wait for CSS to apply
    await page.waitForTimeout(100);

    // Get the computed background color in dark mode
    const darkBgColor = await codeBlock.evaluate((el) => {
      return window.getComputedStyle(el).backgroundColor;
    });

    // The colors should be different between light and dark mode
    // Note: This test verifies the CSS is being applied, not the exact colors
    console.log(`Light mode bg: ${lightBgColor}`);
    console.log(`Dark mode bg: ${darkBgColor}`);

    // If the colors are the same, the dark theme CSS is not being applied
    expect(lightBgColor).not.toBe(darkBgColor);
  });

  test("visual snapshot: light mode", async ({ page }) => {
    await page.goto(`http://localhost:${DEV_SERVER_PORT}/luna/api-js/islands/`);

    // Set to light mode
    await page.evaluate(() => localStorage.setItem("theme", "light"));
    await page.reload();

    // Wait for content
    await page.locator("pre.shiki").first().waitFor();

    // Take screenshot of code block area
    const codeBlock = page.locator("pre.shiki").first();
    await expect(codeBlock).toHaveScreenshot("code-block-light.png", {
      maxDiffPixelRatio: 0.1,
    });
  });

  test("visual snapshot: dark mode", async ({ page }) => {
    await page.goto(`http://localhost:${DEV_SERVER_PORT}/luna/api-js/islands/`);

    // Set to dark mode
    await page.evaluate(() => localStorage.setItem("theme", "dark"));
    await page.reload();

    // Wait for content
    await page.locator("pre.shiki").first().waitFor();

    // Take screenshot of code block area
    const codeBlock = page.locator("pre.shiki").first();
    await expect(codeBlock).toHaveScreenshot("code-block-dark.png", {
      maxDiffPixelRatio: 0.1,
    });
  });
});
