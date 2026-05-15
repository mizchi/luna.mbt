// Smoke spec for sol_api_ref.
//
// Walks four representative URLs covering each level of the hierarchy
// (root → /api/ → /api/<module>/ → /api/<module>/<symbol>/), asserts the
// page renders with the expected title and an <h1>, and captures a
// non-baseline full-page screenshot for spot inspection (saved under
// playwright's `test-results/` — not committed).
//
// No VRT baseline is maintained for this example.
import { expect, test } from "@playwright/test";

const PAGES = [
  { path: "/", title: /Sol API Reference/, name: "root" },
  { path: "/api/", title: /API/, name: "api-index" },
  { path: "/api/string/", title: /string/, name: "api-string" },
  { path: "/api/string/concat/", title: /concat/, name: "api-string-concat" },
] as const;

test.describe("sol_api_ref smoke", () => {
  for (const page of PAGES) {
    test(`${page.path} renders`, async ({ page: p }, testInfo) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      await expect(p).toHaveTitle(page.title);
      await expect(p.locator("h1").first()).toBeVisible();

      // Wait for fonts / images to settle so the screenshot is taken
      // after the page's idle layout.
      await p.evaluate(() => document.fonts?.ready);
      await p.waitForLoadState("networkidle");

      // Capture (no baseline comparison). Attached to the test report
      // for manual inspection; not asserted against a committed PNG.
      const buf = await p.screenshot({ fullPage: true });
      await testInfo.attach(`${page.name}.png`, {
        body: buf,
        contentType: "image/png",
      });
    });
  }
});
