// VRT for sol_docs_search.
//
// Asserts that the home + two representative guide pages render their
// expected document chrome and that the <search-box> island is mounted
// (input visible). No interaction with search is performed in VRT — the
// baseline only confirms the search UI is present on the page.
//
// Baselines under e2e/__screenshots__/{darwin,linux}/ are seeded in main.
//
// To refresh after a deliberate change:
//   pnpm --filter @luna_ui/sol-docs-search-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Astra Docs Search/, slug: "home" },
  { path: "/guide/intro/", title: /Introduction/, slug: "guide-intro" },
  { path: "/guide/search/", title: /Adding search/, slug: "guide-search" },
] as const;

test.describe("sol_docs_search visual regression", () => {
  for (const page of PAGES) {
    test(`${page.path} renders and matches baseline`, async ({ page: p }) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      await expect(p).toHaveTitle(page.title);
      await expect(p.locator("h1").first()).toBeVisible();

      // The <search-box> island upgrades into an <input> + .results
      // container. Either the index is available (input is visible) or
      // the fallback message renders inside .results. Both states count
      // as "the island mounted".
      await expect(
        p.locator("search-box input, search-box .empty"),
        "search-box island should mount",
      ).toBeVisible();

      // Wait for fonts / islands JS to settle so the screenshot is
      // taken after idle layout.
      await p.evaluate(() => document.fonts?.ready);
      await p.waitForLoadState("networkidle");

      await expect(p).toHaveScreenshot(`docs-search-${page.slug}.png`, {
        fullPage: true,
      });
    });
  }
});
