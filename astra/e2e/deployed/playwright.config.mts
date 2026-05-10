import { defineConfig, devices } from "@playwright/test";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// Smoke tests against the deployed Luna UI website. Defaults to the
// canonical Cloudflare Workers deploy; override with WEBSITE_URL to point
// at the GitHub Pages mirror or a preview build.
//
// Examples:
//   pnpm exec playwright test --config=astra/e2e/deployed/playwright.config.mts
//   WEBSITE_URL=https://mizchi.github.io/luna.mbt pnpm exec playwright test \
//     --config=astra/e2e/deployed/playwright.config.mts
const baseURL =
  process.env.WEBSITE_URL ?? "https://luna.mizchi.workers.dev";

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
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],
});
