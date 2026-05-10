// Smoke tests for the deployed Luna UI website (built by `astra build`).
//
// Default target: https://luna.mizchi.workers.dev (Cloudflare Workers).
// Override WEBSITE_URL to point at https://mizchi.github.io/luna.mbt
// (GitHub Pages mirror) or any preview build.
//
// Run:
//   pnpm exec playwright test --config=astra/e2e/deployed/playwright.config.mts
import { test, expect } from "@playwright/test";

const PAGES = [
  { path: "/", title: "Luna UI" },
  { path: "/introduction/overview/" },
  { path: "/luna/", title: /Luna/ },
  { path: "/sol/", title: /Sol/ },
  { path: "/astra/", title: /Astra/ },
  { path: "/astra/getting-started/", title: /Getting Started|はじめる/ },
  { path: "/astra/mount-on-mars/", title: /Mount on Mars|Mars にマウントする/ },
  { path: "/astra/deploy/", title: /Deploy|デプロイ/ },
  { path: "/search/" },
  { path: "/ja/" },
  { path: "/ja/astra/", title: /Astra/ },
] as const;

test.describe("Luna UI website deploy smoke", () => {
  for (const page of PAGES) {
    test(`page ${page.path} renders`, async ({ page: p }) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      if (page.title) {
        await expect(p).toHaveTitle(page.title);
      }
      // Every page must render at least one heading — empty body means CSS
      // / Markdown pipeline blew up.
      await expect(p.locator("h1, h2").first()).toBeVisible();
    });
  }

  test("home loads inline CSS with theme variables", async ({ page }) => {
    await page.goto("/");

    // Astra inlines the design-system CSS (no external stylesheet for the
    // base theme). If the inline <style> goes missing the variables vanish
    // and the whole page renders unstyled.
    const tokens = await page.evaluate(() => {
      const style = getComputedStyle(document.documentElement);
      return {
        primary: style.getPropertyValue("--primary-color").trim(),
        bg: style.getPropertyValue("--bg-color").trim(),
        text: style.getPropertyValue("--text-color").trim(),
        border: style.getPropertyValue("--border-color").trim(),
      };
    });
    for (const [name, value] of Object.entries(tokens)) {
      expect(value, `--${name}-color should resolve`).toMatch(
        /^(#[0-9a-f]{3,8}|rgba?\(.+\))$/i,
      );
    }

    // Theme bootstrap script flips `html` between light/dark on load. One
    // of the two classes must end up on <html> — the absence of both means
    // the inline script never ran.
    const cls = await page.evaluate(() => document.documentElement.className);
    expect(cls).toMatch(/(^|\s)(light|dark)(\s|$)/);
  });

  test("static assets are reachable", async ({ request }) => {
    const assets = [
      { path: "/assets/loader.js", contentType: /javascript/ },
      { path: "/pagefind/pagefind.js", contentType: /javascript/ },
      { path: "/pagefind/pagefind-ui.css", contentType: /css/ },
    ];
    for (const asset of assets) {
      const res = await request.get(asset.path);
      expect(res.status(), `${asset.path} should be 200`).toBe(200);
      const ct = res.headers()["content-type"] ?? "";
      expect(ct, `${asset.path} content-type`).toMatch(asset.contentType);
    }
  });

  test("pagefind search UI mounts on /search/", async ({ page }) => {
    await page.goto("/search/");
    // The search page should render pagefind's container — either the
    // form input or its wrapper. We don't drive a real search here, just
    // confirm the asset graph hooked up.
    const searchAffordance = page
      .locator('[data-pagefind-ui], input[type="search"], #search')
      .first();
    await expect(searchAffordance).toBeVisible();
  });

  test("nav links to all four chapters from the home", async ({ page }) => {
    await page.goto("/");
    // Nav defined in website/sol.config.json: Luna, Sol, Astra, Search.
    for (const target of ["/luna/", "/sol/", "/astra/", "/search/"]) {
      const link = page.locator(`a[href="${target}"]`).first();
      await expect(link, `home should link to ${target}`).toBeVisible();
    }
  });
});
