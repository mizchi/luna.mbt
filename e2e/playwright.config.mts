import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.test.ts", "**/*.test.mts"],
  testIgnore: ["**/template-app/**", "**/sol/cli/**", "**/sol-app/**", "**/wc_counter*.test.ts", "**/wc-css-isolation.test.ts", "**/wc-ssr-css.test.ts"], // template-app and sol-app have their own configs, sol/cli uses vitest, wc_counter, wc-css-isolation and wc-ssr-css use playwright.config-sol.mts
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "list",
  // Snapshot settings: remove platform suffix, allow small differences
  snapshotPathTemplate: "{testDir}/{testFileDir}/{testFileName}-snapshots/{arg}{ext}",
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.05, // Allow 5% pixel difference
      threshold: 0.3, // Per-pixel color threshold (0-1)
    },
  },
  use: {
    baseURL: "http://localhost:3456",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `node ${join(__dirname, "server.ts")}`,
    url: "http://127.0.0.1:3456",
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    timeout: 30000,
  },
});
