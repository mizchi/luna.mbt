// VRT for sol_components_demo.
//
// Asserts that `/` renders the document chrome with all three component
// systems (TSX swatches, MoonBit info-box, my-counter island) and matches
// the committed full-page screenshot baseline under e2e/__screenshots__/.
//
// Baselines are seeded by main in a follow-up commit; this spec is the
// definition of "what gets compared" only.
//
// To refresh baselines locally (after a deliberate design change):
//   pnpm --filter @luna_ui/sol-components-demo-example test:e2e:update
import { expect, test } from "@playwright/test";

const PAGES = [{ path: "/", title: /Astra Components Demo/, name: "index" }] as const;

test.describe("sol_components_demo visual regression", () => {
  for (const page of PAGES) {
    test(`${page.path} renders three component systems and matches baseline`, async ({
      page: p,
    }) => {
      const res = await p.goto(page.path);
      expect(res?.status(), `expected 2xx at ${page.path}`).toBe(200);
      await expect(p).toHaveTitle(page.title);

      // Heading from the index markdown.
      await expect(p.locator("h1").first()).toBeVisible();

      // TSX section's swatches rendered inline in markdown (the
      // server-side TSX page lives at /color_palette/ as well).
      await expect(p.locator(".color-palette-swatches .swatch")).toHaveCount(3);
      await expect(p.locator("main span.label")).toHaveCount(3);

      // MoonBit section's info-box body.
      await expect(p.locator(".info-box strong")).toBeVisible();

      // Web Component island must hydrate — once connected it injects
      // its own buttons + .count span.
      await expect(
        p.locator("my-counter button[data-act=inc]"),
        "island button should hydrate",
      ).toBeVisible();
      await expect(p.locator("my-counter .count")).toBeVisible();

      // Wait for fonts / images / island JS to settle so the screenshot
      // is taken after the page's idle layout.
      await p.evaluate(() => document.fonts?.ready);
      await p.waitForLoadState("networkidle");

      await expect(p).toHaveScreenshot(`components-${page.name}.png`, {
        fullPage: true,
      });
    });
  }
});

test("React and MoonBit pages contain actual SSR output", async ({ page }) => {
  for (const [path, component] of [
    ["/color_palette/", ".color-palette-component"],
    ["/info_box/", ".info-box-component"],
  ]) {
    const response = await page.goto(path);
    expect(response?.status()).toBe(200);
    await expect(page.locator(component)).toBeVisible();
    await expect(page.locator('[data-ssr="pending"], [data-ssr="failed"]')).toHaveCount(0);
  }
});

test("sidebar hydrates and supports keyboard navigation", async ({ page }) => {
  const response = await page.request.get("/components/sidebar-disclosure.js");
  expect(response.status()).toBe(200);
  expect(response.headers()["content-type"]).toMatch(/javascript/);
  await page.goto("/color_palette/");
  const sidebar = page.locator("aside.sidebar");
  await expect(sidebar).toHaveAttribute("data-hydrated", "true");
  const summaries = sidebar.locator("details.sidebar-collapse > summary");
  await expect(summaries).toHaveCount(2);
  await summaries.first().focus();
  await page.keyboard.press("End");
  await expect(summaries.last()).toBeFocused();
  await page.keyboard.press("Home");
  await expect(summaries.first()).toBeFocused();
});

test("counter island responds to clicks", async ({ page }) => {
  await page.goto("/");
  const counter = page.locator("my-counter");
  await expect(counter.locator(".count")).toHaveText("0");
  await counter.getByRole("button", { name: "increment", exact: true }).click();
  await expect(counter.locator(".count")).toHaveText("1");
  await counter.getByRole("button", { name: "decrement", exact: true }).click();
  await expect(counter.locator(".count")).toHaveText("0");
});
