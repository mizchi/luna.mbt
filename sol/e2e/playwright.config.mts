import { defineConfig, devices } from "@playwright/test";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  testDir: ".",
  testIgnore: ["sol-app-hydration.spec.ts"],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: "http://localhost:3456",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        // Fixed viewport for consistent behavior in CI
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
  webServer: {
    command: "npx tsx server.ts",
    cwd: __dirname,
    url: "http://localhost:3456",
    reuseExistingServer: !process.env.CI,
    env: {
      DEBUG: process.env.DEBUG || "0",
    },
  },
});
