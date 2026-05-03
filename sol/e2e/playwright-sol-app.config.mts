import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, "..");

export default defineConfig({
  testDir: ".",
  testMatch: "sol-app-hydration.spec.ts",
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
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
  webServer: {
    command: `node ${rootDir}/_build/js/release/build/mizchi/sol/cli/cli.js dev --no-watch -p 3457`,
    cwd: resolve(rootDir, "examples/sol_app"),
    url: "http://localhost:3457",
    reuseExistingServer: !process.env.CI,
    timeout: 30000,
  },
});
