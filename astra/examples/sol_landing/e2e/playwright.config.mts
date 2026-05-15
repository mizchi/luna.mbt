// Playwright VRT for sol_landing.
//
// Strategy:
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

const port = Number(process.env.SOL_LANDING_VRT_PORT ?? 5555);

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.spec.ts"],
  // Snapshots are stored alongside the spec, in `e2e/__screenshots__/`
  // (the default `*-snapshots/` per-spec layout becomes noisy with only
  // one or two tests). `{platform}` keeps darwin vs linux baselines
  // separate — chromium's font + rasterization stack differs between
  // host OSes enough that one baseline rarely passes the other.
  snapshotPathTemplate: "{testDir}/__screenshots__/{platform}/{arg}{ext}",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: [["list"]],
  expect: {
    // A fresh chromium across machines won't be byte-identical; cap
    // diff per pixel and total ratio so noise like JPEG resampling on
    // sub-pixel font hinting doesn't fail CI. Threshold values cribbed
    // from playwright's own visual-regression guide.
    toHaveScreenshot: {
      threshold: 0.2,
      maxDiffPixelRatio: 0.02,
      animations: "disabled",
    },
  },
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
          // --font-render-hinting=none reduces glyph-hint flicker across
          // OS font stacks; --disable-skia-runtime-opts removes one more
          // source of GPU-dependent rasterization variance.
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
