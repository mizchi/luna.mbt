import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Playwright config for sol-app E2E tests
 */
export default defineConfig({
  testDir: __dirname,
  testMatch: "**/*.test.ts",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "list",
  use: {
    baseURL: "http://localhost:3457",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `bash ${join(__dirname, "setup.sh")}`,
    url: "http://127.0.0.1:3457",
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    timeout: 120000, // 2 minutes for build + start
  },
});
