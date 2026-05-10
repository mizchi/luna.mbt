import { defineConfig, devices } from "@playwright/test";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Smoke tests against the live luna-examples worker (or any URL set via env).
// No webServer — these only run when the deploy is reachable, so CI should
// gate them on a deploy-succeeded signal rather than running them on every
// push.
const baseURL =
  process.env.LUNA_EXAMPLES_URL ?? "https://luna-examples.mizchi.workers.dev";

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.test.ts"],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: "dot",
  use: {
    baseURL,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
