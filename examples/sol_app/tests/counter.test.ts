import { test, expect } from '@playwright/test';

test.describe('Counter Island Hydration', () => {
  test('should render SSR content initially', async ({ page }) => {
    await page.goto('/');

    // Check SSR rendered content
    const counter = page.locator('.counter');
    await expect(counter).toBeVisible();

    const countDisplay = page.locator('.count-display');
    await expect(countDisplay).toHaveText('0');
  });

  test('should hydrate and increment counter on click', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration (loader script to execute)
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');
    await expect(countDisplay).toHaveText('0');

    // Click increment button
    const incButton = page.locator('button.inc');
    await incButton.click();

    // Counter should increase
    await expect(countDisplay).toHaveText('1');
  });

  test('should decrement counter on click', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');

    // Click increment first to have a positive value
    const incButton = page.locator('button.inc');
    await incButton.click();
    await expect(countDisplay).toHaveText('1');

    // Click decrement
    const decButton = page.locator('button.dec');
    await decButton.click();
    await expect(countDisplay).toHaveText('0');
  });

  test('should handle multiple clicks', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');
    const incButton = page.locator('button.inc');

    // Click multiple times
    await incButton.click();
    await incButton.click();
    await incButton.click();

    await expect(countDisplay).toHaveText('3');
  });
});
