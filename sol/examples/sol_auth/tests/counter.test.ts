import { test, expect } from '@playwright/test';

test.describe('Counter Island Hydration', () => {
  test('should render SSR content initially', async ({ page }) => {
    await page.goto('/');

    // Check SSR rendered content
    const counter = page.locator('.counter');
    await expect(counter).toBeVisible();

    // Initial value is server-generated random number, just verify it exists
    const countDisplay = page.locator('.count-display');
    await expect(countDisplay).toBeVisible();
    const initialText = await countDisplay.textContent();
    expect(initialText).not.toBeNull();
    expect(parseInt(initialText || '0', 10)).toBeGreaterThanOrEqual(0);
  });

  test('should hydrate and increment counter on click', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration (loader script to execute)
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');
    const initialText = await countDisplay.textContent();
    const initialValue = parseInt(initialText || '0', 10);

    // Click increment button
    const incButton = page.locator('button.inc');
    await incButton.click();

    // Counter should increase by 1 from initial value
    await expect(countDisplay).toHaveText(String(initialValue + 1));
  });

  test('should decrement counter on click', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');
    const initialText = await countDisplay.textContent();
    const initialValue = parseInt(initialText || '0', 10);

    // Click increment first
    const incButton = page.locator('button.inc');
    await incButton.click();
    await expect(countDisplay).toHaveText(String(initialValue + 1));

    // Click decrement - should go back to initial value
    const decButton = page.locator('button.dec');
    await decButton.click();
    await expect(countDisplay).toHaveText(String(initialValue));
  });

  test('should handle multiple clicks', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForTimeout(500);

    const countDisplay = page.locator('.count-display');
    const initialText = await countDisplay.textContent();
    const initialValue = parseInt(initialText || '0', 10);

    const incButton = page.locator('button.inc');

    // Click multiple times
    await incButton.click();
    await incButton.click();
    await incButton.click();

    // Counter should increase by 3 from initial value
    await expect(countDisplay).toHaveText(String(initialValue + 3));
  });
});
