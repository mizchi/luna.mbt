import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Use a non-standard port to avoid conflicts with dev servers
const TEST_PORT = 9125;

/**
 * Playwright config for CLI-generated template app tests
 *
 * The webServer command runs the setup script that:
 * 1. Generates app from templates using CLI
 * 2. Builds the MoonBit code
 * 3. Bundles the client code
 * 4. Starts the server on the configured port
 */
export default defineConfig({
  testDir: __dirname,
  testMatch: "**/*.test.ts",
  fullyParallel: false, // Sequential for template app
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "list",
  use: {
    baseURL: `http://localhost:${TEST_PORT}`,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `PORT=${TEST_PORT} bash ${join(__dirname, "../../js/cli/test-template.sh")}`,
    url: `http://127.0.0.1:${TEST_PORT}`,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    timeout: 120000, // 2 minutes for build + start
  },
});
