// Smoke tests for the deployed luna-examples worker.
//
// These run against a live URL (default: https://luna-examples.mizchi.workers.dev,
// override with LUNA_EXAMPLES_URL) and assert that:
//   - each example renders its expected DOM
//   - inline CSS is reaching the browser (computed styles match the HTML
//     `<style>` block — i.e. no asset stripped during build/deploy)
//   - moonbit-built JS is loaded and reaches steady state (counts, custom
//     elements, router base path)
//
// Run:
//   pnpm exec playwright test --config=luna/e2e/deployed/playwright.config.mts
import { test, expect } from "@playwright/test";

test.describe("luna-examples deploy smoke", () => {
  test("landing renders 7 demo links with styled cards", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle("Luna UI Demos");
    await expect(page.locator("h1")).toHaveText("Luna UI Demos");

    const links = page.locator(".demo-link");
    await expect(links).toHaveCount(7);

    // CSS reached: rounded card with white bg on #fafafa body.
    await expect(page.locator("body")).toHaveCSS(
      "background-color",
      "rgb(250, 250, 250)",
    );
    const firstCard = links.first();
    await expect(firstCard).toHaveCSS("background-color", "rgb(255, 255, 255)");
    await expect(firstCard).toHaveCSS("border-radius", "8px");
    await expect(firstCard).toHaveCSS("padding", "20px");

    // Each card links to its example bucket (no /demo/ prefix leaked).
    const hrefs = await links.evaluateAll((els) =>
      els.map((el) => (el as HTMLAnchorElement).getAttribute("href")),
    );
    expect(hrefs).toEqual([
      "./hello_luna/",
      "./todomvc/",
      "./spa/",
      "./browser_router/",
      "./game/",
      "./wc/",
      "./apg-playground/",
    ]);
  });

  test("hello_luna renders the moonbit counter", async ({ page }) => {
    await page.goto("/hello_luna/");
    const app = page.locator("#app");
    await expect(app).toContainText("Count: 0");
    await expect(app.locator("button")).toContainText("Increment");
  });

  test("spa renders all sections with reactive counter", async ({ page }) => {
    await page.goto("/spa/");
    await expect(page.locator("h1")).toHaveText("Luna Examples");
    await expect(page.locator("h2")).toHaveCount(7);

    // CSS reached: h2 border-bottom from inline <style>.
    await expect(page.locator("h2").first()).toHaveCSS(
      "border-bottom-color",
      "rgb(221, 221, 221)",
    );

    // Counter wiring works end-to-end through the rebuilt JS.
    const counter = page.locator(".counter-example");
    await expect(counter.locator("p").first()).toContainText("Count: 0");
    await counter.locator("button", { hasText: "+" }).click();
    await expect(counter.locator("p").first()).toContainText("Count: 1");
  });

  test("todomvc loads with TodoMVC chrome and accepts a todo", async ({
    page,
  }) => {
    await page.goto("/todomvc/");
    const todoApp = page.locator(".todoapp");
    await expect(todoApp).toBeVisible();

    // CSS reached: signature TodoMVC styles (h1 red, body Helvetica Neue,
    // 80px h1, white app bg).
    await expect(page.locator("body")).toHaveCSS(
      "font-family",
      /Helvetica Neue/,
    );
    await expect(page.locator("h1")).toHaveCSS("color", "rgb(184, 63, 69)");
    await expect(page.locator("h1")).toHaveCSS("font-size", "80px");
    await expect(todoApp).toHaveCSS("background-color", "rgb(255, 255, 255)");

    // Functional smoke: input is wired.
    const input = page.locator(".new-todo");
    await expect(input).toBeVisible();
    await input.fill("ship the demo");
    await input.press("Enter");
    await expect(page.locator(".todo-list li")).toHaveCount(1);
  });

  test("browser_router mounts at /browser_router (no /demo/ leak)", async ({
    page,
  }) => {
    await page.goto("/browser_router/");

    // The bug we fixed: stale "/demo/browser_router" base produced a 404 view
    // here. Make sure the home view is rendered instead.
    await expect(page.locator("body")).not.toContainText("404 - Not Found");
    await expect(page.locator("body")).toContainText("Welcome to Browser App");

    // Nav links point at /browser_router/* — without /demo/.
    const hrefs = await page
      .locator("a")
      .evaluateAll((els) =>
        els.map((el) => (el as HTMLAnchorElement).getAttribute("href")),
      );
    expect(hrefs).toContain("/browser_router");
    expect(hrefs).toContain("/browser_router/about");
    expect(hrefs.every((h) => !h?.startsWith("/demo/"))).toBe(true);
  });

  test("game mounts the grid and renders the FPS HUD", async ({ page }) => {
    await page.goto("/game/");
    await expect(page).toHaveTitle("Luna Benchmark Game");

    // Dark theme reached.
    await expect(page.locator("body")).toHaveCSS(
      "background-color",
      "rgb(26, 26, 46)",
    );

    // The grid produces thousands of cells once the loop is running.
    const cellCount = await page.locator("#app *").count();
    expect(cellCount).toBeGreaterThan(1000);

    // HUD copy reaches the page.
    await expect(page.locator("body")).toContainText(/FPS:/);
    await expect(page.locator("body")).toContainText(/Score:/);
  });

  test("wc registers all 7 custom elements", async ({ page }) => {
    await page.goto("/wc/");
    const tags = [
      "wc-counter",
      "wc-input",
      "wc-effect",
      "wc-conditional",
      "wc-style",
      "wc-todo",
      "wc-nested-parent",
    ];
    for (const tag of tags) {
      const defined = await page.evaluate(
        (name) => Boolean(customElements.get(name)),
        tag,
      );
      expect(defined, `${tag} should be defined`).toBe(true);
      await expect(page.locator(tag)).toHaveCount(1);
    }

    // Each component should have populated its shadow root (counter has
    // multiple children — placeholder DOM would be empty).
    const counterShadowKids = await page.evaluate(() => {
      const el = document.querySelector("wc-counter");
      return el?.shadowRoot?.children.length ?? 0;
    });
    expect(counterShadowKids).toBeGreaterThan(0);
  });

  test("apg-playground loads themed shell + color swatches", async ({
    page,
  }) => {
    await page.goto("/apg-playground/");
    await expect(page).toHaveTitle("Component Catalog - Luna UI");

    // CSS variables resolve to theme-correct values. Playwright defaults to
    // a "light" colorScheme, so the inline `:root` (light) values apply
    // unless a future test forces dark via emulateMedia.
    const vars = await page.evaluate(() => {
      const style = getComputedStyle(document.documentElement);
      return {
        bgPrimary: style.getPropertyValue("--bg-primary").trim(),
        textPrimary: style.getPropertyValue("--text-primary").trim(),
      };
    });
    // CSS landed if the custom properties resolve to non-empty hex tokens.
    expect(vars.bgPrimary).toMatch(/^#[0-9a-f]{3,6}$/i);
    expect(vars.textPrimary).toMatch(/^#[0-9a-f]{3,6}$/i);

    await expect(page.locator(".color-swatch")).toHaveCount(6);
    await expect(page.locator(".color-swatch").first()).toHaveCSS(
      "border-radius",
      "50%",
    );
  });
});
