// VRT for sol_api_ref.
//
// Walks four representative URLs covering each level of the docs
// hierarchy (root → /api/ → /api/<module>/ → /api/<module>/<symbol>/)
// and matches each against a committed full-page screenshot baseline
// under e2e/__screenshots__/.
//
// To refresh baselines (after a deliberate design change):
//   pnpm --filter @luna_ui/sol-api-ref-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Sol API Reference/, name: "api-root" },
  { path: "/api/", title: /API/, name: "api-index" },
  { path: "/api/string/", title: /string/, name: "api-string" },
  { path: "/api/string/concat/", title: /concat/, name: "api-string-concat" },
] as const;

test.describe("sol_api_ref visual regression", () => {
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
