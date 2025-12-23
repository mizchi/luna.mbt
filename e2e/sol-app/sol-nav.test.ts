import { test, expect } from "@playwright/test";

/**
 * E2E tests for Sol CSR Navigation
 * Tests client-side routing with sol-link and sol-nav.js
 */
test.describe("Sol CSR Navigation", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("Basic CSR Navigation", () => {
    test("navigates from home to about via CSR", async ({ page }) => {
      await page.goto(BASE_URL);

      // Verify we're on home page
      await expect(page.locator("h1")).toContainText("Welcome to Sol");

      // Count navigation links before click
      const navLinks = page.locator("nav a");
      const initialLinkCount = await navLinks.count();

      // Click About link (should be CSR)
      await page.click('[data-sol-link][href="/about"]');

      // Wait for navigation
      await page.waitForURL(`${BASE_URL}/about`);

      // Verify content changed
      await expect(page.locator("h1")).toContainText("About");

      // Verify layout is NOT duplicated - nav should appear only once
      const navLinksAfter = page.locator("nav a");
      const afterLinkCount = await navLinksAfter.count();
      expect(afterLinkCount).toBe(initialLinkCount);
    });

    test("navigates from about to home via CSR", async ({ page }) => {
      await page.goto(`${BASE_URL}/about`);

      // Verify we're on about page
      await expect(page.locator("h1")).toContainText("About");

      // Click Home link
      await page.click('[data-sol-link][href="/"]');

      // Wait for navigation
      await page.waitForURL(`${BASE_URL}/`);

      // Verify content changed
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });

    test("layout should not be duplicated after navigation", async ({ page }) => {
      await page.goto(BASE_URL);

      // Count nav elements - should be exactly 1
      const navCount = await page.locator("nav").count();
      expect(navCount).toBe(1);

      // Navigate to about
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // After CSR navigation, nav should still be exactly 1
      const navCountAfter = await page.locator("nav").count();
      expect(navCountAfter).toBe(1);

      // Navigate back to home
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      // Still exactly 1 nav
      const navCountFinal = await page.locator("nav").count();
      expect(navCountFinal).toBe(1);
    });
  });

  test.describe("Island Re-hydration after CSR", () => {
    test("counter island works after navigating away and back", async ({ page }) => {
      await page.goto(BASE_URL);

      // Wait for automatic hydration by loader.js
      await page.waitForTimeout(1500);

      // Verify counter works initially
      const display = page.locator(".count-display");
      const incButton = page.locator("button.inc");

      // Get initial value (server-generated random number)
      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      await incButton.click();
      await page.waitForTimeout(100);

      // Verify increment worked
      const afterClick = await display.textContent();
      expect(parseInt(afterClick || "0", 10)).toBe(initialNum + 1);

      // Navigate to about
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");

      // Navigate back to home
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");

      // Wait for re-hydration
      await page.waitForTimeout(1500);

      // Counter should be reset to server-rendered initial state
      const displayAfter = page.locator(".count-display");
      const incButtonAfter = page.locator("button.inc");

      // Get new initial value (different random number from server)
      const newInitial = await displayAfter.textContent();
      const newInitialNum = parseInt(newInitial || "0", 10);

      // Click should work after re-hydration
      await incButtonAfter.click();
      await page.waitForTimeout(100);

      const afterRehydrate = await displayAfter.textContent();
      expect(parseInt(afterRehydrate || "0", 10)).toBe(newInitialNum + 1);
    });

    test("counter re-hydrates automatically after CSR navigation", async ({ page }) => {
      // This test verifies the loader properly re-hydrates islands after CSR nav
      await page.goto(BASE_URL);

      // Wait for initial load and hydration
      await page.waitForTimeout(1500);

      // Navigate away
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Navigate back
      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      // Wait for re-hydration
      await page.waitForTimeout(1500);

      // Try clicking increment - if re-hydration worked, this should work
      const display = page.locator(".count-display");
      const incButton = page.locator("button.inc");

      // Check that island exists (using new ID format)
      await expect(page.locator('[luna\\:id="_static/counter_js"]')).toBeVisible();

      // Get initial value
      const initial = await display.textContent();
      const initialNum = parseInt(initial || "0", 10);

      // Click the button
      await incButton.click();
      await page.waitForTimeout(100);

      // If re-hydration worked, counter should increment
      const value = await display.textContent();
      expect(parseInt(value || "0", 10)).toBe(initialNum + 1);
    });
  });

  test.describe("Browser History", () => {
    test("browser back button works after CSR navigation", async ({ page }) => {
      await page.goto(BASE_URL);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");

      // Navigate to about via CSR
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");

      // Press browser back
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);
      await expect(page.locator("h1")).toContainText("Welcome to Sol");
    });

    test("browser forward button works after back", async ({ page }) => {
      await page.goto(BASE_URL);

      // Navigate to about
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Go back
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);

      // Go forward
      await page.goForward();
      await page.waitForURL(`${BASE_URL}/about`);
      await expect(page.locator("h1")).toContainText("About");
    });

    test("multiple navigation and back works correctly", async ({ page }) => {
      await page.goto(BASE_URL);

      // Home -> About -> Home -> About
      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      await page.click('[data-sol-link][href="/"]');
      await page.waitForURL(`${BASE_URL}/`);

      await page.click('[data-sol-link][href="/about"]');
      await page.waitForURL(`${BASE_URL}/about`);

      // Now back twice
      await page.goBack();
      await page.waitForURL(`${BASE_URL}/`);

      await page.goBack();
      await page.waitForURL(`${BASE_URL}/about`);

      await expect(page.locator("h1")).toContainText("About");
    });
  });
});
