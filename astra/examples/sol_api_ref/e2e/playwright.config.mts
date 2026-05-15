// Playwright config for sol_api_ref.
//
// Strategy:
// 1. `astra build` is run via the `pretest:e2e` npm hook (see package.json).
// 2. This config's `webServer` then serves the resulting `dist/` over
//    `http-server` on a fixed port. We deliberately use a static server
//    rather than `astra dev` here because dev mode renders some
//    non-deterministic prefetch hints that would invalidate snapshots.
// 3. Each spec navigates the served URL, asserts basic chrome, and
//    captures a non-baseline `fullPage` screenshot for spot inspection.
//
// No screenshot baseline is committed for this example — the spec only
// verifies the pages render and do basic chrome assertions.
import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const exampleDir = resolve(__dirname, "..");

const port = Number(process.env.SOL_API_REF_VRT_PORT ?? 5559);

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.spec.ts"],
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: `http://localhost:${port}`,
    trace: "on-first-retry",
    // Pin locale + timezone so Date / Intl-derived strings don't shift
    // the rendered DOM across runners.
    locale: "en-US",
    timezoneId: "UTC",
    colorScheme: "light",
    reducedMotion: "reduce",
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 720 },
        deviceScaleFactor: 1,
        launchOptions: {
          args: [
            "--font-render-hinting=none",
            "--disable-skia-runtime-opts",
            "--force-color-profile=srgb",
          ],
        },
      },
    },
  ],
  webServer: {
    // `pnpm dlx http-server` is undesirable in CI (each invocation hits
    // the network). The dep is listed in package.json so `pnpm install`
    // hydrates it once, then `npx --no-install` resolves it offline.
    command: `npx --no-install http-server dist -p ${port} -s --cors -c-1`,
    cwd: exampleDir,
    url: `http://localhost:${port}/`,
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
