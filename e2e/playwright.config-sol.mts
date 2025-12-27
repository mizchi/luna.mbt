import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const solAppDir = join(__dirname, "../examples/sol_app");

// Use a non-standard port to avoid conflicts with dev servers
const TEST_PORT = 9124;

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/wc_counter*.test.ts", "**/sol_*.test.ts", "**/wc-css-isolation.test.ts", "**/wc-ssr-css.test.ts"],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
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
    command: `cd ${solAppDir} && pnpm build && PORT=${TEST_PORT} node .sol/prod/server/main.js`,
    url: `http://127.0.0.1:${TEST_PORT}`,
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    timeout: 60000, // Longer timeout for build + server startup
  },
});
