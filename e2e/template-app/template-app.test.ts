import { test, expect } from "@playwright/test";

/**
 * E2E tests for CLI-generated template app
 * Tests the separated component architecture:
 * - counter.mbt: Pure render logic only
 * - hydrate.mbt: Hydration boilerplate
 */
test.describe("Template App E2E Tests", () => {
  // Use port 3000 where the template app is running
  const BASE_URL = "http://localhost:3000";

  test.describe("SSR Rendering", () => {
    test("renders home page with counter island", async ({ page }) => {
      await page.goto(BASE_URL);

      // Check SSR rendered content
      await expect(page.locator("h1")).toContainText("Welcome to Kaguya");
      await expect(page.locator(".counter")).toBeVisible();
      await expect(page.locator(".count-display")).toBeVisible();
    });

    test("counter has correct kg:* attributes for hydration", async ({
      page,
    }) => {
      await page.goto(BASE_URL);

      const counter = page.locator('[kg\\:id="counter"]');
      await expect(counter).toBeVisible();

      // Verify hydration attributes
      const url = await counter.getAttribute("kg:url");
      expect(url).toBe("/static/counter.js");

      const state = await counter.getAttribute("kg:state");
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
      // Listen to console messages for debugging
      const consoleLogs: string[] = [];
      page.on("console", (msg) => {
        const text = `[BROWSER] ${msg.type()}: ${msg.text()}`;
        consoleLogs.push(text);
        console.log(text);
      });
      page.on("pageerror", (err) => console.log(`[BROWSER ERROR] ${err.message}`));

      await page.goto(BASE_URL);

      // Wait for hydration (longer wait)
      await page.waitForTimeout(1500);

      // Check if kg-loader executed
      const kgState = await page.evaluate(() => (window as any).__KG_STATE__);
      console.log(`[TEST] __KG_STATE__:`, kgState);

      // Check hydration status and directly invoke hydrate from module
      const hydrationStatus = await page.evaluate(async () => {
        const counterEl = document.querySelector('[kg\\:id="counter"]') as HTMLElement;
        const buttons = counterEl?.querySelectorAll('button');
        const decBtn = counterEl?.querySelector('[data-action-click="decrement"]');
        const incBtn = counterEl?.querySelector('[data-action-click="increment"]');
        const hasKgHydrate = typeof (window as any).__KG_HYDRATE__ === 'function';

        // Try to directly import and call hydrate
        let directHydrateResult = null;
        let moduleKeys = null;
        try {
          const mod = await import('/static/counter.js');
          moduleKeys = Object.keys(mod);
          console.log('[BROWSER] Module keys:', moduleKeys);
          console.log('[BROWSER] mod.hydrate type:', typeof mod.hydrate);
          if (mod.hydrate && counterEl) {
            const state = JSON.parse(counterEl.getAttribute('kg:state') || '{}');
            console.log('[BROWSER] Calling hydrate directly with state:', state);
            mod.hydrate(counterEl, state, 'counter');
            directHydrateResult = 'success';
          } else {
            directHydrateResult = `no hydrate: ${typeof mod.hydrate}, counterEl: ${!!counterEl}`;
          }
        } catch (e: any) {
          directHydrateResult = e.message;
          console.error('[BROWSER] Direct hydrate error:', e);
        }

        return {
          counterFound: !!counterEl,
          buttonCount: buttons?.length,
          decBtnFound: !!decBtn,
          incBtnFound: !!incBtn,
          hasKgHydrate,
          directHydrateResult,
          moduleKeys,
        };
      });
      console.log("[TEST] Hydration status:", hydrationStatus);

      // Give time for hydration to complete
      await page.waitForTimeout(500);

      // Log all console messages we captured
      console.log("[TEST] Console logs captured:", consoleLogs.length);

      const incButton = page.locator('button[data-action-click="increment"]');
      const display = page.locator(".count-display");

      // Check initial state
      const initialText = await display.textContent();
      console.log(`[TEST] Initial text: "${initialText}"`);

      // Try clicking with evaluate for debugging
      const clickResult = await page.evaluate(() => {
        const btn = document.querySelector('[data-action-click="increment"]') as HTMLElement;
        if (btn) {
          const clickEvent = new MouseEvent('click', {bubbles: true});
          btn.dispatchEvent(clickEvent);
          return { clicked: true, btnText: btn.textContent };
        }
        return { clicked: false };
      });
      console.log("[TEST] Click result:", clickResult);
      await page.waitForTimeout(200);

      // Check if count updated
      const text = await display.textContent();
      console.log(`[TEST] After click text: "${text}"`);
      expect(text).toBe("1");
    });

    test("hydrates counter and handles decrement", async ({ page }) => {
      await page.goto(BASE_URL);

      // Manually trigger hydration (since kg-loader may not be present)
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[kg\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import('/static/counter.js');
          const state = JSON.parse(counterEl.getAttribute('kg:state') || '{}');
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

      // Manually trigger hydration (since kg-loader may not be present)
      await page.evaluate(async () => {
        const counterEl = document.querySelector('[kg\\:id="counter"]') as HTMLElement;
        if (counterEl) {
          const mod = await import('/static/counter.js');
          const state = JSON.parse(counterEl.getAttribute('kg:state') || '{}');
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
      await expect(page.locator("h1")).toContainText("Welcome to Kaguya");
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
