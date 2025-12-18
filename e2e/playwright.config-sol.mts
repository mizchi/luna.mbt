import { defineConfig, devices } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const solAppDir = join(__dirname, "../examples/sol_app");

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/wc_counter*.test.ts", "**/sol_*.test.ts", "**/wc-css-isolation.test.ts"],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "list",
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `cd ${solAppDir} && pnpm build && node .sol/prod/server/main.js`,
    url: "http://127.0.0.1:3000",
    reuseExistingServer: !process.env.CI,
    stdout: "pipe",
    timeout: 60000, // Longer timeout for build + server startup
  },
});
