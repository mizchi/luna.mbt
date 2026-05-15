// Playwright config for sol_api_ref. Mirrors sol_landing's VRT config
// (chromium-only, http-server over `dist/`, screenshot diff with
// per-OS baselines under e2e/__screenshots__/{darwin,linux}/).
import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const exampleDir = resolve(__dirname, "..");

const port = Number(process.env.SOL_API_REF_VRT_PORT ?? 5559);

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.spec.ts"],
  snapshotPathTemplate: "{testDir}/__screenshots__/{platform}/{arg}{ext}",
  expect: {
    toHaveScreenshot: {
      threshold: 0.2,
      maxDiffPixelRatio: 0.02,
      animations: "disabled",
    },
  },
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
