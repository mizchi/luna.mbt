// VRT for sol_landing.
//
// Asserts that the en (/) and ja (/ja/) landing pages render their
// expected document chrome AND match the committed full-page screenshot
// baselines under e2e/__screenshots__/.
//
// To refresh baselines (after a deliberate design change):
//   pnpm --filter @luna_ui/sol-landing-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Astra Demo/, lang: "en" },
  { path: "/ja/", title: /Astra/, lang: "ja" },
] as const;

test.describe("sol_landing visual regression", () => {
  for (const page of PAGES) {
    test(`${page.path} renders and matches baseline`, async ({ page: p }) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      await expect(p).toHaveTitle(page.title);
      await expect(p.locator("h1").first()).toBeVisible();
      await expect(
        p.locator("theme-toggle button"),
        "island button should hydrate",
      ).toBeVisible();

      // Wait for fonts / images / island JS to settle so the screenshot
      // is taken after the page's idle layout.
      await p.evaluate(() => document.fonts?.ready);
      await p.waitForLoadState("networkidle");

      await expect(p).toHaveScreenshot(`landing-${page.lang}.png`, {
        fullPage: true,
      });
    });
  }
});
