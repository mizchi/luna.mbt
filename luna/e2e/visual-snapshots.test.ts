import { test, expect } from "@playwright/test";

// Visual snapshot tests for CSS regression testing
// Run `pnpm playwright test e2e/visual-snapshots.test.ts --update-snapshots` to update baselines
// These tests ensure CSS changes don't break visual appearance

test.describe("Visual Snapshots", () => {
  test.describe("WC Example", () => {
    test("full page snapshot", async ({ page }) => {
      await page.goto("/demo/wc");

      // Wait for all custom elements to be defined
      await page.waitForFunction(
        () =>
          customElements.get("wc-counter") &&
          customElements.get("wc-input") &&
          customElements.get("wc-effect") &&
          customElements.get("wc-style") &&
          customElements.get("wc-todo") &&
          customElements.get("wc-child-button") &&
          customElements.get("wc-nested-parent")
      );

      // Wait for initial render to complete
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot("wc-full-page.png", {
        fullPage: true,
        maxDiffPixelRatio: 0.01,
      });
    });

    test("wc-counter component", async ({ page }) => {
      await page.goto("/demo/wc");
      await page.waitForFunction(() => customElements.get("wc-counter"));
      await page.waitForTimeout(200);

      const counter = page.locator("wc-counter");
      await expect(counter).toHaveScreenshot("wc-counter.png");
    });

    test("wc-style component", async ({ page }) => {
      await page.goto("/demo/wc");
      await page.waitForFunction(() => customElements.get("wc-style"));
      await page.waitForTimeout(200);

      const style = page.locator("wc-style");
      await expect(style).toHaveScreenshot("wc-style.png");
    });

    test("wc-todo component", async ({ page }) => {
      await page.goto("/demo/wc");
      await page.waitForFunction(() => customElements.get("wc-todo"));
      await page.waitForTimeout(200);

      const todo = page.locator("wc-todo");
      await expect(todo).toHaveScreenshot("wc-todo.png");
    });

    test("wc-nested-parent component", async ({ page }) => {
      await page.goto("/demo/wc");
      await page.waitForFunction(
        () =>
          customElements.get("wc-child-button") &&
          customElements.get("wc-nested-parent")
      );
      await page.waitForTimeout(200);

      const nested = page.locator("wc-nested-parent");
      await expect(nested).toHaveScreenshot("wc-nested-parent.png");
    });
  });

  test.describe("SPA Example", () => {
    test("full page snapshot", async ({ page }) => {
      await page.goto("/spa");
      await page.waitForSelector("h1");
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot("spa-full-page.png", {
        fullPage: true,
      });
    });

    test("counter section", async ({ page }) => {
      await page.goto("/spa");
      await page.waitForSelector(".counter-example");
      await page.waitForTimeout(200);

      const counter = page.locator(".counter-example");
      await expect(counter).toHaveScreenshot("spa-counter.png");
    });

    test("style section", async ({ page }) => {
      await page.goto("/spa");
      await page.waitForSelector(".style-example");

      // Wait for the color box to have a style attribute
      await page.waitForFunction(() => {
        const box = document.querySelector(".style-example > div");
        return box && box.getAttribute("style")?.includes("hsl");
      });

      const style = page.locator(".style-example");
      await expect(style).toHaveScreenshot("spa-style.png");
    });

    test("modal section", async ({ page }) => {
      await page.goto("/spa");
      await page.waitForSelector(".modal-example");
      await page.waitForTimeout(200);

      const modal = page.locator(".modal-example");
      await expect(modal).toHaveScreenshot("spa-modal-closed.png");
    });
  });

  test.describe("TodoMVC Example", () => {
    test("empty state", async ({ page }) => {
      await page.goto("/todomvc");
      await page.evaluate(() => localStorage.clear());
      await page.reload();
      await page.waitForSelector(".todoapp");
      await page.waitForTimeout(300);

      await expect(page).toHaveScreenshot("todomvc-empty.png", {
        fullPage: true,
      });
    });

    test("with todos", async ({ page }) => {
      await page.goto("/todomvc");
      await page.evaluate(() => localStorage.clear());
      await page.reload();
      await page.waitForSelector(".todoapp");

      // Add some todos
      const input = page.locator(".new-todo");
      await input.fill("Buy milk");
      await input.press("Enter");
      await input.fill("Walk the dog");
      await input.press("Enter");
      await input.fill("Do laundry");
      await input.press("Enter");

      // Toggle one as completed
      await page.locator(".todo-list li").first().locator(".toggle").click();

      await page.waitForTimeout(300);

      await expect(page).toHaveScreenshot("todomvc-with-todos.png", {
        fullPage: true,
      });
    });

    test("footer and filters", async ({ page }) => {
      await page.goto("/todomvc");
      await page.evaluate(() => localStorage.clear());
      await page.reload();
      await page.waitForSelector(".todoapp");

      // Add todos to show footer
      const input = page.locator(".new-todo");
      await input.fill("Test todo");
      await input.press("Enter");

      await page.waitForTimeout(200);

      const footer = page.locator(".footer");
      await expect(footer).toHaveScreenshot("todomvc-footer.png");
    });
  });
});
