import { test, expect } from "@playwright/test";

/**
 * Navigation + Hydration Verification E2E Tests
 *
 * These tests specifically verify that hydration occurs correctly after navigation.
 * This is a common failure point when:
 * - Islands are not re-discovered after CSR navigation
 * - Event handlers are not re-attached
 * - State is not properly initialized
 *
 * Hydration is verified by checking that event handlers work, not by checking attributes.
 */
test.describe("Navigation + Hydration Verification", () => {
  const BASE_URL = "http://localhost:3457";

  // Helper to wait for hydration by checking if counter works
  async function waitForHydration(page: import("@playwright/test").Page) {
    // Wait for island element to be visible
    await expect(page.locator('[luna\\:id="_static/counter_js"]')).toBeVisible({
      timeout: 5000,
    });
    // Wait a bit for hydration scripts to execute
    await page.waitForTimeout(1500);
  }

  // Helper to verify counter functionality (proves hydration worked)
  async function verifyCounterWorks(page: import("@playwright/test").Page) {
    const display = page.locator(".count-display");
    const incButton = page.locator("button.inc");

    // Get initial value
    const initial = await display.textContent();
    const initialNum = parseInt(initial || "0", 10);

    // Click and verify increment
    await incButton.click();
    await page.waitForTimeout(100);

    const after = await display.textContent();
    expect(parseInt(after || "0", 10)).toBe(initialNum + 1);
  }

  test.describe("Hydration after CSR Navigation", () => {
    test("counter works after initial load", async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });

    test("counter works after CSR navigation (home -> about -> home)", async ({
      page,
    }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);

      // Navigate away
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Navigate back
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      // Verify hydration by checking counter works
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });

    test("counter works after multiple round-trip navigations", async ({
      page,
    }) => {
      await page.goto(BASE_URL);

      for (let i = 0; i < 3; i++) {
        // Navigate to about
        await page.click('[data-sol-link][href="/about"]');
        await page.waitForURL(`${BASE_URL}/about`);

        // Navigate back
        await page.click('[data-sol-link][href="/"]');
        await page.waitForURL(`${BASE_URL}/`);
      }

      // Final verification - counter should still work
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });
  });

  test.describe("Decrement Handler Verification", () => {
    test("decrement works after navigation", async ({ page }) => {
      await page.goto(BASE_URL);

      // Navigate away and back
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      await waitForHydration(page);

      const display = page.locator(".count-display");
      const decButton = page.locator("button.dec");

      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      await decButton.click();
      await page.waitForTimeout(100);

      const after = await display.textContent();
      expect(parseInt(after || "0", 10)).toBe(initialNum - 1);
    });
  });

  test.describe("State Behavior after Navigation", () => {
    test("state is fresh (server-rendered) after navigation", async ({
      page,
    }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);

      const display = page.locator(".count-display");
      const incButton = page.locator("button.inc");

      // Modify state
      await incButton.click();
      await incButton.click();
      await incButton.click();
      await page.waitForTimeout(100);

      const modifiedValue = await display.textContent();

      // Navigate away
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Navigate back
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      await waitForHydration(page);

      // State should be reset (server generates new initial value)
      const newValue = await display.textContent();

      // CSR navigation fetches new HTML, so state is re-initialized
      // This verifies the component was re-rendered server-side
      expect(newValue).not.toBe(modifiedValue);
    });
  });

  test.describe("Browser History + Hydration", () => {
    test("hydration works after browser back button", async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);

      // Navigate to about via CSR
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Use browser back button
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);

      // Verify hydration by checking counter works
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });

    test("hydration works after browser forward then back", async ({
      page,
    }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);

      // Navigate to about
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Go back
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);

      // Go forward
      await page.goForward();
      await page.waitForURL(`${BASE_URL}/about`);

      // Go back again
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);

      // Verify hydration still works
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });
  });

  test.describe("Direct URL Access (MPA)", () => {
    test("hydration works on direct URL access", async ({ page }) => {
      // Direct access (not CSR navigation)
      await page.goto(BASE_URL);
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });

    test("hydration works after page reload", async ({ page }) => {
      await page.goto(BASE_URL);
      await waitForHydration(page);

      // Modify state
      const incButton = page.locator("button.inc");
      await incButton.click();
      await incButton.click();

      // Reload page
      await page.reload();

      // Verify hydration works after reload
      await waitForHydration(page);
      await verifyCounterWorks(page);
    });
  });

  test.describe("Layout Integrity after Navigation", () => {
    test("layout is not duplicated after CSR navigation", async ({ page }) => {
      await page.goto(BASE_URL);

      // Count nav elements - should be exactly 1
      const navCount = await page.locator("nav").count();
      expect(navCount).toBe(1);

      // Navigate multiple times
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      // After CSR navigation, nav should still be exactly 1
      const navCountAfter = await page.locator("nav").count();
      expect(navCountAfter).toBe(1);
    });
  });
});
