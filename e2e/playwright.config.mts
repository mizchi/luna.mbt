import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.test.ts", "**/*.test.mts"],
  testIgnore: ["**/template-app/**", "**/sol/cli/**", "**/sol-app/**", "**/wc_counter*.test.ts", "**/wc-css-isolation.test.ts"], // template-app and sol-app have their own configs, sol/cli uses vitest, wc_counter and wc-css-isolation use playwright.config-sol.mts
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "list",
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
