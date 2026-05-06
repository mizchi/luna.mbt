import { defineConfig, devices } from "@playwright/test";
import { existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Prerequisite: run `pnpm build` (or `moon build --target js --release` from
// the luna.mbt root) before this config is used.
// `pnpm test:e2e` chains it via `pretest:e2e` so a fresh checkout works.
const __dirname = dirname(fileURLToPath(import.meta.url));
// astra/e2e -> astra -> luna.mbt
const repoRoot = resolve(__dirname, "..", "..");
const fixtureCwd = resolve(repoRoot, "astra", "examples", "sol_docs");
const astraMain = resolve(
  repoRoot,
  "_build",
  "js",
  "release",
  "build",
  "mizchi",
  "astra",
  "cmd",
  "astra",
  "astra.js",
);
if (!existsSync(astraMain)) {
  throw new Error(
    `astra e2e: ${astraMain} not found. Run \`pnpm build\` (or \`moon build --target js --release\` from the luna.mbt root) first.`,
  );
}

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
