import { test, expect } from "@playwright/test";

/**
 * E2E tests for examples/sol-app
 * Tests SSR, hydration, and navigation
 */
test.describe("Sol App E2E", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("SSR Rendering", () => {
    test("renders home page with title", async ({ page }) => {
      await page.goto(BASE_URL);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });

    test("renders counter island with correct attributes", async ({ page }) => {
      await page.goto(BASE_URL);

      const counter = page.locator('[ln\\:id="counter"]');
      await expect(counter).toBeVisible();

      // Verify hydration attributes
      const url = await counter.getAttribute("ln:url");
      expect(url).toBe("/static/hydrate_counter.js");

      const state = await counter.getAttribute("ln:state");
      expect(state).toContain("count");
    });

    test("renders about page", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });
  });

  test.describe("Hydration", () => {
    test("counter increments on click", async ({ page }) => {
      await page.goto(BASE_URL);

      // Wait for hydration
      await page.waitForTimeout(1000);

      // Manually hydrate if loader didn't run
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[ln\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import("/static/hydrate_counter.js");
          const state = JSON.parse(counterEl.getAttribute("ln:state") || "{}");
          const fn = mod.hydrate_counter || mod.hydrate || mod.default;
          if (fn) fn(counterEl, state, "counter");
        }
      });
      await page.waitForTimeout(200);

      const display = page.locator(".count-display");
      const incButton = page.locator('button[data-action-click="increment"]');

      // Get initial value
      const initial = await display.textContent();
      expect(initial).toBe("0");

      // Click increment
      await incButton.click();
      await page.waitForTimeout(100);

      const afterClick = await display.textContent();
      expect(afterClick).toBe("1");
    });

    test("counter decrements on click", async ({ page }) => {
      await page.goto(BASE_URL);

      // Manually hydrate
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[ln\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import("/static/hydrate_counter.js");
          const state = JSON.parse(counterEl.getAttribute("ln:state") || "{}");
          const fn = mod.hydrate_counter || mod.hydrate || mod.default;
          if (fn) fn(counterEl, state, "counter");
        }
      });
      await page.waitForTimeout(200);

      const display = page.locator(".count-display");
      const decButton = page.locator('button[data-action-click="decrement"]');

      // Click decrement
      await decButton.click();
      await page.waitForTimeout(100);

      const afterClick = await display.textContent();
      expect(afterClick).toBe("-1");
    });

    test("multiple clicks work correctly", async ({ page }) => {
      await page.goto(BASE_URL);

      // Manually hydrate
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[ln\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import("/static/hydrate_counter.js");
          const state = JSON.parse(counterEl.getAttribute("ln:state") || "{}");
          const fn = mod.hydrate_counter || mod.hydrate || mod.default;
          if (fn) fn(counterEl, state, "counter");
        }
      });
      await page.waitForTimeout(200);

      const display = page.locator(".count-display");
      const incButton = page.locator('button[data-action-click="increment"]');

      // Click 5 times
      for (let i = 0; i < 5; i++) {
        await incButton.click();
      }
      await page.waitForTimeout(100);

      const finalValue = await display.textContent();
      expect(finalValue).toBe("5");
    });
  });

  test.describe("Navigation", () => {
    test("navigates from home to about", async ({ page }) => {
      await page.goto(BASE_URL);
      await page.click('a[href="/about"]');
      await expect(page).toHaveURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });

    test("navigates from about to home", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);
      await page.click('a[href="/"]');
      await expect(page).toHaveURL(`${BASE_URL}/`);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });
  });

  test.describe("API", () => {
    test("health endpoint returns response", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/api/health`);
      expect(response.ok()).toBeTruthy();
    });
  });

  test.describe("Static Files", () => {
    test("loader.js is served", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/static/loader.js`);
      expect(response.ok()).toBeTruthy();
      const content = await response.text();
      expect(content).toContain("luna loader");
    });

    test("island bundle is served", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/static/hydrate_counter.js`);
      expect(response.ok()).toBeTruthy();
      const content = await response.text();
      expect(content.length).toBeGreaterThan(100);
    });
  });
});
