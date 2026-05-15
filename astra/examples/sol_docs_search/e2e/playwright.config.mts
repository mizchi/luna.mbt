// Playwright VRT for sol_docs_search.
//
// Strategy mirrors sol_landing's setup, with one important twist:
//   - `pretest:e2e` runs `pnpm build`, which is now `astra build &&
//     pagefind --site dist`. So by the time playwright opens its first
//     page, `dist/pagefind/` is already populated and `<search-box>`
//     can dynamic-import the index without falling back to its empty
//     state.
//   - `webServer` serves `dist/` over `http-server` on a fixed port
//     (5560 by default). We use a static server rather than `astra dev`
//     because dev mode does not run PageFind.
import { defineConfig, devices } from "@playwright/test";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const exampleDir = resolve(__dirname, "..");

const port = Number(process.env.SOL_DOCS_SEARCH_VRT_PORT ?? 5560);

export default defineConfig({
  testDir: __dirname,
  testMatch: ["**/*.spec.ts"],
  // Snapshots are stored alongside the spec, in `e2e/__screenshots__/`.
  // `{platform}` keeps darwin vs linux baselines separate.
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
