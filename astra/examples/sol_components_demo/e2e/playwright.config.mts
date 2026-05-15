// Playwright VRT for sol_components_demo.
//
// Strategy (matches sol_landing):
// 1. `astra build` is run via the `pretest:e2e` npm hook (see package.json).
// 2. This config's `webServer` then serves the resulting `dist/` over
//    `http-server` on a fixed port. We deliberately use a static server
//    rather than `astra dev` here because dev mode renders some
//    non-deterministic prefetch hints that would invalidate baselines.
// 3. Each spec navigates the served URL, disables animations, and
//    snapshots `fullPage`.
import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const exampleDir = resolve(__dirname, "..");

const port = Number(process.env.SOL_COMPONENTS_DEMO_VRT_PORT ?? 5557);

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.spec.ts"],
  // Snapshots are stored alongside the spec, in `e2e/__screenshots__/`
  // (the default `*-snapshots/` per-spec layout becomes noisy with only
  // one or two tests). `{platform}` keeps darwin vs linux baselines
  // separate.
  snapshotPathTemplate: "{testDir}/__screenshots__/{platform}/{arg}{ext}",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["list"]],
  expect: {
    toHaveScreenshot: {
      threshold: 0.2,
      maxDiffPixelRatio: 0.02,
      animations: "disabled",
    },
  },
  use: {
    baseURL: `http://localhost:${port}`,
    trace: "on-first-retry",
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
    command: `npx --no-install http-server dist -p ${port} -s --cors -c-1`,
    cwd: exampleDir,
    url: `http://localhost:${port}/`,
    reuseExistingServer: !process.env.CI,
    timeout: 30_000,
  },
});
