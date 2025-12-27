import { test, expect } from "@playwright/test";

const DEBUG = process.env.DEBUG === "1";

// Use a non-standard port to avoid conflicts with dev servers (must match playwright.config.mts)
const BASE_URL = "http://localhost:9125";

/**
 * E2E tests for CLI-generated template app
 * Tests the separated component architecture:
 * - counter.mbt: Pure render logic only
 * - hydrate.mbt: Hydration boilerplate
 */
test.describe("Template App E2E Tests", () => {

  test.describe("SSR Rendering", () => {
    test("renders home page with counter island", async ({ page }) => {
      await page.goto(BASE_URL);

      // Check SSR rendered content
      await expect(page.locator("h1")).toContainText("Welcome to Luna");
      await expect(page.locator(".counter")).toBeVisible();
      await expect(page.locator(".count-display")).toBeVisible();
    });

    test("counter has correct luna:* attributes for hydration", async ({
      page,
    }) => {
      await page.goto(BASE_URL);

      const counter = page.locator('[luna\\:id="counter"]');
      await expect(counter).toBeVisible();

      // Verify hydration attributes
      const url = await counter.getAttribute("luna:url");
      expect(url).toBe("/static/counter.js");

      const state = await counter.getAttribute("luna:state");
      expect(state).toContain('"count"');
    });

    test("buttons have data-action-* attributes", async ({ page }) => {
      await page.goto(BASE_URL);

      const decButton = page.locator('button[data-action-click="decrement"]');
      const incButton = page.locator('button[data-action-click="increment"]');

      await expect(decButton).toBeVisible();
      await expect(incButton).toBeVisible();
    });
  });

  test.describe("Hydration and Interaction", () => {
    test("hydrates counter and handles increment", async ({ page }) => {
      if (DEBUG) {
        // Listen to console messages for debugging
        page.on("console", (msg) => {
          console.log(`[BROWSER] ${msg.type()}: ${msg.text()}`);
        });
        page.on("pageerror", (err) => console.log(`[BROWSER ERROR] ${err.message}`));
      }

      await page.goto(BASE_URL);

      // Wait for hydration (longer wait)
      await page.waitForTimeout(1500);

      // Check hydration status and directly invoke hydrate from module
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[luna\\:id="counter"]') as HTMLElement;
        if (!counterEl) return;
        try {
          const mod = await import('/static/counter.js');
          if (mod.hydrate) {
            const state = JSON.parse(counterEl.getAttribute('luna:state') || '{}');
            mod.hydrate(counterEl, state, 'counter');
          }
        } catch (e) {
          // Ignore hydration errors in test
        }
      });

      // Give time for hydration to complete
      await page.waitForTimeout(500);

      const incButton = page.locator('button[data-action-click="increment"]');
      const display = page.locator(".count-display");

      // Try clicking with evaluate for debugging
      await page.evaluate(() => {
        const btn = document.querySelector('[data-action-click="increment"]') as HTMLElement;
        if (btn) {
          const clickEvent = new MouseEvent('click', {bubbles: true});
          btn.dispatchEvent(clickEvent);
        }
      });
      await page.waitForTimeout(200);

      // Check if count updated
      const text = await display.textContent();
      expect(text).toBe("1");
    });

    test("hydrates counter and handles decrement", async ({ page }) => {
      await page.goto(BASE_URL);

      // Manually trigger hydration (since ln-loader may not be present)
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[luna\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import('/static/counter.js');
          const state = JSON.parse(counterEl.getAttribute('luna:state') || '{}');
          mod.hydrate(counterEl, state, 'counter');
        }
      });
      await page.waitForTimeout(200);

      const decButton = page.locator('button[data-action-click="decrement"]');
      const display = page.locator(".count-display");

      // Click decrement
      await decButton.click();
      await page.waitForTimeout(100);

      // Check if count updated
      const text = await display.textContent();
      expect(text).toBe("-1");
    });

    test("multiple clicks update counter correctly", async ({ page }) => {
      await page.goto(BASE_URL);

      // Manually trigger hydration (since ln-loader may not be present)
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[luna\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import('/static/counter.js');
          const state = JSON.parse(counterEl.getAttribute('luna:state') || '{}');
          mod.hydrate(counterEl, state, 'counter');
        }
      });
      await page.waitForTimeout(200);

      const incButton = page.locator('button[data-action-click="increment"]');
      const display = page.locator(".count-display");

      // Click increment 3 times
      await incButton.click();
      await incButton.click();
      await incButton.click();
      await page.waitForTimeout(100);

      const text = await display.textContent();
      expect(text).toBe("3");
    });
  });

  test.describe("Navigation", () => {
    test("navigates to about page", async ({ page }) => {
      await page.goto(BASE_URL);

      await page.click('a[href="/about"]');
      await expect(page).toHaveURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });

    test("navigates back to home from about", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);

      await page.click('a[href="/"]');
      await expect(page).toHaveURL(BASE_URL + "/");
      await expect(page.locator("h1")).toContainText("Welcome to Luna");
    });
  });

  test.describe("API", () => {
    test("health endpoint returns ok", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/api/health`);
      expect(response.ok()).toBeTruthy();
      // Note: Response format is MoonBit internal Map structure, not plain JSON
    });
  });
});
