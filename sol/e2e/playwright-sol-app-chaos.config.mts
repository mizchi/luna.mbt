import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Boots `sol dev` against examples/sol_app on a dedicated port and runs the
// chaosbringer-based crawl. Distinct config because the crawl test owns the
// browser context itself (calls `chaos()` instead of using the Playwright
// page fixture), so the rest of the sol e2e suite shouldn't get tangled in.
const __dirname = dirname(fileURLToPath(import.meta.url));
// sol/e2e -> sol -> luna.mbt (workspace root, where _build/ lives)
const repoRoot = resolve(__dirname, "..", "..");
const solDir = resolve(__dirname, "..");

const port = Number(process.env.SOL_APP_CHAOS_PORT ?? 3458);

export default defineConfig({
  testDir: __dirname,
  testMatch: "sol-app-chaos.spec.ts",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "list",
  use: {
    baseURL: `http://localhost:${port}`,
    trace: "off",
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
    command: `node ${repoRoot}/_build/js/release/build/mizchi/sol/cmd/sol/sol.js dev --no-watch -p ${port}`,
    cwd: resolve(solDir, "examples/sol_app"),
    url: `http://localhost:${port}`,
    reuseExistingServer: !process.env.CI,
    timeout: 30000,
  },
});
