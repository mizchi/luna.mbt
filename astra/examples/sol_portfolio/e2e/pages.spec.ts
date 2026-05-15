// VRT for sol_portfolio.
//
// Asserts that the project list (/) and two representative project
// detail pages render the expected document chrome AND match the
// committed full-page screenshot baselines under e2e/__screenshots__/.
//
// To refresh baselines (after a deliberate design change):
//   pnpm --filter @luna_ui/sol-portfolio-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Portfolio/, snapshot: "portfolio-index" },
  {
    path: "/projects/project-1/",
    title: /Aurora Notes/,
    snapshot: "portfolio-project-1",
  },
  {
    path: "/projects/project-3/",
    title: /Comet Graph/,
    snapshot: "portfolio-project-3",
  },
] as const;

test.describe("sol_portfolio visual regression", () => {
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

      await expect(p).toHaveScreenshot(`${page.snapshot}.png`, {
        fullPage: true,
      });
    });
  }
});
