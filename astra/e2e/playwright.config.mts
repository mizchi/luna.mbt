import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
// astra/e2e -> astra -> luna.mbt
const repoRoot = resolve(__dirname, "..", "..");
const fixtureCwd = resolve(repoRoot, "sol", "examples", "sol_docs");
const astraMain = resolve(
  repoRoot,
  "_build",
  "js",
  "release",
  "build",
  "mizchi",
  "astra",
  "cli",
  "main",
  "main.js",
);

const port = Number(process.env.ASTRA_E2E_PORT ?? 7780);

export default defineConfig({
  testDir: ".",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: `http://localhost:${port}`,
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
    command: `node ${JSON.stringify(astraMain)} dev --port ${port}`,
    cwd: fixtureCwd,
    url: `http://localhost:${port}/`,
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
