// VRT for sol_changelog.
//
// Asserts that the release index and a handful of per-version pages render
// expected document chrome AND match the committed full-page screenshot
// baselines under e2e/__screenshots__/.
//
// To refresh baselines (after a deliberate design change):
//   pnpm --filter @luna_ui/sol-changelog-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Sol Changelog/, name: "index" },
  { path: "/release/0.22.4/", title: /Release/, name: "release-0.22.4" },
  { path: "/release/0.22.3/", title: /Release/, name: "release-0.22.3" },
] as const;

test.describe("sol_changelog visual regression", () => {
  for (const page of PAGES) {
    test(`${page.path} renders and matches baseline`, async ({ page: p }) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      await expect(p).toHaveTitle(page.title);
      await expect(p.locator("h1").first()).toBeVisible();

      // Wait for fonts / images to settle so the screenshot is taken
      // after the page's idle layout.
      await p.evaluate(() => document.fonts?.ready);
      await p.waitForLoadState("networkidle");

      await expect(p).toHaveScreenshot(`${page.name}.png`, {
        fullPage: true,
      });
    });
  }
});
