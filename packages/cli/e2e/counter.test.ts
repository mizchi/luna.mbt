import { test, expect } from "@playwright/test";

test.describe("Counter Hydration", () => {
  test("displays initial count from SSR", async ({ page }) => {
    await page.goto("/");

    // Check initial SSR content
    const counter = page.locator('[kg\\:id="counter"]');
    await expect(counter).toBeVisible();

    const display = counter.locator(".count-display");
    await expect(display).toHaveText("Count: 0");
  });

  test("increments count when + button is clicked", async ({ page }) => {
    await page.goto("/");

    const counter = page.locator('[kg\\:id="counter"]');
    const display = counter.locator(".count-display");
    const incBtn = counter.locator(".inc");

    // Wait for hydration (loader to run)
    await page.waitForTimeout(1000);

    // Initial value
    await expect(display).toHaveText("Count: 0");

    // Click + button
    await incBtn.click();
    await expect(display).toHaveText("Count: 1");

    // Click again
    await incBtn.click();
    await expect(display).toHaveText("Count: 2");
  });

  test("decrements count when - button is clicked", async ({ page }) => {
    await page.goto("/");

    const counter = page.locator('[kg\\:id="counter"]');
    const display = counter.locator(".count-display");
    const decBtn = counter.locator(".dec");

    // Wait for hydration
    await page.waitForTimeout(1000);

    // Initial value
    await expect(display).toHaveText("Count: 0");

    // Click - button
    await decBtn.click();
    await expect(display).toHaveText("Count: -1");

    // Click again
    await decBtn.click();
    await expect(display).toHaveText("Count: -2");
  });

  test("both increment and decrement work together", async ({ page }) => {
    await page.goto("/");

    const counter = page.locator('[kg\\:id="counter"]');
    const display = counter.locator(".count-display");
    const incBtn = counter.locator(".inc");
    const decBtn = counter.locator(".dec");

    // Wait for hydration
    await page.waitForTimeout(1000);

    // Start at 0
    await expect(display).toHaveText("Count: 0");

    // Increment 3 times
    await incBtn.click();
    await incBtn.click();
    await incBtn.click();
    await expect(display).toHaveText("Count: 3");

    // Decrement once
    await decBtn.click();
    await expect(display).toHaveText("Count: 2");
  });
});
